<#
.SYNOPSIS
    Exports a list of installed software to CSV or console.

.DESCRIPTION
    Queries installed software from the registry (both 64-bit and
    32-bit paths) and optionally from Get-Package. Returns a sorted
    list with name, version, publisher, and install date.

.PARAMETER OutputPath
    Optional path to export results as CSV.

.PARAMETER Filter
    Optional wildcard to filter by software name (e.g., "*Visual*").

.PARAMETER IncludeUpdates
    Include Windows updates and hotfixes in the output.

.EXAMPLE
    .\Export-InstalledSoftware.ps1
    Lists all installed software to the console.

.EXAMPLE
    .\Export-InstalledSoftware.ps1 -OutputPath "C:\Dev\Artifacts\software.csv"
    Exports the software list to a CSV file.

.EXAMPLE
    .\Export-InstalledSoftware.ps1 -Filter "*Microsoft*"
    Lists only Microsoft software.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$Filter,

    [Parameter()]
    [switch]$IncludeUpdates
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Installed Software Inventory" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Registry paths for installed software
$registryPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$software = foreach ($path in $registryPaths) {
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -and $_.DisplayName.Trim() -ne ''
    } | ForEach-Object {
        [PSCustomObject]@{
            Name         = $_.DisplayName.Trim()
            Version      = $_.DisplayVersion
            Publisher    = $_.Publisher
            InstallDate  = $_.InstallDate
            InstallPath  = $_.InstallLocation
            UninstallCmd = $_.UninstallString
            Source       = 'Registry'
        }
    }
}

# Remove duplicates by name+version
$software = $software | Sort-Object Name, Version -Unique

# Filter updates if not requested
if (-not $IncludeUpdates) {
    $software = $software | Where-Object {
        $_.Name -notmatch '^(Update for|Security Update|Hotfix|KB\d+)'
    }
}

# Apply name filter
if ($Filter) {
    $software = $software | Where-Object { $_.Name -like $Filter }
}

# Sort by name
$software = $software | Sort-Object Name

# Display count
Write-Host "Found $($software.Count) installed applications." -ForegroundColor White
Write-Host ""

# Export or display
if ($OutputPath) {
    $outputDir = Split-Path -Parent $OutputPath
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    $software | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported to: $OutputPath" -ForegroundColor Green
}
else {
    $software | Format-Table Name, Version, Publisher, InstallDate -AutoSize
}

Write-Host ""
