function Get-ScheduledTasks {
    [CmdletBinding()]
    param()

    Get-ScheduledTask | Select-Object TaskName, State, LastRunTime, NextRunTime
}
