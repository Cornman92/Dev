<#
.SYNOPSIS
    Gets the path to the current log file.
.DESCRIPTION
    Returns the full path to the current log file being used by the module.
.OUTPUTS
    System.String. The full path to the current log file.
.EXAMPLE
    Get-LogFile
    
    Returns the path to the current log file.
#>
[CmdletBinding()]
[OutputType([string])]
param()

return $script:logFile
