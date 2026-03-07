# Setup-WinPEIntegration.ps1
# Main script to integrate Better11 Deployment Toolkit into WinPE

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $WinPEWimPath,

    [Parameter()]
    [string] $MountPath = "$env:TEMP\WinPEMount",

    [Parameter()]
    [string] $ToolkitRoot,

    [Parameter()]
    [switch] $AutoLaunch,

    [Parameter()]
    [switch] $CreateISO,

    [Parameter()]
    [string] $OutputISOPath
)

$ErrorActionPreference = 'Stop'

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Better11 WinPE Integration Setup         ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $WinPEWimPath)) {
    throw "WinPE WIM file not found: $WinPEWimPath"
}

if (-not $ToolkitRoot) {
    $ToolkitRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$toolkitRoot = (Resolve-Path $ToolkitRoot).ProviderPath

Write-Host "WinPE WIM: $WinPEWimPath" -ForegroundColor White
Write-Host "Mount Path: $MountPath" -ForegroundColor White
Write-Host "Toolkit Root: $toolkitRoot" -ForegroundColor White
Write-Host ''

# Check if already mounted
$isMounted = $false
try {
    $mountInfo = Get-WindowsImage -Mounted | Where-Object { $_.ImagePath -eq $WinPEWimPath }
    if ($mountInfo) {
        $isMounted = $true
        $MountPath = $mountInfo.MountPath
        Write-Host "WinPE WIM is already mounted at: $MountPath" -ForegroundColor Yellow
    }
}
catch {
    # Not mounted, continue
}

# Mount WinPE WIM if not already mounted
if (-not $isMounted) {
    Write-Host "Mounting WinPE WIM..." -ForegroundColor Yellow
    
    if (Test-Path $MountPath) {
        Remove-Item -Path $MountPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $MountPath -Force | Out-Null

    Mount-WindowsImage -ImagePath $WinPEWimPath -Index 1 -Path $MountPath | Out-Null
    Write-Host "WinPE WIM mounted successfully" -ForegroundColor Green
}

try {
    # Add toolkit to WinPE
    Write-Host ''
    & "$PSScriptRoot\Add-ToolkitToWinPE.ps1" -MountPath $MountPath -ToolkitRoot $toolkitRoot

    # Configure startup
    Write-Host ''
    & "$PSScriptRoot\Configure-WinPEStartup.ps1" -MountPath $MountPath -AutoLaunch:$AutoLaunch

    # Save changes
    Write-Host ''
    Write-Host "Saving changes to WinPE WIM..." -ForegroundColor Yellow
    Save-WindowsImage -Path $MountPath | Out-Null
    Write-Host "Changes saved successfully" -ForegroundColor Green

    # Create ISO if requested
    if ($CreateISO) {
        Write-Host ''
        Write-Host "Creating WinPE ISO..." -ForegroundColor Yellow
        
        if (-not $OutputISOPath) {
            $wimDir = Split-Path -Parent $WinPEWimPath
            $wimName = [System.IO.Path]::GetFileNameWithoutExtension($WinPEWimPath)
            $OutputISOPath = Join-Path $wimDir "$wimName-WithToolkit.iso"
        }

        # Note: ISO creation requires oscdimg.exe from Windows ADK
        $oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        
        if (Test-Path $oscdimg) {
            $bootData = "2#p0,e,b$MountPath\Windows\Boot\EFI\etfsboot.com#pEF,e,b$MountPath\Windows\Boot\EFI\efisys.bin"
            & $oscdimg -bootdata:$bootData -u1 -udfver102 -o $MountPath $OutputISOPath
            
            Write-Host "ISO created: $OutputISOPath" -ForegroundColor Green
        }
        else {
            Write-Host "oscdimg.exe not found. ISO creation skipped." -ForegroundColor Yellow
            Write-Host "Install Windows ADK and ensure oscdimg.exe is available." -ForegroundColor Yellow
        }
    }
}
finally {
    # Unmount if we mounted it
    if (-not $isMounted) {
        Write-Host ''
        Write-Host "Unmounting WinPE WIM..." -ForegroundColor Yellow
        Dismount-WindowsImage -Path $MountPath -Discard | Out-Null
        Remove-Item -Path $MountPath -Force -ErrorAction SilentlyContinue
        Write-Host "WinPE WIM unmounted" -ForegroundColor Green
    }
    else {
        Write-Host ''
        Write-Host "WinPE WIM remains mounted at: $MountPath" -ForegroundColor Yellow
        Write-Host "Unmount manually when done: Dismount-WindowsImage -Path '$MountPath' -Save" -ForegroundColor Gray
    }
}

Write-Host ''
Write-Host "WinPE integration complete!" -ForegroundColor Green

