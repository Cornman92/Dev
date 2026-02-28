<#
.SYNOPSIS
    Bootstraps the Dev workspace after a fresh clone.

.DESCRIPTION
    Creates all required project directories, installs git hooks,
    verifies prerequisites, and validates the workspace is ready
    for development.

.EXAMPLE
    .\Scripts\Setup-Workspace.ps1
    Runs the full workspace setup.

.EXAMPLE
    .\Scripts\Setup-Workspace.ps1 -SkipHooks
    Runs setup but skips git hook installation.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [switch]$SkipHooks
)

$ErrorActionPreference = 'Stop'

# ---- Helpers ----
function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

# ---- Locate workspace root ----
$workspaceRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $workspaceRoot '.git'))) {
    Write-Error "Cannot find .git directory. Run this script from the Scripts/ folder inside the Dev workspace."
}

Set-Location $workspaceRoot
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Dev Workspace Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Check prerequisites ----
Write-Step "Checking prerequisites..."

$prereqs = @{
    'git'        = { git --version 2>$null }
    'PowerShell' = { $PSVersionTable.PSVersion }
}

foreach ($tool in $prereqs.Keys) {
    try {
        $version = & $prereqs[$tool]
        Write-Success "$tool found: $version"
    }
    catch {
        Write-Warn "$tool not found or not in PATH"
    }
}

# ---- Step 2: Create directories ----
Write-Step "Creating project directories..."

$directories = @(
    'Archive',
    'Artifacts',
    'Assets',
    'CurrentProjects',
    'Functions',
    'Modules',
    'Optimizations',
    'Registry',
    'Scratch',
    'Scripts'
)

foreach ($dir in $directories) {
    $dirPath = Join-Path $workspaceRoot $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Success "Created $dir/"
    }
    else {
        Write-Success "$dir/ already exists"
    }

    # Ensure .gitkeep exists
    $gitkeepPath = Join-Path $dirPath '.gitkeep'
    if (-not (Test-Path $gitkeepPath)) {
        New-Item -ItemType File -Path $gitkeepPath -Force | Out-Null
    }
}

# ---- Step 3: Install git hooks ----
if (-not $SkipHooks) {
    Write-Step "Installing git hooks..."
    $hookScript = Join-Path $workspaceRoot 'Scripts' 'Install-GitHooks.ps1'
    if (Test-Path $hookScript) {
        & $hookScript
    }
    else {
        Write-Warn "Install-GitHooks.ps1 not found. Skipping hook installation."
    }
}
else {
    Write-Warn "Skipping git hook installation (-SkipHooks)"
}

# ---- Step 4: Verify key files ----
Write-Step "Verifying workspace files..."

$requiredFiles = @(
    '.gitignore',
    '.gitattributes',
    '.editorconfig',
    'CLAUDE.md',
    'README.md',
    'CONTRIBUTING.md',
    'LICENSE',
    'PSScriptAnalyzerSettings.psd1'
)

$missing = @()
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $workspaceRoot $file
    if (Test-Path $filePath) {
        Write-Success "$file present"
    }
    else {
        Write-Warn "$file is MISSING"
        $missing += $file
    }
}

# ---- Summary ----
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

if ($missing.Count -gt 0) {
    Write-Warn "Missing files: $($missing -join ', ')"
    Write-Host "The workspace is partially set up. Please restore missing files." -ForegroundColor Yellow
}
else {
    Write-Success "Workspace is fully configured and ready for development."
}

Write-Host ""
