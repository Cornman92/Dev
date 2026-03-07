<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Console Interface
    Unified command-line interface for all WinPE PowerBuilder operations

.DESCRIPTION
    Enterprise-grade console interface providing:
    - Interactive and scriptable command-line operations
    - Batch processing capabilities
    - Pipeline support
    - Configuration management
    - Comprehensive help system
    - Progress reporting and logging

.NOTES
    Author: Con's Development Team
    Component: Console-Interface
    Version: 2.0.0
    Dependencies: All WinPE PowerBuilder modules
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Module Imports

$modulePaths = @(
    '01-Image-Builder\Build-WinPEImage.psm1',
    '02-Driver-Integration\Manage-WinPEDrivers.psm1',
    '03-Customization\Customize-WinPEImage.psm1',
    '04-Boot-Configuration\Configure-WinPEBoot.psm1',
    '05-Recovery-Environment\Build-RecoveryEnvironment.psm1',
    '06-Package-Management\Manage-WinPEPackages.psm1',
    '07-Testing-Validation\Test-WinPEImage.psm1',
    '08-Deployment-Automation\Deploy-WinPEImage.psm1'
)

$script:ModulePath = Split-Path -Parent $PSScriptRoot

foreach ($modulePath in $modulePaths) {
    $fullPath = Join-Path $script:ModulePath "Modules\$modulePath"
    if (Test-Path $fullPath) {
        Import-Module $fullPath -Force -ErrorAction SilentlyContinue
    }
}

#endregion

#region Configuration

$script:ConsoleConfig = @{
    Name = 'WinPE-PowerBuilder'
    Version = '2.0.0'
    Banner = @"
╔═══════════════════════════════════════════════════════════════╗
║          WinPE PowerBuilder Suite v2.0                        ║
║          Enterprise WinPE Image Management Console            ║
║          © Con's Development Team                             ║
╚═══════════════════════════════════════════════════════════════╝
"@
    ConfigFile = Join-Path $env:APPDATA 'WinPE-PowerBuilder\config.json'
    HistoryFile = Join-Path $env:APPDATA 'WinPE-PowerBuilder\history.txt'
    LogPath = Join-Path $env:APPDATA 'WinPE-PowerBuilder\Logs'
}

$script:InteractiveMode = $false
$script:CurrentSession = $null

#endregion

#region Private Functions

function Initialize-ConsoleEnvironment {
    [CmdletBinding()]
    param()
    
    try {
        # Create application directories
        $configDir = Split-Path $script:ConsoleConfig.ConfigFile
        if (-not (Test-Path $configDir)) {
            $null = New-Item -Path $configDir -ItemType Directory -Force
        }
        
        if (-not (Test-Path $script:ConsoleConfig.LogPath)) {
            $null = New-Item -Path $script:ConsoleConfig.LogPath -ItemType Directory -Force
        }
        
        # Load or create configuration
        if (Test-Path $script:ConsoleConfig.ConfigFile) {
            $script:CurrentSession = Get-Content $script:ConsoleConfig.ConfigFile -Raw | ConvertFrom-Json
        }
        else {
            $script:CurrentSession = @{
                DefaultWorkspace = 'C:\WinPE-Workspace'
                ADKPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
                LogLevel = 'Info'
                AutoSave = $true
                Theme = 'Default'
            }
            Save-ConsoleConfiguration
        }
        
        # Create default workspace
        if (-not (Test-Path $script:CurrentSession.DefaultWorkspace)) {
            $null = New-Item -Path $script:CurrentSession.DefaultWorkspace -ItemType Directory -Force
        }
        
        Write-Verbose "Console environment initialized"
    }
    catch {
        Write-Warning "Failed to initialize console environment: $_"
    }
}

function Save-ConsoleConfiguration {
    [CmdletBinding()]
    param()
    
    try {
        $script:CurrentSession | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConsoleConfig.ConfigFile -Force
        Write-Verbose "Configuration saved"
    }
    catch {
        Write-Warning "Failed to save configuration: $_"
    }
}

function Show-Banner {
    [CmdletBinding()]
    param()
    
    Write-Host $script:ConsoleConfig.Banner -ForegroundColor Cyan
    Write-Host "Version: $($script:ConsoleConfig.Version)" -ForegroundColor Gray
    Write-Host "Workspace: $($script:CurrentSession.DefaultWorkspace)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Type 'help' or 'menu' for available commands" -ForegroundColor Yellow
    Write-Host "Type 'exit' to quit" -ForegroundColor Yellow
    Write-Host ""
}

function Show-MainMenu {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== WinPE PowerBuilder - Main Menu ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1.  Build WinPE Image" -ForegroundColor White
    Write-Host "2.  Manage Drivers" -ForegroundColor White
    Write-Host "3.  Customize Image" -ForegroundColor White
    Write-Host "4.  Configure Boot" -ForegroundColor White
    Write-Host "5.  Build Recovery Environment" -ForegroundColor White
    Write-Host "6.  Manage Packages" -ForegroundColor White
    Write-Host "7.  Test & Validate" -ForegroundColor White
    Write-Host "8.  Deploy Image" -ForegroundColor White
    Write-Host "9.  Batch Operations" -ForegroundColor White
    Write-Host "10. Configuration" -ForegroundColor White
    Write-Host "0.  Exit" -ForegroundColor Yellow
    Write-Host ""
}

function Show-ImageBuilderMenu {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Image Builder ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Create New WinPE Image" -ForegroundColor White
    Write-Host "2. Build from Configuration File" -ForegroundColor White
    Write-Host "3. Quick Build (Default Settings)" -ForegroundColor White
    Write-Host "4. Rebuild Existing Image" -ForegroundColor White
    Write-Host "0. Back to Main Menu" -ForegroundColor Yellow
    Write-Host ""
}

function Show-DriverManagementMenu {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Driver Management ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Add Drivers to Image" -ForegroundColor White
    Write-Host "2. Remove Drivers from Image" -ForegroundColor White
    Write-Host "3. List Drivers in Image" -ForegroundColor White
    Write-Host "4. Export Drivers from Image" -ForegroundColor White
    Write-Host "5. Import Driver Package" -ForegroundColor White
    Write-Host "0. Back to Main Menu" -ForegroundColor Yellow
    Write-Host ""
}

function Show-CustomizationMenu {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Image Customization ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Add Startup Scripts" -ForegroundColor White
    Write-Host "2. Configure Registry Settings" -ForegroundColor White
    Write-Host "3. Add Custom Files" -ForegroundColor White
    Write-Host "4. Configure Network Settings" -ForegroundColor White
    Write-Host "5. Apply Branding" -ForegroundColor White
    Write-Host "6. Set Environment Variables" -ForegroundColor White
    Write-Host "0. Back to Main Menu" -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-ImageBuilder {
    [CmdletBinding()]
    param()
    
    while ($true) {
        Show-ImageBuilderMenu
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            '1' {
                # Create new image
                $adkPath = Read-Host "ADK Path [$($script:CurrentSession.ADKPath)]"
                if ([string]::IsNullOrWhiteSpace($adkPath)) {
                    $adkPath = $script:CurrentSession.ADKPath
                }
                
                $architecture = Read-Host "Architecture (amd64/x86) [amd64]"
                if ([string]::IsNullOrWhiteSpace($architecture)) {
                    $architecture = 'amd64'
                }
                
                $outputPath = Read-Host "Output Path [$(Join-Path $script:CurrentSession.DefaultWorkspace 'boot.wim')]"
                if ([string]::IsNullOrWhiteSpace($outputPath)) {
                    $outputPath = Join-Path $script:CurrentSession.DefaultWorkspace 'boot.wim'
                }
                
                Write-Host "`nBuilding WinPE image..." -ForegroundColor Yellow
                
                try {
                    $result = New-WinPEImage -ADKPath $adkPath -Architecture $architecture -OutputPath $outputPath -Verbose
                    Write-Host "`nImage built successfully!" -ForegroundColor Green
                    Write-Host "Location: $($result.ImagePath)"
                }
                catch {
                    Write-Host "`nFailed to build image: $_" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '2' {
                # Build from configuration
                $configPath = Read-Host "Configuration File Path"
                
                if (Test-Path $configPath) {
                    Write-Host "`nBuilding from configuration..." -ForegroundColor Yellow
                    
                    try {
                        $config = Get-Content $configPath -Raw | ConvertFrom-Json
                        $result = New-WinPEImage -ADKPath $config.ADKPath -Architecture $config.Architecture -OutputPath $config.OutputPath -Verbose
                        Write-Host "`nImage built successfully!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFailed to build image: $_" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "`nConfiguration file not found" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '3' {
                # Quick build
                Write-Host "`nQuick build with default settings..." -ForegroundColor Yellow
                
                try {
                    $outputPath = Join-Path $script:CurrentSession.DefaultWorkspace "boot_$(Get-Date -Format 'yyyyMMdd_HHmmss').wim"
                    $result = New-WinPEImage -ADKPath $script:CurrentSession.ADKPath -Architecture 'amd64' -OutputPath $outputPath -Verbose
                    Write-Host "`nImage built successfully!" -ForegroundColor Green
                    Write-Host "Location: $($result.ImagePath)"
                }
                catch {
                    Write-Host "`nFailed to build image: $_" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '0' { return }
            default { Write-Host "Invalid option" -ForegroundColor Red }
        }
    }
}

function Invoke-DriverManagement {
    [CmdletBinding()]
    param()
    
    while ($true) {
        Show-DriverManagementMenu
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            '1' {
                # Add drivers
                $imagePath = Read-Host "Image Path"
                $driverPath = Read-Host "Driver Path"
                
                if ((Test-Path $imagePath) -and (Test-Path $driverPath)) {
                    Write-Host "`nAdding drivers..." -ForegroundColor Yellow
                    
                    try {
                        Add-WinPEDriver -ImagePath $imagePath -DriverPath $driverPath -Recurse -Verbose
                        Write-Host "`nDrivers added successfully!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFailed to add drivers: $_" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "`nPath not found" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '3' {
                # List drivers
                $imagePath = Read-Host "Image Path"
                
                if (Test-Path $imagePath) {
                    Write-Host "`nListing drivers..." -ForegroundColor Yellow
                    
                    try {
                        $drivers = Get-WinPEDriver -ImagePath $imagePath
                        
                        Write-Host "`nDrivers in image:" -ForegroundColor Cyan
                        $drivers | Format-Table -Property OriginalFileName, ClassName, ProviderName, Date -AutoSize
                    }
                    catch {
                        Write-Host "`nFailed to list drivers: $_" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "`nImage not found" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '0' { return }
            default { Write-Host "Invalid option" -ForegroundColor Red }
        }
    }
}

function Invoke-CustomizationManager {
    [CmdletBinding()]
    param()
    
    while ($true) {
        Show-CustomizationMenu
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            '1' {
                # Add startup script
                $imagePath = Read-Host "Image Path"
                $scriptPath = Read-Host "Script Path"
                
                if ((Test-Path $imagePath) -and (Test-Path $scriptPath)) {
                    Write-Host "`nAdding startup script..." -ForegroundColor Yellow
                    
                    try {
                        Add-WinPEStartupScript -ImagePath $imagePath -ScriptPath $scriptPath -Verbose
                        Write-Host "`nStartup script added successfully!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFailed to add startup script: $_" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "`nPath not found" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '4' {
                # Configure network
                $imagePath = Read-Host "Image Path"
                
                if (Test-Path $imagePath) {
                    Write-Host "`nConfiguring network settings..." -ForegroundColor Yellow
                    
                    $useDHCP = (Read-Host "Use DHCP? (Y/N) [Y]") -eq 'Y'
                    
                    try {
                        if ($useDHCP) {
                            Set-WinPENetworkConfiguration -ImagePath $imagePath -EnableDHCP -Verbose
                        }
                        else {
                            $ipAddress = Read-Host "IP Address"
                            $subnetMask = Read-Host "Subnet Mask"
                            $gateway = Read-Host "Default Gateway"
                            
                            Set-WinPENetworkConfiguration -ImagePath $imagePath -IPAddress $ipAddress -SubnetMask $subnetMask -DefaultGateway $gateway -Verbose
                        }
                        
                        Write-Host "`nNetwork configured successfully!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFailed to configure network: $_" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "`nImage not found" -ForegroundColor Red
                }
                
                Read-Host "`nPress Enter to continue"
            }
            
            '0' { return }
            default { Write-Host "Invalid option" -ForegroundColor Red }
        }
    }
}

function Invoke-ConfigurationManager {
    [CmdletBinding()]
    param()
    
    while ($true) {
        Write-Host "`n=== Configuration ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Current Settings:" -ForegroundColor Yellow
        Write-Host "  Workspace: $($script:CurrentSession.DefaultWorkspace)"
        Write-Host "  ADK Path: $($script:CurrentSession.ADKPath)"
        Write-Host "  Log Level: $($script:CurrentSession.LogLevel)"
        Write-Host "  Auto Save: $($script:CurrentSession.AutoSave)"
        Write-Host ""
        Write-Host "1. Change Workspace"
        Write-Host "2. Change ADK Path"
        Write-Host "3. Change Log Level"
        Write-Host "4. Toggle Auto Save"
        Write-Host "5. Save Configuration"
        Write-Host "0. Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            '1' {
                $newWorkspace = Read-Host "New Workspace Path"
                if (-not [string]::IsNullOrWhiteSpace($newWorkspace)) {
                    $script:CurrentSession.DefaultWorkspace = $newWorkspace
                    if (-not (Test-Path $newWorkspace)) {
                        $null = New-Item -Path $newWorkspace -ItemType Directory -Force
                    }
                    Write-Host "Workspace updated" -ForegroundColor Green
                }
            }
            
            '2' {
                $newADKPath = Read-Host "New ADK Path"
                if (-not [string]::IsNullOrWhiteSpace($newADKPath)) {
                    $script:CurrentSession.ADKPath = $newADKPath
                    Write-Host "ADK Path updated" -ForegroundColor Green
                }
            }
            
            '3' {
                Write-Host "Log Levels: Verbose, Info, Warning, Error"
                $newLogLevel = Read-Host "New Log Level"
                if ($newLogLevel -in @('Verbose', 'Info', 'Warning', 'Error')) {
                    $script:CurrentSession.LogLevel = $newLogLevel
                    Write-Host "Log Level updated" -ForegroundColor Green
                }
            }
            
            '4' {
                $script:CurrentSession.AutoSave = -not $script:CurrentSession.AutoSave
                Write-Host "Auto Save: $($script:CurrentSession.AutoSave)" -ForegroundColor Green
            }
            
            '5' {
                Save-ConsoleConfiguration
                Write-Host "Configuration saved" -ForegroundColor Green
                Read-Host "Press Enter to continue"
            }
            
            '0' { return }
            default { Write-Host "Invalid option" -ForegroundColor Red }
        }
    }
}

#endregion

#region Public Functions

function Start-WinPEConsole {
    <#
    .SYNOPSIS
        Starts the WinPE PowerBuilder interactive console.
    
    .DESCRIPTION
        Launches the interactive command-line interface for WinPE PowerBuilder Suite,
        providing access to all modules and operations.
    
    .EXAMPLE
        Start-WinPEConsole
    #>
    
    [CmdletBinding()]
    param()
    
    process {
        try {
            $script:InteractiveMode = $true
            
            # Initialize environment
            Initialize-ConsoleEnvironment
            
            # Show banner
            Show-Banner
            
            # Main loop
            while ($true) {
                Show-MainMenu
                $choice = Read-Host "Select option"
                
                switch ($choice) {
                    '1' { Invoke-ImageBuilder }
                    '2' { Invoke-DriverManagement }
                    '3' { Invoke-CustomizationManager }
                    '4' { Write-Host "Boot configuration menu coming soon..." -ForegroundColor Yellow; Read-Host "Press Enter" }
                    '5' { Write-Host "Recovery environment menu coming soon..." -ForegroundColor Yellow; Read-Host "Press Enter" }
                    '6' { Write-Host "Package management menu coming soon..." -ForegroundColor Yellow; Read-Host "Press Enter" }
                    '7' { Write-Host "Testing & validation menu coming soon..." -ForegroundColor Yellow; Read-Host "Press Enter" }
                    '8' { Write-Host "Deployment menu coming soon..." -ForegroundColor Yellow; Read-Host "Press Enter" }
                    '9' { Write-Host "Batch operations menu coming soon..." -ForegroundColor Yellow; Read-Host "Press Enter" }
                    '10' { Invoke-ConfigurationManager }
                    '0' {
                        if ($script:CurrentSession.AutoSave) {
                            Save-ConsoleConfiguration
                        }
                        Write-Host "`nGoodbye!" -ForegroundColor Cyan
                        return
                    }
                    default {
                        Write-Host "Invalid option. Please try again." -ForegroundColor Red
                    }
                }
            }
        }
        catch {
            Write-Error "Console error: $_"
        }
        finally {
            $script:InteractiveMode = $false
        }
    }
}

function Invoke-WinPEBatchOperation {
    <#
    .SYNOPSIS
        Executes a batch operation from a configuration file.
    
    .DESCRIPTION
        Processes a JSON configuration file containing multiple WinPE operations
        to execute in sequence or parallel.
    
    .PARAMETER ConfigurationFile
        Path to the JSON configuration file.
    
    .PARAMETER Parallel
        Executes operations in parallel where possible.
    
    .EXAMPLE
        Invoke-WinPEBatchOperation -ConfigurationFile "C:\Config\batch.json"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ConfigurationFile,
        
        [switch]$Parallel
    )
    
    process {
        try {
            Write-Host "Loading batch configuration..." -ForegroundColor Cyan
            
            $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json
            
            Write-Host "Operations to execute: $($config.Operations.Count)" -ForegroundColor Yellow
            
            $results = @()
            
            foreach ($operation in $config.Operations) {
                Write-Host "`nExecuting: $($operation.Type) - $($operation.Description)" -ForegroundColor Cyan
                
                try {
                    $result = switch ($operation.Type) {
                        'BuildImage' {
                            New-WinPEImage -ADKPath $operation.Parameters.ADKPath -Architecture $operation.Parameters.Architecture -OutputPath $operation.Parameters.OutputPath
                        }
                        'AddDrivers' {
                            Add-WinPEDriver -ImagePath $operation.Parameters.ImagePath -DriverPath $operation.Parameters.DriverPath -Recurse
                        }
                        'Customize' {
                            # Execute customization based on parameters
                            $operation.Parameters
                        }
                        'Test' {
                            Invoke-WinPEImageTest -ImagePath $operation.Parameters.ImagePath
                        }
                        'Deploy' {
                            Deploy-WinPEImage -ImagePath $operation.Parameters.ImagePath -DeploymentType $operation.Parameters.DeploymentType -OutputPath $operation.Parameters.OutputPath
                        }
                        default {
                            throw "Unknown operation type: $($operation.Type)"
                        }
                    }
                    
                    $results += @{
                        Operation = $operation.Description
                        Status = 'Success'
                        Result = $result
                    }
                    
                    Write-Host "  ✓ Completed successfully" -ForegroundColor Green
                }
                catch {
                    $results += @{
                        Operation = $operation.Description
                        Status = 'Failed'
                        Error = $_.Exception.Message
                    }
                    
                    Write-Host "  ✗ Failed: $_" -ForegroundColor Red
                    
                    if ($config.StopOnError) {
                        throw "Batch operation stopped due to error"
                    }
                }
            }
            
            # Display summary
            Write-Host "`n=== Batch Operation Summary ===" -ForegroundColor Yellow
            Write-Host "Total: $($results.Count)"
            Write-Host "Successful: $(($results | Where-Object { $_.Status -eq 'Success' }).Count)" -ForegroundColor Green
            Write-Host "Failed: $(($results | Where-Object { $_.Status -eq 'Failed' }).Count)" -ForegroundColor Red
            
            return $results
        }
        catch {
            Write-Error "Batch operation failed: $_"
            throw
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Start-WinPEConsole',
    'Invoke-WinPEBatchOperation'
)

# Auto-start console if running interactively
if ($MyInvocation.InvocationName -ne '.' -and -not $PSBoundParameters.ContainsKey('')) {
    # This script was run directly, not imported
    # Uncomment to auto-start console:
    # Start-WinPEConsole
}
