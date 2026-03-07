// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Update;

/// <summary>
/// Provides Windows Update management operations via the <c>B11.Update</c> PowerShell module.
/// Implements <see cref="IUpdateService"/> with thread-safe install operations and result caching.
/// </summary>
public sealed class UpdateService : IUpdateService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<UpdateService> _logger;
    private readonly SemaphoreSlim _installSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="UpdateService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public UpdateService(IPowerShellService ps, ILogger<UpdateService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<WindowsUpdateDto>>> CheckForUpdatesAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "AvailableUpdates";

        if (TryGetCached<IReadOnlyList<WindowsUpdateDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached available updates");
            return Result<IReadOnlyList<WindowsUpdateDto>>.Success(cached);
        }

        _logger.LogInformation("Checking for available updates via Get-B11AvailableUpdates");
        try
        {
            var result = await _ps.InvokeCommandListAsync<WindowsUpdateDto>(
                AppConstants.Modules.Update,
                "Get-B11AvailableUpdates",
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
            _logger.LogWarning("CheckForUpdatesAsync was cancelled");
            return Result<IReadOnlyList<WindowsUpdateDto>>.Failure(
                ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check for available updates");
            return Result<IReadOnlyList<WindowsUpdateDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> InstallUpdatesAsync(
        IReadOnlyList<string> updateIds,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(updateIds);

        _logger.LogInformation("Installing {Count} updates via Install-B11Updates", updateIds.Count);

        await _installSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["UpdateIds"] = updateIds,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Update,
                "Install-B11Updates",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                // Invalidate cached available updates and history after install
                _cache.TryRemove("AvailableUpdates", out _);
                _cache.TryRemove("UpdateHistory", out _);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("InstallUpdatesAsync was cancelled");
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to install updates");
            return Result.Failure(ex);
        }
        finally
        {
            _installSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<WindowsUpdateDto>>> GetUpdateHistoryAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "UpdateHistory";

        if (TryGetCached<IReadOnlyList<WindowsUpdateDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached update history");
            return Result<IReadOnlyList<WindowsUpdateDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving update history via Get-B11UpdateHistory");
        try
        {
            var result = await _ps.InvokeCommandListAsync<WindowsUpdateDto>(
                AppConstants.Modules.Update,
                "Get-B11UpdateHistory",
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
            _logger.LogWarning("GetUpdateHistoryAsync was cancelled");
            return Result<IReadOnlyList<WindowsUpdateDto>>.Failure(
                ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve update history");
            return Result<IReadOnlyList<WindowsUpdateDto>>.Failure(ex);
        }
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
