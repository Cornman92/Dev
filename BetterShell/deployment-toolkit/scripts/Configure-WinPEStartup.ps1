# Configure-WinPEStartup.ps1
# Configures WinPE startup script to launch Deployment Center

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $MountPath,

    [Parameter()]
    [switch] $AutoLaunch
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MountPath)) {
    throw "Mount path '$MountPath' does not exist. Please mount the WinPE WIM first."
}

Write-Host "Configuring WinPE startup script..." -ForegroundColor Cyan
Write-Host ''

$peSystem32 = Join-Path $MountPath 'Windows\System32'
$startnetPath = Join-Path $peSystem32 'startnet.cmd'

# Create startup script
$startupScript = @'
@echo off
REM Better11 Deployment Toolkit Startup Script

REM Set environment variables
set DEPLOY_TOOLKIT_ROOT=X:\DeployToolkit
set PSModulePath=%PSModulePath%;X:\Windows\System32\WindowsPowerShell\v1.0\Modules

REM Change to toolkit directory
cd /d %DEPLOY_TOOLKIT_ROOT%

REM Launch PowerShell and import modules
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$env:PSModulePath = 'X:\Windows\System32\WindowsPowerShell\v1.0\Modules'; " ^
    "Import-Module Deployment.UI -Force; " ^
    "Start-DeployCenter"

'@

# If auto-launch is disabled, just set up the environment
if (-not $AutoLaunch) {
    $startupScript = @'
@echo off
REM Better11 Deployment Toolkit Environment Setup

REM Set environment variables
set DEPLOY_TOOLKIT_ROOT=X:\DeployToolkit
set PSModulePath=%PSModulePath%;X:\Windows\System32\WindowsPowerShell\v1.0\Modules

REM Change to toolkit directory
cd /d %DEPLOY_TOOLKIT_ROOT%

REM Launch PowerShell with toolkit available
powershell.exe -NoProfile -ExecutionPolicy Bypass

'@
}

# Backup existing startnet.cmd if it exists
if (Test-Path $startnetPath) {
    $backupPath = "$startnetPath.backup"
    Copy-Item -Path $startnetPath -Destination $backupPath -Force
    Write-Host "Backed up existing startnet.cmd to startnet.cmd.backup" -ForegroundColor Yellow
}

# Write new startup script
Set-Content -Path $startnetPath -Value $startupScript -Encoding ASCII

Write-Host "Startup script configured at: $startnetPath" -ForegroundColor Green
if ($AutoLaunch) {
    Write-Host "Deployment Center will auto-launch on WinPE boot" -ForegroundColor Green
}
else {
    Write-Host "Toolkit environment will be available in PowerShell" -ForegroundColor Green
}

