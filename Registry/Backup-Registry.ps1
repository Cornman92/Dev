<#
.SYNOPSIS
    Creates full or partial Windows registry backups.

.DESCRIPTION
    Exports registry hives or specific keys to .reg files for
    safekeeping. Supports backing up individual keys, common
    hives, or the entire registry.

.PARAMETER Key
    Specific registry key path to back up (e.g., "HKLM\SOFTWARE\MyApp").

.PARAMETER Hive
    Predefined hive to back up: HKLM, HKCU, or All.

.PARAMETER OutputDir
    Directory to save backup files. Defaults to C:\Dev\Artifacts\RegistryBackups.

.EXAMPLE
    .\Backup-Registry.ps1 -Hive HKCU
    Backs up the current user registry hive.

.EXAMPLE
    .\Backup-Registry.ps1 -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Backs up the Run key only.

.EXAMPLE
    .\Backup-Registry.ps1 -Hive All
    Backs up HKLM and HKCU hives.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator for HKLM backups
#>
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'Key')]
    [string]$Key,

    [Parameter(ParameterSetName = 'Hive')]
    [ValidateSet('HKLM', 'HKCU', 'All')]
    [string]$Hive = 'HKCU',

    [Parameter()]
    [string]$OutputDir = "C:\Dev\Artifacts\RegistryBackups"
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Registry Backup" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Export-RegistryKey {
    param([string]$RegKey, [string]$FileName)

    $outputFile = Join-Path $OutputDir "$FileName-$timestamp.reg"

    Write-Host "  Exporting: $RegKey" -ForegroundColor Yellow -NoNewline

    try {
        $process = Start-Process -FilePath 'reg.exe' -ArgumentList "export `"$RegKey`" `"$outputFile`" /y" -Wait -PassThru -NoNewWindow -RedirectStandardError "$env:TEMP\reg-error.txt"

        if ($process.ExitCode -eq 0) {
            $size = (Get-Item $outputFile).Length
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Host " -> $outputFile ($sizeMB MB)" -ForegroundColor Green
        }
        else {
            $errorMsg = Get-Content "$env:TEMP\reg-error.txt" -ErrorAction SilentlyContinue
            Write-Host " FAILED: $errorMsg" -ForegroundColor Red
        }
    }
    catch {
        Write-Host " FAILED: $_" -ForegroundColor Red
    }
}

if ($Key) {
    $safeName = ($Key -replace '[\\:]', '_')
    Export-RegistryKey -RegKey $Key -FileName $safeName
}
else {
    $hivesToBackup = switch ($Hive) {
        'HKLM' { @(@{ Key = 'HKLM'; Name = 'HKLM_Full' }) }
        'HKCU' { @(@{ Key = 'HKCU'; Name = 'HKCU_Full' }) }
        'All'   { @(
            @{ Key = 'HKLM'; Name = 'HKLM_Full' },
            @{ Key = 'HKCU'; Name = 'HKCU_Full' }
        )}
    }

    foreach ($entry in $hivesToBackup) {
        Export-RegistryKey -RegKey $entry.Key -FileName $entry.Name
    }
}

Write-Host ""
Write-Host "Backup directory: $OutputDir" -ForegroundColor Gray
Write-Host "To restore: double-click the .reg file or run: reg import <file.reg>" -ForegroundColor Gray
Write-Host ""
