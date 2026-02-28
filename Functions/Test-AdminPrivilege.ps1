<#
.SYNOPSIS
    Tests whether the current PowerShell session has administrator privileges.

.DESCRIPTION
    Checks if the current user is running in an elevated (admin) PowerShell
    session. Returns $true if elevated, $false otherwise. Optionally throws
    an error or displays a warning if not elevated.

.PARAMETER Require
    If specified, throws a terminating error when the session is not elevated.
    Useful at the top of scripts that require admin privileges.

.PARAMETER Warn
    If specified, writes a warning message when the session is not elevated
    but allows execution to continue.

.EXAMPLE
    Test-AdminPrivilege
    Returns $true or $false silently.

.EXAMPLE
    Test-AdminPrivilege -Require
    Throws an error if not running as administrator.

.EXAMPLE
    if (-not (Test-AdminPrivilege)) { Write-Host "Run as admin for full functionality" }
    Conditional check with custom message.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
function Test-AdminPrivilege {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [switch]$Require,

        [Parameter()]
        [switch]$Warn
    )

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        if ($Require) {
            throw "This script requires administrator privileges. Please run PowerShell as Administrator."
        }

        if ($Warn) {
            Write-Warning "This session is not running with administrator privileges. Some operations may fail."
        }
    }

    return $isAdmin
}
