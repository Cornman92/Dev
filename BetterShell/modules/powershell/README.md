# Better11 PowerShell Modules

**Production-grade PowerShell modules for the Better11 System Enhancement Suite**

## Overview

The Better11 module suite provides comprehensive system management, package installation, driver management, retry logic, and system optimization capabilities for Windows 11.

## Modules

### 📦 Better11.Core

**Core functionality and infrastructure for all Better11 operations**

#### Key Features
- ✅ Configuration management (JSON-based)
- ✅ Advanced logging integration (AutoSuite/Logging fallback)
- ✅ Performance monitoring and telemetry
- ✅ Dependency validation and installation
- ✅ Comprehensive diagnostics and health checks
- ✅ Network connectivity testing
- ✅ System information gathering

#### Main Functions

**Configuration**
- `Get-Better11Config` - Load configuration from project.json
- `Set-Better11Config` - Update configuration values
- `Test-Better11Config` - Validate configuration
- `Repair-Better11Config` - Repair broken configuration with defaults

**Logging & Telemetry**
- `Initialize-Better11Logger` - Set up logging infrastructure
- `Write-Better11Log` - Write log entries with levels (INFO/WARN/ERROR/DEBUG)
- `Get-Better11DiagnosticInfo` - Collect comprehensive diagnostic data
- `Export-Better11DiagnosticReport` - Export diagnostic report to JSON

**Performance**
- `Start-Better11PerformanceMonitor` - Begin performance tracking
- `Stop-Better11PerformanceMonitor` - End tracking and get metrics
- `Get-Better11PerformanceReport` - Retrieve performance history

**Validation**
- `Test-Better11AdminRights` - Check for administrator privileges
- `Assert-Better11AdminRights` - Require admin rights or throw
- `Test-Better11Prerequisites` - Check system requirements
- `Test-Better11Dependencies` - Validate all dependencies
- `Test-Better11NetworkConnectivity` - Test internet connectivity

**System Info**
- `Get-Better11SystemInfo` - Get OS, hardware, memory info
- `Get-Better11ModuleHealth` - Check status of all Better11 modules

**Utilities**
- `Invoke-Better11Action` - Execute actions with error handling & retry
- `Clear-Better11Cache` - Clean up temp files and old logs

#### Example Usage

```powershell
# Import module
Import-Module .\Better11.Core.psm1

# Check prerequisites
$prereqs = Test-Better11Prerequisites -IncludeOptional
if (-not $prereqs.Passed) {
    Write-Warning "Some prerequisites are missing!"
}

# Get system info
$sysInfo = Get-Better11SystemInfo
Write-Host "Running on: $($sysInfo.OSName) - $($sysInfo.OSVersion)"

# Performance monitoring
$monitor = Start-Better11PerformanceMonitor -OperationName "My Operation"
# ... do work ...
$metrics = Stop-Better11PerformanceMonitor -Monitor $monitor
Write-Host "Completed in $($metrics.DurationSeconds)s"

# Export diagnostic report
Export-Better11DiagnosticReport -OutputPath "C:\Logs\diagnostic.json" -IncludePerformance
```

---

### 🚀 Better11.Install

**Multi-package manager abstraction for software installation**

#### Key Features
- ✅ Support for **Winget**, **Chocolatey**, **Scoop**, and **Custom installers**
- ✅ Automatic package manager detection
- ✅ Package search and discovery
- ✅ Package update management
- ✅ Bulk installation with WhatIf support
- ✅ Retry logic integration

#### Main Functions

**Package Management**
- `Install-Better11Package` - Install a package via any manager
- `Uninstall-Better11Package` - Remove installed packages
- `Update-Better11Package` - Update packages to latest version
- `Get-Better11PackageUpdates` - Check for available updates
- `Search-Better11Package` - Search package repositories

**Package Managers**
- `Get-AvailablePackageManagers` - Detect installed package managers
- `Get-Better11InstalledPackages` - List all installed packages

**Bulk Operations**
- `Install-Better11PackagesFromList` - Install multiple packages from JSON/array

#### Example Usage

```powershell
# Import module
Import-Module .\Better11.Install.psm1

# Check available package managers
$managers = Get-AvailablePackageManagers
Write-Host "Winget: $($managers.Winget)"
Write-Host "Chocolatey: $($managers.Chocolatey)"

# Install a package with Winget
Install-Better11Package -PackageName "7zip.7zip" -Method Winget

# Search for packages
Search-Better11Package -SearchTerm "vscode" -Method Winget

# Check for updates
$updates = Get-Better11PackageUpdates -Method Winget
Write-Host "Available updates: $($updates.Count)"

# Update a package
Update-Better11Package -PackageName "7zip.7zip" -Method Winget
```

---

### 🔧 Better11.Drivers

**Hardware driver detection, installation, and management**

#### Key Features
- ✅ Hardware detection via WMI/CIM
- ✅ Driver status checking
- ✅ Windows Update driver installation
- ✅ Local driver installation (INF files)
- ✅ Driver backup and restore
- ✅ Driver update recommendations
- ✅ Automatic driver updates

#### Main Functions

**Hardware Detection**
- `Get-Better11Hardware` - Enumerate hardware devices
- `Get-Better11DriverStatus` - Check driver status for all devices

**Driver Installation**
- `Install-Better11Driver` - Install drivers from various sources
- `Update-Better11Drivers` - Auto-update all outdated drivers
- `Get-Better11DriverRecommendations` - Get driver update suggestions

**Driver Management**
- `Backup-Better11Drivers` - Backup installed drivers
- `Restore-Better11Drivers` - Restore drivers from backup
- `Scan-Better11Drivers` - Comprehensive driver scan

#### Example Usage

```powershell
# Import module
Import-Module .\Better11.Drivers.psm1

# Get hardware information
$hardware = Get-Better11Hardware -DeviceClass "Display"
$hardware | Format-Table

# Check driver status
$status = Get-Better11DriverStatus
$outdated = $status | Where-Object { $_.NeedsUpdate }
Write-Host "Devices needing updates: $($outdated.Count)"

# Get update recommendations
$recommendations = Get-Better11DriverRecommendations
$recommendations | Format-Table DeviceName, CurrentVersion, RecommendedVersion

# Update drivers
Update-Better11Drivers -WhatIf
Update-Better11Drivers -Confirm:$false
```

---

### 🔄 Better11.Retry

**Advanced retry logic with circuit breaker pattern**

#### Key Features
- ✅ Multiple retry strategies (Fixed, Exponential, Linear, Custom)
- ✅ Circuit breaker pattern for fault tolerance
- ✅ Configurable backoff and jitter
- ✅ Error filtering
- ✅ Retry callbacks
- ✅ Comprehensive error handling

#### Main Functions

**Retry Logic**
- `Invoke-Better11Retry` - Execute with automatic retries
- `Get-Better11RetryDelay` - Calculate retry delay based on strategy

**Circuit Breaker**
- `Get-Better11CircuitBreakerState` - Check circuit breaker status
- `Set-Better11CircuitBreakerState` - Modify circuit breaker state
- `Reset-Better11CircuitBreaker` - Reset to closed state

**Error Filters**
- `Test-Better11NetworkError` - Identify network-related errors
- `Test-Better11TransientError` - Identify transient errors

#### Example Usage

```powershell
# Import module
Import-Module .\Better11.Retry.psm1

# Simple retry with exponential backoff
Invoke-Better11Retry -Action {
    Install-Package -Name "MyPackage"
} -RetryCount 3 -Strategy Exponential

# Advanced retry with circuit breaker
Invoke-Better11Retry -Action {
    Invoke-WebRequest "https://api.example.com/data"
} -RetryCount 5 -Strategy Exponential `
  -CircuitBreakerKey "APICall" `
  -CircuitBreakerThreshold 5 `
  -ErrorFilter { Test-Better11NetworkError $_ }

# Reset circuit breaker
Reset-Better11CircuitBreaker -Key "APICall"
```

---

### ⚙️ Better11.Tweaks

**System optimizations and registry tweaks**

#### Key Features
- ✅ Pre-built tweak profiles (Gaming, Performance, Privacy)
- ✅ Registry operations with backup
- ✅ Custom tweak creation
- ✅ WhatIf support for safe testing
- ✅ Tweak export/import
- ✅ Rollback capabilities

#### Main Functions

**Pre-built Tweaks**
- `Apply-Better11GamingTweaks` - Gaming optimizations
- `Apply-Better11PerformanceTweaks` - System performance
- `Apply-Better11PrivacyTweaks` - Privacy enhancements

**Registry Operations**
- `Set-Better11RegistryValue` - Safe registry modifications
- `Get-Better11RegistryValue` - Retrieve registry values

**Custom Tweaks**
- `New-Better11CustomTweak` - Create custom tweak definitions
- `Apply-Better11CustomTweak` - Apply custom tweaks
- `Export-Better11Tweaks` - Export tweak configurations
- `Import-Better11Tweaks` - Import tweak configurations

**Backup & Restore**
- `Backup-Better11Registry` - Backup registry sections
- `Restore-Better11Registry` - Restore from backup

#### Example Usage

```powershell
# Import module
Import-Module .\Better11.Tweaks.psm1

# Preview gaming tweaks
Apply-Better11GamingTweaks -WhatIf

# Apply gaming optimizations
Apply-Better11GamingTweaks -Confirm:$false

# Apply privacy tweaks
Apply-Better11PrivacyTweaks

# Create custom tweak
$tweak = New-Better11CustomTweak -Name "DisableUAC" `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "EnableLUA" `
    -Value 0 `
    -Type DWord

# Apply custom tweak
Apply-Better11CustomTweak -Tweak $tweak -Backup
```

---

## Installation

### Prerequisites
- **PowerShell 7.0+** (recommended)
- **Windows 11** or Windows 10
- **Administrator rights** (for most operations)
- **Winget** (for package management)
- **DISM** (for driver operations)

### Quick Start

```powershell
# Navigate to modules directory
cd E:\OneDrive\Dev\modules

# Import all Better11 modules
Import-Module .\Better11.Core.psm1
Import-Module .\Better11.Install.psm1
Import-Module .\Better11.Drivers.psm1
Import-Module .\Better11.Retry.psm1
Import-Module .\Better11.Tweaks.psm1

# Verify module health
Get-Better11ModuleHealth
```

### Module Manifest Installation

```powershell
# Install from manifest (if available)
Install-Module -Name Better11.Core -Repository Local
Install-Module -Name Better11.Install -Repository Local
Install-Module -Name Better11.Drivers -Repository Local
Install-Module -Name Better11.Retry -Repository Local
Install-Module -Name Better11.Tweaks -Repository Local
```

---

## Configuration

Better11 modules use a `project.json` configuration file:

```json
{
  "name": "Better11 Suite",
  "version": "2.0.0",
  "profile": "gamer",
  "options": {
    "buildISO": false,
    "whatIf": false,
    "offlineOnly": false,
    "maxConcurrency": 3
  },
  "iso": {
    "label": "BETTER11",
    "sourcePath": "C:\\Better11\\Staging",
    "outputIso": "C:\\Better11\\Output\\Better11.iso"
  },
  "appsCatalog": "./Manifests/apps.json",
  "installerMetadata": "./Config/installer_metadata.json"
}
```

### Validate Configuration

```powershell
# Check configuration validity
$validation = Test-Better11Config
if (-not $validation.Valid) {
    Write-Warning "Configuration errors: $($validation.Errors -join ', ')"
}

# Repair configuration
Repair-Better11Config -BackupOriginal
```

---

## Testing & Diagnostics

### Run Health Checks

```powershell
# Check all prerequisites
Test-Better11Prerequisites -IncludeOptional

# Check dependencies
Test-Better11Dependencies -IncludeOptional

# Check module health
Get-Better11ModuleHealth

# Test network connectivity
Test-Better11NetworkConnectivity
```

### Generate Diagnostic Report

```powershell
# Export full diagnostic report
Export-Better11DiagnosticReport `
    -OutputPath "C:\Better11\Logs\diagnostic.json" `
    -IncludePerformance

# View diagnostic info
$diag = Get-Better11DiagnosticInfo -IncludePerformance
$diag | ConvertTo-Json -Depth 10
```

---

## Performance Best Practices

1. **Use Performance Monitoring** for long-running operations
2. **Enable Circuit Breakers** for unreliable operations
3. **Use WhatIf** to preview changes before applying
4. **Regular Cache Cleanup** to maintain performance
5. **Check Dependencies** before major operations

### Example: Production-Ready Installation

```powershell
# Complete production-ready installation workflow
function Install-ProductionPackage {
    param([string]$PackageName)
    
    # Check prerequisites
    Assert-Better11AdminRights
    Test-Better11NetworkConnectivity
    
    # Start performance monitoring
    $monitor = Start-Better11PerformanceMonitor -OperationName "Install $PackageName"
    
    try {
        # Install with retry logic
        Invoke-Better11Retry -Action {
            Install-Better11Package -PackageName $PackageName -Method Winget
        } -RetryCount 3 -Strategy Exponential
        
        # Log success
        Write-Better11Log -Level 'INFO' -Message "Successfully installed $PackageName"
    }
    catch {
        Write-Better11Log -Level 'ERROR' -Message "Failed to install $PackageName : $_"
        throw
    }
    finally {
        # Stop monitoring and report
        $metrics = Stop-Better11PerformanceMonitor -Monitor $monitor
        Write-Host "Installation completed in $($metrics.DurationSeconds)s"
    }
}
```

---

## Troubleshooting

### Common Issues

**Module not found**
```powershell
# Check module path
Get-Better11ModulePath -ModuleName Core

# Re-import with force
Import-Module .\Better11.Core.psm1 -Force
```

**Permission denied**
```powershell
# Check admin rights
Test-Better11AdminRights

# Run as administrator if needed
Start-Process powershell -Verb RunAs
```

**Configuration errors**
```powershell
# Validate and repair
Test-Better11Config
Repair-Better11Config -BackupOriginal
```

---

## Version History

### v2.0.0 (Current)
- ✅ Added performance monitoring capabilities
- ✅ Enhanced configuration validation
- ✅ Implemented dependency management
- ✅ Added comprehensive diagnostics
- ✅ Improved error handling throughout
- ✅ Added telemetry collection
- ✅ Enhanced documentation

### v1.0.0
- ✅ Initial production release
- ✅ Core modules: Core, Install, Drivers, Retry, Tweaks
- ✅ Basic logging and configuration
- ✅ Multi-package manager support

---

## Contributing

For bug reports, feature requests, or contributions, please see the main Better11 project repository.

## License

Part of the Better11 System Enhancement Suite.

---

**Last Updated:** December 2024  
**Module Version:** 2.0.0  
**PowerShell Version Required:** 7.0+
