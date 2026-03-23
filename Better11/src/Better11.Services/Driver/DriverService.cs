// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Driver;

/// <summary>
/// Provides driver management operations via the <c>B11.Drivers</c> PowerShell module.
/// Implements <see cref="IDriverService"/> with thread-safe update, backup, and rollback operations.
/// </summary>
public sealed class DriverService : IDriverService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<DriverService> _logger;
    private readonly SemaphoreSlim _mutateSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="DriverService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public DriverService(IPowerShellService ps, ILogger<DriverService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<DriverDto>>> GetInstalledDriversAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "InstalledDrivers";

        if (TryGetCached<IReadOnlyList<DriverDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached installed drivers");
            return Result<IReadOnlyList<DriverDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving installed drivers via Get-B11InstalledDrivers");
        try
        {
            var result = await _ps.InvokeCommandListAsync<DriverDto>(
                AppConstants.Modules.Drivers,
                "Get-B11InstalledDrivers",
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
            _logger.LogWarning("GetInstalledDriversAsync was cancelled");
            return Result<IReadOnlyList<DriverDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve installed drivers");
            return Result<IReadOnlyList<DriverDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<DriverDto>>> ScanForUpdatesAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Scanning for driver updates via Find-B11DriverUpdates");
        try
        {
            var result = await _ps.InvokeCommandListAsync<DriverDto>(
                AppConstants.Modules.Drivers,
                "Find-B11DriverUpdates",
                null,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("ScanForUpdatesAsync was cancelled");
            return Result<IReadOnlyList<DriverDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to scan for driver updates");
            return Result<IReadOnlyList<DriverDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> UpdateDriverAsync(
        string deviceId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(deviceId);

        _logger.LogInformation("Updating driver for device {DeviceId} via Update-B11Driver", deviceId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["DeviceId"] = deviceId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Drivers,
                "Update-B11Driver",
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
            _logger.LogWarning("UpdateDriverAsync was cancelled for device {DeviceId}", deviceId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update driver for device {DeviceId}", deviceId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result<string>> BackupDriverAsync(
        string deviceId,
        string backupPath,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(deviceId);
        ArgumentException.ThrowIfNullOrWhiteSpace(backupPath);

        _logger.LogInformation(
            "Backing up driver for device {DeviceId} to {BackupPath} via Backup-B11Driver",
            deviceId, backupPath);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["DeviceId"] = deviceId,
                ["BackupPath"] = backupPath,
            };

            var result = await _ps.InvokeCommandAsync<string>(
                AppConstants.Modules.Drivers,
                "Backup-B11Driver",
                parameters,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("BackupDriverAsync was cancelled for device {DeviceId}", deviceId);
            return Result<string>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to backup driver for device {DeviceId}", deviceId);
            return Result<string>.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> RollbackDriverAsync(
        string deviceId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(deviceId);

        _logger.LogInformation("Rolling back driver for device {DeviceId} via Undo-B11DriverUpdate", deviceId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["DeviceId"] = deviceId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Drivers,
                "Undo-B11DriverUpdate",
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
            _logger.LogWarning("RollbackDriverAsync was cancelled for device {DeviceId}", deviceId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to rollback driver for device {DeviceId}", deviceId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    private void InvalidateCache()
    {
        _cache.TryRemove("InstalledDrivers", out _);
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
