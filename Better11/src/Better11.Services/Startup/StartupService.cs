// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Startup;

/// <summary>
/// Provides startup item management via the <c>B11.Startup</c> PowerShell module.
/// Implements <see cref="IStartupService"/> with thread-safe mutating operations.
/// </summary>
public sealed class StartupService : IStartupService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<StartupService> _logger;
    private readonly SemaphoreSlim _mutateSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="StartupService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public StartupService(IPowerShellService ps, ILogger<StartupService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<StartupItemDto>>> GetStartupItemsAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "StartupItems";

        if (TryGetCached<IReadOnlyList<StartupItemDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached startup items");
            return Result<IReadOnlyList<StartupItemDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving startup items via Get-B11StartupItems");
        try
        {
            var result = await _ps.InvokeCommandListAsync<StartupItemDto>(
                AppConstants.Modules.Startup,
                "Get-B11StartupItems",
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
            _logger.LogWarning("GetStartupItemsAsync was cancelled");
            return Result<IReadOnlyList<StartupItemDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve startup items");
            return Result<IReadOnlyList<StartupItemDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> EnableStartupItemAsync(
        string itemId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(itemId);

        _logger.LogInformation("Enabling startup item {ItemId} via Enable-B11StartupItem", itemId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["ItemId"] = itemId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Startup,
                "Enable-B11StartupItem",
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
            _logger.LogWarning("EnableStartupItemAsync was cancelled for item {ItemId}", itemId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to enable startup item {ItemId}", itemId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> DisableStartupItemAsync(
        string itemId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(itemId);

        _logger.LogInformation("Disabling startup item {ItemId} via Disable-B11StartupItem", itemId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["ItemId"] = itemId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Startup,
                "Disable-B11StartupItem",
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
            _logger.LogWarning("DisableStartupItemAsync was cancelled for item {ItemId}", itemId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to disable startup item {ItemId}", itemId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> RemoveStartupItemAsync(
        string itemId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(itemId);

        _logger.LogInformation("Removing startup item {ItemId} via Remove-B11StartupItem", itemId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["ItemId"] = itemId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Startup,
                "Remove-B11StartupItem",
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
            _logger.LogWarning("RemoveStartupItemAsync was cancelled for item {ItemId}", itemId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to remove startup item {ItemId}", itemId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    private void InvalidateCache()
    {
        _cache.TryRemove("StartupItems", out _);
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
