<#
.SYNOPSIS
    WinPE PowerBuilder - Build Orchestration Script
    Main build automation and integration script for WinPE creation

.DESCRIPTION
    This script orchestrates the complete WinPE build process including:
    - Environment validation
    - Module loading and integration
    - Image creation and customization
    - Driver integration
    - Network and storage configuration
    - Testing and validation
    - Report generation
    - Package deployment

.NOTES
    Script: Build-WinPEImage.ps1
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK, Administrator privileges
    
.EXAMPLE
    .\Build-WinPEImage.ps1 -Architecture x64 -OutputPath "C:\WinPE" -IncludeDrivers -RunTests
    
.EXAMPLE
    .\Build-WinPEImage.ps1 -ConfigFile ".\BuildConfig.json" -GenerateReport
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('x86', 'x64', 'arm64')]
    [string]$Architecture = 'x64',
    
    [Parameter()]
    [string]$OutputPath = "C:\WinPE_Build",
    
    [Parameter()]
    [string]$WorkingDirectory = "C:\WinPE_Working",
    
    [Parameter()]
    [string]$MountDirectory = "C:\WinPE_Mount",
    
    [Parameter()]
    [string]$ConfigFile,
    
    [Parameter()]
    [string]$DriverPath,
    
    [Parameter()]
    [switch]$IncludeDrivers,
    
    [Parameter()]
    [switch]$IncludeNetworking,
    
    [Parameter()]
    [switch]$IncludeStorage,
    
    [Parameter()]
    [switch]$RunTests,
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [switch]$CreateISO,
    
    [Parameter()]
    [switch]$CreateUSB,
    
    [Parameter()]
    [string]$USBDriveLetter,
    
    [Parameter()]
    [switch]$SkipCleanup,
    
    [Parameter()]
    [ValidateSet('Minimal', 'Standard', 'Full')]
    [string]$BuildProfile = 'Standard'
)

#region Module Initialization

$ErrorActionPreference = 'Stop'
$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-Build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:BuildStartTime = Get-Date

# Module paths
$script:ModulePaths = @{
    Deploy = Join-Path $ModuleRoot "Modules\Deploy-Automation.psm1"
    Customization = Join-Path $ModuleRoot "Modules\Image-Customization.psm1"
    Network = Join-Path $ModuleRoot "Modules\Network-Configuration.psm1"
    Storage = Join-Path $ModuleRoot "Modules\Storage-Management.psm1"
    Testing = Join-Path $ModuleRoot "Modules\Testing-Framework.psm1"
    Reporting = Join-Path $ModuleRoot "Modules\Reporting-Module.psm1"
}

# Build statistics
$script:BuildStats = @{
    StartTime = $script:BuildStartTime
    EndTime = $null
    Duration = $null
    TotalSteps = 0
    CompletedSteps = 0
    FailedSteps = 0
    Warnings = @()
    Errors = @()
    ImagePath = $null
    ImageSize = 0
    DriversInstalled = 0
    PackagesInstalled = 0
}

#endregion

#region Logging Functions

function Write-BuildLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Step')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
        'Step'    { 'Cyan' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

function Write-BuildStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StepName,
        
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [switch]$Optional
    )
    
    $script:BuildStats.TotalSteps++
    
    try {
        Write-Host "`n=== $StepName ===" -ForegroundColor Cyan
        Write-BuildLog "Starting: $StepName" -Level Step
        
        $result = & $ScriptBlock
        
        $script:BuildStats.CompletedSteps++
        Write-BuildLog "Completed: $StepName" -Level Success
        
        return $result
    }
    catch {
        $script:BuildStats.FailedSteps++
        $script:BuildStats.Errors += "Step '$StepName': $_"
        
        if ($Optional) {
            Write-BuildLog "Optional step failed: $StepName - $_" -Level Warning
            $script:BuildStats.Warnings += "Optional step '$StepName' failed: $_"
        } else {
            Write-BuildLog "Critical step failed: $StepName - $_" -Level Error
            throw
        }
    }
}

#endregion

#region Environment Validation

function Test-BuildEnvironment {
    [CmdletBinding()]
    param()
    
    Write-BuildLog "Validating build environment" -Level Info
    
    # Check for Windows ADK
    $adkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
    if (-not (Test-Path $adkPath)) {
        throw "Windows ADK not found. Please install Windows ADK with WinPE add-on."
    }
    Write-BuildLog "Windows ADK found: $adkPath" -Level Success
    
    # Check for DISM
    $dismPath = Join-Path $env:SystemRoot "System32\dism.exe"
    if (-not (Test-Path $dismPath)) {
        throw "DISM not found at $dismPath"
    }
    Write-BuildLog "DISM found: $dismPath" -Level Success
    
    # Check free disk space
    $systemDrive = (Get-Item $env:SystemRoot).PSDrive.Name
    $freeSpace = (Get-PSDrive -Name $systemDrive).Free / 1GB
    if ($freeSpace -lt 10) {
        throw "Insufficient disk space. At least 10GB free space required. Current: $([Math]::Round($freeSpace, 2))GB"
    }
    Write-BuildLog "Free disk space: $([Math]::Round($freeSpace, 2))GB" -Level Success
    
    # Check administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "This script requires administrator privileges"
    }
    Write-BuildLog "Administrator privileges confirmed" -Level Success
    
    # Check and load modules
    foreach ($module in $script:ModulePaths.GetEnumerator()) {
        if (Test-Path $module.Value) {
            Import-Module $module.Value -Force -ErrorAction Stop
            Write-BuildLog "Module loaded: $($module.Key)" -Level Success
        } else {
            throw "Module not found: $($module.Value)"
        }
    }
    
    Write-BuildLog "Environment validation completed" -Level Success
}

#endregion

#region Configuration Management

function Get-BuildConfiguration {
    [CmdletBinding()]
    param()
    
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        Write-BuildLog "Loading configuration from: $ConfigFile" -Level Info
        $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    } else {
        Write-BuildLog "Using default configuration" -Level Info
        $config = [PSCustomObject]@{
            Architecture = $Architecture
            OutputPath = $OutputPath
            WorkingDirectory = $WorkingDirectory
            MountDirectory = $MountDirectory
            BuildProfile = $BuildProfile
            IncludeDrivers = $IncludeDrivers.IsPresent
            IncludeNetworking = $IncludeNetworking.IsPresent
            IncludeStorage = $IncludeStorage.IsPresent
            DriverPath = $DriverPath
            Packages = @()
            CustomizationSettings = @{
                WallpaperPath = $null
                CompanyName = "WinPE PowerBuilder"
                SupportInfo = $null
            }
        }
    }
    
    # Override with command-line parameters
    if ($PSBoundParameters.ContainsKey('Architecture')) { $config.Architecture = $Architecture }
    if ($PSBoundParameters.ContainsKey('OutputPath')) { $config.OutputPath = $OutputPath }
    if ($PSBoundParameters.ContainsKey('IncludeDrivers')) { $config.IncludeDrivers = $IncludeDrivers.IsPresent }
    
    return $config
}

function Set-BuildProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Profile
    )
    
    $packages = switch ($Profile) {
        'Minimal' {
            @('WinPE-WMI', 'WinPE-Scripting', 'WinPE-PowerShell')
        }
        'Standard' {
            @('WinPE-WMI', 'WinPE-NetFx', 'WinPE-Scripting', 'WinPE-PowerShell',
              'WinPE-StorageWMI', 'WinPE-DismCmdlets')
        }
        'Full' {
            @('WinPE-WMI', 'WinPE-NetFx', 'WinPE-Scripting', 'WinPE-PowerShell',
              'WinPE-StorageWMI', 'WinPE-DismCmdlets', 'WinPE-EnhancedStorage',
              'WinPE-FMAPI', 'WinPE-SecureStartup', 'WinPE-Setup')
        }
    }
    
    Write-BuildLog "Build profile '$Profile' includes $($packages.Count) packages" -Level Info
    return $packages
}

#endregion

#region Build Process

function Initialize-BuildEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )
    
    # Create working directories
    @($Config.OutputPath, $Config.WorkingDirectory, $Config.MountDirectory) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
            Write-BuildLog "Created directory: $_" -Level Info
        } else {
            Write-BuildLog "Directory exists: $_" -Level Info
        }
    }
    
    # Copy WinPE base files
    $adkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
    $sourceWim = Join-Path $adkPath "$($Config.Architecture)\en-us\winpe.wim"
    
    if (-not (Test-Path $sourceWim)) {
        throw "WinPE base image not found: $sourceWim"
    }
    
    $destinationWim = Join-Path $Config.WorkingDirectory "boot.wim"
    Copy-Item -Path $sourceWim -Destination $destinationWim -Force
    
    Write-BuildLog "WinPE base image copied to: $destinationWim" -Level Success
    
    return $destinationWim
}

function Mount-WinPEImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [string]$MountPath
    )
    
    Write-BuildLog "Mounting WinPE image: $ImagePath" -Level Info
    
    # Ensure mount directory is empty
    if (Test-Path $MountPath) {
        Get-ChildItem -Path $MountPath | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Mount-WindowsImage -ImagePath $ImagePath -Index 1 -Path $MountPath -ErrorAction Stop
    
    Write-BuildLog "WinPE image mounted at: $MountPath" -Level Success
}

function Add-WinPEPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [array]$Packages,
        
        [Parameter(Mandatory)]
        [string]$Architecture
    )
    
    $adkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
    $packagePath = Join-Path $adkPath "$Architecture\WinPE_OCs"
    
    $installedCount = 0
    
    foreach ($package in $Packages) {
        $cabFile = Join-Path $packagePath "$package.cab"
        
        if (Test-Path $cabFile) {
            Write-BuildLog "Adding package: $package" -Level Info
            
            Add-WindowsPackage -Path $MountPath -PackagePath $cabFile -ErrorAction Stop
            
            # Add language pack if exists
            $langCab = Join-Path $packagePath "en-us\${package}_en-us.cab"
            if (Test-Path $langCab) {
                Add-WindowsPackage -Path $MountPath -PackagePath $langCab -ErrorAction Stop
            }
            
            $installedCount++
            $script:BuildStats.PackagesInstalled++
        } else {
            Write-BuildLog "Package not found: $cabFile" -Level Warning
            $script:BuildStats.Warnings += "Package not found: $package"
        }
    }
    
    Write-BuildLog "Installed $installedCount packages" -Level Success
}

function Add-WinPEDrivers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [string]$DriverPath
    )
    
    if (-not (Test-Path $DriverPath)) {
        Write-BuildLog "Driver path not found: $DriverPath" -Level Warning
        return
    }
    
    Write-BuildLog "Adding drivers from: $DriverPath" -Level Info
    
    $drivers = Get-ChildItem -Path $DriverPath -Filter *.inf -Recurse
    
    foreach ($driver in $drivers) {
        try {
            Add-WindowsDriver -Path $MountPath -Driver $driver.FullName -ErrorAction Stop
            $script:BuildStats.DriversInstalled++
        }
        catch {
            Write-BuildLog "Failed to add driver: $($driver.Name) - $_" -Level Warning
            $script:BuildStats.Warnings += "Driver installation failed: $($driver.Name)"
        }
    }
    
    Write-BuildLog "Installed $($script:BuildStats.DriversInstalled) drivers" -Level Success
}

function Invoke-WinPECustomization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [object]$Settings
    )
    
    Write-BuildLog "Applying customizations" -Level Info
    
    # Apply wallpaper if specified
    if ($Settings.WallpaperPath -and (Test-Path $Settings.WallpaperPath)) {
        Copy-Item -Path $Settings.WallpaperPath -Destination (Join-Path $MountPath "Windows\System32\winpe.jpg") -Force
        Write-BuildLog "Wallpaper applied" -Level Success
    }
    
    # Create unattend.xml with customizations
    $unattendPath = Join-Path $MountPath "Windows\System32\unattend.xml"
    
    $unattendXml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1024</HorizontalResolution>
                <VerticalResolution>768</VerticalResolution>
            </Display>
        </component>
    </settings>
</unattend>
"@
    
    $unattendXml | Set-Content -Path $unattendPath -Force
    Write-BuildLog "Unattend.xml created" -Level Success
    
    # Create custom startnet.cmd
    $startnetPath = Join-Path $MountPath "Windows\System32\startnet.cmd"
    
    $startnetContent = @"
@echo off
echo WinPE PowerBuilder Suite
echo.
wpeinit
echo.
echo WinPE environment initialized
echo Company: $($Settings.CompanyName)
echo.
"@
    
    $startnetContent | Set-Content -Path $startnetPath -Force
    Write-BuildLog "Startnet.cmd customized" -Level Success
}

function Dismount-WinPEImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [switch]$Discard
    )
    
    Write-BuildLog "Dismounting WinPE image" -Level Info
    
    if ($Discard) {
        Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop
        Write-BuildLog "Image discarded (not saved)" -Level Warning
    } else {
        Dismount-WindowsImage -Path $MountPath -Save -ErrorAction Stop
        Write-BuildLog "Image saved and dismounted" -Level Success
    }
}

function New-WinPEISO {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkingDirectory,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter(Mandatory)]
        [string]$Architecture
    )
    
    Write-BuildLog "Creating bootable ISO" -Level Info
    
    $adkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit"
    $oscdimgPath = Join-Path $adkPath "Deployment Tools\$Architecture\Oscdimg\oscdimg.exe"
    
    if (-not (Test-Path $oscdimgPath)) {
        throw "Oscdimg.exe not found at: $oscdimgPath"
    }
    
    $isoPath = Join-Path $OutputPath "WinPE_$Architecture.iso"
    $etfsboot = Join-Path $adkPath "Deployment Tools\$Architecture\Oscdimg\etfsboot.com"
    $efisys = Join-Path $adkPath "Deployment Tools\$Architecture\Oscdimg\efisys.bin"
    
    # Create ISO media structure
    $mediaPath = Join-Path $WorkingDirectory "media"
    if (-not (Test-Path $mediaPath)) {
        New-Item -Path $mediaPath -ItemType Directory -Force | Out-Null
    }
    
    # Copy boot files
    $bootWim = Join-Path $WorkingDirectory "boot.wim"
    $bootPath = Join-Path $mediaPath "sources"
    New-Item -Path $bootPath -ItemType Directory -Force | Out-Null
    Copy-Item -Path $bootWim -Destination (Join-Path $bootPath "boot.wim") -Force
    
    # Create ISO
    $arguments = @(
        "-m"
        "-o"
        "-u2"
        "-udfver102"
        "-bootdata:2#p0,e,b$etfsboot#pEF,e,b$efisys"
        "`"$mediaPath`""
        "`"$isoPath`""
    )
    
    $process = Start-Process -FilePath $oscdimgPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-BuildLog "ISO created successfully: $isoPath" -Level Success
        $script:BuildStats.ImagePath = $isoPath
        $script:BuildStats.ImageSize = (Get-Item $isoPath).Length
        return $isoPath
    } else {
        throw "Failed to create ISO (Exit code: $($process.ExitCode))"
    }
}

function New-WinPEUSB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkingDirectory,
        
        [Parameter(Mandatory)]
        [string]$DriveLetter
    )
    
    Write-BuildLog "Creating bootable USB drive: $DriveLetter" -Level Info
    
    # Format USB drive
    Format-Volume -DriveLetter $DriveLetter -FileSystem FAT32 -NewFileSystemLabel "WinPE" -Confirm:$false -ErrorAction Stop
    
    # Copy WinPE files
    $bootWim = Join-Path $WorkingDirectory "boot.wim"
    $usbBootPath = "${DriveLetter}:\sources"
    New-Item -Path $usbBootPath -ItemType Directory -Force | Out-Null
    Copy-Item -Path $bootWim -Destination (Join-Path $usbBootPath "boot.wim") -Force
    
    # Make bootable
    $bootsectPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\BCDBoot\bootsect.exe"
    if (Test-Path $bootsectPath) {
        & $bootsectPath /nt60 "${DriveLetter}:" /mbr /force
    }
    
    Write-BuildLog "USB drive created successfully: ${DriveLetter}:" -Level Success
}

#endregion

#region Testing and Reporting

function Invoke-WinPETests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [string]$MountPath
    )
    
    Write-BuildLog "Running WinPE tests" -Level Info
    
    $testResults = Invoke-WinPETestSuite -ImagePath $ImagePath -MountPath $MountPath -TestLevel Full
    
    if ($testResults.PassRate -ge 80) {
        Write-BuildLog "Tests passed with $($testResults.PassRate)% success rate" -Level Success
    } else {
        Write-BuildLog "Tests completed with $($testResults.PassRate)% success rate (below 80% threshold)" -Level Warning
        $script:BuildStats.Warnings += "Test pass rate below 80%: $($testResults.PassRate)%"
    }
    
    return $testResults
}

function New-WinPEBuildReport {
    [CmdletBinding()]
    param()
    
    Write-BuildLog "Generating build report" -Level Info
    
    $script:BuildStats.EndTime = Get-Date
    $script:BuildStats.Duration = $script:BuildStats.EndTime - $script:BuildStats.StartTime
    
    $reportData = [PSCustomObject]@{
        BuildID = (New-Guid).ToString()
        StartTime = $script:BuildStats.StartTime
        EndTime = $script:BuildStats.EndTime
        Duration = $script:BuildStats.Duration
        TotalSteps = $script:BuildStats.TotalSteps
        CompletedSteps = $script:BuildStats.CompletedSteps
        FailedSteps = $script:BuildStats.FailedSteps
        SuccessRate = if ($script:BuildStats.TotalSteps -gt 0) {
            [Math]::Round(($script:BuildStats.CompletedSteps / $script:BuildStats.TotalSteps) * 100, 2)
        } else { 0 }
        Architecture = $Architecture
        BuildProfile = $BuildProfile
        ImagePath = $script:BuildStats.ImagePath
        ImageSize = $script:BuildStats.ImageSize
        PackagesInstalled = $script:BuildStats.PackagesInstalled
        DriversInstalled = $script:BuildStats.DriversInstalled
        Warnings = $script:BuildStats.Warnings
        Errors = $script:BuildStats.Errors
    }
    
    $reportPath = New-WinPEDeploymentReport -DeploymentData $reportData -Format HTML
    
    Write-BuildLog "Build report generated: $reportPath" -Level Success
    
    return $reportPath
}

#endregion

#region Main Build Process

function Start-WinPEBuild {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "WinPE PowerBuilder - Build Orchestration" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        # Step 1: Validate environment
        Write-BuildStep -StepName "Environment Validation" -ScriptBlock {
            Test-BuildEnvironment
        }
        
        # Step 2: Load configuration
        $config = Write-BuildStep -StepName "Configuration Loading" -ScriptBlock {
            Get-BuildConfiguration
        }
        
        # Step 3: Determine packages
        $packages = Write-BuildStep -StepName "Build Profile Setup" -ScriptBlock {
            Set-BuildProfile -Profile $config.BuildProfile
        }
        
        # Step 4: Initialize build environment
        $imagePath = Write-BuildStep -StepName "Build Environment Initialization" -ScriptBlock {
            Initialize-BuildEnvironment -Config $config
        }
        
        # Step 5: Mount WinPE image
        Write-BuildStep -StepName "Mount WinPE Image" -ScriptBlock {
            Mount-WinPEImage -ImagePath $imagePath -MountPath $config.MountDirectory
        }
        
        # Step 6: Add packages
        Write-BuildStep -StepName "Add WinPE Packages" -ScriptBlock {
            Add-WinPEPackages -MountPath $config.MountDirectory -Packages $packages -Architecture $config.Architecture
        }
        
        # Step 7: Add drivers (optional)
        if ($config.IncludeDrivers -and $config.DriverPath) {
            Write-BuildStep -StepName "Add Drivers" -ScriptBlock {
                Add-WinPEDrivers -MountPath $config.MountDirectory -DriverPath $config.DriverPath
            } -Optional
        }
        
        # Step 8: Apply customizations
        Write-BuildStep -StepName "Apply Customizations" -ScriptBlock {
            Invoke-WinPECustomization -MountPath $config.MountDirectory -Settings $config.CustomizationSettings
        }
        
        # Step 9: Dismount and save image
        Write-BuildStep -StepName "Save WinPE Image" -ScriptBlock {
            Dismount-WinPEImage -MountPath $config.MountDirectory
        }
        
        # Step 10: Create ISO (if requested)
        if ($CreateISO) {
            Write-BuildStep -StepName "Create Bootable ISO" -ScriptBlock {
                New-WinPEISO -WorkingDirectory $config.WorkingDirectory -OutputPath $config.OutputPath -Architecture $config.Architecture
            }
        }
        
        # Step 11: Create USB (if requested)
        if ($CreateUSB -and $USBDriveLetter) {
            Write-BuildStep -StepName "Create Bootable USB" -ScriptBlock {
                New-WinPEUSB -WorkingDirectory $config.WorkingDirectory -DriveLetter $USBDriveLetter
            }
        }
        
        # Step 12: Run tests (if requested)
        if ($RunTests) {
            Write-BuildStep -StepName "Run Validation Tests" -ScriptBlock {
                Invoke-WinPETests -ImagePath $imagePath -MountPath $config.MountDirectory
            } -Optional
        }
        
        # Step 13: Generate report (if requested)
        if ($GenerateReport) {
            Write-BuildStep -StepName "Generate Build Report" -ScriptBlock {
                New-WinPEBuildReport
            }
        }
        
        # Build completed
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "Build Completed Successfully!" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Green
        
        Write-BuildLog "Total steps: $($script:BuildStats.TotalSteps)" -Level Info
        Write-BuildLog "Completed: $($script:BuildStats.CompletedSteps)" -Level Success
        Write-BuildLog "Failed: $($script:BuildStats.FailedSteps)" -Level $(if ($script:BuildStats.FailedSteps -gt 0) { 'Warning' } else { 'Info' })
        Write-BuildLog "Duration: $($script:BuildStats.Duration.TotalMinutes) minutes" -Level Info
        
        if ($script:BuildStats.ImagePath) {
            Write-BuildLog "Output: $($script:BuildStats.ImagePath)" -Level Success
        }
    }
    catch {
        Write-BuildLog "Build failed: $_" -Level Error
        
        # Attempt cleanup
        if ((Test-Path $config.MountDirectory) -and (Get-WindowsImage -Mounted | Where-Object { $_.Path -eq $config.MountDirectory })) {
            Write-BuildLog "Attempting to dismount image..." -Level Warning
            Dismount-WinPEImage -MountPath $config.MountDirectory -Discard
        }
        
        throw
    }
    finally {
        # Cleanup (unless skipped)
        if (-not $SkipCleanup -and $config.WorkingDirectory -and (Test-Path $config.WorkingDirectory)) {
            Write-BuildLog "Cleaning up working directory" -Level Info
            # Remove-Item -Path $config.WorkingDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-BuildLog "Build log saved to: $script:LogPath" -Level Info
    }
}

#endregion

# Execute build
Start-WinPEBuild
