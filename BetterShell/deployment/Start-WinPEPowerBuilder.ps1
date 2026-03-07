<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Main Launcher
    
.DESCRIPTION
    Primary entry point for the WinPE PowerBuilder Suite. This script provides:
    - Quick access to all suite features
    - Module verification and loading
    - Interactive console launch
    - Example scripts execution
    - System requirements validation
    
.PARAMETER Mode
    Launch mode: Console (interactive), Examples, or Help
    
.PARAMETER ExampleNumber
    When using Examples mode, specify which example to run (1-7)
    
.EXAMPLE
    .\Start-WinPEPowerBuilder.ps1
    Launches the interactive console
    
.EXAMPLE
    .\Start-WinPEPowerBuilder.ps1 -Mode Examples
    Shows available examples
    
.EXAMPLE
    .\Start-WinPEPowerBuilder.ps1 -Mode Examples -ExampleNumber 1
    Runs Example 1 (Quick Build)
    
.NOTES
    Author: Con's Development Team
    Version: 2.0.0
    Requires: PowerShell 5.1+, Administrator rights
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [ValidateSet('Console', 'Examples', 'Help')]
    [string]$Mode = 'Console',
    
    [ValidateRange(1, 7)]
    [int]$ExampleNumber
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Initialization

$script:SuiteVersion = '2.0.0'
$script:SuitePath = $PSScriptRoot

function Show-Banner {
    $banner = @"

╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║              WinPE PowerBuilder Suite v$script:SuiteVersion                           ║
║              Enterprise WinPE Image Management                            ║
║                                                                           ║
║              © Con's Development Team                                     ║
║              150 Skilled Developers                                       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Test-SystemRequirements {
    Write-Host "Validating system requirements..." -ForegroundColor Yellow
    
    $requirements = @{
        'PowerShell Version' = @{
            Test = { $PSVersionTable.PSVersion.Major -ge 5 -and $PSVersionTable.PSVersion.Minor -ge 1 }
            Message = "PowerShell 5.1 or higher required"
        }
        'Administrator Rights' = @{
            Test = { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
            Message = "Administrator rights required"
        }
        'Operating System' = @{
            Test = { [Environment]::OSVersion.Version.Major -ge 10 }
            Message = "Windows 10/Server 2016 or higher required"
        }
        'DISM Available' = @{
            Test = { Get-Command DISM.exe -ErrorAction SilentlyContinue }
            Message = "DISM must be available"
        }
    }
    
    $failed = @()
    
    foreach ($req in $requirements.GetEnumerator()) {
        $result = & $req.Value.Test
        
        if ($result) {
            Write-Host "  ✓ $($req.Key)" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ $($req.Key): $($req.Value.Message)" -ForegroundColor Red
            $failed += $req.Key
        }
    }
    
    if ($failed.Count -gt 0) {
        Write-Host "`nSystem requirements not met. Please address the issues above." -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n✓ All system requirements met!`n" -ForegroundColor Green
    return $true
}

function Test-ModuleStructure {
    Write-Host "Verifying module structure..." -ForegroundColor Yellow
    
    $requiredModules = @(
        'Modules\01-Image-Builder\Build-WinPEImage.psm1',
        'Modules\02-Driver-Integration\Manage-WinPEDrivers.psm1',
        'Modules\03-Customization\Customize-WinPEImage.psm1',
        'Modules\04-Boot-Configuration\Configure-WinPEBoot.psm1',
        'Modules\05-Recovery-Environment\Build-RecoveryEnvironment.psm1',
        'Modules\06-Package-Management\Manage-WinPEPackages.psm1',
        'Modules\07-Testing-Validation\Test-WinPEImage.psm1',
        'Modules\08-Deployment-Automation\Deploy-WinPEImage.psm1'
    )
    
    $consoleModule = 'Console\WinPE-Console.psm1'
    $examplesScript = 'Examples\Complete-Examples.ps1'
    
    $allFiles = $requiredModules + $consoleModule + $examplesScript
    $missing = @()
    
    foreach ($file in $allFiles) {
        $fullPath = Join-Path $script:SuitePath $file
        
        if (Test-Path $fullPath) {
            Write-Host "  ✓ $file" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ $file" -ForegroundColor Red
            $missing += $file
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "`nSome modules are missing. Please ensure complete installation." -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n✓ All modules present!`n" -ForegroundColor Green
    return $true
}

function Show-QuickHelp {
    $help = @"

WinPE PowerBuilder Suite v$script:SuiteVersion - Quick Reference

LAUNCH MODES:
  Console      Launch interactive console (default)
  Examples     Run example scripts
  Help         Show this help message

USAGE EXAMPLES:
  .\Start-WinPEPowerBuilder.ps1
      Launch interactive console

  .\Start-WinPEPowerBuilder.ps1 -Mode Examples
      Show available examples

  .\Start-WinPEPowerBuilder.ps1 -Mode Examples -ExampleNumber 1
      Run specific example (Quick Build)

MODULES AVAILABLE:
  01 - Image Builder          : Create and manage WinPE images
  02 - Driver Integration     : Add and manage drivers
  03 - Customization          : Apply customizations and branding
  04 - Boot Configuration     : Configure boot settings
  05 - Recovery Environment   : Build WinRE images
  06 - Package Management     : Manage Windows packages
  07 - Testing & Validation   : Test image integrity and boot
  08 - Deployment Automation  : Deploy to USB, ISO, VHD, WDS

QUICK START:
  1. Run this script to launch the interactive console
  2. Select an option from the main menu
  3. Follow the prompts for each operation
  4. Review logs in %APPDATA%\WinPE-PowerBuilder\Logs

DOCUMENTATION:
  README.md           - Comprehensive guide
  PROJECT-STATUS.md   - Project completion status
  Examples\           - Practical example scripts

SUPPORT:
  Contact Con's Development Team for assistance

"@
    Write-Host $help -ForegroundColor White
}

function Show-WelcomeMessage {
    Write-Host "Welcome to WinPE PowerBuilder Suite!" -ForegroundColor Green
    Write-Host ""
    Write-Host "This enterprise toolkit provides comprehensive WinPE management with:" -ForegroundColor Gray
    Write-Host "  • 8 specialized modules for complete WinPE lifecycle" -ForegroundColor Gray
    Write-Host "  • Interactive console for easy access" -ForegroundColor Gray
    Write-Host "  • Batch automation for complex workflows" -ForegroundColor Gray
    Write-Host "  • Testing and validation framework" -ForegroundColor Gray
    Write-Host "  • Multi-site deployment capabilities" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Getting Started:" -ForegroundColor Yellow
    Write-Host "  1. The interactive console will launch automatically" -ForegroundColor Gray
    Write-Host "  2. Choose from the menu options" -ForegroundColor Gray
    Write-Host "  3. Follow the prompts for each operation" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Need help? Type 'help' in the console or run:" -ForegroundColor Yellow
    Write-Host "  .\Start-WinPEPowerBuilder.ps1 -Mode Help" -ForegroundColor Gray
    Write-Host ""
}

#endregion

#region Main Execution

try {
    # Show banner
    Show-Banner
    
    # Handle help mode
    if ($Mode -eq 'Help') {
        Show-QuickHelp
        return
    }
    
    # Validate system requirements
    if (-not (Test-SystemRequirements)) {
        Write-Host "`nPlease resolve the issues above and try again." -ForegroundColor Yellow
        return
    }
    
    # Verify module structure
    if (-not (Test-ModuleStructure)) {
        Write-Host "`nPlease ensure all modules are properly installed." -ForegroundColor Yellow
        return
    }
    
    # Execute based on mode
    switch ($Mode) {
        'Console' {
            Show-WelcomeMessage
            
            # Import and start console
            Write-Host "Loading interactive console..." -ForegroundColor Cyan
            
            $consolePath = Join-Path $script:SuitePath 'Console\WinPE-Console.psm1'
            Import-Module $consolePath -Force
            
            Start-WinPEConsole
        }
        
        'Examples' {
            $examplesPath = Join-Path $script:SuitePath 'Examples\Complete-Examples.ps1'
            
            if ($ExampleNumber) {
                Write-Host "Running Example $ExampleNumber..." -ForegroundColor Cyan
                
                # Dot-source the examples file
                . $examplesPath
                
                # Run specific example
                switch ($ExampleNumber) {
                    1 { Example1-QuickBuild }
                    2 { Example2-CorporateImage }
                    3 { Example3-RecoveryEnvironment }
                    4 { Example4-TestingPipeline }
                    5 { Example5-MultiSiteDeployment }
                    6 { Example6-BatchOperation }
                    7 { 
                        $drive = Read-Host "Enter USB drive letter (e.g., F)"
                        Example7-BootableUSB -DriveLetter $drive
                    }
                }
            }
            else {
                # Launch examples menu
                Write-Host "Loading examples..." -ForegroundColor Cyan
                & $examplesPath
            }
        }
    }
    
    Write-Host "`n" -NoNewline
}
catch {
    Write-Host "`nAn error occurred: $_" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    
    Write-Host "`nFor support, please contact the development team." -ForegroundColor Yellow
    exit 1
}

#endregion
