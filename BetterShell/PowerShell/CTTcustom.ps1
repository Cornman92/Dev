# CTTcustom.ps1 - Custom overlay for Chris Titus Tech PowerShell profile.
# This file is invoked by Microsoft.PowerShell_profile.ps1 when present.
# Loads ProfileMega (mega module) from OneDrive Dev, or falls back to Enhanced-Profile.

# Optional: set overrides for the main profile (see profile header for _Override variables)
# $debug_Override = $true
# $EDITOR_Override = "code"
# $updateInterval_Override = -1

$devRoot = Split-Path $PSScriptRoot -Parent
$profileMegaPath = Join-Path $devRoot "ProfileMega\ProfileMega.psd1"
$enhancedProfilePath = Join-Path $devRoot "Enhanced-Profile.ps1"

# Try ProfileMega first; on failure fall back to Enhanced-Profile
$loaded = $false
if (Test-Path $profileMegaPath) {
    try {
        Import-Module $profileMegaPath -Force -Global
        $loaded = $true
    } catch {
        Write-Warning "ProfileMega failed to load: $_"
    }
}
if (-not $loaded -and (Test-Path $enhancedProfilePath)) {
    try {
        . $enhancedProfilePath
        $loaded = $true
    } catch {
        Write-Warning "Enhanced profile failed to load: $_"
    }
}
if (-not $loaded) {
    Write-Verbose "No ProfileMega or Enhanced-Profile loaded."
}
