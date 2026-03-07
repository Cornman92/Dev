// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Network;

/// <summary>
/// Provides network management operations via the <c>B11.Network</c> PowerShell module.
/// Implements <see cref="INetworkService"/> with thread-safe DNS and cache operations.
/// </summary>
public sealed class NetworkService : INetworkService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<NetworkService> _logger;
    private readonly SemaphoreSlim _dnsSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="NetworkService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public NetworkService(IPowerShellService ps, ILogger<NetworkService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<NetworkAdapterDto>>> GetAdaptersAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "NetworkAdapters";

        if (TryGetCached<IReadOnlyList<NetworkAdapterDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached network adapters");
            return Result<IReadOnlyList<NetworkAdapterDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving network adapters via Get-B11NetworkAdapters");
        try
        {
            var result = await _ps.InvokeCommandListAsync<NetworkAdapterDto>(
                AppConstants.Modules.Network,
                "Get-B11NetworkAdapters",
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
            _logger.LogWarning("GetAdaptersAsync was cancelled");
            return Result<IReadOnlyList<NetworkAdapterDto>>.Failure(
                ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve network adapters");
            return Result<IReadOnlyList<NetworkAdapterDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<DnsConfigDto>> GetDnsConfigAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "DnsConfig";

        if (TryGetCached<DnsConfigDto>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached DNS configuration");
            return Result<DnsConfigDto>.Success(cached);
        }

        _logger.LogInformation("Retrieving DNS configuration via Get-B11DnsConfig");
        try
        {
            var result = await _ps.InvokeCommandAsync<DnsConfigDto>(
                AppConstants.Modules.Network,
                "Get-B11DnsConfig",
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
            _logger.LogWarning("GetDnsConfigAsync was cancelled");
            return Result<DnsConfigDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve DNS configuration");
            return Result<DnsConfigDto>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> SetDnsServersAsync(
        string adapterId,
        string primaryDns,
        string secondaryDns,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(adapterId);
        ArgumentException.ThrowIfNullOrWhiteSpace(primaryDns);
        ArgumentException.ThrowIfNullOrWhiteSpace(secondaryDns);

        _logger.LogInformation(
            "Setting DNS servers on adapter {AdapterId} to {Primary}/{Secondary} via Set-B11DnsServers",
            adapterId, primaryDns, secondaryDns);

        await _dnsSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["AdapterId"] = adapterId,
                ["PrimaryDns"] = primaryDns,
                ["SecondaryDns"] = secondaryDns,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Network,
                "Set-B11DnsServers",
                parameters,
                cancellationToken).ConfigureAwait(false);

            if (result.IsSuccess)
            {
                _cache.TryRemove("DnsConfig", out _);
                _cache.TryRemove("NetworkAdapters", out _);
            }

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("SetDnsServersAsync was cancelled for adapter {AdapterId}", adapterId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to set DNS servers on adapter {AdapterId}", adapterId);
            return Result.Failure(ex);
        }
        finally
        {
            _dnsSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> FlushDnsCacheAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Flushing DNS cache via Clear-B11DnsCache");
        try
        {
            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Network,
                "Clear-B11DnsCache",
                null,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("FlushDnsCacheAsync was cancelled");
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to flush DNS cache");
            return Result.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<NetworkDiagnosticsDto>> RunDiagnosticsAsync(
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Running network diagnostics via Test-B11NetworkDiagnostics");
        try
        {
            var result = await _ps.InvokeCommandAsync<NetworkDiagnosticsDto>(
                AppConstants.Modules.Network,
                "Test-B11NetworkDiagnostics",
                null,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("RunDiagnosticsAsync was cancelled");
            return Result<NetworkDiagnosticsDto>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to run network diagnostics");
            return Result<NetworkDiagnosticsDto>.Failure(ex);
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
