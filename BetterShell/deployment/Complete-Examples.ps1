<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Complete Examples Collection
    Practical examples for common WinPE scenarios

.DESCRIPTION
    This file contains ready-to-use examples for:
    - Basic image creation
    - Advanced customization
    - Multi-site deployment
    - Recovery environment builds
    - Automated testing workflows
    - Production deployment pipelines

.NOTES
    Author: Con's Development Team
    Version: 2.0.0
    All examples include error handling and logging
#>

#region Example 1: Quick WinPE Build

<#
.EXAMPLE 1: QUICK WINPE BUILD
Creates a basic WinPE image with PowerShell support
#>

function Example1-QuickBuild {
    try {
        Write-Host "Example 1: Quick WinPE Build" -ForegroundColor Cyan
        Write-Host "============================`n"
        
        # Import required module
        Import-Module ".\Modules\01-Image-Builder\Build-WinPEImage.psm1" -Force
        
        # Build parameters
        $params = @{
            ADKPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
            Architecture = 'amd64'
            OutputPath = "C:\WinPE-Workspace\Examples\quick-build.wim"
            Verbose = $true
        }
        
        # Create image
        $result = New-WinPEImage @params
        
        Write-Host "`n✓ Image created successfully!" -ForegroundColor Green
        Write-Host "Location: $($result.ImagePath)"
        Write-Host "Size: $([math]::Round($result.Size / 1MB, 2)) MB"
        
        return $result
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Example 2: Customized Corporate Image

<#
.EXAMPLE 2: CUSTOMIZED CORPORATE IMAGE
Creates a fully customized WinPE image for corporate deployment
#>

function Example2-CorporateImage {
    try {
        Write-Host "Example 2: Customized Corporate Image" -ForegroundColor Cyan
        Write-Host "======================================`n"
        
        # Import required modules
        Import-Module ".\Modules\01-Image-Builder\Build-WinPEImage.psm1" -Force
        Import-Module ".\Modules\02-Driver-Integration\Manage-WinPEDrivers.psm1" -Force
        Import-Module ".\Modules\03-Customization\Customize-WinPEImage.psm1" -Force
        Import-Module ".\Modules\06-Package-Management\Manage-WinPEPackages.psm1" -Force
        
        $imagePath = "C:\WinPE-Workspace\Examples\corporate-image.wim"
        
        # Step 1: Build base image
        Write-Host "[1/6] Building base image..." -ForegroundColor Yellow
        $image = New-WinPEImage -ADKPath "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit" `
                                -Architecture amd64 `
                                -OutputPath $imagePath
        
        # Step 2: Add essential packages
        Write-Host "[2/6] Adding packages..." -ForegroundColor Yellow
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-PowerShell"
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-NetFx"
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-DismCmdlets"
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-StorageWMI"
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-Scripting"
        
        # Step 3: Add corporate drivers
        Write-Host "[3/6] Adding drivers..." -ForegroundColor Yellow
        if (Test-Path "C:\Drivers\Corporate") {
            Add-WinPEDriver -ImagePath $imagePath -DriverPath "C:\Drivers\Corporate" -Recurse
        }
        
        # Step 4: Apply branding
        Write-Host "[4/6] Applying corporate branding..." -ForegroundColor Yellow
        Set-WinPEBranding -ImagePath $imagePath `
                          -CompanyName "Contoso Corporation" `
                          -SupportPhone "1-800-CONTOSO" `
                          -SupportURL "https://support.contoso.com"
        
        # Step 5: Add startup script
        Write-Host "[5/6] Adding startup script..." -ForegroundColor Yellow
        $startupScript = @'
@echo off
echo ================================================
echo  Contoso Corporation - WinPE Environment
echo  Support: 1-800-CONTOSO
echo ================================================
echo.
wpeinit
echo Network initialization complete.
echo.
echo Starting PowerShell...
powershell.exe -NoExit -Command "Write-Host 'Corporate WinPE Ready' -ForegroundColor Green"
'@
        $scriptPath = "C:\Temp\corporate-startup.cmd"
        $startupScript | Out-File -FilePath $scriptPath -Encoding ASCII
        
        Add-WinPEStartupScript -ImagePath $imagePath -ScriptPath $scriptPath
        
        # Step 6: Configure network
        Write-Host "[6/6] Configuring network..." -ForegroundColor Yellow
        Set-WinPENetworkConfiguration -ImagePath $imagePath -EnableDHCP
        
        Write-Host "`n✓ Corporate image created successfully!" -ForegroundColor Green
        Write-Host "Location: $imagePath"
        
        return $image
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Example 3: Recovery Environment with BitLocker

<#
.EXAMPLE 3: RECOVERY ENVIRONMENT WITH BITLOCKER
Creates a comprehensive recovery environment with BitLocker support
#>

function Example3-RecoveryEnvironment {
    try {
        Write-Host "Example 3: Recovery Environment with BitLocker" -ForegroundColor Cyan
        Write-Host "==============================================`n"
        
        # Import required modules
        Import-Module ".\Modules\01-Image-Builder\Build-WinPEImage.psm1" -Force
        Import-Module ".\Modules\05-Recovery-Environment\Build-RecoveryEnvironment.psm1" -Force
        Import-Module ".\Modules\06-Package-Management\Manage-WinPEPackages.psm1" -Force
        
        $baseImage = "C:\WinPE-Workspace\Examples\base-winpe.wim"
        $recoveryImage = "C:\WinPE-Workspace\Examples\winre.wim"
        
        # Step 1: Build base WinPE image
        Write-Host "[1/4] Building base WinPE image..." -ForegroundColor Yellow
        if (-not (Test-Path $baseImage)) {
            New-WinPEImage -ADKPath "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit" `
                          -Architecture amd64 `
                          -OutputPath $baseImage
        }
        
        # Step 2: Create recovery environment
        Write-Host "[2/4] Creating recovery environment..." -ForegroundColor Yellow
        $recovery = New-RecoveryEnvironment -BaseImagePath $baseImage `
                                           -OutputPath $recoveryImage `
                                           -IncludeBitLocker `
                                           -IncludeNetworking
        
        # Step 3: Add recovery tools
        Write-Host "[3/4] Adding recovery tools..." -ForegroundColor Yellow
        
        # Custom recovery script
        $recoveryToolScript = @'
@echo off
title Windows Recovery Environment - Contoso Corp
color 0B
cls
echo.
echo ========================================================
echo  Windows Recovery Environment
echo  Contoso Corporation
echo ========================================================
echo.
echo Available Tools:
echo  1. BitLocker Recovery
echo  2. System Restore
echo  3. Command Prompt
echo  4. Disk Management
echo  5. Network Diagnostics
echo  6. Exit to Windows
echo.
set /p choice="Select option (1-6): "

if "%choice%"=="1" start manage-bde -unlock C: -RecoveryPassword
if "%choice%"=="2" start rstrui.exe
if "%choice%"=="3" start cmd.exe
if "%choice%"=="4" start diskpart.exe
if "%choice%"=="5" start powershell.exe -Command "Test-NetConnection; ipconfig /all"
if "%choice%"=="6" wpeutil reboot

pause
'@
        
        $toolPath = "C:\Temp\recovery-menu.cmd"
        $recoveryToolScript | Out-File -FilePath $toolPath -Encoding ASCII
        
        Add-RecoveryTool -ImagePath $recoveryImage `
                        -ToolPath $toolPath `
                        -ToolName "Recovery Menu" `
                        -Description "Main recovery interface"
        
        # Step 4: Configure recovery settings
        Write-Host "[4/4] Configuring recovery settings..." -ForegroundColor Yellow
        Set-RecoveryConfiguration -ImagePath $recoveryImage `
                                 -AutoStart $true `
                                 -Timeout 30
        
        Write-Host "`n✓ Recovery environment created successfully!" -ForegroundColor Green
        Write-Host "Location: $recoveryImage"
        Write-Host "Features: BitLocker, Networking, Custom Tools"
        
        return $recovery
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Example 4: Automated Testing Pipeline

<#
.EXAMPLE 4: AUTOMATED TESTING PIPELINE
Complete build-test-deploy pipeline with validation
#>

function Example4-TestingPipeline {
    try {
        Write-Host "Example 4: Automated Testing Pipeline" -ForegroundColor Cyan
        Write-Host "======================================`n"
        
        # Import required modules
        Import-Module ".\Modules\01-Image-Builder\Build-WinPEImage.psm1" -Force
        Import-Module ".\Modules\02-Driver-Integration\Manage-WinPEDrivers.psm1" -Force
        Import-Module ".\Modules\06-Package-Management\Manage-WinPEPackages.psm1" -Force
        Import-Module ".\Modules\07-Testing-Validation\Test-WinPEImage.psm1" -Force
        Import-Module ".\Modules\08-Deployment-Automation\Deploy-WinPEImage.psm1" -Force
        
        $workspace = "C:\WinPE-Workspace\Examples\Pipeline"
        $null = New-Item -Path $workspace -ItemType Directory -Force
        
        $imagePath = Join-Path $workspace "test-image.wim"
        $isoPath = Join-Path $workspace "test-image.iso"
        
        # Step 1: Build image
        Write-Host "[1/5] Building WinPE image..." -ForegroundColor Yellow
        $image = New-WinPEImage -ADKPath "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit" `
                                -Architecture amd64 `
                                -OutputPath $imagePath
        
        # Step 2: Add components
        Write-Host "[2/5] Adding components..." -ForegroundColor Yellow
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-PowerShell"
        Add-WinPEPackage -ImagePath $imagePath -PackageName "WinPE-NetFx"
        
        if (Test-Path "C:\Drivers\Test") {
            Add-WinPEDriver -ImagePath $imagePath -DriverPath "C:\Drivers\Test" -Recurse
        }
        
        # Step 3: Run comprehensive tests
        Write-Host "[3/5] Running validation tests..." -ForegroundColor Yellow
        $testResults = Invoke-WinPEImageTest -ImagePath $imagePath `
                                            -TestSuite All `
                                            -RequiredComponents @('WinPE-PowerShell', 'WinPE-NetFx')
        
        # Display test summary
        Write-Host "`nTest Summary:" -ForegroundColor Cyan
        Write-Host "  Total Tests: $($testResults.TotalTests)"
        Write-Host "  Passed: $($testResults.PassedTests)" -ForegroundColor Green
        Write-Host "  Failed: $($testResults.FailedTests)" -ForegroundColor $(if ($testResults.FailedTests -gt 0) { 'Red' } else { 'Green' })
        Write-Host "  Success Rate: $($testResults.SuccessRate)%"
        Write-Host "  Status: $($testResults.OverallStatus)" -ForegroundColor $(if ($testResults.OverallStatus -eq 'Passed') { 'Green' } else { 'Red' })
        
        # Step 4: Deploy if tests passed
        if ($testResults.OverallStatus -eq 'Passed') {
            Write-Host "`n[4/5] Tests passed! Deploying to ISO..." -ForegroundColor Yellow
            
            $deployment = Deploy-WinPEImage -ImagePath $imagePath `
                                           -DeploymentType ISO `
                                           -OutputPath $isoPath
            
            Write-Host "[5/5] Deployment complete!" -ForegroundColor Yellow
            Write-Host "`n✓ Pipeline completed successfully!" -ForegroundColor Green
            Write-Host "ISO Location: $isoPath"
        }
        else {
            Write-Host "`n✗ Tests failed! Deployment skipped." -ForegroundColor Red
            Write-Host "Review test report for details."
        }
        
        return @{
            Image = $image
            TestResults = $testResults
            Deployment = if ($testResults.OverallStatus -eq 'Passed') { $deployment } else { $null }
        }
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Example 5: Multi-Site Deployment

<#
.EXAMPLE 5: MULTI-SITE DEPLOYMENT
Deploy WinPE image to multiple sites simultaneously
#>

function Example5-MultiSiteDeployment {
    try {
        Write-Host "Example 5: Multi-Site Deployment" -ForegroundColor Cyan
        Write-Host "=================================`n"
        
        # Import required modules
        Import-Module ".\Modules\01-Image-Builder\Build-WinPEImage.psm1" -Force
        Import-Module ".\Modules\08-Deployment-Automation\Deploy-WinPEImage.psm1" -Force
        
        $imagePath = "C:\WinPE-Workspace\Examples\multi-site-image.wim"
        
        # Step 1: Build master image
        Write-Host "[1/2] Building master image..." -ForegroundColor Yellow
        if (-not (Test-Path $imagePath)) {
            New-WinPEImage -ADKPath "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit" `
                          -Architecture amd64 `
                          -OutputPath $imagePath
        }
        
        # Step 2: Define deployment targets
        Write-Host "[2/2] Deploying to multiple sites..." -ForegroundColor Yellow
        
        $deploymentTargets = @(
            @{
                Type = 'ISO'
                OutputPath = '\\FileServer-US\Deployments\WinPE\us-east-winpe.iso'
                Description = 'US East Coast'
            },
            @{
                Type = 'ISO'
                OutputPath = '\\FileServer-EU\Deployments\WinPE\eu-west-winpe.iso'
                Description = 'EU West'
            },
            @{
                Type = 'ISO'
                OutputPath = '\\FileServer-APAC\Deployments\WinPE\apac-winpe.iso'
                Description = 'Asia Pacific'
            },
            @{
                Type = 'WDS'
                Server = 'WDS-Server-01'
                ImageName = 'Production WinPE v2.0'
                Description = 'Corporate WDS'
            }
        )
        
        # Execute multi-site deployment
        $results = Start-WinPEMultiSiteDeployment -ImagePath $imagePath `
                                                  -DeploymentTargets $deploymentTargets `
                                                  -MaxParallel 3
        
        Write-Host "`n✓ Multi-site deployment completed!" -ForegroundColor Green
        Write-Host "Successful: $(($results | Where-Object { $_.State -eq 'Completed' }).Count)"
        Write-Host "Failed: $(($results | Where-Object { $_.State -eq 'Failed' }).Count)"
        
        return $results
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Example 6: Batch Operation from JSON

<#
.EXAMPLE 6: BATCH OPERATION FROM JSON
Execute complex workflow from configuration file
#>

function Example6-BatchOperation {
    try {
        Write-Host "Example 6: Batch Operation from JSON" -ForegroundColor Cyan
        Write-Host "=====================================`n"
        
        # Import console module
        Import-Module ".\Console\WinPE-Console.psm1" -Force
        
        # Create batch configuration
        $batchConfig = @{
            StopOnError = $false
            Operations = @(
                @{
                    Type = 'BuildImage'
                    Description = 'Build base WinPE image'
                    Parameters = @{
                        ADKPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit'
                        Architecture = 'amd64'
                        OutputPath = 'C:\WinPE-Workspace\Examples\batch-image.wim'
                    }
                },
                @{
                    Type = 'AddDrivers'
                    Description = 'Add network drivers'
                    Parameters = @{
                        ImagePath = 'C:\WinPE-Workspace\Examples\batch-image.wim'
                        DriverPath = 'C:\Drivers\Network'
                    }
                },
                @{
                    Type = 'Customize'
                    Description = 'Apply customizations'
                    Parameters = @{
                        ImagePath = 'C:\WinPE-Workspace\Examples\batch-image.wim'
                        CompanyName = 'Contoso Corp'
                    }
                },
                @{
                    Type = 'Test'
                    Description = 'Validate image'
                    Parameters = @{
                        ImagePath = 'C:\WinPE-Workspace\Examples\batch-image.wim'
                    }
                },
                @{
                    Type = 'Deploy'
                    Description = 'Create bootable ISO'
                    Parameters = @{
                        ImagePath = 'C:\WinPE-Workspace\Examples\batch-image.wim'
                        DeploymentType = 'ISO'
                        OutputPath = 'C:\WinPE-Workspace\Examples\batch-image.iso'
                    }
                }
            )
        }
        
        # Save configuration
        $configPath = "C:\WinPE-Workspace\Examples\batch-config.json"
        $batchConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
        
        Write-Host "Configuration saved to: $configPath`n"
        Write-Host "Executing batch operations..." -ForegroundColor Yellow
        
        # Execute batch operations
        $results = Invoke-WinPEBatchOperation -ConfigurationFile $configPath
        
        Write-Host "`n✓ Batch operation completed!" -ForegroundColor Green
        Write-Host "Total Operations: $($results.Count)"
        Write-Host "Successful: $(($results | Where-Object { $_.Status -eq 'Success' }).Count)" -ForegroundColor Green
        Write-Host "Failed: $(($results | Where-Object { $_.Status -eq 'Failed' }).Count)" -ForegroundColor Red
        
        return $results
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Example 7: USB Bootable Drive Creation

<#
.EXAMPLE 7: USB BOOTABLE DRIVE CREATION
Create a bootable USB drive for WinPE deployment
#>

function Example7-BootableUSB {
    param(
        [Parameter(Mandatory)]
        [string]$DriveLetter,
        
        [switch]$Force
    )
    
    try {
        Write-Host "Example 7: Bootable USB Creation" -ForegroundColor Cyan
        Write-Host "=================================`n"
        
        # Import required modules
        Import-Module ".\Modules\01-Image-Builder\Build-WinPEImage.psm1" -Force
        Import-Module ".\Modules\08-Deployment-Automation\Deploy-WinPEImage.psm1" -Force
        
        $imagePath = "C:\WinPE-Workspace\Examples\usb-image.wim"
        
        # Step 1: Build image
        Write-Host "[1/2] Building WinPE image for USB..." -ForegroundColor Yellow
        if (-not (Test-Path $imagePath)) {
            New-WinPEImage -ADKPath "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit" `
                          -Architecture amd64 `
                          -OutputPath $imagePath
        }
        
        # Step 2: Deploy to USB
        Write-Host "[2/2] Creating bootable USB drive..." -ForegroundColor Yellow
        Write-Warning "This will ERASE all data on drive $DriveLetter`:"
        
        if (-not $Force) {
            $confirmation = Read-Host "Continue? (Y/N)"
            if ($confirmation -ne 'Y') {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                return
            }
        }
        
        $deployment = Deploy-WinPEImage -ImagePath $imagePath `
                                       -DeploymentType USB `
                                       -OutputPath $DriveLetter `
                                       -Force:$Force
        
        Write-Host "`n✓ Bootable USB created successfully!" -ForegroundColor Green
        Write-Host "Drive: $DriveLetter`:"
        Write-Host "Label: WinPE"
        Write-Host "`nYou can now boot from this USB drive."
        
        return $deployment
    }
    catch {
        Write-Host "✗ Failed: $_" -ForegroundColor Red
        throw
    }
}

#endregion

#region Main Menu

function Show-ExamplesMenu {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          WinPE PowerBuilder Suite v2.0                        ║" -ForegroundColor Cyan
    Write-Host "║          Examples Collection                                  ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Quick WinPE Build (Basic)" -ForegroundColor White
    Write-Host "2. Customized Corporate Image" -ForegroundColor White
    Write-Host "3. Recovery Environment with BitLocker" -ForegroundColor White
    Write-Host "4. Automated Testing Pipeline" -ForegroundColor White
    Write-Host "5. Multi-Site Deployment" -ForegroundColor White
    Write-Host "6. Batch Operation from JSON" -ForegroundColor White
    Write-Host "7. Bootable USB Creation" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor Yellow
    Write-Host ""
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    while ($true) {
        Show-ExamplesMenu
        $choice = Read-Host "Select example to run"
        
        switch ($choice) {
            '1' { Example1-QuickBuild; Read-Host "`nPress Enter to continue" }
            '2' { Example2-CorporateImage; Read-Host "`nPress Enter to continue" }
            '3' { Example3-RecoveryEnvironment; Read-Host "`nPress Enter to continue" }
            '4' { Example4-TestingPipeline; Read-Host "`nPress Enter to continue" }
            '5' { Example5-MultiSiteDeployment; Read-Host "`nPress Enter to continue" }
            '6' { Example6-BatchOperation; Read-Host "`nPress Enter to continue" }
            '7' { 
                $drive = Read-Host "Enter USB drive letter (e.g., F)"
                Example7-BootableUSB -DriveLetter $drive
                Read-Host "`nPress Enter to continue"
            }
            '0' { 
                Write-Host "`nGoodbye!" -ForegroundColor Cyan
                break
            }
            default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
        }
        
        if ($choice -eq '0') { break }
    }
}

#endregion
