// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.DiskCleanup;

/// <summary>
/// Provides disk cleanup operations via the <c>B11.DiskCleanup</c> PowerShell module.
/// Implements <see cref="IDiskCleanupService"/> with thread-safe clean operations.
/// </summary>
public sealed class DiskCleanupService : IDiskCleanupService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<DiskCleanupService> _logger;
    private readonly SemaphoreSlim _cleanSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="DiskCleanupService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public DiskCleanupService(IPowerShellService ps, ILogger<DiskCleanupService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<DiskScanResultDto>> ScanAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Scanning for cleanable items via Invoke-B11DiskScan");
        try
        {
            var result = await _ps.InvokeCommandAsync<DiskScanResultDto>(
                AppConstants.Modules.DiskCleanup,
                "Invoke-B11DiskScan",
                null,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("ScanAsync was cancelled");
            return Result<DiskScanResultDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to scan for cleanable items");
            return Result<DiskScanResultDto>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<CleanupResultDto>> CleanAsync(
        IReadOnlyList<string> categories,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(categories);

        _logger.LogInformation("Cleaning {Count} categories via Invoke-B11DiskClean", categories.Count);

        await _cleanSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["Categories"] = categories,
            };

            var result = await _ps.InvokeCommandAsync<CleanupResultDto>(
                AppConstants.Modules.DiskCleanup,
                "Invoke-B11DiskClean",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                // Invalidate disk space cache after cleaning
                _cache.TryRemove("DiskSpace", out _);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("CleanAsync was cancelled");
            return Result<CleanupResultDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to clean selected categories");
            return Result<CleanupResultDto>.Failure(ex);
        }
        finally
        {
            _cleanSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<DiskSpaceDto>>> GetDiskSpaceAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "DiskSpace";

        if (TryGetCached<IReadOnlyList<DiskSpaceDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached disk space information");
            return Result<IReadOnlyList<DiskSpaceDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving disk space information via Get-B11DiskSpace");
        try
        {
            var result = await _ps.InvokeCommandListAsync<DiskSpaceDto>(
                AppConstants.Modules.DiskCleanup,
                "Get-B11DiskSpace",
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
            _logger.LogWarning("GetDiskSpaceAsync was cancelled");
            return Result<IReadOnlyList<DiskSpaceDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve disk space information");
            return Result<IReadOnlyList<DiskSpaceDto>>.Failure(ex);
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
