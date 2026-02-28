<#
.SYNOPSIS
    Writes structured log messages to console and/or file.

.DESCRIPTION
    Provides a consistent logging interface for scripts in the Dev
    workspace. Supports log levels (Info, Warning, Error, Debug),
    timestamped output, and optional file logging.

.PARAMETER Message
    The log message to write.

.PARAMETER Level
    Log level: Info, Warning, Error, or Debug. Defaults to Info.

.PARAMETER LogFile
    Optional path to a log file. If provided, messages are appended
    to this file in addition to console output.

.PARAMETER NoConsole
    Suppress console output and only write to the log file.

.EXAMPLE
    Write-Log "Script started"
    Writes an Info-level message to the console.

.EXAMPLE
    Write-Log "Disk space low" -Level Warning -LogFile "C:\Dev\Artifacts\maintenance.log"
    Writes a Warning to both console and the specified log file.

.EXAMPLE
    Write-Log "Connection failed" -Level Error
    Writes an Error-level message in red to the console.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$LogFile,

        [Parameter()]
        [switch]$NoConsole
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $levelTag = switch ($Level) {
        'Info'    { 'INF' }
        'Warning' { 'WRN' }
        'Error'   { 'ERR' }
        'Debug'   { 'DBG' }
    }

    $logEntry = "[$timestamp] [$levelTag] $Message"

    # Console output
    if (-not $NoConsole) {
        $color = switch ($Level) {
            'Info'    { 'White' }
            'Warning' { 'Yellow' }
            'Error'   { 'Red' }
            'Debug'   { 'Gray' }
        }
        Write-Host $logEntry -ForegroundColor $color
    }

    # File output
    if ($LogFile) {
        $logDir = Split-Path -Parent $LogFile
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }
}
