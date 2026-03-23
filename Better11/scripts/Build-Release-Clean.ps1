# Better11 Release Build Script

param(
    [string]$Configuration = "Release",
    [switch]$Package
)

Write-Host "Better11 Release Build" -ForegroundColor Cyan

# Create release directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$releaseDir = ".\releases\Better11-$timestamp"
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

Write-Host "Release directory: $releaseDir" -ForegroundColor Green

try {
    # Build core libraries
    Write-Host "Building core libraries..." -ForegroundColor Blue
    Set-Location "Better11\Better11"
    
    dotnet restore Better11.sln
    dotnet build src\Better11.Core\Better11.Core.csproj -c $Configuration
    dotnet build src\Better11.Services\Better11.Services.csproj -c $Configuration
    dotnet build src\Better11.ViewModels\Better11.ViewModels.csproj -c $Configuration
    
    # Try to build app (may fail due to XAML)
    Write-Host "Building WinUI application..." -ForegroundColor Blue
    $appResult = dotnet build src\Better11.App\Better11.App.csproj -c $Configuration
    $appSuccess = $LASTEXITCODE -eq 0
    
    if ($appSuccess) {
        Write-Host "App built successfully" -ForegroundColor Green
    } else {
        Write-Host "App build failed (expected XAML issue)" -ForegroundColor Yellow
    }
    
    # Copy artifacts
    Write-Host "Copying build artifacts..." -ForegroundColor Blue
    
    # Core
    New-Item -ItemType Directory -Path "$releaseDir\Core" -Force | Out-Null
    Copy-Item -Path "src\Better11.Core\bin\$Configuration\net8.0-windows10.0.22621.0\*" -Destination "$releaseDir\Core" -Recurse -Force
    
    # Services
    New-Item -ItemType Directory -Path "$releaseDir\Services" -Force | Out-Null
    Copy-Item -Path "src\Better11.Services\bin\$Configuration\net8.0-windows10.0.22621.0\*" -Destination "$releaseDir\Services" -Recurse -Force
    
    # ViewModels
    New-Item -ItemType Directory -Path "$releaseDir\ViewModels" -Force | Out-Null
    Copy-Item -Path "src\Better11.ViewModels\bin\$Configuration\net8.0-windows10.0.22621.0\*" -Destination "$releaseDir\ViewModels" -Recurse -Force
    
    # App if successful
    if ($appSuccess) {
        New-Item -ItemType Directory -Path "$releaseDir\App" -Force | Out-Null
        Copy-Item -Path "src\Better11.App\bin\$Configuration\net8.0-windows10.0.22621.0\*" -Destination "$releaseDir\App" -Recurse -Force
    }
    
    # Copy PowerShell modules
    Write-Host "Copying PowerShell modules..." -ForegroundColor Blue
    Copy-Item -Path "..\PowerShell\Modules" -Destination "$releaseDir\PowerShell" -Recurse -Force
    
    # Copy documentation
    Write-Host "Copying documentation..." -ForegroundColor Blue
    New-Item -ItemType Directory -Path "$releaseDir\Documentation" -Force | Out-Null
    Copy-Item -Path "..\*.md" -Destination "$releaseDir\Documentation" -Force
    
    # Create simple install script
    $installScript = @"
# Better11 Installation Script
Write-Host "Installing Better11..." -ForegroundColor Cyan

# Import PowerShell modules
`$modulePath = Join-Path `$PSScriptRoot "PowerShell\Modules"
if (Test-Path `$modulePath) {
    Get-ChildItem -Path `$modulePath -Filter "*.psm1" -Recurse | ForEach-Object {
        Import-Module `$_.FullName -Force
        Write-Host "Imported: `$(`$_.BaseName)" -ForegroundColor Gray
    }
}

Write-Host "Better11 installation complete!" -ForegroundColor Green
Write-Host "Usage: Import-Module Better11.*" -ForegroundColor Cyan
"@
    
    $installScript | Out-File -FilePath "$releaseDir\Install-Better11.ps1" -Encoding UTF8
    
    # Create ZIP if requested
    if ($Package) {
        Write-Host "Creating ZIP package..." -ForegroundColor Blue
        $zipPath = ".\releases\Better11-$timestamp.zip"
        Compress-Archive -Path "$releaseDir\*" -DestinationPath $zipPath -Force
        Write-Host "ZIP created: $zipPath" -ForegroundColor Green
    }
    
    Write-Host "Release build completed!" -ForegroundColor Green
    Write-Host "Release directory: $releaseDir" -ForegroundColor Cyan
    
} catch {
    Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Set-Location "..\.."
}
