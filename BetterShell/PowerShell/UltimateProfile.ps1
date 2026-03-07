#Requires -Version 7.0
<#
.SYNOPSIS
    Standalone "ultimate" profile entry: PSReadLine + ProfileMega + zoxide.
.DESCRIPTION
    Use this as your only profile (no CTT base) for a single source of truth.
    Set $PROFILE to this script, or dot-source it from your main profile.
.EXAMPLE
    # In your profile, or set: $PROFILE = "C:\...\PowerShell\UltimateProfile.ps1"
    . "C:\Users\You\OneDrive\Dev\PowerShell\UltimateProfile.ps1"
#>

$ErrorActionPreference = 'Continue'
$profileDir = $PSScriptRoot
$devRoot = Split-Path $profileDir -Parent
$profileMegaPath = Join-Path $devRoot "ProfileMega\ProfileMega.psd1"

# Ensure ProfileMega is on path for Import-Module
if ($env:PSModulePath -notlike "*$devRoot*") {
    $env:PSModulePath = "$devRoot;$env:PSModulePath"
}

# Load ProfileMega (PSReadLine, prompt, theme, agents, utilities come from its config)
if (Test-Path $profileMegaPath) {
    try {
        Import-Module $profileMegaPath -Force -Global
    } catch {
        Write-Warning "ProfileMega failed: $_"
    }
}

# Zoxide (smart cd)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
    } catch { }
}
