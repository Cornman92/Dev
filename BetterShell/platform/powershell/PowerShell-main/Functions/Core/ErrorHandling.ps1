# ErrorHandling.ps1 - Advanced error handling and logging for PowerShell

#region Error Handling Configuration
$script:ErrorHandlingConfig = @{
    LogPath = "$env:USERPROFILE\Documents\PowerShell\Logs"
    MaxLogSizeMB = 10
    LogRetentionDays = 30
    EmailNotification = $false
    EmailRecipients = @()
    SlackWebhookUrl = $null
}

# Ensure log directory exists
if (-not (Test-Path -Path $script:ErrorHandlingConfig.LogPath)) {
    New-Item -ItemType Directory -Path $script:ErrorHandlingConfig.LogPath -Force | Out-Null
}
#endregion

#region Error Handler
function Register-ErrorHandler {
    <#
    .SYNOPSIS
        Registers a global error handler for the current PowerShell session.
    #>
    [CmdletBinding()]
    param()

    # Set strict mode and error action preference
    Set-StrictMode -Version Latest
    $global:ErrorActionPreference = 'Stop'
    $global:ProgressPreference = 'SilentlyContinue'

    # Register error handler
    $errorAction = {
        param($sender, $eventArgs)
        
        $errorRecord = $eventArgs.ErrorRecord
        $errorMessage = $errorRecord.Exception.Message
        $errorStackTrace = $errorRecord.ScriptStackTrace
        $errorCategory = $errorRecord.CategoryInfo.Category
        
        # Log the error
        $logEntry = @{
            Timestamp = Get-Date -Format 'o'
            Message = $errorMessage
            StackTrace = $errorStackTrace
            Category = $errorCategory
            CommandName = $errorRecord.InvocationInfo.MyCommand.Name
            ScriptName = $errorRecord.InvocationInfo.ScriptName
            LineNumber = $errorRecord.InvocationInfo.ScriptLineNumber
            Line = $errorRecord.InvocationInfo.Line
        }
        
        Write-ErrorLog -LogEntry $logEntry
        
        # Optionally send notification
        if ($script:ErrorHandlingConfig.EmailNotification) {
            Send-ErrorNotification -ErrorRecord $errorRecord
        }
        
        # Optionally send to Slack
        if ($script:ErrorHandlingConfig.SlackWebhookUrl) {
            Send-SlackNotification -ErrorRecord $errorRecord
        }
    }
    
    # Register the error action
    $global:ErrorView = 'NormalView'
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
    $PSDefaultParameterValues['*:WarningAction'] = 'Continue'
    $PSDefaultParameterValues['*:Verbose'] = $true
    $PSDefaultParameterValues['*:Debug'] = $false
}
#endregion

#region Logging Functions
function Write-ErrorLog {
    <#
    .SYNOPSIS
        Writes error details to the error log.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$LogEntry
    )
    
    try {
        $logFile = Join-Path -Path $script:ErrorHandlingConfig.LogPath -ChildPath "ErrorLog_$(Get-Date -Format 'yyyyMMdd').log"
        $logEntryJson = $LogEntry | ConvertTo-Json -Compress
        
        # Rotate log if needed
        if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt ($script:ErrorHandlingConfig.MaxLogSizeMB * 1MB)) {
            $archiveFile = $logFile -replace '\.log$', "_$(Get-Date -Format 'yyyyMMddHHmmss').log"
            Move-Item -Path $logFile -Destination $archiveFile -Force
        }
        
        # Write to log
        Add-Content -Path $logFile -Value $logEntryJson -Encoding UTF8
        
        # Clean up old logs
        Get-ChildItem -Path $script:ErrorHandlingConfig.LogPath -Filter 'ErrorLog_*.log' | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$script:ErrorHandlingConfig.LogRetentionDays) } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {
        # If logging fails, write to host as last resort
        Write-Host "[ERROR] Failed to write to error log: $_" -ForegroundColor Red
    }
}

function Get-ErrorLog {
    <#
    .SYNOPSIS
        Retrieves error log entries.
    .EXAMPLE
        Get-ErrorLog -Days 1
        Gets all error log entries from the last day.
    #>
    [CmdletBinding()]
    param(
        [int]$Days = 1,
        [string]$Filter = '*'
    )
    
    $startDate = (Get-Date).AddDays(-$Days)
    $logs = @()
    
    Get-ChildItem -Path $script:ErrorHandlingConfig.LogPath -Filter 'ErrorLog_*.log' |
        Where-Object { $_.LastWriteTime -ge $startDate } |
        ForEach-Object {
            Get-Content -Path $_.FullName | ForEach-Object {
                try {
                    $logEntry = $_ | ConvertFrom-Json -ErrorAction Stop
                    if ($logEntry.Message -like "*$Filter*") {
                        $logs += $logEntry
                    }
                }
                catch {
                    Write-Warning "Failed to parse log entry: $_"
                }
            }
        }
    
    return $logs | Sort-Object -Property Timestamp -Descending
}
#endregion

#region Notification Functions
function Send-ErrorNotification {
    <#
    .SYNOPSIS
        Sends an error notification via email.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    try {
        $subject = "[PSError] $($ErrorRecord.Exception.Message)"
        $body = @"
Error Details:
Message: $($ErrorRecord.Exception.Message)
Category: $($ErrorRecord.CategoryInfo.Category)
Script: $($ErrorRecord.InvocationInfo.ScriptName)
Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)
Command: $($ErrorRecord.InvocationInfo.MyCommand)
Stack Trace:
$($ErrorRecord.ScriptStackTrace)
"@
        
        Send-MailMessage -To $script:ErrorHandlingConfig.EmailRecipients \
                        -Subject $subject \
                        -Body $body \
                        -SmtpServer 'smtp.example.com' \
                        -From 'powershell@example.com' \
                        -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to send error notification: $_"
    }
}

function Send-SlackNotification {
    <#
    .SYNOPSIS
        Sends an error notification to Slack.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    try {
        $slackMessage = @{
            text = "*PowerShell Error*"
            attachments = @(
                @{
                    color = "danger"
                    fields = @(
                        @{
                            title = "Message"
                            value = $ErrorRecord.Exception.Message
                            short = $false
                        },
                        @{
                            title = "Script"
                            value = $ErrorRecord.InvocationInfo.ScriptName
                            short = $true
                        },
                        @{
                            title = "Line"
                            value = $ErrorRecord.InvocationInfo.ScriptLineNumber
                            short = $true
                        }
                    )
                    footer = (Get-Date).ToString()
                }
            )
        } | ConvertTo-Json -Depth 5
        
        Invoke-RestMethod -Uri $script:ErrorHandlingConfig.SlackWebhookUrl \
                         -Method Post \
                         -Body $slackMessage \
                         -ContentType 'application/json' \
                         -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to send Slack notification: $_"
    }
}
#endregion

#region Error Handling Cmdlets
function Set-ErrorHandlingConfig {
    <#
    .SYNOPSIS
        Configures error handling settings.
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath,
        [int]$MaxLogSizeMB,
        [int]$LogRetentionDays,
        [bool]$EmailNotification,
        [string[]]$EmailRecipients,
        [string]$SlackWebhookUrl
    )
    
    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $script:ErrorHandlingConfig.LogPath = $LogPath
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
    }
    
    if ($PSBoundParameters.ContainsKey('MaxLogSizeMB')) {
        $script:ErrorHandlingConfig.MaxLogSizeMB = $MaxLogSizeMB
    }
    
    if ($PSBoundParameters.ContainsKey('LogRetentionDays')) {
        $script:ErrorHandlingConfig.LogRetentionDays = $LogRetentionDays
    }
    
    if ($PSBoundParameters.ContainsKey('EmailNotification')) {
        $script:ErrorHandlingConfig.EmailNotification = $EmailNotification
    }
    
    if ($PSBoundParameters.ContainsKey('EmailRecipients')) {
        $script:ErrorHandlingConfig.EmailRecipients = $EmailRecipients
    }
    
    if ($PSBoundParameters.ContainsKey('SlackWebhookUrl')) {
        $script:ErrorHandlingConfig.SlackWebhookUrl = $SlackWebhookUrl
    }
    
    return $script:ErrorHandlingConfig | ConvertTo-Json -Depth 5
}
#endregion

# Initialize error handling
Register-ErrorHandler

# Export public functions
export-modulemember -Function @(
    'Get-ErrorLog',
    'Set-ErrorHandlingConfig'
)
