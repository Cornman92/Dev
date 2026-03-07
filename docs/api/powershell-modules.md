# PowerShell Modules API Reference

> Complete API reference for all PowerShell modules in the Dev workspace  
> Last Updated: 2025-01-20

## Overview

This document provides API reference for all PowerShell modules located in the `modules/` directory.

## Module Index

### Core Modules

#### AccessSentinel
Access control and security module.

#### Better11.Core
Better11 core functionality.

#### Better11.Drivers
Driver management for Better11.

#### Better11.Install
Installation utilities for Better11.

#### Better11.Retry
Retry logic utilities.

#### Better11.Tweaks
System tweaks for Better11.

### Utility Modules

#### Benchmarks
Performance benchmarking utilities.

#### Dashboard
Dashboard functionality.

#### InstallEngine
Installation engine.

#### Integrity
System integrity checks.

#### Logging
Logging utilities.

#### OfflineCache
Offline caching functionality.

#### PackageManager
Package management utilities.

#### Preflight
Pre-flight checks.

#### ReleaseNotes
Release notes management.

#### Reports
Reporting functionality.

#### Security
Security utilities.

#### Signing
Code signing utilities.

#### Telemetry
Telemetry collection.

#### Versioning
Version management.

## Common Patterns

### Module Import

```powershell
# Import a single module
Import-Module .\modules\ModuleName\ModuleName.psd1

# Import all modules
Get-ChildItem -Path .\modules\ -Directory | ForEach-Object {
    Import-Module $_.FullName -Force
}
```

### Error Handling

```powershell
try {
    # Module function call
    $result = Get-ModuleFunction -Parameter $value
} catch {
    Write-Error "Error: $($_.Exception.Message)"
}
```

### Pipeline Support

Most modules support pipeline input:

```powershell
Get-Items | Process-Items | Format-Output
```

## Module-Specific APIs

### PackageManager Module

#### Get-InstalledPackages

Get list of installed packages.

**Syntax**:
```powershell
Get-InstalledPackages [[-PackageType] <String>] [<CommonParameters>]
```

**Parameters**:
- `PackageType` (optional): Filter by package type (Chocolatey, WinGet, Scoop)

**Example**:
```powershell
Get-InstalledPackages -PackageType Chocolatey
```

#### Install-DevPackage

Install a development package.

**Syntax**:
```powershell
Install-DevPackage [-PackageName] <String> [[-Version] <String>] [<CommonParameters>]
```

**Example**:
```powershell
Install-DevPackage -PackageName "git" -Version "2.42.0"
```

### Logging Module

#### Write-Log

Write a log entry.

**Syntax**:
```powershell
Write-Log [-Message] <String> [[-Level] <String>] [<CommonParameters>]
```

**Example**:
```powershell
Write-Log -Message "Operation completed" -Level "Info"
```

### Versioning Module

#### Get-Version

Get current version.

**Syntax**:
```powershell
Get-Version [<CommonParameters>]
```

**Example**:
```powershell
$version = Get-Version
```

## Examples

### Example 1: Package Management

```powershell
# Import module
Import-Module .\modules\PackageManager\PackageManager.psd1

# List installed packages
$packages = Get-InstalledPackages

# Install a package
Install-DevPackage -PackageName "nodejs" -Version "18.17.0"
```

### Example 2: Logging

```powershell
# Import module
Import-Module .\modules\Logging\Logging.psd1

# Write log entries
Write-Log -Message "Starting operation" -Level "Info"
Write-Log -Message "Operation completed" -Level "Success"
Write-Log -Message "Error occurred" -Level "Error"
```

## Module Documentation

For detailed documentation on specific modules, see:
- Module README files: `modules/[ModuleName]/README.md`
- Comment-based help: `Get-Help [FunctionName] -Full`

## Contributing

To add or update module APIs:
1. Update this document
2. Ensure comment-based help is complete
3. Add examples to module README
4. Update module manifest

---

*For module-specific questions, see individual module documentation*
