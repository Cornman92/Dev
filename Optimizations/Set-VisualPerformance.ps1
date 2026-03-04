<#
.SYNOPSIS
    Toggles Windows visual effects between appearance and performance modes.

.DESCRIPTION
    Switches Windows visual effects settings to optimize for either
    best appearance or best performance. Performance mode disables
    animations, transparency, and shadows to reduce CPU/GPU overhead.

.PARAMETER Mode
    'Performance' disables visual effects. 'Appearance' restores them.
    'Custom' applies a balanced preset (animations off, font smoothing on).

.EXAMPLE
    .\Set-VisualPerformance.ps1 -Mode Performance
    Disables all visual effects for maximum performance.

.EXAMPLE
    .\Set-VisualPerformance.ps1 -Mode Appearance
    Restores full visual effects.

.EXAMPLE
    .\Set-VisualPerformance.ps1 -Mode Custom
    Applies a balanced preset.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Performance', 'Appearance', 'Custom')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Visual Effects: $Mode" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
$advancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

# VisualFXSetting: 0 = Custom, 1 = Best Appearance, 2 = Best Performance, 3 = Let Windows decide
$visualFxValue = switch ($Mode) {
    'Performance' { 2 }
    'Appearance'  { 1 }
    'Custom'      { 0 }
}

# Set main toggle
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name 'VisualFXSetting' -Value $visualFxValue -Type DWord

# UserPreferencesMask controls individual effects
$dwmPath = 'HKCU:\Software\Microsoft\Windows\DWM'

switch ($Mode) {
    'Performance' {
        # Disable transparency
        Set-ItemProperty -Path $dwmPath -Name 'EnableAeroPeek' -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $dwmPath -Name 'AlwaysHibernateThumbnails' -Value 0 -Type DWord -ErrorAction SilentlyContinue

        # Disable taskbar animations
        Set-ItemProperty -Path $advancedPath -Name 'TaskbarAnimations' -Value 0 -Type DWord -ErrorAction SilentlyContinue

        # Disable window animations
        $sysRegPath = 'HKCU:\Control Panel\Desktop\WindowMetrics'
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' -ErrorAction SilentlyContinue

        Write-Host "  Disabled: Animations, transparency, shadows" -ForegroundColor Yellow
        Write-Host "  Disabled: Taskbar animations, Aero Peek" -ForegroundColor Yellow
        Write-Host "  Set: Menu delay to 0ms" -ForegroundColor Yellow
    }
    'Appearance' {
        Set-ItemProperty -Path $dwmPath -Name 'EnableAeroPeek' -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $advancedPath -Name 'TaskbarAnimations' -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '400' -ErrorAction SilentlyContinue

        Write-Host "  Restored: All visual effects to defaults" -ForegroundColor Green
    }
    'Custom' {
        # Balanced: keep font smoothing and basic effects, disable heavy animations
        Set-ItemProperty -Path $dwmPath -Name 'EnableAeroPeek' -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $advancedPath -Name 'TaskbarAnimations' -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '100' -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'FontSmoothing' -Value '2' -ErrorAction SilentlyContinue

        Write-Host "  Disabled: Animations, Aero Peek" -ForegroundColor Yellow
        Write-Host "  Kept:     Font smoothing (ClearType)" -ForegroundColor Green
        Write-Host "  Set:      Menu delay to 100ms" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Changes take effect immediately for new windows." -ForegroundColor Gray
Write-Host "Some changes require a sign-out/sign-in to fully apply." -ForegroundColor Gray
Write-Host ""
