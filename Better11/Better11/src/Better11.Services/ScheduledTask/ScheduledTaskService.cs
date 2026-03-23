// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.ScheduledTask;

/// <summary>
/// Provides scheduled task management via the <c>B11.Tasks</c> PowerShell module.
/// Implements <see cref="IScheduledTaskService"/> with thread-safe mutating operations.
/// </summary>
public sealed class ScheduledTaskService : IScheduledTaskService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<ScheduledTaskService> _logger;
    private readonly SemaphoreSlim _mutateSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="ScheduledTaskService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public ScheduledTaskService(IPowerShellService ps, ILogger<ScheduledTaskService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<ScheduledTaskDto>>> GetScheduledTasksAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "ScheduledTasks";

        if (TryGetCached<IReadOnlyList<ScheduledTaskDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached scheduled tasks");
            return Result<IReadOnlyList<ScheduledTaskDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving scheduled tasks via Get-B11ScheduledTasks");
        try
        {
            var result = await _ps.InvokeCommandListAsync<ScheduledTaskDto>(
                AppConstants.Modules.Tasks,
                "Get-B11ScheduledTasks",
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
            _logger.LogWarning("GetScheduledTasksAsync was cancelled");
            return Result<IReadOnlyList<ScheduledTaskDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve scheduled tasks");
            return Result<IReadOnlyList<ScheduledTaskDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> EnableTaskAsync(
        string taskPath,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(taskPath);

        _logger.LogInformation("Enabling scheduled task {TaskPath} via Enable-B11ScheduledTask", taskPath);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["TaskPath"] = taskPath,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Tasks,
                "Enable-B11ScheduledTask",
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
            _logger.LogWarning("EnableTaskAsync was cancelled for task {TaskPath}", taskPath);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to enable scheduled task {TaskPath}", taskPath);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> DisableTaskAsync(
        string taskPath,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(taskPath);

        _logger.LogInformation("Disabling scheduled task {TaskPath} via Disable-B11ScheduledTask", taskPath);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["TaskPath"] = taskPath,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Tasks,
                "Disable-B11ScheduledTask",
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
            _logger.LogWarning("DisableTaskAsync was cancelled for task {TaskPath}", taskPath);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to disable scheduled task {TaskPath}", taskPath);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> RunTaskAsync(
        string taskPath,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(taskPath);

        _logger.LogInformation("Running scheduled task {TaskPath} via Start-B11ScheduledTask", taskPath);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["TaskPath"] = taskPath,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Tasks,
                "Start-B11ScheduledTask",
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
            _logger.LogWarning("RunTaskAsync was cancelled for task {TaskPath}", taskPath);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to run scheduled task {TaskPath}", taskPath);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    private void InvalidateCache()
    {
        _cache.TryRemove("ScheduledTasks", out _);
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
