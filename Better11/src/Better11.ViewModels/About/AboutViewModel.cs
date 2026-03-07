// Copyright (c) Better11. All rights reserved.

using System.Collections.ObjectModel;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.About;

/// <summary>
/// Represents an application component and its operational status.
/// </summary>
/// <param name="Name">The component display name.</param>
/// <param name="Version">The component version string.</param>
/// <param name="Status">The current status (e.g. "OK", "Unavailable").</param>
public sealed record ComponentInfo(string Name, string Version, string Status);

/// <summary>
/// ViewModel for the About page. Displays application metadata,
/// system information, component status, and utility commands.
/// </summary>
public sealed partial class AboutViewModel : BaseViewModel
{
    private readonly ISystemInfoService _systemInfoService;
    private readonly IAppUpdateService _appUpdateService;

    /// <summary>Initializes a new instance of the <see cref="AboutViewModel"/> class.</summary>
    public AboutViewModel(
        ISystemInfoService systemInfoService,
        IAppUpdateService appUpdateService,
        ILogger<AboutViewModel> logger)
        : base(logger)
    {
        _systemInfoService = systemInfoService ?? throw new ArgumentNullException(nameof(systemInfoService));
        _appUpdateService = appUpdateService ?? throw new ArgumentNullException(nameof(appUpdateService));
        PageTitle = "About";
    }

    // ====================================================================
    // Static Metadata
    // ====================================================================

    /// <summary>Gets the application version.</summary>
    public string AppVersion => AppConstants.AppVersion;

    /// <summary>Gets the application version for display (e.g. "v1.0.0").</summary>
    public string AppVersionDisplay => "v" + AppVersion;

    /// <summary>Gets the application display name.</summary>
    public string AppDisplayName => AppConstants.AppDisplayName;

    /// <summary>Gets the copyright notice.</summary>
    public string Copyright => AppConstants.Copyright;

    /// <summary>Gets the license identifier.</summary>
    public string LicenseInfo => "Proprietary \u2014 All Rights Reserved";

    /// <summary>Gets the build date of the running assembly.</summary>
    public string BuildDate { get; } = GetBuildDate();

    /// <summary>Gets the .NET runtime version.</summary>
    public string DotNetVersion => RuntimeInformation.FrameworkDescription;

    // ====================================================================
    // Observable Properties
    // ====================================================================

    /// <summary>Gets or sets the system information.</summary>
    [ObservableProperty]
    private SystemInfoDto? _systemInfo;

    /// <summary>Gets the collection of application components and their status.</summary>
    public ObservableCollection<ComponentInfo> Components { get; } = new();

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Opens the project GitHub repository.</summary>
    [RelayCommand]
    private async Task OpenGitHubAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(_ =>
        {
            OpenUrl("https://github.com/Better11/Better11");
            return Task.CompletedTask;
        }, "Opening GitHub...", cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Opens the project documentation site.</summary>
    [RelayCommand]
    private async Task OpenDocumentationAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(_ =>
        {
            OpenUrl("https://docs.better11.app");
            return Task.CompletedTask;
        }, "Opening documentation...", cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Checks whether a newer application version is available.</summary>
    [RelayCommand]
    private async Task CheckForUpdatesAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(async ct =>
        {
            var result = await _appUpdateService.CheckForUpdatesAsync(ct).ConfigureAwait(false);
            if (!result.IsSuccess)
            {
                SetErrorFromResult(result);
                return;
            }

            if (result.Value is { } updateInfo)
            {
                SetSuccess($"Update available: v{updateInfo.Version}. Use the release page or documentation to download.");
            }
            else
            {
                SetSuccess($"You are running the latest version ({AppConstants.AppDisplayName} v{AppConstants.AppVersion}).");
            }
        }, "Checking for updates...", cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Opens the application log folder in Explorer.</summary>
    [RelayCommand]
    private static void OpenLogFolder()
    {
        var logDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Better11",
            "Logs");
        Directory.CreateDirectory(logDir);
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = "explorer.exe",
            ArgumentList = { logDir },
            UseShellExecute = true,
        });
    }

    /// <summary>Copies a diagnostic system-info summary to the clipboard.</summary>
    [RelayCommand]
    private async Task CopySystemInfoAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(_ =>
        {
            var sb = new StringBuilder();
            sb.AppendLine($"{AppConstants.AppDisplayName} v{AppConstants.AppVersion}");
            sb.AppendLine($"Build: {BuildDate}  |  Runtime: {DotNetVersion}");
            if (SystemInfo is not null)
            {
                sb.AppendLine($"OS: {SystemInfo.OsName} {SystemInfo.OsVersion} (Build {SystemInfo.OsBuild})");
                sb.AppendLine($"CPU: {SystemInfo.CpuName} ({SystemInfo.CpuCores} cores)");
                sb.AppendLine($"RAM: {SystemInfo.TotalRamGb:F1} GB  |  GPU: {SystemInfo.GpuName}");
            }

            var pkg = new Windows.ApplicationModel.DataTransfer.DataPackage();
            pkg.SetText(sb.ToString());
            Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(pkg);
            SetSuccess("System information copied to clipboard.");
            return Task.CompletedTask;
        }, "Copying system info...", cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(async ct =>
        {
            var result = await _systemInfoService.GetSystemInfoAsync(ct).ConfigureAwait(false);
            if (result.IsSuccess) { SystemInfo = result.Value; }
            else { SetErrorFromResult(result); }

            RunOnUIThread(() =>
            {
                Components.Clear();
                Components.Add(new ComponentInfo("CommunityToolkit.Mvvm", "8.4.0", "OK"));
                Components.Add(new ComponentInfo("WinUI 3", "1.6", "OK"));
                Components.Add(new ComponentInfo("PowerShell Engine", "7.4", SystemInfo is not null ? "OK" : "Unavailable"));
                Components.Add(new ComponentInfo(".NET Runtime", DotNetVersion, "OK"));
            });
        }, "Loading about information...", cancellationToken).ConfigureAwait(false);
    }

    private static string GetBuildDate()
    {
        var attr = System.Reflection.Assembly.GetExecutingAssembly()
            .GetCustomAttribute<System.Reflection.AssemblyInformationalVersionAttribute>();
        return attr?.InformationalVersion ?? DateTime.UtcNow.ToString("yyyy-MM-dd");
    }

    private static void OpenUrl(string url)
    {
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = url,
            UseShellExecute = true,
        });
    }
}
