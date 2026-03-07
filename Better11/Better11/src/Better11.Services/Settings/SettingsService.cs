// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using System.Text.Json;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Settings;

/// <summary>
/// Persists application settings to a JSON file under LocalApplicationData.
/// Implements <see cref="ISettingsService"/> with thread-safe get/set and lazy file I/O.
/// </summary>
public sealed class SettingsService : ISettingsService
{
    private static readonly JsonSerializerOptions IndentedOptions = new() { WriteIndented = true };

    private readonly string _filePath;
    private readonly ILogger<SettingsService> _logger;
    private readonly ConcurrentDictionary<string, string> _store = new();
    private readonly SemaphoreSlim _fileLock = new(1, 1);
    private bool _loaded;

    /// <summary>
    /// Initializes a new instance of the <see cref="SettingsService"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    public SettingsService(ILogger<SettingsService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        var baseDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Better11");
        Directory.CreateDirectory(baseDir);
        _filePath = Path.Combine(baseDir, "settings.json");
    }

    /// <inheritdoc/>
    public T GetValue<T>(string key, T defaultValue)
    {
        EnsureLoaded();
        if (_store.TryGetValue(key, out var raw))
        {
            try
            {
                var value = JsonSerializer.Deserialize<T>(raw);
                return value ?? defaultValue;
            }
            catch
            {
                return defaultValue;
            }
        }

        return defaultValue;
    }

    /// <inheritdoc/>
    public void SetValue<T>(string key, T value)
    {
        EnsureLoaded();
        var raw = JsonSerializer.Serialize(value);
        _store[key] = raw;
        _logger.LogDebug("Setting {Key} updated", key);
    }

    /// <inheritdoc/>
    public async Task SaveAsync(CancellationToken cancellationToken = default)
    {
        await _fileLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var snapshot = new Dictionary<string, string>(_store);
            var json = JsonSerializer.Serialize(snapshot, IndentedOptions);
            await File.WriteAllTextAsync(_filePath, json, cancellationToken).ConfigureAwait(false);
            _logger.LogDebug("Settings saved to {Path}", _filePath);
        }
        finally
        {
            _fileLock.Release();
        }
    }

    /// <inheritdoc/>
    public async Task LoadAsync(CancellationToken cancellationToken = default)
    {
        await _fileLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (!File.Exists(_filePath))
            {
                _loaded = true;
                return;
            }

            var json = await File.ReadAllTextAsync(_filePath, cancellationToken).ConfigureAwait(false);
            var dict = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
            if (dict != null)
            {
                foreach (var kv in dict)
                {
                    _store[kv.Key] = kv.Value;
                }
            }

            _loaded = true;
        }
        finally
        {
            _fileLock.Release();
        }
    }

    private void EnsureLoaded()
    {
        if (_loaded)
        {
            return;
        }

        _fileLock.Wait();
        try
        {
            if (_loaded)
            {
                return;
            }

            if (File.Exists(_filePath))
            {
                try
                {
                    var json = File.ReadAllText(_filePath);
                    var dict = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
                    if (dict != null)
                    {
                        foreach (var kv in dict)
                        {
                            _store[kv.Key] = kv.Value;
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to load settings from {Path}", _filePath);
                }
            }

            _loaded = true;
        }
        finally
        {
            _fileLock.Release();
        }
    }
}
