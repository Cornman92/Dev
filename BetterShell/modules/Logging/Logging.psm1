<#
.SYNOPSIS
    Better11.Logging - Enhanced logging module with rotation, structured logging, and multiple output formats

.DESCRIPTION
    Provides comprehensive logging functionality with log rotation, structured logging (JSON),
    multiple output formats, and configurable log levels.

.NOTES
    Version: 2.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

#region Module Variables
$script:LogFile = $null
$script:LogConfig = @{
    MaxFileSizeMB = 10
    MaxFiles = 5
    LogLevel = 'INFO'
    OutputFormat = 'Text'  # Text, JSON, CSV
    EnableRotation = $true
    EnableConsole = $true
    EnableFile = $true
    StructuredLogging = $false
}
$script:LogHistory = @()
#endregion

#region Log Initialization

function Start-Better11Log {
    <#
    .SYNOPSIS
        Starts logging with optional configuration
    
    .DESCRIPTION
        Initializes logging with configurable options including rotation, output formats, and log levels.
    
    .PARAMETER Path
        Path to log file. Defaults to Output directory with timestamp.
    
    .PARAMETER MaxFileSizeMB
        Maximum log file size in MB before rotation
    
    .PARAMETER MaxFiles
        Maximum number of rotated log files to keep
    
    .PARAMETER LogLevel
        Minimum log level to record (DEBUG, INFO, WARN, ERROR)
    
    .PARAMETER OutputFormat
        Output format (Text, JSON, CSV)
    
    .PARAMETER EnableRotation
        Enable automatic log file rotation
    
    .PARAMETER EnableConsole
        Enable console output
    
    .PARAMETER EnableFile
        Enable file output
    
    .PARAMETER StructuredLogging
        Enable structured JSON logging
    
    .EXAMPLE
        Start-Better11Log -LogLevel 'DEBUG' -MaxFileSizeMB 20
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Output') -ChildPath ("better11_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))),
        
        [Parameter()]
        [int]$MaxFileSizeMB = 10,
        
        [Parameter()]
        [int]$MaxFiles = 5,
        
        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$LogLevel = 'INFO',
        
        [Parameter()]
        [ValidateSet('Text', 'JSON', 'CSV')]
        [string]$OutputFormat = 'Text',
        
        [Parameter()]
        [switch]$EnableRotation = $true,
        
        [Parameter()]
        [switch]$EnableConsole = $true,
        
        [Parameter()]
        [switch]$EnableFile = $true,
        
        [Parameter()]
        [switch]$StructuredLogging = $false
    )
    
    $script:LogConfig.MaxFileSizeMB = $MaxFileSizeMB
    $script:LogConfig.MaxFiles = $MaxFiles
    $script:LogConfig.LogLevel = $LogLevel
    $script:LogConfig.OutputFormat = $OutputFormat
    $script:LogConfig.EnableRotation = $EnableRotation.IsPresent
    $script:LogConfig.EnableConsole = $EnableConsole.IsPresent
    $script:LogConfig.EnableFile = $EnableFile.IsPresent
    $script:LogConfig.StructuredLogging = $StructuredLogging.IsPresent
    
    $resolved = Resolve-Path -LiteralPath (Split-Path -Parent $Path) -ErrorAction SilentlyContinue
    if (-not $resolved) { 
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null 
    }
    
    $script:LogFile = $Path
    
    $initMessage = "==== Better11 Log started $(Get-Date -Format o) ===="
    $initMessage += " | Config: Level=$LogLevel, Format=$OutputFormat, Rotation=$EnableRotation"
    
    if ($script:LogConfig.EnableFile) {
        $initMessage | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
    }
    
    if ($script:LogConfig.EnableConsole) {
        Write-Host $initMessage -ForegroundColor Cyan
    }
    
    return $script:LogFile
}

#endregion

#region Log Writing

function Write-Better11Log {
    <#
    .SYNOPSIS
        Writes a log entry
    
    .DESCRIPTION
        Writes a log entry with configurable format, rotation, and output destinations.
    
    .PARAMETER Level
        Log level (DEBUG, INFO, WARN, ERROR)
    
    .PARAMETER Message
        Log message
    
    .PARAMETER Context
        Additional context as hashtable (for structured logging)
    
    .PARAMETER Exception
        Exception object to log
    
    .EXAMPLE
        Write-Better11Log -Level 'INFO' -Message 'Operation completed'
    
    .EXAMPLE
        Write-Better11Log -Level 'ERROR' -Message 'Operation failed' -Exception $_.Exception -Context @{UserId=123}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [Exception]$Exception
    )
    
    # Check log level
    $levelPriority = @{ 'DEBUG' = 0; 'INFO' = 1; 'WARN' = 2; 'ERROR' = 3 }
    $configPriority = $levelPriority[$script:LogConfig.LogLevel]
    $messagePriority = $levelPriority[$Level]
    
    if ($messagePriority -lt $configPriority) {
        return  # Skip logging if below threshold
    }
    
    # Check rotation if enabled
    if ($script:LogConfig.EnableRotation -and $script:LogConfig.EnableFile -and $script:LogFile) {
        if (Test-Path $script:LogFile) {
            $fileSize = (Get-Item $script:LogFile).Length / 1MB
            if ($fileSize -ge $script:LogConfig.MaxFileSizeMB) {
                Rotate-Better11Log
            }
        }
    }
    
    # Build log entry
    $timestamp = Get-Date -Format 'o'
    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
    }
    
    if ($Context.Count -gt 0) {
        $logEntry.Context = $Context
    }
    
    if ($Exception) {
        $logEntry.Exception = @{
            Type = $Exception.GetType().FullName
            Message = $Exception.Message
            StackTrace = $Exception.StackTrace
        }
    }
    
    # Format output based on configuration
    $formattedEntry = Format-Better11LogEntry -Entry $logEntry -Format $script:LogConfig.OutputFormat
    
    # Write to file
    if ($script:LogConfig.EnableFile -and $script:LogFile) {
        $formattedEntry | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
    }
    
    # Write to console
    if ($script:LogConfig.EnableConsole) {
        $color = switch ($Level) {
            'DEBUG' { 'Gray' }
            'INFO'  { 'White' }
            'WARN'  { 'Yellow' }
            'ERROR' { 'Red' }
        }
        Write-Host $formattedEntry -ForegroundColor $color
    }
    
    # Add to history (keep last 100 entries)
    $script:LogHistory += $logEntry
    if ($script:LogHistory.Count -gt 100) {
        $script:LogHistory = $script:LogHistory[-100..-1]
    }
}

function Format-Better11LogEntry {
    <#
    .SYNOPSIS
        Formats log entry based on output format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Entry,
        
        [Parameter(Mandatory)]
        [ValidateSet('Text', 'JSON', 'CSV')]
        [string]$Format
    )
    
    switch ($Format) {
        'Text' {
            $line = "[$($Entry.Level)] $($Entry.Timestamp) $($Entry.Message)"
            if ($Entry.Context) {
                $line += " | Context: $($Entry.Context | ConvertTo-Json -Compress)"
            }
            if ($Entry.Exception) {
                $line += " | Exception: $($Entry.Exception.Message)"
            }
            return $line
        }
        
        'JSON' {
            return $Entry | ConvertTo-Json -Compress -Depth 10
        }
        
        'CSV' {
            $fields = @(
                $Entry.Timestamp,
                $Entry.Level,
                $Entry.Message,
                ($Entry.Context | ConvertTo-Json -Compress),
                ($Entry.Exception.Message ?? '')
            )
            return ($fields -join ',')
        }
    }
}

#endregion

#region Log Rotation

function Rotate-Better11Log {
    <#
    .SYNOPSIS
        Rotates log file
    
    .DESCRIPTION
        Rotates the current log file and manages old log files based on MaxFiles setting.
    #>
    [CmdletBinding()]
    param()
    
    if (-not $script:LogFile -or -not (Test-Path $script:LogFile)) {
        return
    }
    
    try {
        $logDir = Split-Path -Parent $script:LogFile
        $logName = [System.IO.Path]::GetFileNameWithoutExtension($script:LogFile)
        $logExt = [System.IO.Path]::GetExtension($script:LogFile)
        
        # Rotate existing files
        for ($i = $script:LogConfig.MaxFiles - 1; $i -ge 1; $i--) {
            $oldFile = Join-Path $logDir "$logName.$i$logExt"
            $newFile = Join-Path $logDir "$logName.$($i + 1)$logExt"
            
            if (Test-Path $oldFile) {
                if ($i -ge $script:LogConfig.MaxFiles) {
                    Remove-Item $oldFile -Force
                }
                else {
                    Move-Item $oldFile $newFile -Force
                }
            }
        }
        
        # Move current log to .1
        $rotatedFile = Join-Path $logDir "$logName.1$logExt"
        Move-Item $script:LogFile $rotatedFile -Force
        
        # Create new log file
        $script:LogFile = Join-Path $logDir "$logName$logExt"
        "==== Better11 Log rotated and restarted $(Get-Date -Format o) ====" | Out-File -FilePath $script:LogFile -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to rotate log file: $_"
    }
}

#endregion

#region Log Management

function Get-Better11LogHistory {
    <#
    .SYNOPSIS
        Gets log history
    
    .DESCRIPTION
        Returns the in-memory log history (last 100 entries).
    
    .PARAMETER Level
        Filter by log level
    
    .PARAMETER Limit
        Maximum number of entries to return
    
    .EXAMPLE
        Get-Better11LogHistory -Level 'ERROR' -Limit 10
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level,
        
        [Parameter()]
        [int]$Limit = 100
    )
    
    $history = $script:LogHistory
    
    if ($Level) {
        $history = $history | Where-Object { $_.Level -eq $Level }
    }
    
    return $history | Select-Object -Last $Limit
}

function Clear-Better11LogHistory {
    <#
    .SYNOPSIS
        Clears log history
    #>
    [CmdletBinding()]
    param()
    
    $script:LogHistory = @()
    Write-Verbose "Log history cleared"
}

function Get-Better11LogConfig {
    <#
    .SYNOPSIS
        Gets current logging configuration
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return $script:LogConfig.Clone()
}

function Set-Better11LogConfig {
    <#
    .SYNOPSIS
        Updates logging configuration
    
    .PARAMETER LogLevel
        Minimum log level
    
    .PARAMETER OutputFormat
        Output format
    
    .PARAMETER MaxFileSizeMB
        Maximum file size in MB
    
    .PARAMETER MaxFiles
        Maximum number of rotated files
    
    .EXAMPLE
        Set-Better11LogConfig -LogLevel 'DEBUG' -MaxFileSizeMB 20
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$LogLevel,
        
        [Parameter()]
        [ValidateSet('Text', 'JSON', 'CSV')]
        [string]$OutputFormat,
        
        [Parameter()]
        [int]$MaxFileSizeMB,
        
        [Parameter()]
        [int]$MaxFiles
    )
    
    if ($LogLevel) { $script:LogConfig.LogLevel = $LogLevel }
    if ($OutputFormat) { $script:LogConfig.OutputFormat = $OutputFormat }
    if ($MaxFileSizeMB) { $script:LogConfig.MaxFileSizeMB = $MaxFileSizeMB }
    if ($MaxFiles) { $script:LogConfig.MaxFiles = $MaxFiles }
    
    Write-Verbose "Log configuration updated"
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Start-Better11Log',
    'Write-Better11Log',
    'Rotate-Better11Log',
    'Get-Better11LogHistory',
    'Clear-Better11LogHistory',
    'Get-Better11LogConfig',
    'Set-Better11LogConfig'
)
