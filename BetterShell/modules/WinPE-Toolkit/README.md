# Better11 Windows Deployment Toolkit

A comprehensive PowerShell-based toolkit for automated Windows deployment, customization, and optimization. Designed for IT professionals, system administrators, and power users who need to deploy Windows with deep customization and automation capabilities.

## Features

- **Automated Windows Deployment**: Bare-metal deployment with disk partitioning, image application, and boot configuration
- **Hardware-Aware Driver Injection**: Automatic hardware detection and driver pack matching with offline injection
- **Application Deployment**: Multi-source application installation (MSI, EXE, Winget, Chocolatey, MSIX) with dependency resolution
- **System Optimization**: Performance tweaks, debloat profiles, and personalization settings
- **Health Monitoring**: System snapshots, before/after comparisons, and diagnostics export
- **Unattended Setup**: Interactive wizard for generating `autounattend.xml` files
- **Provisioning Packages**: Create and install PPKG files for app and configuration deployment
- **Task Sequences**: JSON-based orchestration for complex deployment workflows
- **Rich TUI**: Console-based control center for easy interaction

## Quick Start

### Prerequisites

- Windows 10/11 (or Windows Server 2016+)
- PowerShell 5.1 or later
- Administrator privileges
- Windows ADK (for WinPE support and DISM tools)

### Installation

1. Clone or download this repository to your deployment share or local machine.

2. Import the modules into your PowerShell session:

```powershell
# Import all modules
$modulePath = "E:\OneDrive\Dev\active-projects\Windows-Deployment-Toolkit\src\Modules"
Get-ChildItem -Path $modulePath -Directory | ForEach-Object {
    Import-Module $_.FullName -Force
}
```

3. Launch the Deployment Control Center:

```powershell
Start-DeployCenter
```

## Usage Examples

### Running a Task Sequence

The easiest way to deploy Windows is through the interactive Control Center:

```powershell
Start-DeployCenter
# Select option [1] to run a task sequence
# Choose from available sequences and follow the prompts
```

Or programmatically:

```powershell
$ctx = New-DeployRunContext
$ts = Get-TaskSequence -Id "baremetal-basic"
Invoke-TaskSequence -RunContext $ctx -TaskSequence $ts -Variables @{ DiskNumber = 0 }
```

### Generating autounattend.xml

Use the interactive wizard:

```powershell
Start-AutounattendWizard
```

Or generate programmatically:

```powershell
$ctx = New-DeployRunContext
New-AutounattendXml -RunContext $ctx `
    -OutputPath "C:\Deploy\autounattend.xml" `
    -ComputerName "PC-*" `
    -TimeZone "Eastern Standard Time" `
    -LocalAdminName "admin" `
    -LocalAdminPassword "SecurePassword123" `
    -EnableAutoLogon
```

### Hardware Detection and Driver Injection

```powershell
# Detect hardware
$hw = Get-HardwareProfile

# Get driver catalog
$catalog = Get-DriverCatalog

# Find matching driver packs
$matches = Find-DriverPacksForHardware -HardwareProfile $hw -DriverCatalog $catalog

# Inject drivers into offline Windows image
$ctx = New-DeployRunContext
Add-DriversToOfflineWindows -RunContext $ctx `
    -WindowsVolumeRoot "C:\" `
    -DriverPacks ($matches | Select-Object -First 3 | ForEach-Object { $_.DriverPack })
```

### Application Installation

```powershell
# Install an app set
$ctx = New-DeployRunContext
Install-AppSet -RunContext $ctx -SetId "dev-workstation"

# Install a single app
$catalog = Get-AppCatalog
$app = $catalog | Where-Object { $_.id -eq "vscode-winget" }
Install-AppPackage -RunContext $ctx -App $app
```

### System Optimization

```powershell
# Apply an optimization profile
$ctx = New-DeployRunContext
Invoke-OptimizationProfile -RunContext $ctx -Id "perf-desktop"

# Apply debloat profile
Invoke-DebloatProfile -RunContext $ctx -Id "light"

# Apply personalization
Set-PersonalizationProfile -RunContext $ctx -Id "dev-personal"
```

### Health Snapshots

```powershell
# Create a snapshot
$ctx = New-DeployRunContext
$snapshot1 = New-HealthSnapshot -RunContext $ctx -Name "before-optimization"

# ... perform operations ...

$snapshot2 = New-HealthSnapshot -RunContext $ctx -Name "after-optimization"

# Compare snapshots
$diff = Compare-HealthSnapshot -BaselinePath $snapshot1 -CurrentPath $snapshot2
$diff.AddedApps
$diff.RemovedApps
$diff.ServiceChanges
```

### Provisioning Packages

```powershell
# Capture apps from a reference machine
$ctx = New-DeployRunContext
New-AppCaptureProvisioningPackage -RunContext $ctx `
    -OutputPath "C:\Deploy\apps.ppkg" `
    -OverwriteExisting

# Install on a target machine
Install-ProvisioningPackageLocal -RunContext $ctx `
    -PackagePath "C:\Deploy\apps.ppkg"
```

## Module Overview

### Deployment.Core
Core utilities for logging, configuration management, and safety helpers.

**Key Functions:**
- `New-DeployRunContext` - Create a deployment run context with logging
- `Write-DeployLog` - Write to deployment log
- `Write-DeployEvent` - Write structured JSON events
- `Confirm-DestructiveAction` - Safety confirmation for destructive operations
- `Invoke-DeployRetry` - Retry logic for operations

### Deployment.Imaging
Disk layout and Windows image application.

**Key Functions:**
- `Get-DeployDisk` - Enumerate available disks
- `New-DeployDiskLayout` - Create disk partitions
- `Invoke-ImageApply` - Apply WIM image to target volume
- `New-BootConfig` - Configure bootloader

### Deployment.TaskSequence
JSON-based task orchestration engine.

**Key Functions:**
- `Get-TaskSequenceCatalog` - Get all available task sequences
- `Get-TaskSequence` - Get a specific task sequence by ID
- `Invoke-TaskSequence` - Execute a task sequence
- `Invoke-TaskStep` - Execute a single task step

### Deployment.Drivers
Hardware detection and driver pack management.

**Key Functions:**
- `Get-HardwareProfile` - Capture system hardware information
- `Get-DriverCatalog` - Load driver catalog from JSON
- `Find-DriverPacksForHardware` - Match driver packs to hardware
- `Add-DriversToOfflineWindows` - Inject drivers into offline image
- `Add-DriversToMountedImage` - Inject drivers into mounted image

### Deployment.Packages
Application catalog and installation engine.

**Key Functions:**
- `Get-AppCatalog` - Load application catalog
- `Get-AppSet` - Get an application set definition
- `Test-AppInstalled` - Check if an app is installed
- `Install-AppPackage` - Install a single application
- `Install-AppSet` - Install an application set

### Deployment.Optimization
System optimization, debloat, and personalization.

**Key Functions:**
- `Get-OptimizationProfile` - Get optimization profile
- `Invoke-OptimizationProfile` - Apply optimization profile
- `Invoke-DebloatProfile` - Apply debloat profile
- `Set-PersonalizationProfile` - Apply personalization profile

### Deployment.Health
System health snapshots and diagnostics.

**Key Functions:**
- `New-HealthSnapshot` - Create system health snapshot
- `Compare-HealthSnapshot` - Compare two snapshots
- `New-SystemRestorePointSafe` - Create system restore point
- `Export-DeployDiagnostics` - Export diagnostics to ZIP

### Deployment.Autounattend
Unattended setup XML generator.

**Key Functions:**
- `New-AutounattendXml` - Generate autounattend.xml
- `Start-AutounattendWizard` - Interactive wizard for generating autounattend.xml

### Deployment.Provisioning
Provisioning package (PPKG) builder and installer.

**Key Functions:**
- `New-AppCaptureProvisioningPackage` - Create PPKG from current system
- `Install-ProvisioningPackageLocal` - Install PPKG on local system
- `Add-ProvisioningPackageToOfflineImage` - Inject PPKG into offline image

### Deployment.UI
Console-based control center UI.

**Key Functions:**
- `Start-DeployCenter` - Launch the main control center
- `Start-DeployConsole` - Backwards-compatible entry point

## Path Configuration

The toolkit supports flexible path configuration using environment variables and relative paths:

### Environment Variable Substitution

Paths in configuration files support environment variable substitution:
- `%VAR_NAME%` or `${VAR_NAME}` syntax
- Common variables:
  - `%DEPLOY_SHARE%` - Deployment share root (e.g., `D:\DeployShare`)
  - `%WIM_PATH%` - Path to Windows installation WIM file
  - `%INSTALL_WIM%` - Alternative WIM path variable

### Relative Paths

Paths starting with `.\` are resolved relative to the toolkit root directory.

### Examples

```json
{
  "source": "%DEPLOY_SHARE%\\Apps\\7zip\\7z2408-x64.msi",
  "wimPath": "%WIM_PATH%",
  "paths": [".\\Drivers\\Dell\\Latitude_7490"]
}
```

## Configuration Files

### Task Sequences (`configs/task_sequences/`)

JSON files defining deployment workflows. Each file can contain one or more task sequences.

**Example:**
```json
[
  {
    "id": "baremetal-basic",
    "name": "Bare-metal GPT deployment",
    "description": "Basic deployment workflow",
    "steps": [
      {
        "id": "partition-disk",
        "name": "Partition target disk",
        "type": "PartitionDisk",
        "inputs": { ... }
      }
    ]
  }
]
```

### Driver Catalog (`configs/drivers/catalog.json`)

Defines driver packs with hardware matching rules. Paths support environment variable substitution.

**Example:**
```json
[
  {
    "id": "dell-latitude-7490",
    "description": "Dell Latitude 7490 drivers",
    "paths": [
      "%DEPLOY_SHARE%\\Drivers\\Dell\\Latitude_7490",
      ".\\Drivers\\Dell\\Latitude_7490"
    ],
    "targetHardware": {
      "manufacturer": "Dell",
      "model": "Latitude 7490"
    }
  }
]
```

### App Catalog (`configs/apps/apps.json`)

Defines applications with installation sources and detection logic. Source paths support environment variable substitution.

**Example:**
```json
[
  {
    "id": "7zip",
    "name": "7-Zip",
    "sourceType": "msi",
    "source": "%DEPLOY_SHARE%\\Apps\\7zip\\7z2408-x64.msi",
    "detection": {
      "files": [{"path": "C:\\Program Files\\7-Zip\\7zFM.exe"}]
    }
  }
]
```

### Optimization Profiles (`configs/optimize/profiles/`)

Defines optimization actions (registry, services, power plans, etc.).

**Example:**
```json
[
  {
    "id": "perf-desktop",
    "name": "Performance desktop profile",
    "actions": [
      {
        "type": "PowerPlanSet",
        "scheme": "High Performance"
      }
    ]
  }
]
```

## Task Sequence Step Types

- `PartitionDisk` - Create disk partitions
- `ApplyImage` - Apply WIM image
- `ConfigureBoot` - Configure bootloader
- `DetectHardware` - Capture hardware profile
- `InjectDrivers` - Inject drivers (offline or mounted image)
- `InstallAppSet` - Install application set
- `HealthSnapshot` - Create health snapshot
- `ApplyOptimizationProfile` - Apply optimization profile
- `ApplyDebloatProfile` - Apply debloat profile
- `ApplyPersonalizationProfile` - Apply personalization profile
- `Reboot` - Reboot system

## Logging

All operations are logged to:
- **Deployment Log**: `logs/{RunId}/deployment.log` - Plain text log
- **Event Stream**: `logs/{RunId}/events.jsonl` - Structured JSON events

Each deployment run gets a unique Run ID (GUID) for tracking.

## WinPE Support

The toolkit is designed to work in both full Windows and WinPE environments. Some features (like system restore points) are automatically disabled in WinPE.

## Safety Features

- **Destructive Action Confirmations**: Operations that modify disk layout or wipe data require explicit confirmation
- **Run Context Tracking**: All operations are tracked with unique run IDs
- **Comprehensive Logging**: All operations are logged for audit and troubleshooting
- **Error Handling**: Robust error handling with retry logic where appropriate

## Contributing

This toolkit is designed to be extensible. You can:
- Add new task sequence step types by extending `Invoke-TaskStep`
- Create custom optimization profiles
- Add new application sources
- Extend driver matching logic

## License

Copyright (c) Better11. All rights reserved.

## Support

For issues, questions, or contributions, please refer to the project repository.

