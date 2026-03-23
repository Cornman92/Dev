// Copyright (c) Better11. All rights reserved.

using System.Collections.Concurrent;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.Package;

/// <summary>
/// Provides package management operations via the <c>B11.Packages</c> PowerShell module.
/// Implements <see cref="IPackageService"/> with thread-safe install/uninstall/update operations.
/// </summary>
public sealed class PackageService : IPackageService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromSeconds(30);

    private readonly IPowerShellService _ps;
    private readonly ILogger<PackageService> _logger;
    private readonly SemaphoreSlim _mutateSemaphore = new(1, 1);
    private readonly ConcurrentDictionary<string, (object Value, DateTime ExpiresAt)> _cache = new();

    /// <summary>
    /// Initializes a new instance of the <see cref="PackageService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service used to invoke commands.</param>
    /// <param name="logger">The logger instance.</param>
    public PackageService(IPowerShellService ps, ILogger<PackageService> logger)
    {
        _ps = ps ?? throw new ArgumentNullException(nameof(ps));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<PackageDto>>> GetInstalledPackagesAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "InstalledPackages";

        if (TryGetCached<IReadOnlyList<PackageDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached installed packages");
            return Result<IReadOnlyList<PackageDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving installed packages via Get-B11InstalledPackages");
        try
        {
            var result = await _ps.InvokeCommandListAsync<PackageDto>(
                AppConstants.Modules.Packages,
                "Get-B11InstalledPackages",
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
            _logger.LogWarning("GetInstalledPackagesAsync was cancelled");
            return Result<IReadOnlyList<PackageDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve installed packages");
            return Result<IReadOnlyList<PackageDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<PackageDto>>> GetAvailableUpdatesAsync(
        CancellationToken cancellationToken = default)
    {
        const string cacheKey = "PackageUpdates";

        if (TryGetCached<IReadOnlyList<PackageDto>>(cacheKey, out var cached))
        {
            _logger.LogDebug("Returning cached package updates");
            return Result<IReadOnlyList<PackageDto>>.Success(cached);
        }

        _logger.LogInformation("Retrieving available package updates via Get-B11PackageUpdates");
        try
        {
            var result = await _ps.InvokeCommandListAsync<PackageDto>(
                AppConstants.Modules.Packages,
                "Get-B11PackageUpdates",
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
            _logger.LogWarning("GetAvailableUpdatesAsync was cancelled");
            return Result<IReadOnlyList<PackageDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve available package updates");
            return Result<IReadOnlyList<PackageDto>>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result> InstallPackageAsync(
        string packageId,
        string source,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(packageId);
        ArgumentException.ThrowIfNullOrWhiteSpace(source);

        _logger.LogInformation(
            "Installing package {PackageId} from {Source} via Install-B11Package",
            packageId, source);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["PackageId"] = packageId,
                ["Source"] = source,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Packages,
                "Install-B11Package",
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
            _logger.LogWarning("InstallPackageAsync was cancelled for package {PackageId}", packageId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to install package {PackageId}", packageId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> UninstallPackageAsync(
        string packageId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(packageId);

        _logger.LogInformation("Uninstalling package {PackageId} via Uninstall-B11Package", packageId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["PackageId"] = packageId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Packages,
                "Uninstall-B11Package",
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
            _logger.LogWarning("UninstallPackageAsync was cancelled for package {PackageId}", packageId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to uninstall package {PackageId}", packageId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result> UpdatePackageAsync(
        string packageId,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(packageId);

        _logger.LogInformation("Updating package {PackageId} via Update-B11Package", packageId);

        await _mutateSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["PackageId"] = packageId,
            };

            var result = await _ps.InvokeCommandVoidAsync(
                AppConstants.Modules.Packages,
                "Update-B11Package",
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
            _logger.LogWarning("UpdatePackageAsync was cancelled for package {PackageId}", packageId);
            return Result.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update package {PackageId}", packageId);
            return Result.Failure(ex);
        }
        finally
        {
            _mutateSemaphore.Release();
        }
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<PackageDto>>> SearchPackagesAsync(
        string query,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(query);

        _logger.LogInformation("Searching packages with query '{Query}' via Search-B11Packages", query);
        try
        {
            var parameters = new Dictionary<string, object>
            {
                ["Query"] = query,
            };

            var result = await _ps.InvokeCommandListAsync<PackageDto>(
                AppConstants.Modules.Packages,
                "Search-B11Packages",
                parameters,
                cancellationToken).ConfigureAwait(false);

            return result;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("SearchPackagesAsync was cancelled for query '{Query}'", query);
            return Result<IReadOnlyList<PackageDto>>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to search packages with query '{Query}'", query);
            return Result<IReadOnlyList<PackageDto>>.Failure(ex);
        }
    }

    private void InvalidateCache()
    {
        _cache.TryRemove("InstalledPackages", out _);
        _cache.TryRemove("PackageUpdates", out _);
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
