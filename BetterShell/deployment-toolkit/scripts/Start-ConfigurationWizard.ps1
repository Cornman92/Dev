# Configuration Wizard - First-time setup wizard

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Better11 Deployment Toolkit Setup Wizard ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$config = @{}

# Step 1: Deployment Share
Write-Host 'Step 1: Deployment Share Configuration' -ForegroundColor Yellow
Write-Host ''
$deployShare = Read-Host 'Enter deployment share path (or press Enter for default: D:\DeploymentShare)'
if ([string]::IsNullOrWhiteSpace($deployShare)) {
    $deployShare = 'D:\DeploymentShare'
}
$config.DeploymentShare = $deployShare

Write-Host "Deployment share: $deployShare" -ForegroundColor Green
Write-Host ''

# Step 2: WIM Path
Write-Host 'Step 2: Windows Image (WIM) Path' -ForegroundColor Yellow
Write-Host ''
$wimPath = Read-Host 'Enter path to Windows installation WIM file'
if (-not [string]::IsNullOrWhiteSpace($wimPath)) {
    $config.WimPath = $wimPath
    Write-Host "WIM path: $wimPath" -ForegroundColor Green
}
Write-Host ''

# Step 3: Network Settings
Write-Host 'Step 3: Network Deployment (Optional)' -ForegroundColor Yellow
Write-Host ''
$enableNetwork = Read-Host 'Enable network deployment (PXE/WDS)? (Y/N)'
if ($enableNetwork -eq 'Y' -or $enableNetwork -eq 'y') {
    $config.EnableNetworkDeployment = $true
    $wdsServer = Read-Host 'WDS Server name (or press Enter for localhost)'
    if ([string]::IsNullOrWhiteSpace($wdsServer)) {
        $wdsServer = $env:COMPUTERNAME
    }
    $config.WdsServer = $wdsServer
    Write-Host "Network deployment enabled on: $wdsServer" -ForegroundColor Green
}
else {
    $config.EnableNetworkDeployment = $false
}
Write-Host ''

# Step 4: Cloud Integration
Write-Host 'Step 4: Cloud Integration (Optional)' -ForegroundColor Yellow
Write-Host ''
$enableCloud = Read-Host 'Enable cloud deployment (Azure/AWS)? (Y/N)'
if ($enableCloud -eq 'Y' -or $enableCloud -eq 'y') {
    $cloudProvider = Read-Host 'Cloud provider (Azure/AWS)'
    $config.CloudProvider = $cloudProvider
    Write-Host "Cloud provider: $cloudProvider" -ForegroundColor Green
}
Write-Host ''

# Save configuration
Write-Host 'Saving configuration...' -ForegroundColor Yellow
$root = Get-DeployRoot
$configPath = Join-Path $root 'configs\toolkit-config.json'

$config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8

Write-Host ''
Write-Host 'Configuration saved successfully!' -ForegroundColor Green
Write-Host "Configuration file: $configPath" -ForegroundColor Gray
Write-Host ''

# Set environment variables
Write-Host 'Setting environment variables...' -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable('DEPLOY_SHARE', $deployShare, 'Machine')
[Environment]::SetEnvironmentVariable('WIM_PATH', $config.WimPath, 'Machine')

Write-Host 'Environment variables set successfully!' -ForegroundColor Green
Write-Host ''
Write-Host 'Setup wizard completed!' -ForegroundColor Cyan

