#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Point this to the mounted FoD ISO folder "LanguagesAndOptionalFeatures"
    # Example: "E:\LanguagesAndOptionalFeatures"
    [Parameter(Mandatory = $true)]
    [string]$FoDSource,

    # Prevent contacting Windows Update (recommended for offline/WSUS environments)
    [switch]$LimitAccess = $true,

    # If set, includes language-tagged non-Language.* capabilities ONLY when tag is en-US or und-*
    # If not set, the script skips ALL language-tagged capabilities (safest).
    [switch]$AllowEnUsOrUndTagged = $true,

    # If set, attempts to enable *all* optional features (even if already enabled it will skip)
    [switch]$EnableAllOptionalFeatures = $true,

    # If set, attempts to install *all* non-language capabilities that are NotPresent
    [switch]$InstallAllNonLanguageCapabilities = $true
)

function Resolve-FoDSource {
    param([string]$Path)

    if (-not (Test-Path $Path)) { throw "FoDSource not found: $Path" }

    # Allow passing the ISO root (drive:\) and auto-finding LanguagesAndOptionalFeatures
    $candidate = Join-Path $Path "LanguagesAndOptionalFeatures"
    if (Test-Path $candidate) { return $candidate }

    return $Path
}

$FoDSource = Resolve-FoDSource -Path $FoDSource
Write-Host "Using FoD repository: $FoDSource" -ForegroundColor Cyan

$LogDir = "C:\Scripts\Logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
Start-Transcript -Path (Join-Path $LogDir "Install_All_NonLanguage_FoD_$Stamp.log") -Force

try {
    # -------------------------------
    # 1) OPTIONAL FEATURES
    # -------------------------------
    if ($EnableAllOptionalFeatures) {
        Write-Host "`n=== Enabling Optional Features (Windows Features) ===" -ForegroundColor Yellow

        # Enumerate optional features in running OS. [5](https://ss64.com/ps/add-windowscapability.html)
        $features = Get-WindowsOptionalFeature -Online |
            Where-Object { $_.State -eq 'Disabled' } |
            Sort-Object FeatureName

        Write-Host ("Disabled optional features found: {0}" -f $features.Count) -ForegroundColor Cyan

        foreach ($f in $features) {
            $name = $f.FeatureName

            if ($PSCmdlet.ShouldProcess("OptionalFeature: $name", "Enable-WindowsOptionalFeature")) {
                try {
                    $p = @{
                        Online      = $true
                        FeatureName = $name
                        All         = $true
                        NoRestart   = $true
                        ErrorAction = 'Stop'
                    }

                    # Enable-WindowsOptionalFeature supports Source/LimitAccess for restore payload scenarios. [4](https://files.rg-adguard.net/file/025cfc5d-f5fa-7d00-246e-76c04a40e210)
                    if ($FoDSource) { $p.Source = @($FoDSource) }
                    if ($LimitAccess) { $p.LimitAccess = $true }

                    Enable-WindowsOptionalFeature @p | Out-Null
                    Write-Host "Enabled: $name" -ForegroundColor Green
                }
                catch {
                    Write-Warning "FAILED enabling feature $name : $($_.Exception.Message)"
                }
            }
        }
    }

    # -------------------------------
    # 2) CAPABILITIES (FoD)
    # -------------------------------
    if ($InstallAllNonLanguageCapabilities) {
        Write-Host "`n=== Installing Capabilities (Non-language only) ===" -ForegroundColor Yellow

        $caps = Get-WindowsCapability -Online |
            Where-Object { $_.State -eq 'NotPresent' } |
            Sort-Object Name

        Write-Host ("NotPresent capabilities found: {0}" -f $caps.Count) -ForegroundColor Cyan

        # Filtering rules:
        # - Skip anything that starts with "Language." (language features)
        # - Skip anything with a language tag ~~~xx-XX~ unless AllowEnUsOrUndTagged and tag is en-US or und-*
        # This keeps installs "non-language" and avoids pulling other locales.
        $nonLangCaps = foreach ($c in $caps) {
            $n = $c.Name

            if ($n -like 'Language.*') { continue }

            # Detect a language tag in the capability name (~~~xx-XX~ or ~~~und-XXXX~)
            if ($n -match '~~~([a-z]{2}-[A-Z]{2}|und-[A-Za-z]+)~') {
                if (-not $AllowEnUsOrUndTagged) { continue }

                $tag = $Matches[1]
                if ($tag -ne 'en-US' -and $tag -notmatch '^und-') { continue }
            }

            $c
        }

        Write-Host ("Non-language capabilities selected for install: {0}" -f $nonLangCaps.Count) -ForegroundColor Cyan

        foreach ($c in $nonLangCaps) {
            $name = $c.Name

            if ($PSCmdlet.ShouldProcess("Capability: $name", "Add-WindowsCapability")) {
                try {
                    $p = @{
                        Online      = $true
                        Name        = $name
                        Source      = @($FoDSource)
                        ErrorAction = 'Stop'
                    }

                    # Add-WindowsCapability supports -Source and -LimitAccess. [2](https://superuser.com/questions/1688019/cant-install-open-ssh-server-in-windows-10)[3](https://serverfault.com/questions/1170111/which-configuration-i-should-enable-so-i-can-install-openssh-server-via-wsus-on)
                    if ($LimitAccess) { $p.LimitAccess = $true }

                    Add-WindowsCapability @p | Out-Null
                    Write-Host "Installed: $name" -ForegroundColor Green
                }
                catch {
                    Write-Warning "FAILED installing capability $name : $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Host "`nAll requested operations completed. Reboot recommended." -ForegroundColor Yellow
}
finally {
    Stop-Transcript
}