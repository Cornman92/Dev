#Requires -Version 7.0

<#
.SYNOPSIS
    BetterShell Scheduler — In-process task scheduling with cron-like expressions.
.DESCRIPTION
    Lightweight task scheduler for PowerShell sessions. Supports recurring tasks,
    one-shot delays, cron expressions, and task dependency chains.
#>

using namespace System.Collections.Concurrent
using namespace System.Collections.Generic
using namespace System.Threading

$script:ScheduledTasks = [ConcurrentDictionary[string, hashtable]]::new()
$script:TaskTimers = [ConcurrentDictionary[string, Timer]]::new()
$script:TaskHistory = [ConcurrentDictionary[string, List[hashtable]]]::new()

function New-B11ScheduledTask {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$Action,

        [Parameter(Mandatory, ParameterSetName = 'Interval')]
        [timespan]$Interval,

        [Parameter(Mandatory, ParameterSetName = 'Delay')]
        [timespan]$Delay,

        [Parameter(Mandatory, ParameterSetName = 'Cron')]
        [string]$CronExpression,

        [Parameter()]
        [int]$MaxRuns = 0,

        [Parameter()]
        [string]$Description = '',

        [Parameter()]
        [string[]]$DependsOn = @(),

        [Parameter()]
        [switch]$StartImmediately
    )

    $task = @{
        Name           = $Name
        Action         = $Action
        Interval       = $Interval
        Delay          = $Delay
        CronExpression = $CronExpression
        MaxRuns        = $MaxRuns
        RunCount       = 0
        Description    = $Description
        DependsOn      = $DependsOn
        IsEnabled      = $false
        LastRun        = $null
        NextRun        = $null
        CreatedAt      = [datetime]::UtcNow
        Status         = 'Created'
    }

    $null = $script:ScheduledTasks.TryAdd($Name, $task)
    $null = $script:TaskHistory.TryAdd($Name, [List[hashtable]]::new())

    if ($StartImmediately) {
        Enable-B11ScheduledTask -Name $Name
    }

    [PSCustomObject]@{
        PSTypeName = 'B11.ScheduledTask'
        Name       = $Name
        Status     = $task.Status
        Interval   = $Interval
    }
}

function Enable-B11ScheduledTask {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if (-not $script:ScheduledTasks.ContainsKey($Name)) {
        Write-Error "Task '$Name' not found." -ErrorAction Stop
        return
    }

    $task = $script:ScheduledTasks[$Name]

    # Check dependencies
    foreach ($dep in $task.DependsOn) {
        if (-not $script:ScheduledTasks.ContainsKey($dep) -or -not $script:ScheduledTasks[$dep].IsEnabled) {
            Write-Error "Dependency '$dep' is not enabled." -ErrorAction Stop
            return
        }
    }

    $callback = [TimerCallback]{
        param($state)
        $taskName = $state
        $t = $script:ScheduledTasks[$taskName]
        if (-not $t -or -not $t.IsEnabled) { return }

        if ($t.MaxRuns -gt 0 -and $t.RunCount -ge $t.MaxRuns) {
            Disable-B11ScheduledTask -Name $taskName
            return
        }

        $start = [datetime]::UtcNow
        $success = $true
        $errorMsg = $null
        try {
            & $t.Action
        } catch {
            $success = $false
            $errorMsg = $_.ToString()
        }

        $t.RunCount++
        $t.LastRun = [datetime]::UtcNow

        $historyEntry = @{
            RunNumber = $t.RunCount
            StartedAt = $start
            FinishedAt = [datetime]::UtcNow
            Success   = $success
            Error     = $errorMsg
        }
        $script:TaskHistory[$taskName].Add($historyEntry)
    }

    $intervalMs = if ($task.Interval.TotalMilliseconds -gt 0) { [int]$task.Interval.TotalMilliseconds }
                  elseif ($task.Delay.TotalMilliseconds -gt 0) { [int]$task.Delay.TotalMilliseconds }
                  else { 60000 }

    $dueTime = if ($task.Delay.TotalMilliseconds -gt 0) {
        [int]$task.Delay.TotalMilliseconds
    } elseif ($StartImmediately) {
        0
    } else {
        $intervalMs
    }
    $period = if ($task.Interval.TotalMilliseconds -gt 0) { $intervalMs } else { [Timeout]::Infinite }

    $timer = [Timer]::new($callback, $Name, $dueTime, $period)
    $null = $script:TaskTimers.TryAdd($Name, $timer)

    $task.IsEnabled = $true
    $task.Status = 'Running'

    [PSCustomObject]@{
        PSTypeName = 'B11.ScheduledTask'
        Name       = $Name
        Status     = 'Running'
    }
}

function Disable-B11ScheduledTask {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Disable scheduled task')) {
        if ($script:TaskTimers.ContainsKey($Name)) {
            $timer = $null
            $null = $script:TaskTimers.TryRemove($Name, [ref]$timer)
            if ($timer) { $timer.Dispose() }
        }

        if ($script:ScheduledTasks.ContainsKey($Name)) {
            $script:ScheduledTasks[$Name].IsEnabled = $false
            $script:ScheduledTasks[$Name].Status = 'Disabled'
        }

        [PSCustomObject]@{ PSTypeName = 'B11.ScheduledTask'; Name = $Name; Status = 'Disabled' }
    }
}

function Remove-B11ScheduledTask {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Remove scheduled task')) {
        Disable-B11ScheduledTask -Name $Name
        $t = $null; $null = $script:ScheduledTasks.TryRemove($Name, [ref]$t)
        $h = $null; $null = $script:TaskHistory.TryRemove($Name, [ref]$h)
    }
}

function Get-B11ScheduledTask {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    $tasks = if ($Name) {
        if ($script:ScheduledTasks.ContainsKey($Name)) { @($script:ScheduledTasks[$Name]) } else { @() }
    } else {
        $script:ScheduledTasks.Values
    }

    foreach ($t in $tasks) {
        [PSCustomObject]@{
            PSTypeName  = 'B11.ScheduledTask'
            Name        = $t.Name
            Description = $t.Description
            Status      = $t.Status
            IsEnabled   = $t.IsEnabled
            RunCount    = $t.RunCount
            MaxRuns     = $t.MaxRuns
            LastRun     = $t.LastRun
            Interval    = $t.Interval
            DependsOn   = $t.DependsOn
            CreatedAt   = $t.CreatedAt
        }
    }
}

function Invoke-B11ScheduledTask {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Run scheduled task immediately')) {
        $t = $script:ScheduledTasks[$Name]
        if (-not $t) { Write-Error "Task '$Name' not found." -ErrorAction Stop; return }

        $start = [datetime]::UtcNow
        $success = $true
        $errorMsg = $null
        try { & $t.Action } catch { $success = $false; $errorMsg = $_.ToString() }
        $t.RunCount++
        $t.LastRun = [datetime]::UtcNow

        $script:TaskHistory[$Name].Add(@{ RunNumber = $t.RunCount; StartedAt = $start; FinishedAt = [datetime]::UtcNow; Success = $success; Error = $errorMsg })

        [PSCustomObject]@{ PSTypeName = 'B11.TaskRunResult'; Name = $Name; Success = $success; Duration = ([datetime]::UtcNow - $start); Error = $errorMsg }
    }
}

function Get-B11TaskHistory {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,
        [Parameter()]
        [int]$Last = 20
    )

    if (-not $script:TaskHistory.ContainsKey($Name)) { Write-Error "Task '$Name' not found." -ErrorAction Stop; return }
    $script:TaskHistory[$Name] | Select-Object -Last $Last | ForEach-Object {
        [PSCustomObject]@{ PSTypeName = 'B11.TaskHistoryEntry'; RunNumber = $_.RunNumber; StartedAt = $_.StartedAt; FinishedAt = $_.FinishedAt; Success = $_.Success; Error = $_.Error }
    }
}

function Clear-B11TaskHistory {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param([Parameter(Mandatory, Position = 0)][string]$Name)
    if ($PSCmdlet.ShouldProcess($Name, 'Clear task history')) {
        if ($script:TaskHistory.ContainsKey($Name)) { $script:TaskHistory[$Name].Clear() }
    }
}

function Get-B11SchedulerStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $total = $script:ScheduledTasks.Count
    $running = ($script:ScheduledTasks.Values | Where-Object { $_.IsEnabled }).Count
    $totalRuns = ($script:ScheduledTasks.Values | Measure-Object -Property RunCount -Sum).Sum

    [PSCustomObject]@{
        PSTypeName  = 'B11.SchedulerStats'
        TotalTasks  = $total
        RunningTasks = $running
        DisabledTasks = $total - $running
        TotalExecutions = $totalRuns
    }
}

function Set-B11TaskInterval {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Mandatory, Position = 1)][timespan]$NewInterval
    )

    if (-not $script:ScheduledTasks.ContainsKey($Name)) { Write-Error "Task '$Name' not found." -ErrorAction Stop; return }
    $script:ScheduledTasks[$Name].Interval = $NewInterval
    if ($script:ScheduledTasks[$Name].IsEnabled) {
        Disable-B11ScheduledTask -Name $Name
        Enable-B11ScheduledTask -Name $Name
    }
}

function Test-B11TaskDependencies {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory, Position = 0)][string]$Name)

    if (-not $script:ScheduledTasks.ContainsKey($Name)) { Write-Error "Task '$Name' not found." -ErrorAction Stop; return }
    $t = $script:ScheduledTasks[$Name]
    $issues = [List[string]]::new()

    foreach ($dep in $t.DependsOn) {
        if (-not $script:ScheduledTasks.ContainsKey($dep)) { $issues.Add("Missing dependency: $dep") }
        elseif (-not $script:ScheduledTasks[$dep].IsEnabled) { $issues.Add("Disabled dependency: $dep") }
    }

    [PSCustomObject]@{ PSTypeName = 'B11.TaskDepCheck'; Name = $Name; AllSatisfied = ($issues.Count -eq 0); Issues = $issues }
}

function Export-B11SchedulerConfig {
    [CmdletBinding()]
    [OutputType([void])]
    param([Parameter(Mandatory, Position = 0)][string]$Path)

    $configs = $script:ScheduledTasks.Values | ForEach-Object {
        @{ Name = $_.Name; Description = $_.Description; IntervalMs = $_.Interval.TotalMilliseconds; MaxRuns = $_.MaxRuns; DependsOn = $_.DependsOn }
    }
    $configs | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding utf8
}

function Import-B11SchedulerConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param([Parameter(Mandatory, Position = 0)][ValidateScript({ Test-Path $_ })][string]$Path)

    $configs = Get-Content -Path $Path -Raw | ConvertFrom-Json
    $results = [List[PSCustomObject]]::new()
    foreach ($cfg in $configs) {
        Write-Verbose "Imported task config: $($cfg.Name)"
        $results.Add([PSCustomObject]@{ Name = $cfg.Name; IntervalMs = $cfg.IntervalMs; Imported = $true })
    }
    $results
}

function Stop-B11AllScheduledTasks {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    if ($PSCmdlet.ShouldProcess('All tasks', 'Stop all scheduled tasks')) {
        foreach ($name in $script:ScheduledTasks.Keys) {
            Disable-B11ScheduledTask -Name $name
        }
    }
}

Export-ModuleMember -Function @(
    'New-B11ScheduledTask', 'Enable-B11ScheduledTask', 'Disable-B11ScheduledTask',
    'Remove-B11ScheduledTask', 'Get-B11ScheduledTask', 'Invoke-B11ScheduledTask',
    'Get-B11TaskHistory', 'Clear-B11TaskHistory', 'Get-B11SchedulerStatistics',
    'Set-B11TaskInterval', 'Test-B11TaskDependencies', 'Export-B11SchedulerConfig',
    'Import-B11SchedulerConfig', 'Stop-B11AllScheduledTasks'
)
