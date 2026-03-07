function Write-ModuleLog {
<#
.SYNOPSIS
    Writes a message to the module log file and optionally to the console.
.DESCRIPTION
    This function writes log messages to the module's log file with timestamps and log levels.
    It can also output to the console based on the specified log level.
.PARAMETER Message
    The message to log. This parameter is required.
.PARAMETER Level
    The severity level of the log message. Valid values are: Info, Warning, Error, Verbose, Debug.
    Default is 'Info'.
.PARAMETER PassThru
    If specified, the message will also be written to the appropriate output stream.
.EXAMPLE
    Write-ModuleLog -Message "Starting backup process" -Level Info -PassThru
    
    Writes an informational message to the log file and outputs it to the console.
.NOTES
    Author: C-Man
    Date:   $(Get-Date -Format 'yyyy-MM-dd')
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [ValidateSet('Info', 'Warning', 'Error', 'Verbose', 'Debug')]
        [string]$Level = 'Info',
        
        [switch]$PassThru
    )

    begin {
        # Ensure the log directory exists
        $logDir = Split-Path -Path $script:logFile -Parent
        if (-not (Test-Path -Path $logDir)) {
            $null = New-Item -ItemType Directory -Path $logDir -Force
        }
        
        # Define log level colors
        $levelColors = @{
            'Error'   = 'Red'
            'Warning' = 'Yellow'
            'Info'    = 'Cyan'
            'Debug'   = 'Gray'
            'Verbose' = 'Green'
        }
        
        # Get the current timestamp
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        
        # Format the log entry
        $logMessage = "$timestamp [$($Level.ToUpper())] $Message"
    }

    process {
        try {
            # Write to log file
            Add-Content -Path $script:logFile -Value $logMessage -ErrorAction Stop
            
            # If PassThru is specified, write to the appropriate output stream
            if ($PassThru) {
                $params = @{
                    Message = $Message
                    NoNewline = $false
                }
                
                switch ($Level) {
                    'Error'   { Write-Error @params }
                    'Warning' { Write-Warning $Message }
                    'Verbose' { Write-Verbose $Message }
                    'Debug'   { Write-Debug $Message }
                    default   { 
                        if ($Host.UI.RawUI) {
                            $originalColor = $Host.UI.RawUI.ForegroundColor
                            $Host.UI.RawUI.ForegroundColor = $levelColors[$Level]
                            Write-Output $Message
                            $Host.UI.RawUI.ForegroundColor = $originalColor
                        }
                        else {
                            Write-Output $Message
                        }
                    }
                }
            }
            return $true
        }
        catch {
            # If we can't write to the log file, try to write to the event log as a fallback
            $errorMessage = "Failed to write to log file: $_"
            try {
                $source = $script:ModuleName
                if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
                    [System.Diagnostics.EventLog]::CreateEventSource($source, 'Application')
                }
                [System.Diagnostics.EventLog]::WriteEntry($source, $errorMessage, [System.Diagnostics.EventLogEntryType]::Error)
                return $false
            }
            catch {
                # If all else fails, write to the error stream
                Write-Error $errorMessage -ErrorAction Continue
                return $false
            }
        }
    }

    end {
        # Clean up
        Remove-Variable -Name logMessage, timestamp -ErrorAction SilentlyContinue -Scope Local
    }
}
