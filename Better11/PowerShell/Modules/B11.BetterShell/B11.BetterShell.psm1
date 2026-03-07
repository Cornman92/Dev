#Requires -Version 7.0

<#
.SYNOPSIS
    BetterShell v3.0 — Advanced terminal framework for PowerShell.
.DESCRIPTION
    Root module that aggregates all BetterShell sub-modules: Core, PromptEngine,
    CompletionSystem, HistoryManager, ThemeEngine, Navigation, GitIntegration,
    CloudIntegration, Watcher, Scheduler, Parallel, FileTools, DevTools, Plugin.
#>

$subModulesDir = Join-Path $PSScriptRoot 'SubModules'

# Import all sub-modules
$subModules = @(
    'Watcher/B11.BetterShell.Watcher.psm1',
    'Scheduler/B11.BetterShell.Scheduler.psm1',
    'Parallel/B11.BetterShell.Parallel.psm1',
    'FileTools/B11.BetterShell.FileTools.psm1',
    'DevTools/B11.BetterShell.DevTools.psm1',
    'Plugin/B11.BetterShell.Plugin.psm1'
)

foreach ($mod in $subModules) {
    $modPath = Join-Path $subModulesDir $mod
    if (Test-Path $modPath) {
        try {
            Import-Module $modPath -Force -Global -ErrorAction Stop
            Write-Verbose "Loaded BetterShell sub-module: $mod"
        }
        catch {
            Write-Warning "Failed to load BetterShell sub-module '$mod': $_"
        }
    }
}

function Get-B11BetterShellVersion {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    [PSCustomObject]@{
        PSTypeName = 'B11.BetterShellVersion'
        Version    = '3.0.0'
        SubModules = @(
            'Core', 'PromptEngine', 'CompletionSystem', 'HistoryManager',
            'ThemeEngine', 'Navigation', 'GitIntegration', 'CloudIntegration',
            'Watcher', 'Scheduler', 'Parallel', 'FileTools', 'DevTools', 'Plugin'
        )
        NewInV3    = @('Watcher', 'Scheduler', 'Parallel', 'FileTools', 'DevTools', 'Plugin')
        TotalFunctions = 301
    }
}

Export-ModuleMember -Function @('Get-B11BetterShellVersion')
