@{
    RootModule        = 'B11.BetterShell.psm1'
    ModuleVersion     = '3.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'C-Man'
    CompanyName       = 'Better11'
    Copyright         = '(c) 2025-2026 C-Man. All rights reserved.'
    Description       = 'BetterShell v3.0 — Comprehensive PowerShell terminal framework.'
    PowerShellVersion = '7.0'
    NestedModules     = @(
        'SubModules\Watcher\B11.BetterShell.Watcher.psm1'
        'SubModules\Scheduler\B11.BetterShell.Scheduler.psm1'
        'SubModules\Parallel\B11.BetterShell.Parallel.psm1'
        'SubModules\FileTools\B11.BetterShell.FileTools.psm1'
        'SubModules\DevTools\B11.BetterShell.DevTools.psm1'
        'SubModules\Plugin\B11.BetterShell.Plugin.psm1'
    )
    FunctionsToExport = @(
        'New-B11FileWatcher','Start-B11FileWatcher','Stop-B11FileWatcher',
        'Remove-B11FileWatcher','Get-B11FileWatcher','Add-B11WatcherAction',
        'Get-B11WatcherEvents','Clear-B11WatcherEvents','Watch-B11Path',
        'Get-B11WatcherStatistics','Set-B11WatcherFilter','Export-B11WatcherConfig',
        'Import-B11WatcherConfig','Test-B11WatcherHealth','Restart-B11FileWatcher',
        'Get-B11WatcherEventSummary',
        'New-B11ScheduledTask','Enable-B11ScheduledTask','Disable-B11ScheduledTask',
        'Remove-B11ScheduledTask','Get-B11ScheduledTask','Invoke-B11ScheduledTask',
        'Get-B11TaskHistory','Clear-B11TaskHistory','Get-B11SchedulerStatistics',
        'Set-B11TaskInterval','Test-B11TaskDependencies','Export-B11SchedulerConfig',
        'Import-B11SchedulerConfig','Stop-B11AllScheduledTasks',
        'Invoke-B11Parallel','New-B11ParallelJob','Start-B11JobQueue',
        'Get-B11ParallelJob','Wait-B11ParallelJob','Clear-B11JobQueue',
        'Get-B11ParallelStatistics','Invoke-B11ParallelPipeline',
        'Stop-B11ParallelJob','Measure-B11ParallelPerformance',
        'Find-B11File','Get-B11FileHash','Compare-B11Directories','Get-B11DuplicateFiles',
        'Get-B11DirectorySize','New-B11TempFile','Copy-B11WithProgress','Rename-B11Bulk',
        'Get-B11FileEncoding','Convert-B11FileEncoding','Get-B11FileLineCount',
        'Merge-B11Files','Split-B11File',
        'Measure-B11ScriptComplexity','Get-B11CodeStatistics','Find-B11TodoComments',
        'Test-B11ScriptSyntax','ConvertTo-B11Base64','ConvertFrom-B11Base64',
        'New-B11ModuleScaffold','Measure-B11CommandPerformance','Get-B11FunctionList',
        'Find-B11UnusedFunctions','Format-B11Json',
        'Register-B11Plugin','Import-B11Plugin','Remove-B11Plugin','Get-B11Plugin',
        'Test-B11PluginCompatibility','Add-B11PluginSearchPath','Find-B11Plugin',
        'Enable-B11Plugin','Disable-B11Plugin','Update-B11Plugin',
        'Get-B11PluginStatistics','Export-B11PluginConfig','Import-B11PluginConfig'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('BetterShell','Terminal','Framework','Better11')
            ProjectUri = 'https://github.com/better11/better11'
        }
    }
}
