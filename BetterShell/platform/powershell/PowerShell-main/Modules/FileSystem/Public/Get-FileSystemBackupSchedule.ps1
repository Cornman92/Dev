<#
.SYNOPSIS
    Gets file system backup schedules.
.DESCRIPTION
    Retrieves a list of all configured file system backup schedules or a specific schedule by name.
.PARAMETER Name
    The name of the backup schedule to retrieve. If not specified, all schedules are returned.
.PARAMETER Detailed
    If specified, returns detailed information about each backup schedule.
.EXAMPLE
    PS> Get-FileSystemBackupSchedule
    
    Gets all backup schedules.
.EXAMPLE
    PS> Get-FileSystemBackupSchedule -Name "DailyBackup" -Detailed
    
    Gets detailed information about the "DailyBackup" schedule.
.OUTPUTS
    PSCustomObject representing the backup schedule(s).
.NOTES
    File Name      : Get-FileSystemBackupSchedule.ps1
    Author         : C-Man
    Prerequisite   : PowerShell 5.1 or later
    Copyright      : (c) 2025 C-Man. All rights reserved.
#>
function Get-FileSystemBackupSchedule {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Position = 0)]
        [string]$Name,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    begin {
        # Import required modules
        Import-Module -Name 'ScheduledTasks' -ErrorAction Stop
        
        # Define the task path for our backup tasks
        $taskPath = '\FileSystem\Backup\'
        
        # Get all scheduled tasks under our path
        try {
            $tasks = Get-ScheduledTask -TaskPath $taskPath -ErrorAction Stop | 
                    Where-Object { $_.TaskName -ne '\' }
        }
        catch {
            Write-Error "Failed to retrieve scheduled tasks: $_"
            return
        }
    }
    
    process {
        # Filter by name if specified
        if ($PSBoundParameters.ContainsKey('Name')) {
            $tasks = $tasks | Where-Object { $_.TaskName -eq $Name }
            if (-not $tasks) {
                Write-Warning "No backup schedule found with name '$Name'"
                return
            }
        }
        
        # Process each task
        foreach ($task in $tasks) {
            $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
            $taskActions = $task.Actions
            $taskTriggers = $task.Triggers
            $taskSettings = $task.Settings
            
            # Parse the task action to extract source and destination
            $actionCommand = $taskActions[0].Execute
            $actionArgs = $taskActions[0].Arguments
            
            # Create output object
            $output = [PSCustomObject]@{
                Name = $task.TaskName
                Enabled = $task.State -eq 'Ready'
                LastRunTime = $taskInfo.LastRunTime
                NextRunTime = $taskInfo.NextRunTime
                LastTaskResult = $taskInfo.LastTaskResult
                TaskPath = $task.TaskPath
                Description = $task.Description
                Author = $task.Author
                Date = $task.Date
                Actions = $task.Actions
                Triggers = $task.Triggers
            }
            
            # Add detailed information if requested
            if ($Detailed) {
                $output | Add-Member -MemberType NoteProperty -Name 'DetailedInfo' -Value @{
                    Settings = $task.Settings
                    Actions = $task.Actions
                    Triggers = $task.Triggers
                    TaskInfo = $taskInfo
                }
            }
            
            # Output the result
            $output
        }
    }
    
    end {
        # Clean up if needed
    }
}

# Set an alias for convenience
Set-Alias -Name 'gfsbs' -Value 'Get-FileSystemBackupSchedule' -Force