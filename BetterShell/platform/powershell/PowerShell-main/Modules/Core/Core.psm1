<#
.SYNOPSIS
    Core PowerShell module containing shared functions and utilities
.DESCRIPTION
    This module provides common functions used across other modules in the PowerShell environment.
    It includes logging, admin checks, file operations, and other utility functions.
.NOTES
    File Name      : Core.psm1
    Author         : C-Man
    Prerequisite   : PowerShell 5.1 or later
    Copyright      : (c) 2025. All rights reserved.
    Version        : 1.0.0
#>

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Module Variables

# Initialize module variables
$script:ModuleName = 'Core'
$script:ModuleVersion = '1.0.0'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleConfig = $null
$script:Initialized = $false
$script:IsAdmin = $false

# Initialize logging variables
$script:LogFormat = '{0:yyyy-MM-dd HH:mm:ss.fff} [{1}] {2} - {3}'
$script:LogFile = Join-Path -Path $env:TEMP -ChildPath "$($script:ModuleName).log"
$script:LogLevels = @{
    'DEBUG' = 0
    'INFO' = 1
    'WARNING' = 2
    'ERROR' = 3
    'CRITICAL' = 4
}
$script:CurrentLogLevel = $script:LogLevels['INFO']

# Performance tracking
$script:Timers = @{}
$script:PerformanceCounters = @{}

# Platform detection
$script:IsWindows = $false
$script:IsLinux = $false
$script:IsMacOS = $false

# Initialize platform-specific settings
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $script:IsWindows = $IsWindows
    $script:IsLinux = $IsLinux
    $script:IsMacOS = $IsMacOS
} else {
    $script:IsWindows = $true
}

# Initialize admin status
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$script:IsAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

#endregion

#region Logging Functions

<#
.SYNOPSIS
    Writes a log message with the specified level.
.DESCRIPTION
    This function writes a log message to the log file and optionally to the console.
.PARAMETER Message
    The message to log.
.PARAMETER Level
    The log level (DEBUG, INFO, WARNING, ERROR, CRITICAL). Default is INFO.
.PARAMETER WriteToConsole
    Whether to write the message to the console. Default is $true for WARNING and above.
.EXAMPLE
    Write-ModuleLog -Message 'Starting operation' -Level 'INFO'
#>
function Write-ModuleLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')]
        [string]$Level = 'INFO',
        
        [Parameter(Mandatory=$false)]
        [bool]$WriteToConsole = ($Level -in @('WARNING', 'ERROR', 'CRITICAL'))
    )
    
    $levelValue = $script:LogLevels[$Level]
    
    # Skip if the message level is below the current log level
    if ($levelValue -lt $script:CurrentLogLevel) {
        return
    }
    
    $timestamp = Get-Date
    $logMessage = $script:LogFormat -f $timestamp, $Level, $script:ModuleName, $Message
    
    # Write to log file
    try {
        Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction Stop
    }
    catch {
        # If we can't write to the log file, write to the error stream
        Write-Error "Failed to write to log file: $_"
    }
    
    # Write to console if requested
    if ($WriteToConsole) {
        $params = @{
            Message = $Message
            NoNewline = $false
        }
        
        switch ($Level) {
            'DEBUG' { Write-Debug @params }
            'INFO' { Write-Host $Message -ForegroundColor Cyan }
            'WARNING' { Write-Warning $Message }
            'ERROR' { Write-Error $Message }
            'CRITICAL' { 
                Write-Host $Message -ForegroundColor Red -BackgroundColor Black
                if (-not $script:IsAdmin) {
                    Write-Warning "This operation may require administrative privileges."
                }
            }
        }
    }
}

#endregion

#region Admin and Security Functions

<#
.SYNOPSIS
    Tests if the current user has administrator privileges.
.DESCRIPTION
    Returns $true if the current user has administrator privileges, $false otherwise.
.EXAMPLE
    if (Test-IsAdmin) { # Do admin stuff }
#>
function Test-IsAdmin {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    return $script:IsAdmin
}

<#
.SYNOPSIS
    Tests if the current process is running with elevated privileges.
.DESCRIPTION
    Returns $true if the current process is running with elevated privileges, $false otherwise.
    This is an alias for Test-IsAdmin for backward compatibility.
.EXAMPLE
    if (Test-IsElevated) { # Do elevated stuff }
#>
function Test-IsElevated {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    return $script:IsAdmin
}

<#
.SYNOPSIS
    Tests if admin privileges are required and available.
.DESCRIPTION
    Throws an error if admin privileges are required but not available.
.PARAMETER Operation
    A description of the operation requiring admin privileges.
.PARAMETER ThrowIfNotAdmin
    Whether to throw an error if admin privileges are not available. Default is $true.
.EXAMPLE
    Test-AdminRequirement -Operation 'Modify system settings'
#>
function Test-AdminRequirement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [Parameter(Mandatory=$false)]
        [bool]$ThrowIfNotAdmin = $true
    )
    
    if (-not $script:IsAdmin) {
        $message = "The operation '$Operation' requires administrative privileges. Please run this script as an administrator."
        
        if ($ThrowIfNotAdmin) {
            throw [System.Security.SecurityException]::new($message)
        } else {
            Write-Warning $message
            return $false
        }
    }
    
    return $true
}

#endregion

#region Platform Detection

<#
.SYNOPSIS
    Gets information about the current operating system.
.DESCRIPTION
    Returns a hashtable with information about the current operating system.
.EXAMPLE
    $osInfo = Get-OperatingSystem
#>
function Get-OperatingSystem {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    $osInfo = @{
        IsWindows = $script:IsWindows
        IsLinux = $script:IsLinux
        IsMacOS = $script:IsMacOS
        OSVersion = [System.Environment]::OSVersion
        OSPlatform = if ($script:IsWindows) { 'Windows' } elseif ($script:IsLinux) { 'Linux' } else { 'macOS' }
        Is64Bit = [Environment]::Is64BitOperatingSystem
        ProcessArchitecture = if ([Environment]::Is64BitProcess) { 'x64' } else { 'x86' }
    }
    
    if ($script:IsWindows) {
        $osInfo.WindowsVersion = [System.Environment]::OSVersion.Version
        $osInfo.WindowsBuild = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
        $osInfo.WindowsRelease = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion
    }
    
    return $osInfo
}

<#
.SYNOPSIS
    Gets information about the current environment.
.DESCRIPTION
    Returns a hashtable with information about the current PowerShell environment.
.EXAMPLE
    $envInfo = Get-EnvironmentInfo
#>
function Get-EnvironmentInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        CLRVersion = $PSVersionTable.CLRVersion.ToString()
        Host = $Host.Name
        HostVersion = $Host.Version.ToString()
        CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        IsAdmin = $script:IsAdmin
        CurrentDirectory = $PWD.Path
        ScriptRoot = $PSScriptRoot
        ModulePath = $env:PSModulePath -split ';'
    }
}

# Export public functions
Export-ModuleMember -Function Write-ModuleLog, Test-IsAdmin, Test-IsElevated, Test-AdminRequirement, Get-OperatingSystem, Get-EnvironmentInfo

# Initialize the module
Write-ModuleLog -Message "Module $($script:ModuleName) v$($script:ModuleVersion) initialized" -Level 'DEBUG'
$script:Initialized = $true
