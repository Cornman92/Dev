# Better11 Installation Script
Write-Host "Installing Better11..." -ForegroundColor Cyan

# Import PowerShell modules
$modulePath = Join-Path $PSScriptRoot "PowerShell\Modules"
if (Test-Path $modulePath) {
    Get-ChildItem -Path $modulePath -Filter "*.psm1" -Recurse | ForEach-Object {
        Import-Module $_.FullName -Force
        Write-Host "Imported: $($_.BaseName)" -ForegroundColor Gray
    }
}

Write-Host "Better11 installation complete!" -ForegroundColor Green
Write-Host "Usage: Import-Module Better11.*" -ForegroundColor Cyan
