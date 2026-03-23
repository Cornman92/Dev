// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Security;

/// <summary>
/// Provides security management operations via the <c>B11.Security</c> PowerShell module.
/// Implements <see cref="ISecurityService"/> with thread-safe mutating operations.
/// </summary>
public sealed class SecurityService : ISecurityService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<SecurityService> _logger;
    private readonly SemaphoreSlim _hardeningSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="SecurityService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public SecurityService(IPowerShellService ps, ILogger<SecurityService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<SecurityStatusDto>> GetSecurityStatusAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "SecurityStatus";

        if (TryGetCached<SecurityStatusDto>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached security status");
            return Result<SecurityStatusDto>.Success(cached);
        }

        _logger.LogInformation("Retrieving security status via Get-B11SecurityStatus");
        try
        {
            var result = await _ps.InvokeCommandAsync<SecurityStatusDto>(
                AppConstants.Modules.Security,
                "Get-B11SecurityStatus",
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
            _logger.LogWarning("GetSecurityStatusAsync was cancelled");
            return Result<SecurityStatusDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve security status");
            return Result<SecurityStatusDto>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<SecurityScanDto>> RunSecurityScanAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Running security scan via Invoke-B11SecurityScan");
        try
        {
            var result = await _ps.InvokeCommandAsync<SecurityScanDto>(
                AppConstants.Modules.Security,
                "Invoke-B11SecurityScan",
                null,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                // Invalidate cached status after a scan completes
                _cache.TryRemove("SecurityStatus", out _);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("RunSecurityScanAsync was cancelled");
            return Result<SecurityScanDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to run security scan");
            return Result<SecurityScanDto>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> ApplyHardeningAsync(
        string actionId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(actionId);

        _logger.LogInformation("Applying security hardening action {ActionId} via Set-B11SecurityHardening", actionId);

        await _hardeningSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["ActionId"] = actionId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Security,
                "Set-B11SecurityHardening",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                // Invalidate cached status after hardening
                _cache.TryRemove("SecurityStatus", out _);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("ApplyHardeningAsync was cancelled for action {ActionId}", actionId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to apply security hardening action {ActionId}", actionId);
            return Result.Failure(ex);
        }
        finally
        {
            _hardeningSemaphore.Release();
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
