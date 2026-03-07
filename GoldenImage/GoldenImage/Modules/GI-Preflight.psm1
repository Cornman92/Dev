<#
.SYNOPSIS
    Golden Image Preflight Module

.DESCRIPTION
    Handles preflight checks and system validation before Golden Image creation

.NOTES
    Extracted from Create-GoldenImage.ps1 for modularization
#>

function Test-GIPreflight {
    <#
    .SYNOPSIS
        Performs preflight checks and system validation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,
        
        [Parameter(Mandatory)]
        [object]$Logger
    )
    
    # Check administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        throw "Create-GoldenImage must be run as Administrator."
    }
    
    # Check OS version
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $Logger.Write('INFO', "OS: $($os.Caption) $($os.Version)")
    
    # Check disk space
    $drive = Get-PSDrive -Name $Config.Drives.OsDriveLetter -ErrorAction Stop
    if ($drive.Free -lt 40GB) {
        throw "Insufficient free space on OS drive ($($Config.Drives.OsDriveLetter)): need at least 40 GB."
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }
    
    # Check required tools
    $requiredTools = @('choco', 'winget')
    foreach ($tool in $requiredTools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $Logger.Write('WARN', "Required tool not found: $tool. Some features may not work.")
        }
    }
    
    $Logger.Write('INFO', 'Pre-flight checks passed.')
}

Export-ModuleMember -Function Test-GIPreflight

