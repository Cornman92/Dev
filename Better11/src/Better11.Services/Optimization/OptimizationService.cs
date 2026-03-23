// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Optimization;

/// <summary>
/// Provides system optimization operations via the <c>B11.Optimization</c> PowerShell module.
/// Implements <see cref="IOptimizationService"/> with thread-safe apply and restore operations.
/// </summary>
public sealed class OptimizationService : IOptimizationService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<OptimizationService> _logger;
    private readonly SemaphoreSlim _applySemaphore = new(1, 1);
    private readonly SemaphoreSlim _restoreSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="OptimizationService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public OptimizationService(IPowerShellService ps, ILogger<OptimizationService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<OptimizationCategoryDto>>> GetCategoriesAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "OptimizationCategories";

        if (TryGetCached<IReadOnlyList<OptimizationCategoryDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached optimization categories");
            return Result<IReadOnlyList<OptimizationCategoryDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving optimization categories via Get-B11OptimizationCategories");
        try
        {
            var result = await _ps.InvokeCommandListAsync<OptimizationCategoryDto>(
                AppConstants.Modules.Optimization,
                "Get-B11OptimizationCategories",
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
            _logger.LogWarning("GetCategoriesAsync was cancelled");
            return Result<IReadOnlyList<OptimizationCategoryDto>>.Failure(
                ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve optimization categories");
            return Result<IReadOnlyList<OptimizationCategoryDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<OptimizationResultDto>> ApplyOptimizationsAsync(
        IReadOnlyList<string> tweakIds,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(tweakIds);

        _logger.LogInformation(
            "Applying {Count} optimizations via Invoke-B11Optimization", tweakIds.Count);

        await _applySemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["TweakIds"] = tweakIds,
            };

            var result = await _ps.InvokeCommandAsync<OptimizationResultDto>(
                AppConstants.Modules.Optimization,
                "Invoke-B11Optimization",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                // Invalidate categories cache since applied states may have changed
                _cache.TryRemove("OptimizationCategories", out _);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("ApplyOptimizationsAsync was cancelled");
            return Result<OptimizationResultDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to apply optimizations");
            return Result<OptimizationResultDto>.Failure(ex);
        }
        finally
        {
            _applySemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result<string>> CreateRestorePointAsync(
        string description,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(description);

        _logger.LogInformation(
            "Creating restore point '{Description}' via New-B11RestorePoint", description);

        await _restoreSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["Description"] = description,
            };

            var result = await _ps.InvokeCommandAsync<string>(
                AppConstants.Modules.Optimization,
                "New-B11RestorePoint",
                parameters,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("CreateRestorePointAsync was cancelled");
            return Result<string>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create restore point");
            return Result<string>.Failure(ex);
        }
        finally
        {
            _restoreSemaphore.Release();
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
