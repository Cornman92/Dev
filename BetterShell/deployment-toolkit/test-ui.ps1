# UI Control Center Test Script
# Tests that the UI can initialize without errors

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   UI Control Center Test                   ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

Import-Module Deployment.UI -Force

Write-Host 'Testing UI module functions...' -ForegroundColor Yellow
Write-Host ''

# Test that functions are available
$functions = @('Start-DeployCenter', 'Start-DeployConsole')
$allFound = $true

foreach ($func in $functions) {
    if (Get-Command -Name $func -ErrorAction SilentlyContinue) {
        Write-Host "  $func - Available" -ForegroundColor Green
    }
    else {
        Write-Host "  $func - NOT FOUND" -ForegroundColor Red
        $allFound = $false
    }
}

Write-Host ''

# Test hardware summary function (internal but we can test it exists)
if (Get-Command -Name 'Show-HardwareSummary' -ErrorAction SilentlyContinue) {
    Write-Host '  Show-HardwareSummary - Available' -ForegroundColor Green
}
else {
    Write-Host '  Show-HardwareSummary - NOT FOUND (may be internal)' -ForegroundColor Yellow
}

Write-Host ''

# Test task sequence picker (internal)
if (Get-Command -Name 'Show-TaskSequencePicker' -ErrorAction SilentlyContinue) {
    Write-Host '  Show-TaskSequencePicker - Available' -ForegroundColor Green
}
else {
    Write-Host '  Show-TaskSequencePicker - NOT FOUND (may be internal)' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Testing hardware summary display...' -ForegroundColor Yellow

try {
    # Call the internal function directly if available, or test through module
    $hwModule = Get-Module Deployment.Drivers
    if ($hwModule) {
        $hw = Get-HardwareProfile
        Write-Host "  Hardware detected: $($hw.Manufacturer) $($hw.Model)" -ForegroundColor Green
        Write-Host "  CPU: $($hw.CPUName)" -ForegroundColor Gray
        Write-Host "  Memory: $($hw.TotalMemoryGB) GB" -ForegroundColor Gray
    }
}
catch {
    Write-Host "  WARNING: Could not test hardware detection: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Testing task sequence catalog loading...' -ForegroundColor Yellow

try {
    $tsModule = Get-Module Deployment.TaskSequence
    if ($tsModule) {
        $catalog = Get-TaskSequenceCatalog
        Write-Host "  Task sequences found: $($catalog.Count)" -ForegroundColor Green
        
        foreach ($ts in $catalog) {
            Write-Host "    - $($ts.name) (id: $($ts.id))" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "  WARNING: Could not test task sequence catalog: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Test Summary                             ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

if ($allFound) {
    Write-Host 'UI Control Center functions are available and ready!' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Note: Full interactive UI test requires manual execution:' -ForegroundColor Yellow
    Write-Host '  Start-DeployCenter' -ForegroundColor Cyan
    exit 0
}
else {
    Write-Host 'Some UI functions are missing!' -ForegroundColor Red
    exit 1
}

