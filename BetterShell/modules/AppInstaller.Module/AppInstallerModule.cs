using System.Management.Automation;
using Microsoft.Extensions.Logging;
using WindowsPowerSuite.Core;

namespace WindowsPowerSuite.Modules.AppInstaller;

/// <summary>
/// Application installer module for Windows Power Suite
/// Provides automated app installation and management via WinGet, Chocolatey, and custom installers
/// </summary>
public class AppInstallerModule : ModuleBase
{
    public override string Name => "App Installer";
    public override string Version => "1.0.0";
    public override string Description => "Automated application installation and management";

    private readonly List<IPackageManager> _packageManagers = new();

    public AppInstallerModule(ILogger<AppInstallerModule> logger) : base(logger)
    {
    }

    protected override async Task OnInitializeAsync()
    {
        Logger.LogInformation("Initializing App Installer module...");
        
        // Register available package managers
        _packageManagers.Add(new WinGetPackageManager(Logger));
        _packageManagers.Add(new ChocolateyPackageManager(Logger));
        
        // Detect which package managers are available
        foreach (var pm in _packageManagers)
        {
            var available = await pm.IsAvailableAsync();
            Logger.LogInformation("Package Manager {Name}: {Status}", pm.Name, available ? "Available" : "Not Available");
        }
    }

    /// <summary>
    /// Installs an application using the best available package manager
    /// </summary>
    public async Task<InstallResult> InstallAppAsync(string packageId, bool silent = true)
    {
        Logger.LogInformation("Installing application: {PackageId}", packageId);

        foreach (var pm in _packageManagers)
        {
            if (!await pm.IsAvailableAsync())
                continue;

            try
            {
                var result = await pm.InstallAsync(packageId, silent);
                if (result.Success)
                {
                    Logger.LogInformation("Application installed successfully via {PackageManager}", pm.Name);
                    return result;
                }
            }
            catch (Exception ex)
            {
                Logger.LogWarning(ex, "Failed to install via {PackageManager}, trying next...", pm.Name);
            }
        }

        Logger.LogError("Failed to install application: {PackageId}", packageId);
        return new InstallResult { Success = false, Message = "No package manager could install the application" };
    }

    /// <summary>
    /// Searches for available applications
    /// </summary>
    public async Task<List<AppInfo>> SearchAppsAsync(string query)
    {
        var results = new List<AppInfo>();

        foreach (var pm in _packageManagers)
        {
            if (!await pm.IsAvailableAsync())
                continue;

            try
            {
                var apps = await pm.SearchAsync(query);
                results.AddRange(apps);
            }
            catch (Exception ex)
            {
                Logger.LogWarning(ex, "Search failed for {PackageManager}", pm.Name);
            }
        }

        return results.DistinctBy(a => a.Id).ToList();
    }
}

/// <summary>
/// Package manager interface
/// </summary>
public interface IPackageManager
{
    string Name { get; }
    Task<bool> IsAvailableAsync();
    Task<InstallResult> InstallAsync(string packageId, bool silent);
    Task<List<AppInfo>> SearchAsync(string query);
}

/// <summary>
/// WinGet package manager implementation
/// </summary>
public class WinGetPackageManager : IPackageManager
{
    private readonly ILogger _logger;

    public string Name => "WinGet";

    public WinGetPackageManager(ILogger logger)
    {
        _logger = logger;
    }

    public async Task<bool> IsAvailableAsync()
    {
        try
        {
            var process = System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = "winget",
                Arguments = "--version",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            });

            await process!.WaitForExitAsync();
            return process.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    public async Task<InstallResult> InstallAsync(string packageId, bool silent)
    {
        var args = $"install {packageId} --silent --accept-package-agreements --accept-source-agreements";
        
        var process = System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = "winget",
            Arguments = args,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        });

        await process!.WaitForExitAsync();
        var output = await process.StandardOutput.ReadToEndAsync();

        return new InstallResult
        {
            Success = process.ExitCode == 0,
            Message = output
        };
    }

    public Task<List<AppInfo>> SearchAsync(string query)
    {
        // TODO: Implement WinGet search parsing
        return Task.FromResult(new List<AppInfo>());
    }
}

/// <summary>
/// Chocolatey package manager implementation
/// </summary>
public class ChocolateyPackageManager : IPackageManager
{
    private readonly ILogger _logger;

    public string Name => "Chocolatey";

    public ChocolateyPackageManager(ILogger logger)
    {
        _logger = logger;
    }

    public async Task<bool> IsAvailableAsync()
    {
        try
        {
            var process = System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = "choco",
                Arguments = "--version",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            });

            await process!.WaitForExitAsync();
            return process.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    public async Task<InstallResult> InstallAsync(string packageId, bool silent)
    {
        var args = $"install {packageId} -y";
        
        var process = System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = "choco",
            Arguments = args,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        });

        await process!.WaitForExitAsync();
        var output = await process.StandardOutput.ReadToEndAsync();

        return new InstallResult
        {
            Success = process.ExitCode == 0,
            Message = output
        };
    }

    public Task<List<AppInfo>> SearchAsync(string query)
    {
        // TODO: Implement Chocolatey search parsing
        return Task.FromResult(new List<AppInfo>());
    }
}

/// <summary>
/// Installation result
/// </summary>
public class InstallResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}

/// <summary>
/// Application information
/// </summary>
public class AppInfo
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Version { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
}

#region PowerShell Cmdlets

/// <summary>
/// Install-App cmdlet
/// </summary>
[Cmdlet(VerbsLifecycle.Install, "App")]
[OutputType(typeof(InstallResult))]
public class InstallAppCommand : PSCmdlet
{
    [Parameter(Position = 0, Mandatory = true, ValueFromPipeline = true)]
    public string? PackageId { get; set; }

    [Parameter]
    public SwitchParameter Silent { get; set; } = true;

    protected override void ProcessRecord()
    {
        WriteVerbose($"Installing application: {PackageId}");
        
        // TODO: Create and use module instance
        var result = new InstallResult { Success = true, Message = "Installation queued" };
        
        WriteObject(result);
    }
}

/// <summary>
/// Search-App cmdlet
/// </summary>
[Cmdlet(VerbsCommon.Search, "App")]
[OutputType(typeof(AppInfo[]))]
public class SearchAppCommand : PSCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public string? Query { get; set; }

    protected override void ProcessRecord()
    {
        WriteVerbose($"Searching for: {Query}");
        
        // TODO: Implement search logic
        WriteObject(new List<AppInfo>(), true);
    }
}

#endregion
