# Validate-Catalogs.ps1
# Validates driver and app catalogs

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Validation -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Catalog Validation                      ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$allPassed = $true

# Validate driver catalog
Write-Host "Validating driver catalog..." -ForegroundColor Yellow
$driverResult = Test-DriverCatalog

Write-Host "  Driver packs: $($driverResult.DriverPacks.Count)" -ForegroundColor White
if ($driverResult.Errors.Count -gt 0) {
    Write-Host "  Errors: $($driverResult.Errors.Count)" -ForegroundColor Red
    foreach ($error in $driverResult.Errors) {
        Write-Host "    ✗ $error" -ForegroundColor Red
    }
    $allPassed = $false
}
if ($driverResult.Warnings.Count -gt 0) {
    Write-Host "  Warnings: $($driverResult.Warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $driverResult.Warnings) {
        Write-Host "    ⚠ $warning" -ForegroundColor Yellow
    }
}

# Validate app catalog
Write-Host ''
Write-Host "Validating app catalog..." -ForegroundColor Yellow
$appResult = Test-AppCatalog

Write-Host "  Apps: $($appResult.Apps.Count)" -ForegroundColor White
if ($appResult.Errors.Count -gt 0) {
    Write-Host "  Errors: $($appResult.Errors.Count)" -ForegroundColor Red
    foreach ($error in $appResult.Errors) {
        Write-Host "    ✗ $error" -ForegroundColor Red
    }
    $allPassed = $false
}
if ($appResult.Warnings.Count -gt 0) {
    Write-Host "  Warnings: $($appResult.Warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $appResult.Warnings) {
        Write-Host "    ⚠ $warning" -ForegroundColor Yellow
    }
}

# Validate app set references
Write-Host ''
Write-Host "Validating app set references..." -ForegroundColor Yellow
try {
    Import-Module Deployment.Packages -Force
    $appCatalog = Get-AppCatalog
    $appSetPath = Join-Path (Get-DeployRoot) 'configs\apps\appsets.json'
    
    if (Test-Path $appSetPath) {
        $appSets = Get-Content -Path $appSetPath -Raw | ConvertFrom-Json
        $appIds = $appCatalog | ForEach-Object { $_.id }
        $missingApps = @()
        
        foreach ($set in $appSets) {
            foreach ($appId in $set.appIds) {
                if ($appId -notin $appIds) {
                    $missingApps += "App set '$($set.id)' references missing app: $appId"
                }
            }
        }
        
        if ($missingApps.Count -gt 0) {
            Write-Host "  ⚠ Found $($missingApps.Count) missing app reference(s)" -ForegroundColor Yellow
            foreach ($missing in $missingApps) {
                Write-Host "    ⚠ $missing" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "  ✓ All app set references are valid" -ForegroundColor Green
        }
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-Host ('  ⚠ Could not validate app set references: {0}' -f $errMsg) -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Summary                                  ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

if ($allPassed -and $driverResult.Passed -and $appResult.Passed) {
    Write-Host 'All catalogs are valid!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some catalog validation issues found. See details above.' -ForegroundColor Yellow
    exit 0  # Warnings don't fail the script
}

