#Requires -Version 7.0
<#
.SYNOPSIS
    ProfileMega - PowerShell profile mega module.
.DESCRIPTION
    Single module that loads agents, advanced features, utilities, quick actions,
    themes, and diagnostics. Import this from your profile for a full experience.
#>

$Global:ProfileMegaRoot = $PSScriptRoot
$root = $PSScriptRoot

#region CONFIG
. (Join-Path $root "Scripts\Config.ps1")
# Apply Lite mode: disable heavy features for faster load
if ($Global:ProfileConfig.ProfileMode -eq 'Lite') {
    $Global:ProfileConfig.EnableAgents = $false
    $Global:ProfileConfig.EnableAdvancedFeatures = $false
    $Global:ProfileConfig.EnableQuickActions = $false
}
# User overrides (load after defaults)
$userConfigPaths = @(
    (Join-Path $root "ProfileMegaUser.ps1"),
    (Join-Path $root "ProfileMega.Config.ps1"),
    (Join-Path $env:APPDATA "ProfileMega\Config.ps1")
)
foreach ($up in $userConfigPaths) {
    if (Test-Path $up) { . $up; break }
}
#endregion

#region BASE UTILITIES (define-if-missing so base profile wins when both loaded)
. (Join-Path $root "Scripts\BaseUtilities.ps1")
#endregion

#region PSREADLINE (single source for input/prompt tuning)
if ($Global:ProfileConfig.EnablePSReadLineConfig) {
    . (Join-Path $root "Scripts\PSReadLine.ps1")
}
#endregion

#region GLOBAL HELPERS (for submodules e.g. QuickActions)
function global:Test-CommandExists { param($command) $null -ne (Get-Command $command -ErrorAction SilentlyContinue) }
#endregion

#region MODULE LOADER
class ModuleLoader {
    [hashtable]$LoadedModules
    [hashtable]$LoadTimes
    ModuleLoader() {
        $this.LoadedModules = @{}
        $this.LoadTimes = @{}
    }
    [void]Load([string]$modulePath, [string]$name, [bool]$lazy) {
        if ($lazy) {
            $this.LoadedModules[$name] = "Lazy"
            return
        }
        $sw = [Diagnostics.Stopwatch]::StartNew()
        try {
            Import-Module $modulePath -Global -Force -ErrorAction Stop
            $this.LoadedModules[$name] = $true
        } catch {
            Write-Warning "Failed to load $name : $_"
            $this.LoadedModules[$name] = $false
        }
        $sw.Stop()
        $this.LoadTimes[$name] = $sw.Elapsed.TotalMilliseconds
    }
    [hashtable]GetStats() {
        $sum = ($this.LoadTimes.Values | Measure-Object -Sum).Sum
        $avg = ($this.LoadTimes.Values | Measure-Object -Average).Average
        return @{
            LoadedCount = ($this.LoadedModules.Values | Where-Object { $_ -eq $true }).Count
            FailedCount = ($this.LoadedModules.Values | Where-Object { $_ -eq $false }).Count
            LazyCount   = ($this.LoadedModules.Values | Where-Object { $_ -eq "Lazy" }).Count
            TotalTime   = if ($null -ne $sum) { $sum } else { 0 }
            AverageTime = if ($null -ne $avg) { $avg } else { 0 }
        }
    }
}
$Global:ModuleLoader = [ModuleLoader]::new()
#endregion

#region CORE AGENTS
if ($Global:ProfileConfig.EnableAgents) {
    $corePath = Join-Path $root "Core\AgentFramework.psm1"
    if (Test-Path $corePath) {
        try {
            Import-Module $corePath -Force -Global
            Initialize-AgentFramework
        } catch {
            Write-Warning "Failed to load AgentFramework: $_"
        }
    }
    $phase2Path = Join-Path $root "Agents\Phase2-Agents.psm1"
    if (Test-Path $phase2Path) {
        try {
            $Global:ModuleLoader.Load($phase2Path, "Phase2Agents", $false)
            if (Get-Command -Name "Register-Phase2Agents" -ErrorAction SilentlyContinue) {
                Register-Phase2Agents
            }
        } catch {
            Write-Warning "Failed to load Phase2Agents: $_"
        }
    }
}
#endregion

#region FEATURES
if ($Global:ProfileConfig.EnableAdvancedFeatures) {
    try {
        $Global:ModuleLoader.Load((Join-Path $root "Features\AdvancedFeatures.psm1"), "AdvancedFeatures", $false)
    } catch {
        Write-Warning "Failed to load AdvancedFeatures: $_"
        $Global:ModuleLoader.LoadedModules["AdvancedFeatures"] = $false
    }
}
try {
    $Global:ModuleLoader.Load((Join-Path $root "Features\AdvancedUtilities.psm1"), "AdvancedUtilities", $false)
} catch {
    Write-Warning "Failed to load AdvancedUtilities: $_"
    $Global:ModuleLoader.LoadedModules["AdvancedUtilities"] = $false
}
if ($Global:ProfileConfig.EnableQuickActions) {
    try {
        $Global:ModuleLoader.Load((Join-Path $root "Actions\QuickActions.psm1"), "QuickActions", $false)
    } catch {
        Write-Warning "Failed to load QuickActions: $_"
        $Global:ModuleLoader.LoadedModules["QuickActions"] = $false
    }
}
# Stub or lazy-load QuickActions when disabled so aliases (qh, clean, analyze) don't break
$quickActionsPath = Join-Path $root "Actions\QuickActions.psm1"
$needQuickActionsStubs = (-not $Global:ProfileConfig.EnableQuickActions) -or ($Global:ModuleLoader.LoadedModules["QuickActions"] -ne $true)
if ($needQuickActionsStubs) {
    function Show-QuickHelp {
        if ($Global:ModuleLoader.LoadedModules["QuickActions"] -eq $true) {
            $cmd = Get-Command -Name Show-QuickHelp -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'QuickActions' }
            if ($cmd) { & $cmd @args }; return
        }
        if ($Global:ProfileConfig.LazyLoadQuickActions -ne $false -and (Test-Path $quickActionsPath)) {
            try {
                $null = $Global:ModuleLoader.Load($quickActionsPath, "QuickActions", $false)
                if ($Global:ModuleLoader.LoadedModules["QuickActions"] -eq $true) {
                    $cmd = Get-Command -Name Show-QuickHelp -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'QuickActions' }
                    if ($cmd) { & $cmd @args }; return
                }
            } catch { }
        }
        Write-Host "QuickActions is disabled. Set ProfileConfig.EnableQuickActions = `$true and reload (profile-reload)." -ForegroundColor Yellow
    }
    function Clean-ProjectCache {
        if ($Global:ModuleLoader.LoadedModules["QuickActions"] -eq $true) {
            $cmd = Get-Command -Name Clean-ProjectCache -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'QuickActions' }
            if ($cmd) { & $cmd @args }; return
        }
        if ($Global:ProfileConfig.LazyLoadQuickActions -ne $false -and (Test-Path $quickActionsPath)) {
            try {
                $null = $Global:ModuleLoader.Load($quickActionsPath, "QuickActions", $false)
                if ($Global:ModuleLoader.LoadedModules["QuickActions"] -eq $true) {
                    $cmd = Get-Command -Name Clean-ProjectCache -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'QuickActions' }
                    if ($cmd) { & $cmd @args }; return
                }
            } catch { }
        }
        Write-Host "QuickActions is disabled. Set ProfileConfig.EnableQuickActions = `$true and reload." -ForegroundColor Yellow
    }
    function Analyze-Project {
        if ($Global:ModuleLoader.LoadedModules["QuickActions"] -eq $true) {
            $cmd = Get-Command -Name Analyze-Project -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'QuickActions' }
            if ($cmd) { & $cmd @args }; return
        }
        if ($Global:ProfileConfig.LazyLoadQuickActions -ne $false -and (Test-Path $quickActionsPath)) {
            try {
                $null = $Global:ModuleLoader.Load($quickActionsPath, "QuickActions", $false)
                if ($Global:ModuleLoader.LoadedModules["QuickActions"] -eq $true) {
                    $cmd = Get-Command -Name Analyze-Project -ErrorAction SilentlyContinue | Where-Object { $_.ModuleName -eq 'QuickActions' }
                    if ($cmd) { & $cmd @args }; return
                }
            } catch { }
        }
        Write-Host "QuickActions is disabled. Set ProfileConfig.EnableQuickActions = `$true and reload." -ForegroundColor Yellow
    }
}
#endregion

#region PROMPT & HELPERS
. (Join-Path $root "Scripts\Prompt.ps1")
# When PromptDriver is OhMyPosh or Starship, init here (so standalone ProfileMega gets the prompt)
$pDriver = $Global:ProfileConfig.PromptDriver
if ($pDriver -eq 'OhMyPosh') {
    try {
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    } catch {
        Write-Warning "oh-my-posh init failed: $_"
    }
} elseif ($pDriver -eq 'Starship') {
    try {
        Invoke-Expression (&starship init powershell)
    } catch {
        Write-Warning "starship init failed: $_"
    }
}
. (Join-Path $root "Scripts\NavigationAndGit.ps1")
. (Join-Path $root "Scripts\Enhancements.ps1")
#endregion

#region ALIASES
Set-Alias -Name ".."   -Value Set-LocationParent -ErrorAction SilentlyContinue
Set-Alias -Name "..."  -Value Set-LocationGrandParent -ErrorAction SilentlyContinue
Set-Alias -Name "~"    -Value Set-LocationHome -ErrorAction SilentlyContinue
# Git aliases: only set when base profile did not already define gs, ga, etc.
if (-not (Get-Command -Name gs -ErrorAction SilentlyContinue)) { Set-Alias -Name gs -Value git-status -ErrorAction SilentlyContinue }
if (-not (Get-Command -Name ga -ErrorAction SilentlyContinue)) { Set-Alias -Name ga -Value git-add-all -ErrorAction SilentlyContinue }
if (-not (Get-Command -Name gc -ErrorAction SilentlyContinue)) { Set-Alias -Name gc -Value git-commit -ErrorAction SilentlyContinue }
if (-not (Get-Command -Name gp -ErrorAction SilentlyContinue)) { Set-Alias -Name gp -Value git-push -ErrorAction SilentlyContinue }
if (-not (Get-Command -Name gl -ErrorAction SilentlyContinue)) { Set-Alias -Name gl -Value git-pull -ErrorAction SilentlyContinue }
Set-Alias -Name qh     -Value Show-QuickHelp -ErrorAction SilentlyContinue
Set-Alias -Name clean  -Value Clean-ProjectCache -ErrorAction SilentlyContinue
Set-Alias -Name analyze -Value Analyze-Project -ErrorAction SilentlyContinue
if (Get-Command docker -ErrorAction SilentlyContinue) { Set-Alias -Name d -Value docker -ErrorAction SilentlyContinue }
if (Get-Command docker-compose -ErrorAction SilentlyContinue) { Set-Alias -Name dc -Value docker-compose -ErrorAction SilentlyContinue }
if (Get-Command kubectl -ErrorAction SilentlyContinue) { Set-Alias -Name k -Value kubectl -ErrorAction SilentlyContinue }
Set-Alias -Name profile-reload      -Value Invoke-ProfileReload -ErrorAction SilentlyContinue
Set-Alias -Name profile-help        -Value Show-ProfileHelp -ErrorAction SilentlyContinue
Set-Alias -Name profile-info        -Value Get-ProfileInfo -ErrorAction SilentlyContinue
Set-Alias -Name profile-diagnostics -Value Invoke-ProfileDiagnostics -ErrorAction SilentlyContinue
if (Get-Command -Name admin -ErrorAction SilentlyContinue) { Set-Alias -Name su -Value admin -ErrorAction SilentlyContinue }
#endregion

#region STARTUP TASKS
if ($Global:TaskScheduler) { $Global:TaskScheduler.Start() }
if ($Global:ProfileConfig.EnablePlugins -and $Global:PluginManager) { $Global:PluginManager.LoadAllPlugins() }
if ($Global:ProfileConfig.EnableMonitoring -and $Global:AgentOrchestrator) {
    $monitorAgent = $Global:AgentOrchestrator.Agents["SystemMonitorAgent"]
    if ($monitorAgent -and $Global:TaskScheduler) {
        $Global:TaskScheduler.ScheduleTask("SystemMonitor", {
            $task = [AgentTask]::new("monitor.system", @{})
            $Global:AgentOrchestrator.Agents["SystemMonitorAgent"].EnqueueTask($task)
        }, "5m")
    }
}
#endregion

#region WELCOME
. (Join-Path $root "Scripts\Welcome.ps1")
#endregion

#region CLEANUP
if (Get-Command -Name "Register-EngineEvent" -ErrorAction SilentlyContinue) {
    try {
        Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
            if ($Global:AgentOrchestrator) { Stop-AgentFramework }
            if ($Global:TaskScheduler) { $Global:TaskScheduler.Stop() }
        } -ErrorAction SilentlyContinue
    } catch { }
}
#endregion

$Global:ProfileLoaded = $true
$Global:ProfileLoadTime = ((Get-Date) - $Global:ProfileLoadStart).TotalMilliseconds

# Export so manifest FunctionsToExport is satisfied (explicit export for clarity)
$functionsToExport = @(
    'Initialize-AgentFramework', 'Stop-AgentFramework', 'Get-AgentStatus', 'Show-AgentDashboard',
    'Get-ProfileInfo', 'Invoke-ProfileDiagnostics', 'Set-ProfileTheme', 'Get-ProfileTheme',
    'Invoke-ProfileReload', 'Show-ProfileHelp', 'Get-ProfileCommand',
    'Export-ProfileConfig', 'Import-ProfileConfig',
    'Set-LocationParent', 'Set-LocationGrandParent', 'Set-LocationHome',
    'git-status', 'git-add-all', 'git-commit', 'git-push', 'git-pull'
)
Export-ModuleMember -Function $functionsToExport
