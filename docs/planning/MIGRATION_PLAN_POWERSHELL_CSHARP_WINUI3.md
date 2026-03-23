# Better11 Migration Plan: PowerShell Backend + C# Frontend + WinUI 3 GUI

**Version**: 1.0  
**Date**: December 10, 2025  
**Status**: Planning Phase  
**Goal**: Migrate Better11 to native Windows technologies while preserving all Python code

---

## 📋 Executive Summary

This plan outlines the migration of Better11 from Python-based implementation to a hybrid architecture:

- **Backend**: PowerShell modules for all system operations
- **Frontend**: C# libraries for business logic and orchestration
- **GUI**: WinUI 3 application with MVVM architecture
- **Legacy**: All existing Python code remains intact for backward compatibility

### Key Objectives

1. ✅ **Preserve Python codebase** - No changes to existing Python implementation
2. ✅ **PowerShell Backend** - Native Windows PowerShell modules for system operations
3. ✅ **C# Frontend** - Modern C# libraries for application logic
4. ✅ **WinUI 3 GUI** - Beautiful, native Windows 11 UI with MVVM pattern
5. ✅ **100% Feature Parity** - All features from Python version implemented
6. ✅ **Interoperability** - C# can call PowerShell backend seamlessly

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interfaces                          │
│  ┌──────────────────────┐          ┌──────────────────────┐     │
│  │   WinUI 3 GUI        │          │   CLI (pwsh)         │     │
│  │   (C# + XAML)        │          │   (PowerShell)       │     │
│  │   MVVM Architecture  │          │                      │     │
│  └──────────┬───────────┘          └──────────┬───────────┘     │
└─────────────┼──────────────────────────────────┼─────────────────┘
              │                                  │
              └──────────────┬───────────────────┘
                             │
┌─────────────────────────────┼─────────────────────────────────────┐
│                    C# Frontend Layer (.NET 8)                      │
│             ┌───────────────▼──────────────┐                      │
│             │   Better11.Core              │                      │
│             │   - Models                   │                      │
│             │   - Services                 │                      │
│             │   - Interfaces               │                      │
│             └───────┬──────────────────────┘                      │
│                     │                                             │
│      ┌──────────────┼──────────────┬──────────────┐              │
│      │              │              │              │              │
│  ┌───▼────────┐ ┌──▼──────────┐ ┌─▼──────────┐ ┌─▼───────────┐ │
│  │AppManager  │ │SystemTools  │ │Config      │ │ PowerShell  │ │
│  │Service     │ │Service      │ │Manager     │ │ Executor    │ │
│  └────────────┘ └─────────────┘ └────────────┘ └──────┬──────┘ │
└──────────────────────────────────────────────────────┼──────────┘
              │
┌─────────────┼─────────────────────────────────────────────────────┐
│        PowerShell Backend Layer (Modules)                          │
│   ┌─────────▼──────────────────────────────────────────────────┐  │
│   │  Better11.psm1 (Main Module)                               │  │
│   ├────────────────────────────────────────────────────────────┤  │
│   │  ├── Better11.AppManager.psm1                              │  │
│   │  │   ├── Get-Better11Apps                                  │  │
│   │  │   ├── Install-Better11App                               │  │
│   │  │   ├── Uninstall-Better11App                             │  │
│   │  │   └── Update-Better11App                                │  │
│   │  │                                                          │  │
│   │  ├── Better11.SystemTools.psm1                             │  │
│   │  │   ├── Set-Better11RegistryTweak                         │  │
│   │  │   ├── Remove-Better11Bloatware                          │  │
│   │  │   ├── Set-Better11Service                               │  │
│   │  │   ├── Set-Better11PerformancePreset                     │  │
│   │  │   ├── Set-Better11PrivacySetting                        │  │
│   │  │   └── Manage-Better11Startup                            │  │
│   │  │                                                          │  │
│   │  ├── Better11.Updates.psm1                                 │  │
│   │  │   ├── Get-Better11WindowsUpdate                         │  │
│   │  │   ├── Install-Better11WindowsUpdate                     │  │
│   │  │   └── Set-Better11UpdatePolicy                          │  │
│   │  │                                                          │  │
│   │  ├── Better11.Security.psm1                                │  │
│   │  │   ├── Test-Better11CodeSignature                        │  │
│   │  │   ├── Get-Better11CertificateInfo                       │  │
│   │  │   └── New-Better11RestorePoint                          │  │
│   │  │                                                          │  │
│   │  └── Better11.Common.psm1                                  │  │
│   │      ├── Confirm-Better11Action                            │  │
│   │      ├── Backup-Better11Registry                           │  │
│   │      ├── Write-Better11Log                                 │  │
│   │      └── Test-Better11Administrator                        │  │
│   └────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
              │
┌─────────────┼─────────────────────────────────────────────────────┐
│        Windows OS Layer                                            │
│   ┌─────────▼──────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐     │
│   │  Registry      │  │AppX     │  │Services │  │msiexec   │     │
│   │  APIs          │  │(DISM)   │  │(sc.exe) │  │          │     │
│   └────────────────┘  └──────────┘  └─────────┘  └──────────┘     │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📁 New Directory Structure

```
better11/
├── python/                          # EXISTING: All Python code (unchanged)
│   ├── better11/
│   │   ├── apps/
│   │   ├── cli.py
│   │   ├── gui.py
│   │   └── config.py
│   ├── system_tools/
│   └── tests/
│
├── powershell/                      # NEW: PowerShell backend modules
│   ├── Better11/
│   │   ├── Better11.psd1           # Module manifest
│   │   ├── Better11.psm1           # Main module
│   │   ├── Modules/
│   │   │   ├── AppManager/
│   │   │   │   ├── AppManager.psd1
│   │   │   │   ├── AppManager.psm1
│   │   │   │   └── Functions/
│   │   │   │       ├── Public/
│   │   │   │       │   ├── Get-Better11Apps.ps1
│   │   │   │       │   ├── Install-Better11App.ps1
│   │   │   │       │   ├── Uninstall-Better11App.ps1
│   │   │   │       │   └── Update-Better11App.ps1
│   │   │   │       └── Private/
│   │   │   │           ├── Get-AppMetadata.ps1
│   │   │   │           ├── Download-AppInstaller.ps1
│   │   │   │           └── Invoke-Installer.ps1
│   │   │   │
│   │   │   ├── SystemTools/
│   │   │   │   ├── SystemTools.psd1
│   │   │   │   ├── SystemTools.psm1
│   │   │   │   └── Functions/
│   │   │   │       ├── Public/
│   │   │   │       │   ├── Set-Better11RegistryTweak.ps1
│   │   │   │       │   ├── Remove-Better11Bloatware.ps1
│   │   │   │       │   ├── Set-Better11Service.ps1
│   │   │   │       │   ├── Set-Better11PerformancePreset.ps1
│   │   │   │       │   ├── Set-Better11PrivacySetting.ps1
│   │   │   │       │   └── Manage-Better11Startup.ps1
│   │   │   │       └── Private/
│   │   │   │           ├── Backup-RegistryKey.ps1
│   │   │   │           └── New-RestorePoint.ps1
│   │   │   │
│   │   │   ├── Updates/
│   │   │   │   ├── Updates.psd1
│   │   │   │   ├── Updates.psm1
│   │   │   │   └── Functions/
│   │   │   │       └── Public/
│   │   │   │           ├── Get-Better11WindowsUpdate.ps1
│   │   │   │           ├── Install-Better11WindowsUpdate.ps1
│   │   │   │           └── Set-Better11UpdatePolicy.ps1
│   │   │   │
│   │   │   ├── Security/
│   │   │   │   ├── Security.psd1
│   │   │   │   ├── Security.psm1
│   │   │   │   └── Functions/
│   │   │   │       └── Public/
│   │   │   │           ├── Test-Better11CodeSignature.ps1
│   │   │   │           ├── Get-Better11CertificateInfo.ps1
│   │   │   │           └── Verify-FileHash.ps1
│   │   │   │
│   │   │   └── Common/
│   │   │       ├── Common.psd1
│   │   │       ├── Common.psm1
│   │   │       └── Functions/
│   │   │           └── Public/
│   │   │               ├── Confirm-Better11Action.ps1
│   │   │               ├── Write-Better11Log.ps1
│   │   │               └── Test-Better11Administrator.ps1
│   │   │
│   │   ├── Data/
│   │   │   └── catalog.json        # App catalog
│   │   │
│   │   └── Tests/
│   │       ├── AppManager.Tests.ps1
│   │       ├── SystemTools.Tests.ps1
│   │       └── Security.Tests.ps1
│   │
│   ├── Scripts/
│   │   ├── Install-Better11Module.ps1
│   │   └── Import-Better11.ps1
│   │
│   └── README.md
│
├── csharp/                          # NEW: C# frontend
│   ├── Better11.sln                # Solution file
│   │
│   ├── Better11.Core/              # Core library
│   │   ├── Better11.Core.csproj
│   │   ├── Models/
│   │   │   ├── AppMetadata.cs
│   │   │   ├── AppStatus.cs
│   │   │   ├── RegistryTweak.cs
│   │   │   ├── ServiceAction.cs
│   │   │   ├── PerformancePreset.cs
│   │   │   ├── PrivacySetting.cs
│   │   │   └── WindowsFeature.cs
│   │   │
│   │   ├── Interfaces/
│   │   │   ├── IAppManager.cs
│   │   │   ├── ISystemToolsService.cs
│   │   │   ├── IUpdateService.cs
│   │   │   ├── ISecurityService.cs
│   │   │   └── IConfigService.cs
│   │   │
│   │   ├── Services/
│   │   │   ├── AppManagerService.cs
│   │   │   ├── SystemToolsService.cs
│   │   │   ├── UpdateService.cs
│   │   │   ├── SecurityService.cs
│   │   │   └── ConfigService.cs
│   │   │
│   │   ├── PowerShell/
│   │   │   ├── PowerShellExecutor.cs
│   │   │   └── PowerShellModuleLoader.cs
│   │   │
│   │   └── Utilities/
│   │       ├── Logger.cs
│   │       ├── FileHelper.cs
│   │       └── VersionHelper.cs
│   │
│   ├── Better11.WinUI/              # WinUI 3 GUI
│   │   ├── Better11.WinUI.csproj
│   │   ├── App.xaml
│   │   ├── App.xaml.cs
│   │   │
│   │   ├── Views/
│   │   │   ├── MainWindow.xaml
│   │   │   ├── MainWindow.xaml.cs
│   │   │   ├── ApplicationsPage.xaml
│   │   │   ├── ApplicationsPage.xaml.cs
│   │   │   ├── SystemToolsPage.xaml
│   │   │   ├── SystemToolsPage.xaml.cs
│   │   │   ├── UpdatesPage.xaml
│   │   │   ├── UpdatesPage.xaml.cs
│   │   │   ├── PrivacyPage.xaml
│   │   │   ├── PrivacyPage.xaml.cs
│   │   │   ├── StartupPage.xaml
│   │   │   ├── StartupPage.xaml.cs
│   │   │   ├── FeaturesPage.xaml
│   │   │   ├── FeaturesPage.xaml.cs
│   │   │   └── SettingsPage.xaml
│   │   │   └── SettingsPage.xaml.cs
│   │   │
│   │   ├── ViewModels/
│   │   │   ├── MainViewModel.cs
│   │   │   ├── ApplicationsViewModel.cs
│   │   │   ├── SystemToolsViewModel.cs
│   │   │   ├── UpdatesViewModel.cs
│   │   │   ├── PrivacyViewModel.cs
│   │   │   ├── StartupViewModel.cs
│   │   │   ├── FeaturesViewModel.cs
│   │   │   └── SettingsViewModel.cs
│   │   │
│   │   ├── Controls/
│   │   │   ├── AppCard.xaml
│   │   │   ├── ProgressCard.xaml
│   │   │   └── TweakToggle.xaml
│   │   │
│   │   ├── Converters/
│   │   │   ├── BoolToVisibilityConverter.cs
│   │   │   └── StatusToColorConverter.cs
│   │   │
│   │   ├── Assets/
│   │   │   └── (images, icons)
│   │   │
│   │   └── Strings/
│   │       └── en-US/
│   │           └── Resources.resw
│   │
│   ├── Better11.CLI/                # CLI application
│   │   ├── Better11.CLI.csproj
│   │   ├── Program.cs
│   │   └── Commands/
│   │       ├── AppCommands.cs
│   │       ├── SystemCommands.cs
│   │       └── UpdateCommands.cs
│   │
│   └── Better11.Tests/              # Unit tests
│       ├── Better11.Tests.csproj
│       ├── Services/
│       │   ├── AppManagerServiceTests.cs
│       │   └── SystemToolsServiceTests.cs
│       └── PowerShell/
│           └── PowerShellExecutorTests.cs
│
├── docs/                            # Documentation (updated)
│   ├── POWERSHELL_API.md
│   ├── CSHARP_API.md
│   └── WINUI3_GUIDE.md
│
└── README.md                        # Updated main readme
```

---

## 🔧 Phase 1: PowerShell Backend Implementation (4-6 weeks)

### 1.1 Core PowerShell Module Structure

#### Module Manifest (Better11.psd1)
```powershell
@{
    RootModule = 'Better11.psm1'
    ModuleVersion = '0.3.0'
    GUID = 'GENERATE-NEW-GUID'
    Author = 'Better11 Development Team'
    CompanyName = 'Better11'
    Copyright = '(c) 2025 Better11. MIT License.'
    Description = 'PowerShell backend for Better11 Windows enhancement toolkit'
    
    PowerShellVersion = '5.1'
    
    NestedModules = @(
        'Modules\AppManager\AppManager.psd1',
        'Modules\SystemTools\SystemTools.psd1',
        'Modules\Updates\Updates.psd1',
        'Modules\Security\Security.psd1',
        'Modules\Common\Common.psd1'
    )
    
    FunctionsToExport = @(
        # AppManager
        'Get-Better11Apps',
        'Install-Better11App',
        'Uninstall-Better11App',
        'Update-Better11App',
        'Get-Better11AppStatus',
        
        # SystemTools
        'Set-Better11RegistryTweak',
        'Remove-Better11Bloatware',
        'Set-Better11Service',
        'Set-Better11PerformancePreset',
        'Set-Better11PrivacySetting',
        'Set-Better11TelemetryLevel',
        'Manage-Better11Startup',
        'Get-Better11StartupItems',
        'Set-Better11WindowsFeature',
        
        # Updates
        'Get-Better11WindowsUpdate',
        'Install-Better11WindowsUpdate',
        'Set-Better11UpdatePolicy',
        
        # Security
        'Test-Better11CodeSignature',
        'Get-Better11CertificateInfo',
        'Verify-Better11FileHash',
        
        # Common
        'Confirm-Better11Action',
        'New-Better11RestorePoint',
        'Backup-Better11Registry',
        'Write-Better11Log'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
```

### 1.2 Application Manager Module (AppManager.psm1)

**File**: `powershell/Better11/Modules/AppManager/Functions/Public/Get-Better11Apps.ps1`

```powershell
function Get-Better11Apps {
    <#
    .SYNOPSIS
        Retrieves available applications from the Better11 catalog.
    
    .DESCRIPTION
        Lists all available applications that can be installed through Better11,
        including their metadata, versions, and installation status.
    
    .PARAMETER CatalogPath
        Path to the catalog JSON file. Defaults to module's Data directory.
    
    .PARAMETER Installed
        If specified, only returns installed applications.
    
    .PARAMETER Available
        If specified, only returns available (not installed) applications.
    
    .EXAMPLE
        Get-Better11Apps
        Lists all applications in the catalog.
    
    .EXAMPLE
        Get-Better11Apps -Installed
        Lists only installed applications.
    
    .OUTPUTS
        PSCustomObject[]
        Array of application metadata objects.
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter()]
        [string]$CatalogPath = "$PSScriptRoot\..\..\..\..\Data\catalog.json",
        
        [Parameter()]
        [switch]$Installed,
        
        [Parameter()]
        [switch]$Available
    )
    
    begin {
        Write-Better11Log -Message "Retrieving Better11 applications" -Level Info
    }
    
    process {
        try {
            # Load catalog
            if (-not (Test-Path $CatalogPath)) {
                throw "Catalog file not found: $CatalogPath"
            }
            
            $catalogData = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
            $apps = $catalogData.applications
            
            # Load installation state
            $statePath = "$env:USERPROFILE\.better11\installed.json"
            $installedApps = @{}
            
            if (Test-Path $statePath) {
                $stateData = Get-Content -Path $statePath -Raw | ConvertFrom-Json
                foreach ($app in $stateData.applications) {
                    $installedApps[$app.app_id] = $app
                }
            }
            
            # Process applications
            $results = foreach ($app in $apps) {
                $isInstalled = $installedApps.ContainsKey($app.app_id)
                
                # Filter based on parameters
                if ($Installed -and -not $isInstalled) { continue }
                if ($Available -and $isInstalled) { continue }
                
                [PSCustomObject]@{
                    AppId = $app.app_id
                    Name = $app.name
                    Version = $app.version
                    InstallerType = $app.installer_type
                    Description = $app.description
                    Installed = $isInstalled
                    InstalledVersion = if ($isInstalled) { $installedApps[$app.app_id].version } else { $null }
                    Uri = $app.uri
                    Dependencies = $app.dependencies
                }
            }
            
            return $results
        }
        catch {
            Write-Better11Log -Message "Failed to retrieve applications: $_" -Level Error
            throw
        }
    }
}
```

**File**: `powershell/Better11/Modules/AppManager/Functions/Public/Install-Better11App.ps1`

```powershell
function Install-Better11App {
    <#
    .SYNOPSIS
        Installs an application from the Better11 catalog.
    
    .DESCRIPTION
        Downloads, verifies, and installs an application along with its dependencies.
        Supports MSI, EXE, and AppX installers with automatic silent installation.
    
    .PARAMETER AppId
        The unique identifier of the application to install.
    
    .PARAMETER Force
        Skip confirmation prompts.
    
    .PARAMETER SkipDependencies
        Do not automatically install dependencies.
    
    .PARAMETER DryRun
        Simulate installation without actually installing.
    
    .EXAMPLE
        Install-Better11App -AppId "vscode"
        Installs Visual Studio Code with dependencies.
    
    .EXAMPLE
        Install-Better11App -AppId "chrome" -Force
        Installs Google Chrome without confirmation.
    
    .OUTPUTS
        PSCustomObject
        Installation result with status and details.
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$AppId,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$SkipDependencies,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    begin {
        Write-Better11Log -Message "Starting installation of $AppId" -Level Info
        
        # Check administrator privileges
        if (-not (Test-Better11Administrator)) {
            throw "Installation requires administrator privileges"
        }
    }
    
    process {
        try {
            # Get app metadata
            $app = Get-Better11Apps | Where-Object { $_.AppId -eq $AppId }
            if (-not $app) {
                throw "Application not found: $AppId"
            }
            
            # Check if already installed
            if ($app.Installed -and -not $Force) {
                Write-Better11Log -Message "$AppId is already installed" -Level Warning
                return [PSCustomObject]@{
                    Status = 'AlreadyInstalled'
                    AppId = $AppId
                    Version = $app.InstalledVersion
                }
            }
            
            # Confirm action
            if (-not $Force -and -not $DryRun) {
                $confirmed = Confirm-Better11Action -Prompt "Install $($app.Name) v$($app.Version)?"
                if (-not $confirmed) {
                    throw "Installation cancelled by user"
                }
            }
            
            # Create restore point
            if (-not $DryRun) {
                New-Better11RestorePoint -Description "Before installing $AppId"
            }
            
            # Install dependencies
            if (-not $SkipDependencies -and $app.Dependencies.Count -gt 0) {
                Write-Better11Log -Message "Installing dependencies for $AppId" -Level Info
                foreach ($depId in $app.Dependencies) {
                    Install-Better11App -AppId $depId -Force:$Force -DryRun:$DryRun
                }
            }
            
            # Download installer
            $installerPath = Get-AppInstaller -App $app -DryRun:$DryRun
            
            if (-not $DryRun) {
                # Verify hash
                Verify-Better11FileHash -FilePath $installerPath -ExpectedHash $app.sha256
                
                # Verify signature if required
                $sigResult = Test-Better11CodeSignature -FilePath $installerPath
                if (-not $sigResult.IsTrusted) {
                    Write-Better11Log -Message "Warning: Installer signature not trusted" -Level Warning
                }
                
                # Install
                $installResult = Invoke-Installer -App $app -InstallerPath $installerPath
                
                # Update state
                Update-InstallationState -AppId $AppId -Version $app.Version -Installed $true
                
                return [PSCustomObject]@{
                    Status = 'Success'
                    AppId = $AppId
                    Version = $app.Version
                    ExitCode = $installResult.ExitCode
                    Output = $installResult.Output
                }
            }
            else {
                return [PSCustomObject]@{
                    Status = 'DryRun'
                    AppId = $AppId
                    Version = $app.Version
                }
            }
        }
        catch {
            Write-Better11Log -Message "Installation failed for ${AppId}: $_" -Level Error
            throw
        }
    }
}
```

### 1.3 System Tools Module (SystemTools.psm1)

**File**: `powershell/Better11/Modules/SystemTools/Functions/Public/Set-Better11RegistryTweak.ps1`

```powershell
function Set-Better11RegistryTweak {
    <#
    .SYNOPSIS
        Applies registry tweaks with automatic backup.
    
    .DESCRIPTION
        Applies one or more registry modifications with safety features including
        automatic backup, restore point creation, and user confirmation.
    
    .PARAMETER Tweaks
        Array of registry tweak objects to apply.
    
    .PARAMETER Force
        Skip confirmation prompts.
    
    .PARAMETER NoBackup
        Skip registry backup (not recommended).
    
    .PARAMETER NoRestorePoint
        Skip restore point creation (not recommended).
    
    .EXAMPLE
        $tweak = @{
            Hive = 'HKCU'
            Path = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            Name = 'HideFileExt'
            Value = 0
            Type = 'DWord'
        }
        Set-Better11RegistryTweak -Tweaks $tweak
    
    .OUTPUTS
        PSCustomObject
        Result of the operation with applied tweaks.
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]$Tweaks,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$NoBackup,
        
        [Parameter()]
        [switch]$NoRestorePoint
    )
    
    begin {
        Write-Better11Log -Message "Applying registry tweaks" -Level Info
        
        # Check administrator
        if (-not (Test-Better11Administrator)) {
            throw "Registry modifications require administrator privileges"
        }
        
        # Create restore point
        if (-not $NoRestorePoint) {
            New-Better11RestorePoint -Description "Before registry tweaks"
        }
        
        $appliedTweaks = @()
        $backedUpPaths = @{}
    }
    
    process {
        foreach ($tweak in $Tweaks) {
            try {
                $fullPath = "$($tweak.Hive):\$($tweak.Path)"
                
                # Confirm
                if (-not $Force) {
                    $confirmed = Confirm-Better11Action -Prompt "Apply tweak to $fullPath\$($tweak.Name)?"
                    if (-not $confirmed) {
                        Write-Better11Log -Message "Tweak cancelled for $fullPath" -Level Warning
                        continue
                    }
                }
                
                # Backup registry key
                if (-not $NoBackup -and -not $backedUpPaths.ContainsKey($fullPath)) {
                    Backup-Better11Registry -KeyPath $fullPath
                    $backedUpPaths[$fullPath] = $true
                }
                
                # Ensure path exists
                if (-not (Test-Path $fullPath)) {
                    New-Item -Path $fullPath -Force | Out-Null
                }
                
                # Set value
                $valueType = switch ($tweak.Type) {
                    'String' { 'String' }
                    'DWord' { 'DWord' }
                    'QWord' { 'QWord' }
                    'Binary' { 'Binary' }
                    'MultiString' { 'MultiString' }
                    'ExpandString' { 'ExpandString' }
                    default { 'String' }
                }
                
                Set-ItemProperty -Path $fullPath -Name $tweak.Name -Value $tweak.Value -Type $valueType -Force
                
                Write-Better11Log -Message "Applied tweak: $fullPath\$($tweak.Name) = $($tweak.Value)" -Level Info
                
                $appliedTweaks += [PSCustomObject]@{
                    Path = $fullPath
                    Name = $tweak.Name
                    Value = $tweak.Value
                    Success = $true
                }
            }
            catch {
                Write-Better11Log -Message "Failed to apply tweak: $_" -Level Error
                
                $appliedTweaks += [PSCustomObject]@{
                    Path = $fullPath
                    Name = $tweak.Name
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
    }
    
    end {
        return [PSCustomObject]@{
            TotalTweaks = $Tweaks.Count
            AppliedSuccessfully = ($appliedTweaks | Where-Object Success).Count
            Failed = ($appliedTweaks | Where-Object { -not $_.Success }).Count
            Details = $appliedTweaks
        }
    }
}
```

### 1.4 Security Module (Security.psm1)

**File**: `powershell/Better11/Modules/Security/Functions/Public/Test-Better11CodeSignature.ps1`

```powershell
function Test-Better11CodeSignature {
    <#
    .SYNOPSIS
        Verifies the Authenticode signature of a file.
    
    .DESCRIPTION
        Checks if a file is digitally signed and validates the signature chain,
        expiration, and trust status.
    
    .PARAMETER FilePath
        Path to the file to verify.
    
    .PARAMETER CheckRevocation
        Check certificate revocation status (slower).
    
    .EXAMPLE
        Test-Better11CodeSignature -FilePath "C:\installer.exe"
    
    .OUTPUTS
        PSCustomObject
        Signature information including status and certificate details.
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$FilePath,
        
        [Parameter()]
        [switch]$CheckRevocation
    )
    
    process {
        try {
            Write-Better11Log -Message "Verifying signature for: $FilePath" -Level Info
            
            if (-not (Test-Path $FilePath)) {
                throw "File not found: $FilePath"
            }
            
            $signature = Get-AuthenticodeSignature -FilePath $FilePath
            
            $status = switch ($signature.Status) {
                'Valid' { 'Valid' }
                'NotSigned' { 'Unsigned' }
                'HashMismatch' { 'Invalid' }
                'NotTrusted' { 'Untrusted' }
                default { 'Unknown' }
            }
            
            $certificateInfo = if ($signature.SignerCertificate) {
                [PSCustomObject]@{
                    Subject = $signature.SignerCertificate.Subject
                    Issuer = $signature.SignerCertificate.Issuer
                    SerialNumber = $signature.SignerCertificate.SerialNumber
                    Thumbprint = $signature.SignerCertificate.Thumbprint
                    ValidFrom = $signature.SignerCertificate.NotBefore
                    ValidTo = $signature.SignerCertificate.NotAfter
                    IsExpired = (Get-Date) -gt $signature.SignerCertificate.NotAfter
                }
            } else {
                $null
            }
            
            return [PSCustomObject]@{
                Status = $status
                IsTrusted = ($status -eq 'Valid')
                Certificate = $certificateInfo
                Timestamp = $signature.TimeStamperCertificate.NotBefore
                HashAlgorithm = $signature.HashAlgorithm
                StatusMessage = $signature.StatusMessage
            }
        }
        catch {
            Write-Better11Log -Message "Signature verification failed: $_" -Level Error
            throw
        }
    }
}
```

### 1.5 Common Module (Common.psm1)

**File**: `powershell/Better11/Modules/Common/Functions/Public/Confirm-Better11Action.ps1`

```powershell
function Confirm-Better11Action {
    <#
    .SYNOPSIS
        Prompts the user to confirm an action.
    
    .DESCRIPTION
        Displays a confirmation prompt and returns true if user confirms.
    
    .PARAMETER Prompt
        The prompt message to display.
    
    .PARAMETER DefaultYes
        Default to Yes if user presses Enter.
    
    .EXAMPLE
        if (Confirm-Better11Action "Delete files?") {
            # Proceed with deletion
        }
    
    .OUTPUTS
        Boolean
        True if user confirmed, False otherwise.
    #>
    
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        
        [Parameter()]
        [switch]$DefaultYes
    )
    
    $choice = if ($DefaultYes) { 'Y/n' } else { 'y/N' }
    $response = Read-Host -Prompt "$Prompt [$choice]"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes.IsPresent
    }
    
    $confirmed = $response -match '^[yY]'
    
    if ($confirmed) {
        Write-Better11Log -Message "User confirmed: $Prompt" -Level Info
    } else {
        Write-Better11Log -Message "User declined: $Prompt" -Level Warning
    }
    
    return $confirmed
}
```

---

## 💻 Phase 2: C# Frontend Implementation (4-6 weeks)

### 2.1 Core Models

**File**: `csharp/Better11.Core/Models/AppMetadata.cs`

```csharp
using System;
using System.Collections.Generic;

namespace Better11.Core.Models
{
    /// <summary>
    /// Represents metadata for an application in the Better11 catalog.
    /// </summary>
    public class AppMetadata
    {
        public string AppId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string Uri { get; set; } = string.Empty;
        public string Sha256 { get; set; } = string.Empty;
        public InstallerType InstallerType { get; set; }
        public List<string> VettedDomains { get; set; } = new();
        public string? Signature { get; set; }
        public string? SignatureKey { get; set; }
        public List<string> Dependencies { get; set; } = new();
        public List<string> SilentArgs { get; set; } = new();
        public string? UninstallCommand { get; set; }
        public string? Description { get; set; }
        
        public bool DomainIsVetted(string hostname)
        {
            var normalizedHost = hostname.ToLowerInvariant();
            return VettedDomains.Exists(d => 
                d.Equals(normalizedHost, StringComparison.OrdinalIgnoreCase));
        }
        
        public bool RequiresSignatureVerification()
        {
            return !string.IsNullOrEmpty(Signature) && !string.IsNullOrEmpty(SignatureKey);
        }
    }
    
    public enum InstallerType
    {
        MSI,
        EXE,
        APPX
    }
}
```

**File**: `csharp/Better11.Core/Models/AppStatus.cs`

```csharp
using System;
using System.Collections.Generic;

namespace Better11.Core.Models
{
    /// <summary>
    /// Represents the installation status of an application.
    /// </summary>
    public class AppStatus
    {
        public string AppId { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string InstallerPath { get; set; } = string.Empty;
        public bool Installed { get; set; }
        public List<string> DependenciesInstalled { get; set; } = new();
        public DateTime InstalledDate { get; set; }
    }
}
```

**File**: `csharp/Better11.Core/Models/RegistryTweak.cs`

```csharp
using System;

namespace Better11.Core.Models
{
    /// <summary>
    /// Represents a registry modification.
    /// </summary>
    public class RegistryTweak
    {
        public string Hive { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public object Value { get; set; } = null!;
        public RegistryValueType ValueType { get; set; }
        
        public string FullPath => $"{Hive}\\{Path}";
    }
    
    public enum RegistryValueType
    {
        String = 1,
        ExpandString = 2,
        Binary = 3,
        DWord = 4,
        MultiString = 7,
        QWord = 11
    }
}
```

### 2.2 PowerShell Executor

**File**: `csharp/Better11.Core/PowerShell/PowerShellExecutor.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace Better11.Core.PowerShell
{
    /// <summary>
    /// Executes PowerShell commands and scripts with the Better11 module loaded.
    /// </summary>
    public class PowerShellExecutor : IDisposable
    {
        private readonly ILogger<PowerShellExecutor> _logger;
        private readonly Runspace _runspace;
        private bool _disposed = false;
        
        public PowerShellExecutor(ILogger<PowerShellExecutor> logger)
        {
            _logger = logger;
            
            // Create runspace
            var initialSessionState = InitialSessionState.CreateDefault();
            
            // Import Better11 module
            string modulePath = GetBetter11ModulePath();
            initialSessionState.ImportPSModule(new[] { modulePath });
            
            _runspace = RunspaceFactory.CreateRunspace(initialSessionState);
            _runspace.Open();
            
            _logger.LogInformation("PowerShell runspace created and Better11 module loaded");
        }
        
        /// <summary>
        /// Executes a PowerShell command and returns the results.
        /// </summary>
        public async Task<PSExecutionResult> ExecuteCommandAsync(string command, 
            Dictionary<string, object>? parameters = null)
        {
            try
            {
                _logger.LogDebug("Executing PowerShell command: {Command}", command);
                
                using var powershell = System.Management.Automation.PowerShell.Create();
                powershell.Runspace = _runspace;
                
                powershell.AddCommand(command);
                
                if (parameters != null)
                {
                    foreach (var param in parameters)
                    {
                        powershell.AddParameter(param.Key, param.Value);
                    }
                }
                
                var results = await Task.Run(() => powershell.Invoke());
                
                var errors = new List<string>();
                if (powershell.HadErrors)
                {
                    foreach (var error in powershell.Streams.Error)
                    {
                        errors.Add(error.ToString());
                        _logger.LogError("PowerShell error: {Error}", error);
                    }
                }
                
                var output = new List<object>();
                foreach (var result in results)
                {
                    output.Add(result.BaseObject);
                }
                
                return new PSExecutionResult
                {
                    Success = !powershell.HadErrors,
                    Output = output,
                    Errors = errors
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to execute PowerShell command: {Command}", command);
                throw;
            }
        }
        
        /// <summary>
        /// Executes a PowerShell script file.
        /// </summary>
        public async Task<PSExecutionResult> ExecuteScriptAsync(string scriptPath, 
            Dictionary<string, object>? parameters = null)
        {
            try
            {
                _logger.LogDebug("Executing PowerShell script: {Script}", scriptPath);
                
                using var powershell = System.Management.Automation.PowerShell.Create();
                powershell.Runspace = _runspace;
                
                powershell.AddCommand(scriptPath);
                
                if (parameters != null)
                {
                    powershell.AddParameters(parameters);
                }
                
                var results = await Task.Run(() => powershell.Invoke());
                
                var errors = new List<string>();
                if (powershell.HadErrors)
                {
                    foreach (var error in powershell.Streams.Error)
                    {
                        errors.Add(error.ToString());
                    }
                }
                
                var output = new List<object>();
                foreach (var result in results)
                {
                    output.Add(result.BaseObject);
                }
                
                return new PSExecutionResult
                {
                    Success = !powershell.HadErrors,
                    Output = output,
                    Errors = errors
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to execute PowerShell script: {Script}", scriptPath);
                throw;
            }
        }
        
        private string GetBetter11ModulePath()
        {
            // Get path relative to assembly location
            var assemblyDir = AppDomain.CurrentDomain.BaseDirectory;
            var modulePath = System.IO.Path.Combine(assemblyDir, 
                "..", "..", "..", "powershell", "Better11", "Better11.psd1");
            
            return System.IO.Path.GetFullPath(modulePath);
        }
        
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
        
        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    _runspace?.Dispose();
                }
                _disposed = true;
            }
        }
    }
    
    public class PSExecutionResult
    {
        public bool Success { get; set; }
        public List<object> Output { get; set; } = new();
        public List<string> Errors { get; set; } = new();
    }
}
```

### 2.3 App Manager Service

**File**: `csharp/Better11.Core/Services/AppManagerService.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Better11.Core.Interfaces;
using Better11.Core.Models;
using Better11.Core.PowerShell;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace Better11.Core.Services
{
    /// <summary>
    /// Service for managing application installation and updates.
    /// Communicates with PowerShell backend to perform operations.
    /// </summary>
    public class AppManagerService : IAppManager
    {
        private readonly PowerShellExecutor _psExecutor;
        private readonly ILogger<AppManagerService> _logger;
        
        public AppManagerService(
            PowerShellExecutor psExecutor,
            ILogger<AppManagerService> logger)
        {
            _psExecutor = psExecutor;
            _logger = logger;
        }
        
        /// <summary>
        /// Lists all available applications from the catalog.
        /// </summary>
        public async Task<List<AppMetadata>> ListAvailableAppsAsync()
        {
            try
            {
                _logger.LogInformation("Fetching available applications");
                
                var result = await _psExecutor.ExecuteCommandAsync("Get-Better11Apps");
                
                if (!result.Success)
                {
                    throw new InvalidOperationException(
                        $"Failed to get applications: {string.Join(", ", result.Errors)}");
                }
                
                var apps = new List<AppMetadata>();
                
                foreach (var item in result.Output)
                {
                    var psObj = item as PSObject;
                    if (psObj == null) continue;
                    
                    apps.Add(new AppMetadata
                    {
                        AppId = psObj.Properties["AppId"]?.Value?.ToString() ?? string.Empty,
                        Name = psObj.Properties["Name"]?.Value?.ToString() ?? string.Empty,
                        Version = psObj.Properties["Version"]?.Value?.ToString() ?? string.Empty,
                        InstallerType = ParseInstallerType(
                            psObj.Properties["InstallerType"]?.Value?.ToString() ?? "exe"),
                        Description = psObj.Properties["Description"]?.Value?.ToString(),
                        Dependencies = ParseStringList(psObj.Properties["Dependencies"]?.Value)
                    });
                }
                
                _logger.LogInformation("Retrieved {Count} applications", apps.Count);
                return apps;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to list available applications");
                throw;
            }
        }
        
        /// <summary>
        /// Installs an application and its dependencies.
        /// </summary>
        public async Task<InstallResult> InstallAppAsync(
            string appId, 
            bool force = false, 
            bool skipDependencies = false)
        {
            try
            {
                _logger.LogInformation("Installing application: {AppId}", appId);
                
                var parameters = new Dictionary<string, object>
                {
                    { "AppId", appId },
                    { "Force", force },
                    { "SkipDependencies", skipDependencies }
                };
                
                var result = await _psExecutor.ExecuteCommandAsync(
                    "Install-Better11App", 
                    parameters);
                
                if (!result.Success)
                {
                    return new InstallResult
                    {
                        Success = false,
                        AppId = appId,
                        ErrorMessage = string.Join("\n", result.Errors)
                    };
                }
                
                var output = result.Output.FirstOrDefault() as PSObject;
                
                return new InstallResult
                {
                    Success = true,
                    AppId = appId,
                    Version = output?.Properties["Version"]?.Value?.ToString() ?? string.Empty,
                    Status = output?.Properties["Status"]?.Value?.ToString() ?? "Unknown"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to install application: {AppId}", appId);
                return new InstallResult
                {
                    Success = false,
                    AppId = appId,
                    ErrorMessage = ex.Message
                };
            }
        }
        
        /// <summary>
        /// Uninstalls an application.
        /// </summary>
        public async Task<UninstallResult> UninstallAppAsync(string appId, bool force = false)
        {
            try
            {
                _logger.LogInformation("Uninstalling application: {AppId}", appId);
                
                var parameters = new Dictionary<string, object>
                {
                    { "AppId", appId },
                    { "Force", force }
                };
                
                var result = await _psExecutor.ExecuteCommandAsync(
                    "Uninstall-Better11App", 
                    parameters);
                
                return new UninstallResult
                {
                    Success = result.Success,
                    AppId = appId,
                    ErrorMessage = result.Success ? null : string.Join("\n", result.Errors)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to uninstall application: {AppId}", appId);
                return new UninstallResult
                {
                    Success = false,
                    AppId = appId,
                    ErrorMessage = ex.Message
                };
            }
        }
        
        /// <summary>
        /// Gets the installation status of all or specific applications.
        /// </summary>
        public async Task<List<AppStatus>> GetAppStatusAsync(string? appId = null)
        {
            try
            {
                var parameters = new Dictionary<string, object>();
                if (!string.IsNullOrEmpty(appId))
                {
                    parameters["AppId"] = appId;
                }
                
                var result = await _psExecutor.ExecuteCommandAsync(
                    "Get-Better11AppStatus", 
                    parameters);
                
                var statuses = new List<AppStatus>();
                
                foreach (var item in result.Output)
                {
                    var psObj = item as PSObject;
                    if (psObj == null) continue;
                    
                    statuses.Add(new AppStatus
                    {
                        AppId = psObj.Properties["AppId"]?.Value?.ToString() ?? string.Empty,
                        Version = psObj.Properties["Version"]?.Value?.ToString() ?? string.Empty,
                        Installed = Convert.ToBoolean(psObj.Properties["Installed"]?.Value ?? false),
                        InstallerPath = psObj.Properties["InstallerPath"]?.Value?.ToString() ?? string.Empty
                    });
                }
                
                return statuses;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get application status");
                throw;
            }
        }
        
        private InstallerType ParseInstallerType(string type)
        {
            return type.ToLowerInvariant() switch
            {
                "msi" => InstallerType.MSI,
                "exe" => InstallerType.EXE,
                "appx" => InstallerType.APPX,
                _ => InstallerType.EXE
            };
        }
        
        private List<string> ParseStringList(object? value)
        {
            if (value == null) return new List<string>();
            
            if (value is IEnumerable<object> enumerable)
            {
                return enumerable.Select(o => o.ToString() ?? string.Empty).ToList();
            }
            
            return new List<string>();
        }
    }
    
    public class InstallResult
    {
        public bool Success { get; set; }
        public string AppId { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? ErrorMessage { get; set; }
    }
    
    public class UninstallResult
    {
        public bool Success { get; set; }
        public string AppId { get; set; } = string.Empty;
        public string? ErrorMessage { get; set; }
    }
}
```

---

## 🎨 Phase 3: WinUI 3 GUI with MVVM (6-8 weeks)

### 3.1 Main Window

**File**: `csharp/Better11.WinUI/Views/MainWindow.xaml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<Window
    x:Class="Better11.WinUI.Views.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    mc:Ignorable="d">

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="48"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Title Bar -->
        <Grid Grid.Row="0" Background="{ThemeResource SystemControlAcrylicWindowBrush}">
            <TextBlock 
                Text="Better11 - Windows Enhancement Toolkit"
                VerticalAlignment="Center"
                Margin="20,0,0,0"
                Style="{StaticResource TitleTextBlockStyle}"/>
        </Grid>

        <!-- Navigation -->
        <NavigationView 
            Grid.Row="1"
            IsBackButtonVisible="Collapsed"
            IsSettingsVisible="True"
            PaneDisplayMode="Left"
            SelectionChanged="NavigationView_SelectionChanged">
            
            <NavigationView.MenuItems>
                <NavigationViewItem 
                    Content="Applications" 
                    Tag="applications"
                    Icon="Apps">
                    <NavigationViewItem.InfoBadge>
                        <InfoBadge x:Name="AppUpdatesBadge" Value="0" Visibility="Collapsed"/>
                    </NavigationViewItem.InfoBadge>
                </NavigationViewItem>
                
                <NavigationViewItem 
                    Content="System Tools" 
                    Tag="systemtools">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE90F;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                
                <NavigationViewItem 
                    Content="Windows Updates" 
                    Tag="windowsupdates">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE777;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                
                <NavigationViewItem 
                    Content="Privacy" 
                    Tag="privacy">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE72E;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                
                <NavigationViewItem 
                    Content="Startup" 
                    Tag="startup">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE7E8;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
                
                <NavigationViewItem 
                    Content="Features" 
                    Tag="features">
                    <NavigationViewItem.Icon>
                        <FontIcon Glyph="&#xE713;"/>
                    </NavigationViewItem.Icon>
                </NavigationViewItem>
            </NavigationView.MenuItems>

            <Frame x:Name="ContentFrame"/>
        </NavigationView>
    </Grid>
</Window>
```

### 3.2 Applications Page

**File**: `csharp/Better11.WinUI/Views/ApplicationsPage.xaml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<Page
    x:Class="Better11.WinUI.Views.ApplicationsPage"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:controls="using:Better11.WinUI.Controls"
    mc:Ignorable="d"
    Background="{ThemeResource ApplicationPageBackgroundThemeBrush}">

    <Grid Padding="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <TextBlock 
            Grid.Row="0"
            Text="Applications"
            Style="{StaticResource TitleLargeTextBlockStyle}"
            Margin="0,0,0,16"/>

        <!-- Search and Filter -->
        <Grid Grid.Row="1" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <AutoSuggestBox 
                Grid.Column="0"
                PlaceholderText="Search applications..."
                QueryIcon="Find"
                Text="{x:Bind ViewModel.SearchText, Mode=TwoWay}"
                Margin="0,0,12,0"/>

            <ComboBox 
                Grid.Column="1"
                Header="Filter"
                SelectedIndex="{x:Bind ViewModel.SelectedFilterIndex, Mode=TwoWay}"
                MinWidth="150"
                Margin="0,0,12,0">
                <ComboBoxItem Content="All"/>
                <ComboBoxItem Content="Installed"/>
                <ComboBoxItem Content="Available"/>
                <ComboBoxItem Content="Updates Available"/>
            </ComboBox>

            <Button 
                Grid.Column="2"
                Content="Refresh"
                Command="{x:Bind ViewModel.RefreshCommand}">
                <Button.Icon>
                    <FontIcon Glyph="&#xE72C;"/>
                </Button.Icon>
            </Button>
        </Grid>

        <!-- Applications List -->
        <ScrollViewer Grid.Row="2">
            <ItemsRepeater ItemsSource="{x:Bind ViewModel.FilteredApplications, Mode=OneWay}">
                <ItemsRepeater.Layout>
                    <UniformGridLayout 
                        MinItemWidth="400" 
                        MinItemHeight="120"
                        ItemsStretch="Fill"/>
                </ItemsRepeater.Layout>
                
                <ItemsRepeater.ItemTemplate>
                    <DataTemplate>
                        <controls:AppCard 
                            AppName="{Binding Name}"
                            AppVersion="{Binding Version}"
                            AppDescription="{Binding Description}"
                            IsInstalled="{Binding IsInstalled}"
                            HasUpdate="{Binding HasUpdate}"
                            InstallCommand="{Binding InstallCommand}"
                            UninstallCommand="{Binding UninstallCommand}"
                            UpdateCommand="{Binding UpdateCommand}"
                            Margin="0,0,12,12"/>
                    </DataTemplate>
                </ItemsRepeater.ItemTemplate>
            </ItemsRepeater>
        </ScrollViewer>

        <!-- Loading Indicator -->
        <ProgressRing 
            Grid.Row="2"
            IsActive="{x:Bind ViewModel.IsLoading, Mode=OneWay}"
            Width="60"
            Height="60"
            HorizontalAlignment="Center"
            VerticalAlignment="Center"/>
    </Grid>
</Page>
```

### 3.3 Applications View Model

**File**: `csharp/Better11.WinUI/ViewModels/ApplicationsViewModel.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using Better11.Core.Interfaces;
using Better11.Core.Models;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.WinUI.ViewModels
{
    /// <summary>
    /// View model for the Applications page.
    /// Manages application listing, installation, and updates.
    /// </summary>
    public partial class ApplicationsViewModel : ObservableObject
    {
        private readonly IAppManager _appManager;
        private readonly ILogger<ApplicationsViewModel> _logger;
        
        [ObservableProperty]
        private ObservableCollection<AppViewModel> _applications = new();
        
        [ObservableProperty]
        private ObservableCollection<AppViewModel> _filteredApplications = new();
        
        [ObservableProperty]
        private string _searchText = string.Empty;
        
        [ObservableProperty]
        private int _selectedFilterIndex = 0;
        
        [ObservableProperty]
        private bool _isLoading = false;
        
        public ApplicationsViewModel(
            IAppManager appManager,
            ILogger<ApplicationsViewModel> logger)
        {
            _appManager = appManager;
            _logger = logger;
        }
        
        public async Task InitializeAsync()
        {
            await LoadApplicationsAsync();
        }
        
        [RelayCommand]
        private async Task RefreshAsync()
        {
            await LoadApplicationsAsync();
        }
        
        partial void OnSearchTextChanged(string value)
        {
            ApplyFilters();
        }
        
        partial void OnSelectedFilterIndexChanged(int value)
        {
            ApplyFilters();
        }
        
        private async Task LoadApplicationsAsync()
        {
            try
            {
                IsLoading = true;
                _logger.LogInformation("Loading applications");
                
                var apps = await _appManager.ListAvailableAppsAsync();
                var statuses = await _appManager.GetAppStatusAsync();
                
                var statusDict = statuses.ToDictionary(s => s.AppId);
                
                Applications.Clear();
                
                foreach (var app in apps)
                {
                    var status = statusDict.GetValueOrDefault(app.AppId);
                    
                    Applications.Add(new AppViewModel
                    {
                        AppId = app.AppId,
                        Name = app.Name,
                        Version = app.Version,
                        Description = app.Description,
                        IsInstalled = status?.Installed ?? false,
                        InstalledVersion = status?.Version ?? string.Empty,
                        HasUpdate = false, // TODO: Check for updates
                        InstallCommand = new RelayCommand(() => InstallAppAsync(app.AppId)),
                        UninstallCommand = new RelayCommand(() => UninstallAppAsync(app.AppId)),
                        UpdateCommand = new RelayCommand(() => UpdateAppAsync(app.AppId))
                    });
                }
                
                ApplyFilters();
                
                _logger.LogInformation("Loaded {Count} applications", Applications.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load applications");
                // Show error dialog
            }
            finally
            {
                IsLoading = false;
            }
        }
        
        private void ApplyFilters()
        {
            var filtered = Applications.AsEnumerable();
            
            // Apply search filter
            if (!string.IsNullOrWhiteSpace(SearchText))
            {
                filtered = filtered.Where(a => 
                    a.Name.Contains(SearchText, StringComparison.OrdinalIgnoreCase) ||
                    (a.Description?.Contains(SearchText, StringComparison.OrdinalIgnoreCase) ?? false));
            }
            
            // Apply status filter
            filtered = SelectedFilterIndex switch
            {
                1 => filtered.Where(a => a.IsInstalled),  // Installed
                2 => filtered.Where(a => !a.IsInstalled), // Available
                3 => filtered.Where(a => a.HasUpdate),    // Updates Available
                _ => filtered
            };
            
            FilteredApplications.Clear();
            foreach (var app in filtered)
            {
                FilteredApplications.Add(app);
            }
        }
        
        private async Task InstallAppAsync(string appId)
        {
            try
            {
                _logger.LogInformation("Installing app: {AppId}", appId);
                
                // Show progress dialog
                IsLoading = true;
                
                var result = await _appManager.InstallAppAsync(appId);
                
                if (result.Success)
                {
                    // Show success notification
                    await LoadApplicationsAsync(); // Refresh list
                }
                else
                {
                    // Show error dialog
                    _logger.LogError("Installation failed: {Error}", result.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to install app: {AppId}", appId);
            }
            finally
            {
                IsLoading = false;
            }
        }
        
        private async Task UninstallAppAsync(string appId)
        {
            try
            {
                _logger.LogInformation("Uninstalling app: {AppId}", appId);
                
                IsLoading = true;
                
                var result = await _appManager.UninstallAppAsync(appId);
                
                if (result.Success)
                {
                    await LoadApplicationsAsync();
                }
                else
                {
                    _logger.LogError("Uninstall failed: {Error}", result.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to uninstall app: {AppId}", appId);
            }
            finally
            {
                IsLoading = false;
            }
        }
        
        private async Task UpdateAppAsync(string appId)
        {
            // Similar to InstallAppAsync but for updates
            await InstallAppAsync(appId);
        }
    }
    
    public class AppViewModel
    {
        public string AppId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Version { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsInstalled { get; set; }
        public string InstalledVersion { get; set; } = string.Empty;
        public bool HasUpdate { get; set; }
        public ICommand? InstallCommand { get; set; }
        public ICommand? UninstallCommand { get; set; }
        public ICommand? UpdateCommand { get; set; }
    }
}
```

---

## 📋 Implementation Checklist

### PowerShell Backend
- [ ] Module structure and manifests
- [ ] AppManager module (Get, Install, Uninstall, Update)
- [ ] SystemTools module (Registry, Bloatware, Services, Performance)
- [ ] Updates module (Windows Update management)
- [ ] Security module (Code signing verification)
- [ ] Privacy module (Telemetry, app permissions)
- [ ] Startup module (Startup items management)
- [ ] Features module (Windows Features)
- [ ] Common module (Safety, logging, utilities)
- [ ] Pester tests for all modules
- [ ] Module documentation and help

### C# Frontend
- [ ] Solution and project setup (.NET 8)
- [ ] Core models (AppMetadata, AppStatus, etc.)
- [ ] Interfaces (IAppManager, ISystemToolsService, etc.)
- [ ] PowerShell executor and module loader
- [ ] AppManagerService implementation
- [ ] SystemToolsService implementation
- [ ] UpdateService implementation
- [ ] SecurityService implementation
- [ ] ConfigService implementation
- [ ] Unit tests for all services
- [ ] Integration tests with PowerShell

### WinUI 3 GUI
- [ ] WinUI 3 project setup
- [ ] Main window with navigation
- [ ] Applications page (XAML + ViewModel)
- [ ] System Tools page
- [ ] Windows Updates page
- [ ] Privacy page
- [ ] Startup page
- [ ] Features page
- [ ] Settings page
- [ ] Custom controls (AppCard, ProgressCard, etc.)
- [ ] Converters and helpers
- [ ] Localization resources
- [ ] Theme support (Light/Dark)
- [ ] Dependency injection setup
- [ ] Error handling and logging
- [ ] Progress notifications
- [ ] UI tests

### CLI Application
- [ ] CLI project setup
- [ ] Command parser
- [ ] App commands (list, install, uninstall, update)
- [ ] System commands (registry, bloatware, services)
- [ ] Update commands
- [ ] Configuration commands
- [ ] Progress display
- [ ] Help documentation

### Documentation
- [ ] POWERSHELL_API.md - PowerShell module documentation
- [ ] CSHARP_API.md - C# API documentation
- [ ] WINUI3_GUIDE.md - GUI user guide
- [ ] MIGRATION_GUIDE.md - Migration from Python guide
- [ ] Updated README.md
- [ ] Architecture diagrams
- [ ] Code examples

### Testing & Quality
- [ ] Pester tests for PowerShell (50+ tests)
- [ ] xUnit tests for C# (100+ tests)
- [ ] Integration tests
- [ ] UI automation tests
- [ ] Performance tests
- [ ] Security audit
- [ ] Code coverage >80%

---

## 🚀 Deployment & Distribution

### Packaging Options

1. **PowerShell Module**
   - Publish to PowerShell Gallery
   - Signed module files
   - Installation via `Install-Module Better11`

2. **WinUI 3 Application**
   - MSIX package for Microsoft Store
   - Standalone installer (EXE)
   - Chocolatey package
   - Winget manifest

3. **CLI Application**
   - Self-contained executable
   - Scoop package
   - Chocolatey package

### Installation Methods

```powershell
# PowerShell Module
Install-Module -Name Better11 -Repository PSGallery

# WinUI 3 App (Microsoft Store)
winget install Better11

# CLI (Chocolatey)
choco install better11

# Manual
git clone https://github.com/yourusername/better11.git
cd better11/powershell
Import-Module ./Better11/Better11.psd1
```

---

## 📊 Timeline Estimate

| Phase | Duration | Description |
|-------|----------|-------------|
| Phase 1: PowerShell Backend | 4-6 weeks | Complete PowerShell module implementation |
| Phase 2: C# Frontend | 4-6 weeks | Core libraries and services |
| Phase 3: WinUI 3 GUI | 6-8 weeks | Full GUI with MVVM |
| Phase 4: CLI Application | 2-3 weeks | Command-line interface |
| Phase 5: Testing & QA | 3-4 weeks | Comprehensive testing |
| Phase 6: Documentation | 2-3 weeks | Complete documentation |
| Phase 7: Packaging & Release | 2 weeks | Distribution packages |

**Total Estimated Time**: 23-32 weeks (5-8 months)

---

## 🎯 Success Criteria

- ✅ 100% feature parity with Python version
- ✅ All PowerShell functions tested with Pester
- ✅ All C# services have unit tests (>80% coverage)
- ✅ WinUI 3 GUI is responsive and modern
- ✅ MVVM architecture properly implemented
- ✅ PowerShell and C# integration seamless
- ✅ CLI matches Python CLI functionality
- ✅ Complete documentation
- ✅ Successful deployment to Microsoft Store
- ✅ Python codebase remains untouched

---

## 📝 Notes

1. **Python Preservation**: All existing Python code remains in `python/` directory unchanged
2. **Gradual Migration**: Can be done incrementally, module by module
3. **Interoperability**: C# and PowerShell can coexist with Python during transition
4. **Testing**: Each module thoroughly tested before moving to next
5. **Documentation**: Updated as modules are completed
6. **Performance**: Native Windows technologies should provide better performance
7. **Modern UI**: WinUI 3 provides beautiful, modern Windows 11 UI
8. **Maintainability**: MVVM pattern makes GUI easily maintainable and testable

---

**Last Updated**: December 10, 2025  
**Document Owner**: Better11 Development Team  
**Status**: PLANNING - Ready for Review and Implementation
