<#
.SYNOPSIS
    Automates local and cloud backup operations from a JSON configuration.

.DESCRIPTION
    Reads a backup configuration file defining source directories, destinations,
    and sync options. Supports local copy (robocopy-based), and optional cloud
    sync via OneDrive folder or rclone. Generates a summary report and log file.

.PARAMETER ConfigFile
    Path to backup configuration JSON. Defaults to C:\Dev\Assets\backup-config.json.

.PARAMETER DryRun
    Show what would be backed up without actually copying.

.PARAMETER LogFile
    Path to log file. Defaults to C:\Dev\Artifacts\backup.log.

.PARAMETER Job
    Run only a specific named backup job from the config.

.EXAMPLE
    .\Invoke-BackupAutomation.ps1
    Runs all backup jobs defined in the config.

.EXAMPLE
    .\Invoke-BackupAutomation.ps1 -DryRun
    Shows what would be backed up without copying.

.EXAMPLE
    .\Invoke-BackupAutomation.ps1 -Job "Documents"
    Runs only the "Documents" backup job.

.EXAMPLE
    .\Invoke-BackupAutomation.ps1 -ConfigFile "C:\custom-backup.json"
    Uses a custom configuration file.

.NOTES
    Author: C-Man
    Date:   2026-03-23
    Reuses: Write-Log patterns from Functions/Write-Log.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ConfigFile = "C:\Dev\Assets\backup-config.json",

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [string]$LogFile = "C:\Dev\Artifacts\backup.log",

    [Parameter()]
    [string]$Job
)

$ErrorActionPreference = 'Stop'

# --- Logging Helper ---
function Write-BackupLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $levelTag = switch ($Level) {
        'Info'    { 'INF' }
        'Warning' { 'WRN' }
        'Error'   { 'ERR' }
    }
    $entry = "[$timestamp] [$levelTag] $Message"

    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    Write-Host "  $entry" -ForegroundColor $color

    if ($LogFile) {
        $logDir = Split-Path -Parent $LogFile
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $entry -Encoding UTF8
    }
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Backup Automation" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "  ** DRY RUN MODE - No files will be copied **" -ForegroundColor Yellow
    Write-Host ""
}

# --- Load Config ---
if (-not (Test-Path $ConfigFile)) {
    # Create default config if it doesn't exist
    $defaultConfig = @{
        Jobs = @(
            @{
                Name        = 'Documents'
                Source      = "$env:USERPROFILE\Documents"
                Destination = 'D:\Backups\Documents'
                Method      = 'robocopy'
                Exclude     = @('*.tmp', '*.log', 'Thumbs.db')
                Mirror      = $false
            }
            @{
                Name        = 'DevWorkspace'
                Source      = 'C:\Dev'
                Destination = 'D:\Backups\Dev'
                Method      = 'robocopy'
                Exclude     = @('node_modules', '.venv', '__pycache__', '*.exe', '*.dll')
                Mirror      = $false
            }
            @{
                Name        = 'GameSaves'
                Source      = "$env:APPDATA"
                Destination = 'D:\Backups\GameSaves'
                Method      = 'copy'
                Include     = @('.minecraft\saves', 'StardewValley\Saves', 'EldenRing')
                Mirror      = $false
            }
        )
    }

    $configDir = Split-Path $ConfigFile -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $defaultConfig | ConvertTo-Json -Depth 4 | Set-Content -Path $ConfigFile -Encoding UTF8
    Write-BackupLog "Default config created at: $ConfigFile"
}

$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

# Filter to specific job
$jobs = $config.Jobs
if ($Job) {
    $jobs = $jobs | Where-Object { $_.Name -like "*$Job*" }
    if (-not $jobs) {
        Write-BackupLog "No job matching '$Job' found in config." -Level Error
        return
    }
}

Write-BackupLog "Starting backup: $($jobs.Count) job(s)"

# --- Execute Backup Jobs ---
$results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($j in $jobs) {
    $jobName = $j.Name
    $source = $j.Source
    $destination = $j.Destination
    $method = if ($j.Method) { $j.Method } else { 'robocopy' }

    Write-BackupLog "Job: $jobName ($source -> $destination)"

    if (-not (Test-Path $source)) {
        Write-BackupLog "Source not found: $source" -Level Warning
        $results.Add([PSCustomObject]@{ Job = $jobName; Status = 'Skipped'; Message = 'Source not found'; Files = 0; SizeMB = 0 })
        continue
    }

    if ($DryRun) {
        $fileCount = (Get-ChildItem -Path $source -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-BackupLog "[DRY RUN] Would copy $fileCount files from $source"
        $results.Add([PSCustomObject]@{ Job = $jobName; Status = 'DryRun'; Message = "Would copy $fileCount files"; Files = $fileCount; SizeMB = 0 })
        continue
    }

    # Ensure destination exists
    if (-not (Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    $startTime = Get-Date

    try {
        if ($method -eq 'robocopy') {
            $robocopyArgs = @($source, $destination, '/E', '/R:2', '/W:3', '/NP', '/NDL', '/NFL', '/LOG+:' + $LogFile)

            if ($j.Mirror) { $robocopyArgs += '/MIR' }

            if ($j.Exclude) {
                $robocopyArgs += '/XF'
                $robocopyArgs += $j.Exclude
                $robocopyArgs += '/XD'
                $robocopyArgs += $j.Exclude
            }

            $robocopyResult = & robocopy @robocopyArgs 2>&1
            $exitCode = $LASTEXITCODE

            # Robocopy exit codes: 0-7 are success/info, 8+ are errors
            if ($exitCode -ge 8) {
                Write-BackupLog "Robocopy reported errors (exit: $exitCode)" -Level Error
                $results.Add([PSCustomObject]@{ Job = $jobName; Status = 'Failed'; Message = "Exit code: $exitCode"; Files = 0; SizeMB = 0 })
            }
            else {
                $duration = (Get-Date) - $startTime
                Write-BackupLog "Completed in $([math]::Round($duration.TotalSeconds, 1))s (exit: $exitCode)"
                $results.Add([PSCustomObject]@{ Job = $jobName; Status = 'OK'; Message = "Robocopy exit: $exitCode"; Files = 0; SizeMB = 0 })
            }
        }
        else {
            # Simple Copy-Item method
            $files = Get-ChildItem -Path $source -Recurse -File -ErrorAction SilentlyContinue
            $totalSize = 0
            $fileCount = 0

            foreach ($file in $files) {
                $relativePath = $file.FullName.Replace($source, '').TrimStart('\')
                $destPath = Join-Path $destination $relativePath
                $destDir = Split-Path $destPath -Parent

                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }

                Copy-Item -Path $file.FullName -Destination $destPath -Force
                $fileCount++
                $totalSize += $file.Length
            }

            $sizeMB = [math]::Round($totalSize / 1MB, 2)
            $duration = (Get-Date) - $startTime
            Write-BackupLog "Copied $fileCount files ($sizeMB MB) in $([math]::Round($duration.TotalSeconds, 1))s"
            $results.Add([PSCustomObject]@{ Job = $jobName; Status = 'OK'; Message = "$fileCount files copied"; Files = $fileCount; SizeMB = $sizeMB })
        }
    }
    catch {
        Write-BackupLog "Error: $($_.Exception.Message)" -Level Error
        $results.Add([PSCustomObject]@{ Job = $jobName; Status = 'Failed'; Message = $_.Exception.Message; Files = 0; SizeMB = 0 })
    }
}

# --- Summary ---
Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Backup Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$okCount = ($results | Where-Object Status -eq 'OK').Count
$failCount = ($results | Where-Object Status -eq 'Failed').Count
$skipCount = ($results | Where-Object Status -eq 'Skipped').Count

foreach ($r in $results) {
    $color = switch ($r.Status) { 'OK' { 'Green' } 'Failed' { 'Red' } 'Skipped' { 'Yellow' } default { 'Gray' } }
    Write-Host ("  [{0,-7}] {1,-20} {2}" -f $r.Status, $r.Job, $r.Message) -ForegroundColor $color
}

Write-Host ""
Write-Host "  OK: $okCount | Failed: $failCount | Skipped: $skipCount" -ForegroundColor White
Write-Host "  Log: $LogFile" -ForegroundColor Gray
Write-Host ""
