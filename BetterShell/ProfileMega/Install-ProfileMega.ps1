#Requires -Version 7.0
<#
.SYNOPSIS
    Installs ProfileMega so it loads in your PowerShell profile.
.DESCRIPTION
    Adds the ProfileMega module path to PSModulePath (current user) and optionally
    appends a line to $PROFILE so PowerShell loads ProfileMega at startup.
.EXAMPLE
    .\Install-ProfileMega.ps1
    .\Install-ProfileMega.ps1 -SkipProfileUpdate
#>
[CmdletBinding()]
param(
    [switch]$SkipProfileUpdate
)

$ErrorActionPreference = 'Stop'
$moduleDir = $PSScriptRoot
$manifestPath = Join-Path $moduleDir "ProfileMega.psd1"

if (-not (Test-Path $manifestPath)) {
    Write-Error "ProfileMega.psd1 not found at $moduleDir. Run this script from the ProfileMega folder."
}

# Ensure PowerShell 7+
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "ProfileMega requires PowerShell 7+. Current: $($PSVersionTable.PSVersion). Install from https://github.com/PowerShell/PowerShell/releases"
}

# Add to PSModulePath (current user)
$userModules = [Environment]::GetFolderPath('UserProfile')
$currentPath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
if ($currentPath -notlike "*$moduleDir*") {
    $newPath = "$moduleDir;$currentPath"
    [Environment]::SetEnvironmentVariable('PSModulePath', $newPath, 'User')
    $env:PSModulePath = "$moduleDir;$env:PSModulePath"
    Write-Host "Added ProfileMega to PSModulePath (User)." -ForegroundColor Green
} else {
    Write-Host "ProfileMega already in PSModulePath." -ForegroundColor Gray
}

# Optionally update profile
if (-not $SkipProfileUpdate) {
    $profileLine = "Import-Module ProfileMega -Force -Global"
    $profileContent = $null
    if (Test-Path $PROFILE) {
        $profileContent = Get-Content $PROFILE -Raw
    }
    if ($profileContent -and $profileContent -match [regex]::Escape($profileLine)) {
        Write-Host "Profile already loads ProfileMega." -ForegroundColor Gray
    } else {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        $append = "`n# ProfileMega (install script added)`n$profileLine`n"
        Add-Content -Path $PROFILE -Value $append
        Write-Host "Appended ProfileMega load to: $PROFILE" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. Restart PowerShell, then run: profile-help" -ForegroundColor Cyan
Write-Host ""
