#Requires -Version 5.1
<#
.SYNOPSIS
    Consolidates workspace folders into BetterShell and BetterPE.

.DESCRIPTION
    Moves platform, PowerShell, modules, deployment-toolkit, etc. into BetterShell;
    My-WinPE-RE and DeployForge into BetterPE. Use -WhatIf to preview.

.PARAMETER WhatIf
    Show what would be done without making changes.
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = "Stop"

$baseDir = "D:\Dev"
$betterShellDir = Join-Path $baseDir "BetterShell"
$betterPEDir = Join-Path $baseDir "BetterPE"

# Ensure target directories exist (unless WhatIf)
if (-not (Test-Path $betterShellDir)) {
    if ($PSCmdlet.ShouldProcess($betterShellDir, "Create directory")) {
        Write-Host "Creating BetterShell directory..."
        New-Item -Path $betterShellDir -ItemType Directory | Out-Null
    }
}

if (-not (Test-Path $betterPEDir)) {
    if ($PSCmdlet.ShouldProcess($betterPEDir, "Create directory")) {
        Write-Host "Creating BetterPE directory..."
        New-Item -Path $betterPEDir -ItemType Directory | Out-Null
    }
}

$betterShellSources = @(
    "platform",
    "PowerShell",
    "modules",
    "deployment-toolkit",
    "deployment",
    "scripts",
    "ProfileMega",
    "ConnorOS"
)

$betterPESources = @(
    "My-WinPE-RE",
    "DeployForge"
)

Write-Host "--- Moving to BetterShell ---"
foreach ($srcFolderName in $betterShellSources) {
    $srcPath = Join-Path $baseDir $srcFolderName
    $destPath = Join-Path $betterShellDir $srcFolderName

    if (Test-Path $srcPath) {
        if (-not (Test-Path $destPath)) {
            if ($PSCmdlet.ShouldProcess($srcPath, "Move to BetterShell")) {
                Write-Host "Moving $srcFolderName -> BetterShell"
                Move-Item -Path $srcPath -Destination $betterShellDir -ErrorAction Continue
            } else {
                Write-Host "Would move $srcFolderName -> BetterShell" -ForegroundColor Cyan
            }
        }
        else {
            Write-Host "Skipping ${srcFolderName}: Already exists at destination." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Skipping ${srcFolderName}: Source does not exist." -ForegroundColor Red
    }
}

Write-Host "`n--- Moving to BetterPE ---"
foreach ($srcFolderName in $betterPESources) {
    $srcPath = Join-Path $baseDir $srcFolderName
    $destPath = Join-Path $betterPEDir $srcFolderName

    if (Test-Path $srcPath) {
        if (-not (Test-Path $destPath)) {
            if ($PSCmdlet.ShouldProcess($srcPath, "Move to BetterPE")) {
                Write-Host "Moving $srcFolderName -> BetterPE"
                Move-Item -Path $srcPath -Destination $betterPEDir -ErrorAction Continue
            } else {
                Write-Host "Would move $srcFolderName -> BetterPE" -ForegroundColor Cyan
            }
        }
        else {
            Write-Host "Skipping ${srcFolderName}: Already exists at destination." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Skipping ${srcFolderName}: Source does not exist." -ForegroundColor Red
    }
}

Write-Host "`nConsolidation complete."
