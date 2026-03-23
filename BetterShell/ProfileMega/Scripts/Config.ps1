#Requires -Version 7.0
# ProfileMega default configuration (dot-sourced by root module)
# Override in ProfileMegaUser.ps1 (same dir as .psd1) or $env:APPDATA\ProfileMega\Config.ps1

$Global:ProfileLoadStart = Get-Date
$Global:ProfileVersion = "1.0.0"

$Global:ProfileConfig = @{
    # ProfileMode: 'Full' = all features; 'Lite' = no agents, no AdvancedFeatures/QuickActions (faster load)
    ProfileMode            = 'Full'
    EnableAgents           = $true
    EnableAdvancedFeatures = $true
    EnableQuickActions     = $true
    EnableAI               = $true
    EnableDevOps           = $true
    EnableMonitoring       = $true
    EnablePlugins          = $true
    EnableWorkflows        = $true
    LazyLoad               = $true
    QuietMode              = $false
    Theme                  = "Dark"
    # PromptDriver: 'ProfileMega' | 'OhMyPosh' | 'Starship' | 'None' (ProfileMega = built-in prompt)
    PromptDriver           = "ProfileMega"
    # Load time (ms) above which to show a speed-up tip in Welcome
    LoadTimeTipThresholdMs  = 800
    # When false and QuickActions is disabled, stubs never try to load on first use
    LazyLoadQuickActions   = $true
    # Optional: URL for hb (hastebin-style paste). If empty, hb prints a message.
    HastebinUrl             = ""
    # When true, ProfileMega configures PSReadLine (Scripts/PSReadLine.ps1)
    EnablePSReadLineConfig  = $true
    # Self-update: 'None' | 'Git' | 'Url'. If 'Url', set UpdateManifestUrl to a raw URL (e.g. version.json).
    UpdateSource            = 'None'
    UpdateManifestUrl       = ""
}
