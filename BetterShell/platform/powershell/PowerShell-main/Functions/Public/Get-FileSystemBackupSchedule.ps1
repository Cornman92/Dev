<#
.SYNOPSIS
    Gets information about scheduled file system backup tasks.
.DESCRIPTION
    This function retrieves information about scheduled backup tasks created by the Register-FileSystemBackupSchedule function.
    It can also remove or disable tasks.
.PARAMETER TaskName
    The name of the scheduled task to retrieve. Supports wildcards.
.PARAMETER TaskPath
    The task path to search in. Default is '\' (root).
.PARAMETER Remove
    If specified, removes the matching scheduled tasks.
.PARAMETER Disable
    If specified, disables the matching scheduled tasks.
.PARAMETER Enable
    If specified, enables the matching scheduled tasks.
.EXAMPLE
    Get-FileSystemBackupSchedule -TaskName "Documents Backup"
    Gets information about the "Documents Backup" scheduled task.
.EXAMPLE
    Get-FileSystemBackupSchedule -TaskName "*Backup*" -Remove
    Removes all scheduled tasks with "Backup" in the name.
#>
function Get-FileSystemBackupSchedule {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [SupportsWildcards()]
        [string]$TaskName = '*',
        
        [string]$TaskPath = '\',
        
        [Parameter(ParameterSetName = 'Remove', Mandatory = $true)]
        [switch]$Remove,
        
        [Parameter(ParameterSetName = 'Disable', Mandatory = $true)]
        [switch]$Disable,
        
        [Parameter(ParameterSetName = 'Enable', Mandatory = $true)]
        [switch]$Enable,
        
        [switch]$Force
    )
    
    begin {
        # Ensure we're running as administrator if modifying tasks
        if (($Remove -or $Disable -or $Enable) -and 
            -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This operation requires administrator privileges. Please run PowerShell as Administrator."
        }
        
        $results = @()
    }
    
    process {
        try {
            # Get all scheduled tasks that match the criteria
            $tasks = Get-ScheduledTask | Where-Object {
                $_.TaskPath -like "$TaskPath*" -and 
                $_.TaskName -like $TaskName
            }
            
            if (-not $tasks) {
                Write-Verbose "No scheduled tasks found matching the criteria."
                return
            }
            
            foreach ($task in $tasks) {
                try {
                    $taskInfo = $task | Get-ScheduledTaskInfo
                    $taskDefinition = $task | Get-ScheduledTask
                    
                    # Extract task information
                    $taskProps = [ordered]@{
                        TaskName = $task.TaskName
                        TaskPath = $task.TaskPath
                        State = $task.State.ToString()
                        LastRunTime = $taskInfo.LastRunTime
                        LastTaskResult = $taskInfo.LastTaskResult
                        NextRunTime = $taskInfo.NextRunTime
                        Description = $taskDefinition.Description
                        Author = $taskDefinition.Author
                        Actions = $taskDefinition.Actions
                        Triggers = $taskDefinition.Triggers
                    }
                    
                    $result = [PSCustomObject]$taskProps
                    
                    # Perform the requested action
                    switch ($PSCmdlet.ParameterSetName) {
                        'Remove' {
                            if ($PSCmdlet.ShouldProcess($task.TaskName, 'Remove scheduled task')) {
                                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false -ErrorAction Stop
                                $result | Add-Member -MemberType NoteProperty -Name 'Action' -Value 'Removed' -Force
                                Write-Verbose "Removed scheduled task: $($task.TaskPath)$($task.TaskName)"
                            }
                        }
                        'Disable' {
                            if ($PSCmdlet.ShouldProcess($task.TaskName, 'Disable scheduled task')) {
                                $task | Disable-ScheduledTask -ErrorAction Stop
                                $result | Add-Member -MemberType NoteProperty -Name 'Action' -Value 'Disabled' -Force
                                $result.State = 'Disabled'
                                Write-Verbose "Disabled scheduled task: $($task.TaskPath)$($task.TaskName)"
                            }
                        }
                        'Enable' {
                            if ($PSCmdlet.ShouldProcess($task.TaskName, 'Enable scheduled task')) {
                                $task | Enable-ScheduledTask -ErrorAction Stop
                                $result | Add-Member -MemberType NoteProperty -Name 'Action' -Value 'Enabled' -Force
                                $result.State = 'Ready'
                                Write-Verbose "Enabled scheduled task: $($task.TaskPath)$($task.TaskName)"
                            }
                        }
                        default {
                            $result | Add-Member -MemberType NoteProperty -Name 'Action' -Value 'Listed' -Force
                        }
                    }
                    
                    $results += $result
                }
                catch {
                    Write-Error "Error processing task '$($task.TaskName)': $_"
                }
            }
        }
        catch {
            Write-Error "Failed to retrieve scheduled tasks: $_"
            throw
        }
    }
    
    end {
        # Output the results
        return $results | Sort-Object -Property TaskPath, TaskName
    }
}
