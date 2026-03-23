// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.SystemInfo;

/// <summary>
/// Provides system information retrieval via the <c>B11.SystemInfo</c> PowerShell module.
/// Implements <see cref="ISystemInfoService"/> with short-lived caching for expensive queries.
/// </summary>
public sealed class SystemInfoService : ISystemInfoService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<SystemInfoService> _logger;
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="SystemInfoService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public SystemInfoService(IPowerShellService ps, ILogger<SystemInfoService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<SystemInfoDto>> GetSystemInfoAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "SystemInfo";

        if (TryGetCached<SystemInfoDto>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached system info");
            return Result<SystemInfoDto>.Success(cached);
        }

        _logger.LogInformation("Retrieving system information via Get-B11SystemInfo");
        try
        {
            var result = await _ps.InvokeCommandAsync<SystemInfoDto>(
                AppConstants.Modules.SystemInfo,
                "Get-B11SystemInfo",
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
            _logger.LogWarning("GetSystemInfoAsync was cancelled");
            return Result<SystemInfoDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve system information");
            return Result<SystemInfoDto>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<PerformanceMetricsDto>> GetPerformanceMetricsAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Retrieving performance metrics via Get-B11PerformanceMetrics");
        try
        {
            var result = await _ps.InvokeCommandAsync<PerformanceMetricsDto>(
                AppConstants.Modules.SystemInfo,
                "Get-B11PerformanceMetrics",
                null,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("GetPerformanceMetricsAsync was cancelled");
            return Result<PerformanceMetricsDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve performance metrics");
            return Result<PerformanceMetricsDto>.Failure(ex);
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
