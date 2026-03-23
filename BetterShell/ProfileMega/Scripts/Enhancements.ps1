#Requires -Version 7.0
# ProfileMega enhancements: theme, diagnostics, reload, help (dot-sourced by root module)

$script:ProfileThemes = @{
    Dark = @{
        PromptUserColor   = 'Green'
        PromptHostColor   = 'Cyan'
        PromptPathColor   = 'Blue'
        AccentColor       = 'Magenta'
    }
    Light = @{
        PromptUserColor   = 'DarkGreen'
        PromptHostColor   = 'DarkCyan'
        PromptPathColor   = 'DarkBlue'
        AccentColor       = 'DarkMagenta'
    }
    Minimal = @{
        PromptUserColor   = 'Gray'
        PromptHostColor   = 'Gray'
        PromptPathColor   = 'Gray'
        AccentColor       = 'Gray'
    }
    Ocean = @{
        PromptUserColor   = 'Cyan'
        PromptHostColor   = 'DarkCyan'
        PromptPathColor   = 'Blue'
        AccentColor       = 'Yellow'
    }
}

function Get-ProfileInfo {
    <#
    .SYNOPSIS
        Returns version, load time, and config for the ProfileMega module.
    .DESCRIPTION
        Get-ProfileInfo returns a hashtable with Version, LoadTimeMs, Loaded, Root, Config,
        and optionally ModuleStats from the ModuleLoader.
    .EXAMPLE
        Get-ProfileInfo
    #>
    [CmdletBinding()]
    param()
    $info = @{
        Version     = $Global:ProfileVersion
        LoadTimeMs  = $Global:ProfileLoadTime
        Loaded      = $Global:ProfileLoaded
        Root        = $Global:ProfileMegaRoot
        Config     = $Global:ProfileConfig
    }
    if ($Global:ModuleLoader) {
        $info.ModuleStats = $Global:ModuleLoader.GetStats()
    }
    return $info
}

function Invoke-ProfileDiagnostics {
    <#
    .SYNOPSIS
        Prints ProfileMega diagnostics: version, load time, config, module stats, and per-module load times.
    .DESCRIPTION
        Invoke-ProfileDiagnostics displays version, profile mode, prompt driver, theme, module load counts,
        per-module load times (slowest first), and optional tips when load time exceeds the threshold.
    .EXAMPLE
        Invoke-ProfileDiagnostics
    #>
    [CmdletBinding()]
    param(
        [switch]$Verbose
    )
    Write-Host "`n  ProfileMega Diagnostics" -ForegroundColor Cyan
    Write-Host "  ======================`n" -ForegroundColor Cyan

    $info = Get-ProfileInfo
    Write-Host "  Version:      $($info.Version)" -ForegroundColor White
    Write-Host "  Load time:    $($info.LoadTimeMs) ms" -ForegroundColor White
    Write-Host "  Root:         $($info.Root)" -ForegroundColor White
    Write-Host "  Loaded:       $($info.Loaded)" -ForegroundColor White
    Write-Host "  ProfileMode:  $($Global:ProfileConfig.ProfileMode)" -ForegroundColor White
    Write-Host "  PromptDriver: $($Global:ProfileConfig.PromptDriver)" -ForegroundColor White
    Write-Host "  Theme:        $($Global:ProfileConfig.Theme)" -ForegroundColor White

    if ($info.ModuleStats) {
        Write-Host "`n  Module stats:" -ForegroundColor Yellow
        Write-Host "    Loaded: $($info.ModuleStats.LoadedCount)  Failed: $($info.ModuleStats.FailedCount)  Lazy: $($info.ModuleStats.LazyCount)" -ForegroundColor White
        Write-Host "    Total load time: $($info.ModuleStats.TotalTime) ms" -ForegroundColor White
        if ($Global:ModuleLoader -and $info.ModuleStats.FailedCount -gt 0) {
            $failed = $Global:ModuleLoader.LoadedModules.GetEnumerator() | Where-Object { $_.Value -eq $false }
            if ($failed) {
                Write-Host "    Failed modules: $($failed.Name -join ', ')" -ForegroundColor Yellow
            }
        }
        if ($Global:ModuleLoader.LoadTimes -and $Global:ModuleLoader.LoadTimes.Count -gt 0) {
            Write-Host "`n  Per-module load (ms):" -ForegroundColor Yellow
            $Global:ModuleLoader.LoadTimes.GetEnumerator() |
                Where-Object { $_.Value -is [double] -or $_.Value -is [int] } |
                Sort-Object -Property Value -Descending |
                ForEach-Object { Write-Host "    $($_.Key): $([math]::Round($_.Value, 0)) ms" -ForegroundColor White }
        }
    }

    $threshold = $Global:ProfileConfig.LoadTimeTipThresholdMs
    if ($null -ne $threshold -and $info.LoadTimeMs -gt $threshold) {
        Write-Host "`n  Tip: Consider ProfileMode = Lite or disabling agents to speed up (profile-help)." -ForegroundColor DarkGray
    }

    if ($Global:AgentOrchestrator) {
        $status = $Global:AgentOrchestrator.GetStatus()
        Write-Host "`n  Agents: $($status.Running) running, $($status.Stopped) stopped" -ForegroundColor Green
    }

    Write-Host "`n  PSReadLine: " -NoNewline
    if (Get-Module PSReadLine) { Write-Host "Loaded" -ForegroundColor Green } else { Write-Host "Not loaded" -ForegroundColor Yellow }
    Write-Host ""
}

function Set-ProfileTheme {
    <#
    .SYNOPSIS
        Sets the ProfileMega theme (Dark, Light, Minimal, Ocean).
    .DESCRIPTION
        Set-ProfileTheme updates $Global:ProfileConfig.Theme. The theme affects prompt colors when using the ProfileMega prompt driver.
    .EXAMPLE
        Set-ProfileTheme -Name Ocean
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Dark', 'Light', 'Minimal', 'Ocean')]
        [string]$Name
    )
    if (-not $script:ProfileThemes.ContainsKey($Name)) {
        Write-Warning "Unknown theme: $Name"
        return
    }
    $Global:ProfileConfig.Theme = $Name
    Write-Host "Theme set to: $Name" -ForegroundColor Green
}

function Get-ProfileTheme {
    <#
    .SYNOPSIS
        Returns the current ProfileMega theme name.
    .DESCRIPTION
        Get-ProfileTheme returns the value of $Global:ProfileConfig.Theme.
    .EXAMPLE
        Get-ProfileTheme
    #>
    [CmdletBinding()]
    param()
    return $Global:ProfileConfig.Theme
}

function Invoke-ProfileReload {
    <#
    .SYNOPSIS
        Reloads the current user PowerShell profile.
    .DESCRIPTION
        Invoke-ProfileReload runs & $PROFILE to reload the profile in the current session.
    .EXAMPLE
        Invoke-ProfileReload
    #>
    [CmdletBinding()]
    param()
    Write-Host "Reloading profile..." -ForegroundColor Cyan
    & $PROFILE
    Write-Host "Profile reloaded." -ForegroundColor Green
}

function Get-ProfileCommand {
    <#
    .SYNOPSIS
        Lists commands and optionally aliases provided by ProfileMega.
    .DESCRIPTION
        Get-ProfileCommand returns a list of profile-related commands that exist in the session. Use -IncludeAliases to also include profile aliases.
    .EXAMPLE
        Get-ProfileCommand
    .EXAMPLE
        Get-ProfileCommand -IncludeAliases
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeAliases
    )
    $commands = @(
        'Get-ProfileInfo', 'Invoke-ProfileDiagnostics', 'Set-ProfileTheme', 'Get-ProfileTheme',
        'Invoke-ProfileReload', 'Show-ProfileHelp', 'Get-ProfileCommand',
        'Initialize-AgentFramework', 'Stop-AgentFramework', 'Get-AgentStatus', 'Show-AgentDashboard',
        'Set-LocationParent', 'Set-LocationGrandParent', 'Set-LocationHome',
        'git-status', 'git-add-all', 'git-commit', 'git-push', 'git-pull'
    )
    $result = [System.Collections.ArrayList]::new()
    foreach ($c in $commands) {
        $cmd = Get-Command -Name $c -ErrorAction SilentlyContinue
        if ($cmd) {
            $result.Add([PSCustomObject]@{ Name = $c; Type = $cmd.CommandType }) | Out-Null
        }
    }
    if ($IncludeAliases) {
        $aliases = @('profile-info', 'profile-diagnostics', 'profile-reload', 'profile-help', '..', '...', '~', 'gs', 'ga', 'gc', 'gp', 'gl', 'qh', 'clean', 'analyze')
        foreach ($a in $aliases) {
            $al = Get-Command -Name $a -ErrorAction SilentlyContinue
            if ($al) { $result.Add([PSCustomObject]@{ Name = $a; Type = 'Alias' }) | Out-Null }
        }
    }
    return $result
}

function Show-ProfileHelp {
    <#
    .SYNOPSIS
        Displays a quick reference of ProfileMega commands and aliases.
    .DESCRIPTION
        Show-ProfileHelp prints a short help summary: profile-* commands, agent commands, theme, navigation, and git aliases.
    .EXAMPLE
        Show-ProfileHelp
    #>
    [CmdletBinding()]
    param()
    $help = @"
$($PSStyle.Foreground.Cyan)ProfileMega - Quick Reference$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)================================$($PSStyle.Reset)

  profile-info          Get-ProfileInfo           Version, load time, config
  profile-diagnostics   Invoke-ProfileDiagnostics Full diagnostics
  profile-reload        Invoke-ProfileReload       Reload profile
  profile-help          Show-ProfileHelp           This message
  Get-ProfileCommand     List profile commands     Use -IncludeAliases for aliases

  Get-AgentStatus       Agent status
  Show-AgentDashboard   Agent dashboard
  Set-ProfileTheme      Set theme (Dark|Light|Minimal|Ocean)
  qh                    Show-QuickHelp (quick actions)

  Navigation: ..  ...  ~
  Git: gs ga gc gp gl

  Also see (base profile): Show-Help, ep (Edit-Profile), reload-profile
  Export-ProfileConfig / Import-ProfileConfig to backup or share config.
"@
    Write-Host $help
}

# Tab completion for Set-ProfileTheme
Register-ArgumentCompleter -CommandName Set-ProfileTheme -ParameterName Name -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    @('Dark', 'Light', 'Minimal', 'Ocean') | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

function Export-ProfileConfig {
    <#
    .SYNOPSIS
        Exports the current ProfileConfig to a .ps1 file for backup or sharing.
    .DESCRIPTION
        Export-ProfileConfig writes $Global:ProfileConfig keys to a script that can be dot-sourced later. Default path is ProfileMegaUser.ps1 next to the module.
    .EXAMPLE
        Export-ProfileConfig
    .EXAMPLE
        Export-ProfileConfig -Path $env:APPDATA\ProfileMega\MyConfig.ps1
    #>
    [CmdletBinding()]
    param(
        [string]$Path
    )
    if (-not $Path) {
        $Path = Join-Path $Global:ProfileMegaRoot "ProfileMegaUser.ps1"
    }
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $lines = @(
        "# ProfileMega user config - generated by Export-ProfileConfig",
        "# $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "",
        "`$Global:ProfileConfig = @{"
    )
    foreach ($key in ($Global:ProfileConfig.Keys | Sort-Object)) {
        $val = $Global:ProfileConfig[$key]
        if ($val -is [string]) {
            $lines += "    $key = '$($val -replace "'", "''")'"
        } elseif ($val -is [bool]) {
            $lines += "    $key = `$$val"
        } elseif ($null -eq $val) {
            $lines += "    $key = `$null"
        } else {
            $lines += "    $key = $val"
        }
    }
    $lines += "}"
    $lines | Set-Content -Path $Path -Encoding utf8
    Write-Host "Exported config to: $Path" -ForegroundColor Green
}

function Import-ProfileConfig {
    <#
    .SYNOPSIS
        Loads a ProfileConfig from a .ps1 file by dot-sourcing it.
    .DESCRIPTION
        Import-ProfileConfig dot-sources the given path. Use for loading a backup or shared config. Changes apply in the current session; use profile-reload to fully reapply.
    .EXAMPLE
        Import-ProfileConfig -Path C:\Backup\ProfileMegaUser.ps1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return
    }
    . $Path
    Write-Host "Imported config from: $Path" -ForegroundColor Green
}

function Update-ProfileMega {
    <#
    .SYNOPSIS
        Checks for and optionally applies ProfileMega updates (Git or URL manifest).
    .DESCRIPTION
        Update-ProfileMega uses ProfileConfig.UpdateSource: None (disabled), Git (git pull at module root), or Url (fetch UpdateManifestUrl and compare version). When Url is used, only a version check is performed; you are informed if a newer version is available.
    .EXAMPLE
        Update-ProfileMega
    .EXAMPLE
        Update-ProfileMega (when UpdateSource is Git) - runs git pull and suggests profile-reload
    #>
    [CmdletBinding()]
    param()
    $source = $Global:ProfileConfig.UpdateSource
    $root = $Global:ProfileMegaRoot
    $currentVersion = $Global:ProfileVersion

    if ([string]::IsNullOrWhiteSpace($source) -or $source -eq 'None') {
        Write-Host "Self-update is disabled. Set ProfileConfig.UpdateSource to 'Git' or 'Url' to enable." -ForegroundColor Yellow
        return
    }

    if ($source -eq 'Git') {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Warning "Git is not available. Install Git or use UpdateSource = 'Url'."
            return
        }
        if (-not (Test-Path (Join-Path $root ".git"))) {
            Write-Warning "ProfileMega root is not a git repo: $root"
            return
        }
        try {
            Push-Location $root
            $output = git pull 2>&1
            Pop-Location
            Write-Host $output
            Write-Host "`nRun profile-reload to use the updated module." -ForegroundColor Cyan
        } catch {
            Pop-Location -ErrorAction SilentlyContinue
            Write-Error "Git pull failed: $_"
        }
        return
    }

    if ($source -eq 'Url') {
        $manifestUrl = $Global:ProfileConfig.UpdateManifestUrl
        if ([string]::IsNullOrWhiteSpace($manifestUrl)) {
            Write-Warning "UpdateSource is 'Url' but UpdateManifestUrl is not set. Set ProfileConfig.UpdateManifestUrl to a raw URL (e.g. version.json)."
            return
        }
        try {
            $response = Invoke-RestMethod -Uri $manifestUrl -MaximumRetryCount 2 -ErrorAction Stop
            $remoteVersion = $null
            if ($response -is [string]) {
                $remoteVersion = $response.Trim()
            } elseif ($response.PSObject.Properties['version']) {
                $remoteVersion = $response.version
            } elseif ($response.PSObject.Properties['Version']) {
                $remoteVersion = $response.Version
            }
            if (-not $remoteVersion) {
                Write-Host "Could not read version from manifest at $manifestUrl (expected 'version' property or plain text)." -ForegroundColor Yellow
                return
            }
            $remoteVer = [System.Version]::new(0, 0, 0, 0)
            $currentVer = [System.Version]::new(0, 0, 0, 0)
            [System.Version]::TryParse($remoteVersion, [ref]$remoteVer) | Out-Null
            [System.Version]::TryParse($currentVersion, [ref]$currentVer) | Out-Null
            if ($remoteVer -gt $currentVer) {
                Write-Host "New version $remoteVersion available (current: $currentVersion). Update manually or set UpdateSource = 'Git' and use Update-ProfileMega to pull." -ForegroundColor Green
            } else {
                Write-Host "ProfileMega is up to date (version $currentVersion)." -ForegroundColor Green
            }
        } catch {
            Write-Warning "Failed to fetch update manifest: $_"
        }
        return
    }

    Write-Host "Unknown UpdateSource: $source. Use 'None', 'Git', or 'Url'." -ForegroundColor Yellow
}
