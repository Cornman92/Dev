# Add-ToolkitToWinPE.ps1
# Copies deployment toolkit modules and configuration to a mounted WinPE image

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $MountPath,

    [Parameter()]
    [string] $ToolkitRoot
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MountPath)) {
    throw "Mount path '$MountPath' does not exist. Please mount the WinPE WIM first."
}

if (-not $ToolkitRoot) {
    $ToolkitRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$toolkitRoot = (Resolve-Path $ToolkitRoot).ProviderPath

Write-Host "Adding Better11 Deployment Toolkit to WinPE at: $MountPath" -ForegroundColor Cyan
Write-Host "Toolkit root: $toolkitRoot" -ForegroundColor Gray
Write-Host ''

# Create directory structure in WinPE
$peModulesPath = Join-Path $MountPath 'Windows\System32\WindowsPowerShell\v1.0\Modules'
$peConfigPath = Join-Path $MountPath 'DeployToolkit'

if (-not (Test-Path $peModulesPath)) {
    New-Item -ItemType Directory -Path $peModulesPath -Force | Out-Null
}

if (-not (Test-Path $peConfigPath)) {
    New-Item -ItemType Directory -Path $peConfigPath -Force | Out-Null
}

# Copy modules
$sourceModules = Join-Path $toolkitRoot 'src\Modules'
$modules = Get-ChildItem -Path $sourceModules -Directory

Write-Host "Copying modules..." -ForegroundColor Yellow
foreach ($module in $modules) {
    $dest = Join-Path $peModulesPath $module.Name
    Write-Host "  Copying $($module.Name)..." -ForegroundColor Gray
    
    if (Test-Path $dest) {
        Remove-Item -Path $dest -Recurse -Force
    }
    
    Copy-Item -Path $module.FullName -Destination $dest -Recurse -Force
}

# Copy configuration files
$sourceConfigs = Join-Path $toolkitRoot 'configs'
$destConfigs = Join-Path $peConfigPath 'configs'

Write-Host "Copying configuration files..." -ForegroundColor Yellow
if (Test-Path $destConfigs) {
    Remove-Item -Path $destConfigs -Recurse -Force
}
Copy-Item -Path $sourceConfigs -Destination $destConfigs -Recurse -Force

# Create logs directory
$peLogsPath = Join-Path $peConfigPath 'logs'
if (-not (Test-Path $peLogsPath)) {
    New-Item -ItemType Directory -Path $peLogsPath -Force | Out-Null
}

Write-Host ''
Write-Host "Toolkit successfully added to WinPE!" -ForegroundColor Green
Write-Host "Modules location: $peModulesPath" -ForegroundColor Gray
Write-Host "Config location: $peConfigPath" -ForegroundColor Gray

