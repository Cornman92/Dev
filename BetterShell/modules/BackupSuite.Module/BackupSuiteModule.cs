using System.IO.Compression;
using System.Management.Automation;
using Microsoft.Extensions.Logging;
using WindowsPowerSuite.Core;

namespace WindowsPowerSuite.Modules.BackupSuite;

/// <summary>
/// Backup and restore module for Windows Power Suite
/// Provides system and user data backup capabilities
/// </summary>
public class BackupSuiteModule : ModuleBase
{
    public override string Name => "Backup Suite";
    public override string Version => "1.0.0";
    public override string Description => "System and data backup functionality";

    private readonly string _defaultBackupPath;

    public BackupSuiteModule(ILogger<BackupSuiteModule> logger) : base(logger)
    {
        _defaultBackupPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
            "WindowsPowerSuite", "Backups"
        );
    }

    protected override async Task OnInitializeAsync()
    {
        Logger.LogInformation("Initializing Backup Suite module...");
        
        // Ensure backup directory exists
        if (!Directory.Exists(_defaultBackupPath))
        {
            Directory.CreateDirectory(_defaultBackupPath);
            Logger.LogInformation("Created backup directory: {Path}", _defaultBackupPath);
        }

        await Task.CompletedTask;
    }

    /// <summary>
    /// Creates a backup of specified directories
    /// </summary>
    public async Task<BackupResult> CreateBackupAsync(
        string[] sourcePaths,
        string? destinationPath = null,
        CompressionLevel compressionLevel = CompressionLevel.Optimal)
    {
        try
        {
            destinationPath ??= _defaultBackupPath;
            var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            var backupFileName = $"Backup_{timestamp}.zip";
            var backupFilePath = Path.Combine(destinationPath, backupFileName);

            Logger.LogInformation("Creating backup: {FileName}", backupFileName);

            using var archive = ZipFile.Open(backupFilePath, ZipArchiveMode.Create);
            
            foreach (var sourcePath in sourcePaths)
            {
                if (Directory.Exists(sourcePath))
                {
                    await AddDirectoryToArchiveAsync(archive, sourcePath, compressionLevel);
                }
                else if (File.Exists(sourcePath))
                {
                    archive.CreateEntryFromFile(sourcePath, Path.GetFileName(sourcePath), compressionLevel);
                }
                else
                {
                    Logger.LogWarning("Source path not found: {Path}", sourcePath);
                }
            }

            var fileInfo = new FileInfo(backupFilePath);
            Logger.LogInformation("Backup created successfully: {Size} bytes", fileInfo.Length);

            return new BackupResult
            {
                Success = true,
                BackupPath = backupFilePath,
                Size = fileInfo.Length,
                Message = "Backup created successfully"
            };
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to create backup");
            return new BackupResult
            {
                Success = false,
                Message = $"Backup failed: {ex.Message}"
            };
        }
    }

    /// <summary>
    /// Restores a backup
    /// </summary>
    public async Task<bool> RestoreBackupAsync(string backupPath, string destinationPath)
    {
        try
        {
            Logger.LogInformation("Restoring backup from: {BackupPath}", backupPath);

            if (!File.Exists(backupPath))
            {
                Logger.LogError("Backup file not found: {Path}", backupPath);
                return false;
            }

            ZipFile.ExtractToDirectory(backupPath, destinationPath, overwriteFiles: true);

            Logger.LogInformation("Backup restored successfully to: {Destination}", destinationPath);
            return true;
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to restore backup");
            return false;
        }
    }

    /// <summary>
    /// Lists all available backups
    /// </summary>
    public List<BackupInfo> ListBackups(string? backupDirectory = null)
    {
        backupDirectory ??= _defaultBackupPath;
        
        if (!Directory.Exists(backupDirectory))
            return new List<BackupInfo>();

        return Directory.GetFiles(backupDirectory, "Backup_*.zip")
            .Select(path => new FileInfo(path))
            .Select(fi => new BackupInfo
            {
                Path = fi.FullName,
                FileName = fi.Name,
                Size = fi.Length,
                CreatedDate = fi.CreationTime
            })
            .OrderByDescending(b => b.CreatedDate)
            .ToList();
    }

    private async Task AddDirectoryToArchiveAsync(
        ZipArchive archive,
        string sourcePath,
        CompressionLevel compressionLevel)
    {
        var files = Directory.GetFiles(sourcePath, "*", SearchOption.AllDirectories);
        
        foreach (var file in files)
        {
            var relativePath = Path.GetRelativePath(sourcePath, file);
            archive.CreateEntryFromFile(file, relativePath, compressionLevel);
        }

        await Task.CompletedTask;
    }
}

/// <summary>
/// Backup operation result
/// </summary>
public class BackupResult
{
    public bool Success { get; set; }
    public string BackupPath { get; set; } = string.Empty;
    public long Size { get; set; }
    public string Message { get; set; } = string.Empty;
}

/// <summary>
/// Backup file information
/// </summary>
public class BackupInfo
{
    public string Path { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public long Size { get; set; }
    public DateTime CreatedDate { get; set; }
}

#region PowerShell Cmdlets

/// <summary>
/// New-Backup cmdlet
/// </summary>
[Cmdlet(VerbsCommon.New, "Backup")]
[OutputType(typeof(BackupResult))]
public class NewBackupCommand : PSCmdlet
{
    [Parameter(Position = 0, Mandatory = true, ValueFromPipeline = true)]
    [Alias("Path")]
    public string[]? SourcePaths { get; set; }

    [Parameter]
    public string? Destination { get; set; }

    [Parameter]
    public CompressionLevel CompressionLevel { get; set; } = CompressionLevel.Optimal;

    protected override void ProcessRecord()
    {
        WriteVerbose($"Creating backup of {SourcePaths?.Length ?? 0} items");
        
        // TODO: Implement with module instance
        var result = new BackupResult 
        { 
            Success = true, 
            Message = "Backup creation queued" 
        };
        
        WriteObject(result);
    }
}

/// <summary>
/// Restore-Backup cmdlet
/// </summary>
[Cmdlet(VerbsData.Restore, "Backup")]
[OutputType(typeof(bool))]
public class RestoreBackupCommand : PSCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public string? BackupPath { get; set; }

    [Parameter(Position = 1, Mandatory = true)]
    public string? Destination { get; set; }

    protected override void ProcessRecord()
    {
        WriteVerbose($"Restoring backup from: {BackupPath}");
        
        // TODO: Implement with module instance
        WriteObject(true);
    }
}

/// <summary>
/// Get-Backups cmdlet
/// </summary>
[Cmdlet(VerbsCommon.Get, "Backups")]
[OutputType(typeof(BackupInfo[]))]
public class GetBackupsCommand : PSCmdlet
{
    [Parameter]
    public string? Path { get; set; }

    protected override void ProcessRecord()
    {
        WriteVerbose("Listing available backups");
        
        // TODO: Implement with module instance
        WriteObject(new List<BackupInfo>(), true);
    }
}

#endregion
