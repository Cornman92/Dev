# Test-ConfigurationFiles.ps1
# Validates all JSON configuration files

[CmdletBinding()]
param(
    [Parameter()]
    [switch] $Detailed
)

$ErrorActionPreference = 'Stop'

$toolkitRoot = if ($PSScriptRoot) {
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
else {
    $PWD
}

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Configuration Files Validation           ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$results = @{
    Passed = $true
    Files = @()
    Errors = @()
}

# Test task sequences
Write-Host "Validating task sequences..." -ForegroundColor Yellow
$tsPath = Join-Path $toolkitRoot 'configs\task_sequences'
if (Test-Path $tsPath) {
    $tsFiles = Get-ChildItem -Path $tsPath -Filter '*.json' -File
    
    foreach ($file in $tsFiles) {
        try {
            $raw = Get-Content -Path $file.FullName -Raw
            $data = $raw | ConvertFrom-Json -ErrorAction Stop
            
            $seqCount = if ($data -is [System.Collections.IEnumerable]) { $data.Count } else { 1 }
            
            $results.Files += [pscustomobject]@{
                File = $file.Name
                Type = 'Task Sequence'
                Status = 'Valid'
                Details = "$seqCount sequence(s)"
            }
            
            Write-Host "  ✓ $($file.Name) - Valid JSON" -ForegroundColor Green
        }
        catch {
            $results.Passed = $false
            $results.Errors += "$($file.Name): $($_.Exception.Message)"
            $results.Files += [pscustomobject]@{
                File = $file.Name
                Type = 'Task Sequence'
                Status = 'Invalid'
                Details = $_.Exception.Message
            }
            Write-Host "  ✗ $($file.Name) - Invalid: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Test driver catalog
Write-Host ''
Write-Host "Validating driver catalog..." -ForegroundColor Yellow
$driverPath = Join-Path $toolkitRoot 'configs\drivers\catalog.json'
if (Test-Path $driverPath) {
    try {
        $raw = Get-Content -Path $driverPath -Raw
        $data = $raw | ConvertFrom-Json -ErrorAction Stop
        
        $results.Files += [pscustomobject]@{
            File = 'catalog.json'
            Type = 'Driver Catalog'
            Status = 'Valid'
            Details = "$($data.Count) driver pack(s)"
        }
        Write-Host "  ✓ catalog.json - Valid JSON with $($data.Count) driver pack(s)" -ForegroundColor Green
    }
    catch {
        $results.Passed = $false
        $results.Errors += "catalog.json: $($_.Exception.Message)"
        Write-Host "  ✗ catalog.json - Invalid: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test app catalog
Write-Host ''
Write-Host "Validating app catalog..." -ForegroundColor Yellow
$appPath = Join-Path $toolkitRoot 'configs\apps\apps.json'
if (Test-Path $appPath) {
    try {
        $raw = Get-Content -Path $appPath -Raw
        $data = $raw | ConvertFrom-Json -ErrorAction Stop
        
        $results.Files += [pscustomobject]@{
            File = 'apps.json'
            Type = 'App Catalog'
            Status = 'Valid'
            Details = "$($data.Count) app(s)"
        }
        Write-Host "  ✓ apps.json - Valid JSON with $($data.Count) app(s)" -ForegroundColor Green
    }
    catch {
        $results.Passed = $false
        $results.Errors += "apps.json: $($_.Exception.Message)"
        Write-Host "  ✗ apps.json - Invalid: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test app sets
Write-Host ''
Write-Host "Validating app sets..." -ForegroundColor Yellow
$appSetPath = Join-Path $toolkitRoot 'configs\apps\appsets.json'
if (Test-Path $appSetPath) {
    try {
        $raw = Get-Content -Path $appSetPath -Raw
        $data = $raw | ConvertFrom-Json -ErrorAction Stop
        
        $results.Files += [pscustomobject]@{
            File = 'appsets.json'
            Type = 'App Sets'
            Status = 'Valid'
            Details = "$($data.Count) app set(s)"
        }
        Write-Host "  ✓ appsets.json - Valid JSON with $($data.Count) app set(s)" -ForegroundColor Green
    }
    catch {
        $results.Passed = $false
        $results.Errors += "appsets.json: $($_.Exception.Message)"
        Write-Host "  ✗ appsets.json - Invalid: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test optimization profiles
Write-Host ''
Write-Host "Validating optimization profiles..." -ForegroundColor Yellow
$optPath = Join-Path $toolkitRoot 'configs\optimize\profiles'
if (Test-Path $optPath) {
    $optFiles = Get-ChildItem -Path $optPath -Filter '*.json' -File
    
    foreach ($file in $optFiles) {
        try {
            $raw = Get-Content -Path $file.FullName -Raw
            $data = $raw | ConvertFrom-Json -ErrorAction Stop
            
            $profileCount = if ($data -is [System.Collections.IEnumerable]) { $data.Count } else { 1 }
            
            $results.Files += [pscustomobject]@{
                File = $file.Name
                Type = 'Optimization Profile'
                Status = 'Valid'
                Details = "$profileCount profile(s)"
            }
            Write-Host "  ✓ $($file.Name) - Valid JSON" -ForegroundColor Green
        }
        catch {
            $results.Passed = $false
            $results.Errors += "$($file.Name): $($_.Exception.Message)"
            Write-Host "  ✗ $($file.Name) - Invalid: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Validation Summary                       ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$valid = ($results.Files | Where-Object { $_.Status -eq 'Valid' }).Count
$invalid = ($results.Files | Where-Object { $_.Status -eq 'Invalid' }).Count

Write-Host ('Total files validated: {0}' -f $results.Files.Count)
Write-Host ('Valid: {0}' -f $valid) -ForegroundColor Green
$invalidColor = if ($invalid -gt 0) { 'Red' } else { 'Green' }
Write-Host ('Invalid: {0}' -f $invalid) -ForegroundColor $invalidColor

if ($Detailed -and $results.Files.Count -gt 0) {
    Write-Host ''
    Write-Host 'Detailed results:' -ForegroundColor Cyan
    $results.Files | Format-Table -AutoSize
}

if ($results.Errors.Count -gt 0) {
    Write-Host ''
    Write-Host 'Errors:' -ForegroundColor Red
    foreach ($err in $results.Errors) {
        Write-Host ('  - {0}' -f $err) -ForegroundColor Red
    }
}

Write-Host ''

if ($results.Passed) {
    Write-Host 'All configuration files are valid!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some configuration files are invalid. See errors above.' -ForegroundColor Red
    exit 1
}

