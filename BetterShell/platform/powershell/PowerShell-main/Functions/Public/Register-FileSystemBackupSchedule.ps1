<#
.SYNOPSIS
    Registers a scheduled task to perform regular file system backups.
.DESCRIPTION
    This function creates a scheduled task that will automatically back up a source directory
    to a destination directory at the specified interval.
.PARAMETER TaskName
    The name of the scheduled task to create.
.PARAMETER SourcePath
    The path to the source directory to back up.
.PARAMETER DestinationPath
    The path where backups will be stored.
.PARAMETER Interval
    The interval at which to perform backups. Can be 'Daily', 'Weekly', or a timespan (e.g., '1.00:00:00' for 1 day).
.PARAMETER DaysOfWeek
    Required if Interval is 'Weekly'. Specifies which days of the week to run the backup.
.PARAMETER StartTime
    The time of day to start the backup. Defaults to 1:00 AM.
.PARAMETER RetentionDays
    Number of days to keep backup files. Older backups will be deleted. Set to 0 to keep all backups.
.PARAMETER CompressionLevel
    The compression level to use for the backup.
.EXAMPLE
    Register-FileSystemBackupSchedule -TaskName "Documents Backup" \
        -SourcePath "C:\Documents" \
        -DestinationPath "D:\Backups" \
        -Interval Daily \
        -RetentionDays 30
#>
function Register-FileSystemBackupSchedule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Source path '$_' does not exist or is not a directory."
            }
            $true
        })]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Daily', 'Weekly', 'Monthly')]
        [string]$Interval,
        
        [Parameter()]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string[]]$DaysOfWeek,
        
        [Parameter()]
        [DateTime]$StartTime = (Get-Date -Hour 1 -Minute 0 -Second 0),
        
        [int]$RetentionDays = 30,
        
        [ValidateSet('NoCompression', 'Fastest', 'Optimal', 'SmallestSize')]
        [string]$CompressionLevel = 'Optimal',
        
        [switch]$Force
    )
    
    begin {
        # Ensure we're running as administrator if creating a scheduled task
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            throw "This function requires administrator privileges to create scheduled tasks. Please run PowerShell as Administrator."
        }
        
        # Resolve paths to full paths
        $SourcePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($SourcePath)
        $DestinationPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        
        # Create destination directory if it doesn't exist
        if (-not (Test-Path -Path $DestinationPath)) {
            if ($PSCmdlet.ShouldProcess($DestinationPath, 'Create destination directory')) {
                try {
                    $null = New-Item -Path $DestinationPath -ItemType Directory -Force:$Force -ErrorAction Stop
                    Write-Verbose "Created destination directory: $DestinationPath"
                }
                catch {
                    throw "Failed to create destination directory '$DestinationPath': $_"
                }
            }
        }
        
        # Validate DaysOfWeek for Weekly interval
        if ($Interval -eq 'Weekly' -and (-not $DaysOfWeek -or $DaysOfWeek.Count -eq 0)) {
            throw "The DaysOfWeek parameter is required when Interval is 'Weekly'."
        }
        
        # Create a unique task name if not provided
        if ([string]::IsNullOrWhiteSpace($TaskName)) {
            $folderName = Split-Path -Path $SourcePath -Leaf
            $TaskName = "FileSystemBackup_${folderName}_$(Get-Date -Format 'yyyyMMddHHmmss')"
            Write-Verbose "Generated task name: $TaskName"
        }
        
        # Define the script block that will be executed by the scheduled task
        $scriptBlock = {
            param(
                [string]$SourcePath,
                [string]$DestinationPath,
                [string]$CompressionLevel,
                [int]$RetentionDays
            )
            
            try {
                # Import the FileSystem module
                Import-Module FileSystem -Force -ErrorAction Stop
                
                # Create a timestamped backup
                $backupResult = Backup-Folder -SourcePath $SourcePath -DestinationPath $DestinationPath \
                    -CompressionLevel $CompressionLevel -Force
                
                if ($backupResult.Status -ne 'Success') {
                    throw "Backup failed with status: $($backupResult.Status)"
                }
                
                # Clean up old backups if retention is enabled
                if ($RetentionDays -gt 0) {
                    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
                    
                    Get-ChildItem -Path $DestinationPath -Filter "Backup_*" -Directory | 
                        Where-Object { $_.LastWriteTime -lt $cutoffDate } |
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                }
                
                # Log success
                "[$(Get-Date)] Backup completed successfully" | Out-File -FilePath "$DestinationPath\backup.log" -Append
                return $true
            }
            catch {
                # Log error
                "[$(Get-Date)] ERROR: $_" | Out-File -FilePath "$DestinationPath\backup_error.log" -Append
                return $false
            }
        }
        
        # Convert script block to base64 for scheduled task
        $scriptText = $scriptBlock.ToString()
        $scriptBytes = [System.Text.Encoding]::Unicode.GetBytes($scriptText)
        $encodedCommand = [Convert]::ToBase64String($scriptBytes)
    }
    
    process {
        try {
            # Register the scheduled task
            $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"
            
            # Create trigger based on interval
            switch ($Interval) {
                'Daily' {
                    $trigger = New-ScheduledTaskTrigger -Daily -At $StartTime
                }
                'Weekly' {
                    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DaysOfWeek -At $StartTime
                }
                'Monthly' {
                    $trigger = New-ScheduledTaskTrigger -Monthly -At $StartTime
                }
            }
            
            # Set task settings
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
            
            # Register the task
            $taskParams = @{
                TaskName    = $TaskName
                Action      = $action
                Trigger     = $trigger
                Settings    = $settings
                Description = "Scheduled backup of $SourcePath to $DestinationPath"
                RunLevel    = 'Highest'
                Force       = $Force
            }
            
            if ($PSCmdlet.ShouldProcess($TaskName, 'Register scheduled task')) {
                $task = Register-ScheduledTask @taskParams -ErrorAction Stop
                
                # Output task information
                [PSCustomObject]@{
                    TaskName        = $TaskName
                    SourcePath      = $SourcePath
                    DestinationPath = $DestinationPath
                    Interval        = $Interval
                    NextRunTime     = $task.NextRunTime
                    TaskPath        = $task.TaskPath
                    Status          = 'Scheduled'
                }
                
                Write-Verbose "Scheduled task '$TaskName' created successfully."
            }
        }
        catch {
            Write-Error "Failed to register scheduled task: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Backup schedule registration completed."
    }
}

<#
.SYNOPSIS
    Gets information about scheduled backup tasks.
.DESCRIPTION
    Retrieves information about backup tasks created by Register-FileSystemBackupSchedule.
.PARAMETER TaskName
    The name of the task to retrieve. If not specified, all backup tasks are returned.
.EXAMPLE
    Get-FileSystemBackupSchedule
.EXAMPLE
    Get-FileSystemBackupSchedule -TaskName "DailyBackup"
#>
function Get-FileSystemBackupSchedule {
    [CmdletBinding()]
    param(
        [string]$TaskName = '*'
    )
    
    try {
        $tasks = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue |
            Where-Object { $_.Description -like "Scheduled backup of *" }
        
        foreach ($task in $tasks) {
            $action = $task.Actions | Select-Object -First 1
            $trigger = $task.Triggers | Select-Object -First 1
            
            # Extract interval information
            $interval = if ($trigger.Repetition.Interval) {
                $span = $trigger.Repetition.Interval
                if ($span.TotalMinutes -lt 60) { "$($span.TotalMinutes)m" }
                elseif ($span.TotalHours -lt 24) { "$([math]::Round($span.TotalHours))h" }
                else { "$([math]::Round($span.TotalDays))d" }
            }
            else { 'Once' }
            
            [PSCustomObject]@{
                TaskName = $task.TaskName
                State = $task.State
                LastRunTime = $task.LastRunTime
                NextRunTime = $task.NextRunTime
                Interval = $interval
                Description = $task.Description
                TaskPath = $task.TaskPath
            }
        }
    }
    catch {
        Write-Error "Failed to retrieve backup tasks: $_"
    }
}

# Export the functions
Export-ModuleMember -Function Register-FileSystemBackupSchedule, Get-FileSystemBackupSchedule
