# ErrorHandling.optimized.ps1
# Advanced error handling and logging for PowerShell
# Optimized for performance and reliability

#region Configuration
$script:ErrorHandlingConfig = @{
    LogPath = "$env:USERPROFILE\Documents\PowerShell\Logs"
    MaxLogSizeMB = 10
    LogRetentionDays = 30
    EnableFileLogging = $true
    EnableConsoleOutput = $true
    EnableEmailNotifications = $false
    EmailRecipients = @()
    SlackWebhookUrl = $null
    MaxErrorCount = 1000
    ErrorCount = 0
    LastError = $null
    ErrorHistory = [System.Collections.Queue]::new(100)
}

# Ensure log directory exists
if (-not (Test-Path -Path $script:ErrorHandlingConfig.LogPath)) {
    $null = New-Item -ItemType Directory -Path $script:ErrorHandlingConfig.LogPath -Force
}
#endregion

#region Private Functions
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Error', 'Warning', 'Info', 'Debug')]
        [string]$Level = 'Error',
        
        [hashtable]$Properties = @{}
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($Properties.Count -gt 0) {
        $logMessage += " | " + ($Properties.GetEnumerator() | 
            ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
    }
    
    # Add to console output if enabled
    if ($script:ErrorHandlingConfig.EnableConsoleOutput) {
        $color = switch ($Level) {
            'Error'   { 'Red' }
            'Warning' { 'Yellow' }
            'Info'    { 'Cyan' }
            'Debug'   { 'Gray' }
            default   { 'White' }
        }
        
        [System.Console]::ForegroundColor = $color
        [System.Console]::WriteLine($logMessage)
        [System.Console]::ResetColor()
    }
    
    # Add to file if enabled
    if ($script:ErrorHandlingConfig.EnableFileLogging) {
        $logFile = Join-Path -Path $script:ErrorHandlingConfig.LogPath -ChildPath "ErrorLog_$(Get-Date -Format 'yyyyMMdd').log"
        
        # Rotate log file if it's too large
        if (Test-Path $logFile) {
            $fileInfo = Get-Item $logFile
            if ($fileInfo.Length -gt ($script:ErrorHandlingConfig.MaxLogSizeMB * 1MB)) {
                $archiveFile = $logFile -replace '\.log$', "_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
                Move-Item -Path $logFile -Destination $archiveFile -Force
            }
        }
        
        # Write to log file
        try {
            Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
        }
        catch {
            # If we can't write to the log file, try once more after a short delay
            Start-Sleep -Milliseconds 100
            try {
                Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
            }
            catch {
                # If we still can't write, write to event log as last resort
                Write-EventLog -LogName 'Application' -Source 'PowerShell' -EntryType Error -EventId 1001 -Message "Failed to write to log file: $_"
            }
        }
    }
    
    # Add to error history
    $errorRecord = [PSCustomObject]@{
        Timestamp = Get-Date
        Level = $Level
        Message = $Message
        Properties = $Properties
    }
    
    $script:ErrorHandlingConfig.ErrorHistory.Enqueue($errorRecord)
    if ($script:ErrorHandlingConfig.ErrorHistory.Count -gt $script:ErrorHandlingConfig.MaxErrorCount) {
        $null = $script:ErrorHandlingConfig.ErrorHistory.Dequeue()
    }
    
    $script:ErrorHandlingConfig.LastError = $errorRecord
    $script:ErrorHandlingConfig.ErrorCount++
}

function Invoke-SafeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [string]$ErrorMessage = "Command failed",
        
        [ValidateSet('Stop', 'Continue', 'SilentlyContinue', 'Inquire')]
        [string]$ErrorAction = 'Stop',
        
        [switch]$PassThru,
        
        [hashtable]$Context = @{}
    )
    
    try {
        $result = & $ScriptBlock
        
        if ($PassThru) {
            return $result
        }
    }
    catch {
        $errorRecord = $_
        $exception = $errorRecord.Exception
        
        $errorDetails = @{
            ErrorMessage = $exception.Message
            ErrorType = $exception.GetType().FullName
            ScriptName = $errorRecord.InvocationInfo.ScriptName
            LineNumber = $errorRecord.InvocationInfo.ScriptLineNumber
            ColumnNumber = $errorRecord.InvocationInfo.OffsetInLine
            Line = $errorRecord.InvocationInfo.Line.Trim()
            Category = $errorRecord.CategoryInfo.Category
            TargetObject = $errorRecord.TargetObject
        }
        
        # Add any additional context
        foreach ($key in $Context.Keys) {
            $errorDetails["Context_$key"] = $Context[$key]
        }
        
        # Log the error
        Write-ErrorLog -Message $ErrorMessage -Level Error -Properties $errorDetails
        
        # Handle the error based on the specified action
        switch ($ErrorAction) {
            'Stop' { throw $errorRecord }
            'Continue' { Write-Error $errorRecord -ErrorAction Continue }
            'SilentlyContinue' { return $null }
            'Inquire' { 
                $choice = $host.UI.PromptForChoice(
                    'Error Occurred', 
                    "$ErrorMessage`n$($exception.Message)`nContinue?",
                    @('&Yes', '&No'),
                    0
                )
                
                if ($choice -eq 1) {
                    throw $errorRecord
                }
            }
        }
        
        return $null
    }
}
#endregion

#region Public Functions
function Get-ErrorHistory {
    [CmdletBinding()]
    param(
        [int]$Last = 10,
        
        [ValidateSet('Error', 'Warning', 'Info', 'Debug', 'All')]
        [string]$Level = 'All'
    )
    
    $errors = if ($Level -eq 'All') {
        $script:ErrorHandlingConfig.ErrorHistory.ToArray()
    }
    else {
        $script:ErrorHandlingConfig.ErrorHistory | Where-Object { $_.Level -eq $Level }
    }
    
    $errors | Select-Object -Last $Last
}

function Clear-ErrorHistory {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess('Clear error history', 'Are you sure you want to clear the error history?', 'Confirm')) {
        $script:ErrorHandlingConfig.ErrorHistory.Clear()
        $script:ErrorHandlingConfig.ErrorCount = 0
        $script:ErrorHandlingConfig.LastError = $null
    }
}

function Test-ErrorRate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$TimeWindowMinutes = 60,
        
        [int]$Threshold = 10
    )
    
    $cutoffTime = (Get-Date).AddMinutes(-$TimeWindowMinutes)
    $recentErrors = $script:ErrorHandlingConfig.ErrorHistory | 
        Where-Object { $_.Timestamp -ge $cutoffTime -and $_.Level -eq 'Error' } | 
        Measure-Object | 
        Select-Object -ExpandProperty Count
    
    return $recentErrors -ge $Threshold
}
#endregion

# Export public functions
Export-ModuleMember -Function @(
    'Invoke-SafeCommand',
    'Get-ErrorHistory',
    'Clear-ErrorHistory',
    'Test-ErrorRate'
)
