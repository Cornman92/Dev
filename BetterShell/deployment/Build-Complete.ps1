# Build-Complete.ps1
# Complete build script for Better11 Ultimate

param(
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',
    
    [Parameter()]
    [switch]$Run
)

$ErrorActionPreference = 'Stop'

Write-Host "`n=== Better11 Ultimate - Build Script ===" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration`n" -ForegroundColor Yellow

# Step 1: Clean previous builds
Write-Host "[1/5] Cleaning previous builds..." -ForegroundColor Green
if (Test-Path "Better11.Core\bin") {
    Remove-Item -Path "Better11.Core\bin" -Recurse -Force
}
if (Test-Path "Better11.Core\obj") {
    Remove-Item -Path "Better11.Core\obj" -Recurse -Force
}
if (Test-Path "Better11.TUI\bin") {
    Remove-Item -Path "Better11.TUI\bin" -Recurse -Force
}
if (Test-Path "Better11.TUI\obj") {
    Remove-Item -Path "Better11.TUI\obj" -Recurse -Force
}
Write-Host "   Clean complete!`n" -ForegroundColor DarkGreen

# Step 2: Restore NuGet packages
Write-Host "[2/5] Restoring NuGet packages..." -ForegroundColor Green
dotnet restore Better11.sln
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: NuGet restore failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   Restore complete!`n" -ForegroundColor DarkGreen

# Step 3: Build Better11.Core
Write-Host "[3/5] Building Better11.Core..." -ForegroundColor Green
dotnet build Better11.Core\Better11.Core.csproj --configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: Core build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   Core build complete!`n" -ForegroundColor DarkGreen

# Step 4: Build Better11.TUI
Write-Host "[4/5] Building Better11.TUI..." -ForegroundColor Green
dotnet build Better11.TUI\Better11.TUI.csproj --configuration $Configuration
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERROR: TUI build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "   TUI build complete!`n" -ForegroundColor DarkGreen

# Step 5: Verify PowerShell modules copied
Write-Host "[5/5] Verifying PowerShell modules..." -ForegroundColor Green
$modulePath = "Better11.TUI\bin\$Configuration\net8.0\PowerShell\Modules"
if (Test-Path $modulePath) {
    $moduleCount = (Get-ChildItem -Path $modulePath -Filter "*.psm1" -Recurse).Count
    Write-Host "   Found $moduleCount PowerShell modules" -ForegroundColor DarkGreen
} else {
    Write-Host "   WARNING: PowerShell modules directory not found!" -ForegroundColor Yellow
}
Write-Host ""

# Build summary
Write-Host "=== Build Complete ===" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Green
Write-Host "Output: Better11.TUI\bin\$Configuration\net8.0\Better11.TUI.exe`n" -ForegroundColor Green

# Run if requested
if ($Run) {
    Write-Host "=== Running Better11 TUI ===" -ForegroundColor Cyan
    Write-Host ""
    
    $exePath = "Better11.TUI\bin\$Configuration\net8.0\Better11.TUI.exe"
    if (Test-Path $exePath) {
        & $exePath
    } else {
        Write-Host "ERROR: Executable not found at $exePath" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "To run the application, use:" -ForegroundColor Yellow
    Write-Host "  .\Build-Complete.ps1 -Run" -ForegroundColor White
    Write-Host "or:" -ForegroundColor Yellow
    Write-Host "  cd Better11.TUI\bin\$Configuration\net8.0" -ForegroundColor White
    Write-Host "  .\Better11.TUI.exe`n" -ForegroundColor White
}
