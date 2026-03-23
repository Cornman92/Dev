<#
.SYNOPSIS
    Detects available WinPE environments (ADK WinPE and WinRE).

.DESCRIPTION
    This script detects the presence and location of:
    - Windows ADK WinPE installation
    - Windows Recovery Environment (WinRE) WIM files
    
    It validates the environment and returns structured information about
    available WinPE sources for building custom recovery environments.

.PARAMETER CustomADKPath
    Optional custom path to ADK installation directory.

.PARAMETER CustomWinREPath
    Optional custom path to WinRE.wim file.

.PARAMETER Verbose
    Display detailed detection information.

.EXAMPLE
    .\WinPE-Detect.ps1
    Detects WinPE environments using default paths.

.EXAMPLE
    .\WinPE-Detect.ps1 -CustomADKPath "D:\ADK" -Verbose
    Detects WinPE environments with custom ADK path and verbose output.

.NOTES
    Author: Better11 Development Team
    Version: 1.0.0
    Part of: WinPE PowerBuilder Suite
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$CustomADKPath,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CustomWinREPath
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-Detect'
$scriptVersion = '1.0.0'

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes formatted log messages to console and optionally to file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'INFO'    { Write-Host $logMessage -ForegroundColor Cyan }
        'WARN'    { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# ============================================================================
# DETECTION FUNCTIONS
# ============================================================================

function Test-ADKWinPE {
    <#
    .SYNOPSIS
        Detects Windows ADK WinPE installation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomPath
    )

    Write-Log "Detecting Windows ADK WinPE installation..." -Level 'INFO'

    # Define default ADK path
    $defaultADKPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"

    # Determine search path
    $searchPath = if ($CustomPath) {
        Write-Log "Using custom ADK path: $CustomPath" -Level 'INFO'
        $CustomPath
    } else {
        Write-Log "Using default ADK path: $defaultADKPath" -Level 'INFO'
        $defaultADKPath
    }

    # Check if path exists
    if (-not (Test-Path $searchPath)) {
        Write-Log "ADK WinPE path not found: $searchPath" -Level 'WARN'
        return $null
    }

    # Validate critical ADK components
    $copypeCmd = Join-Path $searchPath "copype.cmd"
    $amdArch = Join-Path $searchPath "amd64"

    if (-not (Test-Path $copypeCmd)) {
        Write-Log "copype.cmd not found in ADK installation" -Level 'WARN'
        return $null
    }

    if (-not (Test-Path $amdArch)) {
        Write-Log "AMD64 architecture folder not found in ADK installation" -Level 'WARN'
        return $null
    }

    # Validate WinPE.wim existence
    $winpeWim = Join-Path $amdArch "en-us\winpe.wim"
    if (-not (Test-Path $winpeWim)) {
        Write-Log "winpe.wim not found in ADK installation" -Level 'WARN'
        return $null
    }

    Write-Log "ADK WinPE detected successfully" -Level 'SUCCESS'

    # Return detection result
    return [PSCustomObject]@{
        Type          = 'ADK'
        Path          = $searchPath
        CopypePath    = $copypeCmd
        WimPath       = $winpeWim
        Architecture  = 'amd64'
        Available     = $true
        Version       = Get-ADKVersion -ADKPath $searchPath
    }
}

function Test-WinRE {
    <#
    .SYNOPSIS
        Detects Windows Recovery Environment (WinRE).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomPath
    )

    Write-Log "Detecting Windows Recovery Environment (WinRE)..." -Level 'INFO'

    $winreWim = $null

    if ($CustomPath) {
        Write-Log "Using custom WinRE path: $CustomPath" -Level 'INFO'
        if (Test-Path $CustomPath) {
            $winreWim = $CustomPath
        } else {
            Write-Log "Custom WinRE path not found: $CustomPath" -Level 'WARN'
        }
    }

    # Search standard WinRE locations if no custom path or custom path failed
    if (-not $winreWim) {
        $searchLocations = @(
            "$env:SystemRoot\System32\Recovery\Winre.wim",
            "C:\Recovery\WindowsRE\Winre.wim",
            "D:\Recovery\WindowsRE\Winre.wim",
            "E:\Recovery\WindowsRE\Winre.wim"
        )

        foreach ($location in $searchLocations) {
            if (Test-Path $location) {
                Write-Log "Found WinRE.wim at: $location" -Level 'INFO'
                $winreWim = $location
                break
            }
        }
    }

    # Try reagentc to get WinRE location
    if (-not $winreWim) {
        try {
            $reagentcInfo = reagentc /info 2>&1 | Out-String
            if ($reagentcInfo -match 'Windows RE location:\s+(.+)') {
                $winrePath = $matches[1].Trim()
                $potentialWim = Join-Path $winrePath "Winre.wim"
                
                if (Test-Path $potentialWim) {
                    Write-Log "Found WinRE.wim via reagentc: $potentialWim" -Level 'INFO'
                    $winreWim = $potentialWim
                }
            }
        } catch {
            Write-Log "Unable to query reagentc for WinRE location" -Level 'WARN'
        }
    }

    if (-not $winreWim) {
        Write-Log "WinRE.wim not found in standard locations" -Level 'WARN'
        return $null
    }

    # Validate WIM file
    try {
        $wimInfo = dism /Get-WimInfo /WimFile:$winreWim /Index:1 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WinRE.wim validated successfully" -Level 'SUCCESS'
            
            return [PSCustomObject]@{
                Type         = 'WinRE'
                Path         = Split-Path $winreWim -Parent
                WimPath      = $winreWim
                Available    = $true
                Size         = (Get-Item $winreWim).Length
                SizeMB       = [math]::Round((Get-Item $winreWim).Length / 1MB, 2)
            }
        } else {
            Write-Log "WinRE.wim validation failed" -Level 'ERROR'
            return $null
        }
    } catch {
        Write-Log "Error validating WinRE.wim: $($_.Exception.Message)" -Level 'ERROR'
        return $null
    }
}

function Get-ADKVersion {
    <#
    .SYNOPSIS
        Retrieves the ADK version from installation path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ADKPath
    )

    try {
        # Try to get version from registry
        $adkRegPath = "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
        if (Test-Path $adkRegPath) {
            $adkProps = Get-ItemProperty -Path $adkRegPath -ErrorAction SilentlyContinue
            if ($adkProps.KitsRoot10) {
                # Try to extract version from path
                if ($adkProps.KitsRoot10 -match '\\(\d+)\\') {
                    return $matches[1]
                }
            }
        }

        # Fallback: Try to detect from path structure
        if ($ADKPath -match '\\(\d+)\\') {
            return $matches[1]
        }

        return 'Unknown'
    } catch {
        return 'Unknown'
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "$scriptName v$scriptVersion" -Level 'INFO'
    Write-Log "WinPE Environment Detection" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Detect ADK WinPE
    $adkResult = Test-ADKWinPE -CustomPath $CustomADKPath

    # Detect WinRE
    $winreResult = Test-WinRE -CustomPath $CustomWinREPath

    # Build detection summary
    $detectionResult = [PSCustomObject]@{
        Timestamp       = Get-Date -Format 'o'
        ComputerName    = $env:COMPUTERNAME
        ADK = $adkResult
        WinRE = $winreResult
        HasADK = ($null -ne $adkResult)
        HasWinRE = ($null -ne $winreResult)
        RecommendedSource = if ($adkResult) { 'ADK' } elseif ($winreResult) { 'WinRE' } else { 'None' }
    }

    # Display results
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Detection Results:" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    if ($detectionResult.HasADK) {
        Write-Log "✓ ADK WinPE: Available" -Level 'SUCCESS'
        Write-Log "  Path: $($adkResult.Path)" -Level 'INFO'
        Write-Log "  Version: $($adkResult.Version)" -Level 'INFO'
        Write-Log "  WIM: $($adkResult.WimPath)" -Level 'INFO'
    } else {
        Write-Log "✗ ADK WinPE: Not Available" -Level 'WARN'
    }

    if ($detectionResult.HasWinRE) {
        Write-Log "✓ WinRE: Available" -Level 'SUCCESS'
        Write-Log "  Path: $($winreResult.Path)" -Level 'INFO'
        Write-Log "  WIM: $($winreResult.WimPath)" -Level 'INFO'
        Write-Log "  Size: $($winreResult.SizeMB) MB" -Level 'INFO'
    } else {
        Write-Log "✗ WinRE: Not Available" -Level 'WARN'
    }

    Write-Log "========================================" -Level 'INFO'
    Write-Log "Recommended Source: $($detectionResult.RecommendedSource)" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Return result object
    return $detectionResult

} catch {
    Write-Log "Fatal error during WinPE detection: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
