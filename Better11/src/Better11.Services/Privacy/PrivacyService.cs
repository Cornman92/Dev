// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Privacy;

/// <summary>
/// Provides privacy management operations via the <c>B11.Privacy</c> PowerShell module.
/// Implements <see cref="IPrivacyService"/> with thread-safe mutating operations.
/// </summary>
public sealed class PrivacyService : IPrivacyService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<PrivacyService> _logger;
    private readonly SemaphoreSlim _mutateSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="PrivacyService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public PrivacyService(IPowerShellService ps, ILogger<PrivacyService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<PrivacyAuditDto>> GetPrivacyAuditAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "PrivacyAudit";

        if (TryGetCached<PrivacyAuditDto>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached privacy audit");
            return Result<PrivacyAuditDto>.Success(cached);
        }

        _logger.LogInformation("Retrieving privacy audit via Get-B11PrivacyAudit");
        try
        {
            var result = await _ps.InvokeCommandAsync<PrivacyAuditDto>(
                AppConstants.Modules.Privacy,
                "Get-B11PrivacyAudit",
                null,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                SetCache(cacheKey, result.Value);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("GetPrivacyAuditAsync was cancelled");
            return Result<PrivacyAuditDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve privacy audit");
            return Result<PrivacyAuditDto>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> ApplyPrivacyProfileAsync(
        string profileName,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(profileName);

        _logger.LogInformation("Applying privacy profile {ProfileName} via Set-B11PrivacyProfile", profileName);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["ProfileName"] = profileName,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Privacy,
                "Set-B11PrivacyProfile",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                InvalidateCache();
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("ApplyPrivacyProfileAsync was cancelled for profile {ProfileName}", profileName);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to apply privacy profile {ProfileName}", profileName);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> SetPrivacySettingAsync(
        string settingId,
        bool enabled,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(settingId);

        _logger.LogInformation(
            "Setting privacy setting {SettingId} to {Enabled} via Set-B11PrivacySetting",
            settingId, enabled);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["SettingId"] = settingId,
                ["Enabled"] = enabled,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Privacy,
                "Set-B11PrivacySetting",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                InvalidateCache();
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("SetPrivacySettingAsync was cancelled for setting {SettingId}", settingId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to set privacy setting {SettingId}", settingId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    private void InvalidateCache()
    {
        _cache.TryRemove("PrivacyAudit", out _);
    }

    private bool TryGetCached<T>(string key, out T value)
    {
        if (_cache.TryGetValue(key, out var entry) && entry.ExpiresAt > DateTime.UtcNow)
        {
            value = (T)entry.Value;
            return true;
        }

        value = default!;
        return false;
    }

    private void SetCache<T>(string key, T value) where T : notnull
    {
        _cache[key] = (value, DateTime.UtcNow.Add(CacheDuration));
    }
}
