// Copyright (c) Better11. All rights reserved.

using System.Diagnostics;
using System.Text.Json;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.AppUpdate;

/// <summary>
/// Checks for, downloads, and installs application updates using a version manifest.
/// </summary>
public sealed class AppUpdateService : IAppUpdateService
{
    private static readonly HttpClient SharedHttpClient = new()
    {
        Timeout = TimeSpan.FromSeconds(15),
    };

    private readonly ILogger<AppUpdateService> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="AppUpdateService"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    public AppUpdateService(ILogger<AppUpdateService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc/>
    public async Task<Result<AppUpdateInfo?>> CheckForUpdatesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Checking for application updates from {Url}", AppConstants.UpdateManifestUrl);
            var response = await SharedHttpClient.GetAsync(AppConstants.UpdateManifestUrl, cancellationToken).ConfigureAwait(false);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            var manifest = JsonSerializer.Deserialize<VersionManifest>(json);
            if (manifest == null || string.IsNullOrWhiteSpace(manifest.Version))
            {
                _logger.LogWarning("Version manifest was empty or invalid");
                return Result<AppUpdateInfo?>.Success(null);
            }

            var currentVersion = GetCurrentVersion();
            if (!Version.TryParse(manifest.Version, out var available) || !Version.TryParse(currentVersion, out var current))
            {
                _logger.LogDebug("Could not parse versions; assuming no update. Current: {Current}, Available: {Available}", currentVersion, manifest.Version);
                return Result<AppUpdateInfo?>.Success(null);
            }

            if (available <= current)
            {
                _logger.LogInformation("No update available. Current: {Current}, Available: {Available}", currentVersion, manifest.Version);
                return Result<AppUpdateInfo?>.Success(null);
            }

            var info = new AppUpdateInfo
            {
                Version = manifest.Version,
                DownloadUrl = manifest.DownloadUrl ?? string.Empty,
                ReleaseNotes = manifest.ReleaseNotes ?? string.Empty,
                PublishDate = manifest.PublishDate,
            };

            _logger.LogInformation("Update available: {Version}", info.Version);
            return Result<AppUpdateInfo?>.Success(info);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Update check was cancelled");
            return Result<AppUpdateInfo?>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Failed to fetch update manifest");
            return Result<AppUpdateInfo?>.Failure(ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking for updates");
            return Result<AppUpdateInfo?>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public async Task<Result<string>> DownloadUpdateAsync(AppUpdateInfo updateInfo, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(updateInfo);

        if (string.IsNullOrWhiteSpace(updateInfo.DownloadUrl))
        {
            return Result<string>.Failure("Update info has no download URL.");
        }

        try
        {
            var extension = Path.GetExtension(new Uri(updateInfo.DownloadUrl).LocalPath);
            if (string.IsNullOrEmpty(extension))
            {
                extension = ".msix";
            }

            var tempPath = Path.Combine(Path.GetTempPath(), "Better11", $"Better11_{updateInfo.Version}{extension}");
            Directory.CreateDirectory(Path.GetDirectoryName(tempPath)!);

            _logger.LogInformation("Downloading update from {Url} to {Path}", updateInfo.DownloadUrl, tempPath);
            var response = await SharedHttpClient.GetAsync(updateInfo.DownloadUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken).ConfigureAwait(false);
            response.EnsureSuccessStatusCode();

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
            await using var fileStream = File.Create(tempPath);
            await stream.CopyToAsync(fileStream, cancellationToken).ConfigureAwait(false);

            _logger.LogInformation("Update downloaded to {Path}", tempPath);
            return Result<string>.Success(tempPath);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Update download was cancelled");
            return Result<string>.Failure(ErrorCodes.Cancelled, "Download was cancelled.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to download update");
            return Result<string>.Failure(ex);
        }
    }

    /// <inheritdoc/>
    public Task<Result> InstallUpdateAsync(string downloadedPath, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(downloadedPath) || !File.Exists(downloadedPath))
        {
            return Task.FromResult(Result.Failure("Downloaded file not found or path is invalid."));
        }

        try
        {
            _logger.LogInformation("Launching installer: {Path}", downloadedPath);
            Process.Start(new ProcessStartInfo
            {
                FileName = downloadedPath,
                UseShellExecute = true,
            });
            return Task.FromResult(Result.Success());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to launch installer");
            return Task.FromResult(Result.Failure(ex));
        }
    }

    private static string GetCurrentVersion()
    {
        return AppConstants.AppVersion;
    }

    private sealed class VersionManifest
    {
        public string? Version { get; set; }
        public string? DownloadUrl { get; set; }
        public string? ReleaseNotes { get; set; }
        public DateTimeOffset? PublishDate { get; set; }
    }
}
