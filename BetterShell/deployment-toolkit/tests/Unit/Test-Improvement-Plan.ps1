# Test Improvement Plan and Coverage Enhancement Script
# This script helps identify gaps in test coverage and provides guidance for improvements

[CmdletBinding()]
param(
    [Parameter()]
    [switch] $GenerateReport,
    
    [Parameter()]
    [switch] $FixCommonIssues
)

$ErrorActionPreference = 'Continue'

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Windows-Deployment-Toolkit Test Analysis  " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Get module paths
$moduleRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$testRoot = $PSScriptRoot

# Find all modules
$modules = Get-ChildItem -Path $moduleRoot -Directory | Where-Object { 
    Test-Path (Join-Path $_.FullName "$($_.Name).psm1")
}

Write-Host "Found $($modules.Count) modules to analyze" -ForegroundColor Green
Write-Host ""

$coverageReport = @{
    Modules = @()
    TotalFunctions = 0
    TestedFunctions = 0
    MissingTests = @()
    Recommendations = @()
}

foreach ($module in $modules) {
    $moduleName = $module.Name
    $moduleFile = Join-Path $module.FullName "$moduleName.psm1"
    $testFile = Join-Path $testRoot "$moduleName.Tests.ps1"
    
    Write-Host "Analyzing: $moduleName" -ForegroundColor Yellow
    
    # Get functions from module
    $functions = @()
    if (Test-Path $moduleFile) {
        $content = Get-Content $moduleFile -Raw
        $functionMatches = [regex]::Matches($content, 'function\s+([A-Z][a-zA-Z0-9-]+)')
        $functions = $functionMatches | ForEach-Object { $_.Groups[1].Value }
    }
    
    # Check if test file exists
    $hasTests = Test-Path $testFile
    
    # Count tests
    $testCount = 0
    if ($hasTests) {
        $testContent = Get-Content $testFile -Raw
        $testMatches = [regex]::Matches($testContent, 'It\s+[''"]')
        $testCount = $testMatches.Count
    }
    
    $moduleInfo = @{
        Name = $moduleName
        Functions = $functions
        FunctionCount = $functions.Count
        HasTestFile = $hasTests
        TestCount = $testCount
        TestFile = $testFile
        ModuleFile = $moduleFile
    }
    
    $coverageReport.Modules += $moduleInfo
    $coverageReport.TotalFunctions += $functions.Count
    
    if ($hasTests) {
        $coverageReport.TestedFunctions += $functions.Count
    } else {
        $coverageReport.MissingTests += $moduleName
        Write-Host "  ⚠️  No test file found" -ForegroundColor Red
    }
    
    Write-Host "  Functions: $($functions.Count), Tests: $testCount" -ForegroundColor $(if ($hasTests) { 'Green' } else { 'Yellow' })
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Coverage Summary                          " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$coveragePercent = if ($coverageReport.TotalFunctions -gt 0) {
    [math]::Round(($coverageReport.TestedFunctions / $coverageReport.TotalFunctions) * 100, 2)
} else {
    0
}

Write-Host "Total Functions: $($coverageReport.TotalFunctions)" -ForegroundColor Cyan
Write-Host "Tested Functions: $($coverageReport.TestedFunctions)" -ForegroundColor Green
Write-Host "Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { 'Green' } elseif ($coveragePercent -ge 60) { 'Yellow' } else { 'Red' })
Write-Host ""

# Generate recommendations
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Recommendations                           " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

if ($coverageReport.MissingTests.Count -gt 0) {
    Write-Host "Modules without test files:" -ForegroundColor Yellow
    foreach ($module in $coverageReport.MissingTests) {
        Write-Host "  - $module" -ForegroundColor Red
        $coverageReport.Recommendations += "Create test file for $module module"
    }
    Write-Host ""
}

# Identify modules with low test-to-function ratio
foreach ($module in $coverageReport.Modules) {
    if ($module.HasTestFile -and $module.FunctionCount -gt 0) {
        $ratio = $module.TestCount / $module.FunctionCount
        if ($ratio -lt 2) {
            Write-Host "$($module.Name): Low test coverage (ratio: $([math]::Round($ratio, 2)))" -ForegroundColor Yellow
            $coverageReport.Recommendations += "Add more tests for $($module.Name) (currently $($module.TestCount) tests for $($module.FunctionCount) functions)"
        }
    }
}

Write-Host ""
Write-Host "Target: 80%+ coverage with 2+ tests per function" -ForegroundColor Cyan
Write-Host ""

# Generate report file if requested
if ($GenerateReport) {
    $reportPath = Join-Path $testRoot "Coverage-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $coverageReport | ConvertTo-Json -Depth 10 | Out-File $reportPath
    Write-Host "Coverage report saved to: $reportPath" -ForegroundColor Green
}

# Fix common issues if requested
if ($FixCommonIssues) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  Fixing Common Issues                     " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check for missing process blocks in pipeline functions
    foreach ($module in $coverageReport.Modules) {
        if (Test-Path $module.ModuleFile) {
            $content = Get-Content $module.ModuleFile -Raw
            
            # Check for functions with ValueFromPipeline but no process block
            $pipelineFunctions = [regex]::Matches($content, 'function\s+([A-Z][a-zA-Z0-9-]+)[\s\S]*?ValueFromPipeline', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($match in $pipelineFunctions) {
                $funcName = $match.Groups[1].Value
                $funcContent = [regex]::Match($content, "function\s+$funcName[\s\S]*?(?=function|\Z)", [System.Text.RegularExpressions.RegexOptions]::Singleline).Value
                
                if ($funcContent -notmatch 'process\s*\{') {
                    Write-Host "⚠️  $($module.Name)\$funcName: Missing process block for pipeline support" -ForegroundColor Yellow
                }
            }
        }
    }
}

Write-Host ""
Write-Host "Analysis complete!" -ForegroundColor Green
