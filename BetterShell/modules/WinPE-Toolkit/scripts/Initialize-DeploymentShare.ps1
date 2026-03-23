# Initialize-DeploymentShare.ps1
# Creates deployment share directory structure

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SharePath,

    [Parameter()]
    [switch] $SetPermissions,

    [Parameter()]
    [string] $ShareName = 'DeploymentShare$'
)

$ErrorActionPreference = 'Stop'

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Initialize Deployment Share              ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$sharePath = (Resolve-Path $SharePath -ErrorAction SilentlyContinue).ProviderPath
if (-not $sharePath) {
    $sharePath = (New-Item -ItemType Directory -Path $SharePath -Force).FullName
}

Write-Host "Creating deployment share structure at: $sharePath" -ForegroundColor White
Write-Host ''

# Create directory structure
$directories = @(
    'Drivers\Dell',
    'Drivers\HP',
    'Drivers\Lenovo',
    'Drivers\Generic\Intel',
    'Drivers\Generic\AMD',
    'Drivers\Generic\Realtek',
    'Drivers\Generic\USB',
    'Drivers\Generic\NVMe',
    'Apps\MSI',
    'Apps\EXE',
    'Apps\MSIX',
    'Images',
    'Logs',
    'Configs',
    'Scripts'
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $sharePath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Green
    }
    else {
        Write-Host "Exists: $dir" -ForegroundColor Gray
    }
}

# Create README files
$readmeContent = @"
# Deployment Share Structure

This directory contains deployment resources for the Better11 Deployment Toolkit.

## Directory Structure

- **Drivers/** - Driver packs organized by manufacturer/model
- **Apps/** - Application installers (MSI, EXE, MSIX)
- **Images/** - Windows installation WIM files
- **Logs/** - Deployment logs
- **Configs/** - Configuration files (optional, usually in toolkit root)
- **Scripts/** - Custom deployment scripts

## Usage

Set the DEPLOY_SHARE environment variable to this path:
`$env:DEPLOY_SHARE = "$sharePath"`

Or use relative paths in configuration files.
"@

$readmePath = Join-Path $sharePath 'README.md'
Set-Content -Path $readmePath -Value $readmeContent

Write-Host ''
Write-Host "Deployment share structure created successfully!" -ForegroundColor Green
Write-Host "Share path: $sharePath" -ForegroundColor White

# Set permissions if requested
if ($SetPermissions) {
    Write-Host ''
    Write-Host "Setting share permissions..." -ForegroundColor Yellow
    
    try {
        # Create network share
        $share = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
        if (-not $share) {
            New-SmbShare -Name $ShareName -Path $sharePath -FullAccess 'Administrators' -ReadAccess 'Everyone' | Out-Null
            Write-Host "Network share created: \\$env:COMPUTERNAME\$ShareName" -ForegroundColor Green
        }
        else {
            Write-Host "Network share already exists: \\$env:COMPUTERNAME\$ShareName" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Could not create network share: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You may need to create the share manually or run as Administrator" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Copy Windows WIM files to: $sharePath\Images\" -ForegroundColor White
Write-Host "  2. Copy driver packs to: $sharePath\Drivers\" -ForegroundColor White
Write-Host "  3. Copy application installers to: $sharePath\Apps\" -ForegroundColor White
Write-Host "  4. Set DEPLOY_SHARE environment variable: `$env:DEPLOY_SHARE = '$sharePath'" -ForegroundColor White

