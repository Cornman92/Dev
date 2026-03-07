---
name: windows-system-hardware
description: Comprehensive Windows system and hardware configuration skill for inventory, analysis, diagnostics, and configuration. Use when working with CPU, GPU, memory, storage, network adapters, BIOS/UEFI, drivers, device management, performance monitoring, or system specifications. Triggers on hardware inventory, system info, device enumeration, driver operations, health monitoring, benchmark data, or any Windows hardware configuration task.
---

# Windows System & Hardware Configuration

## Quick Start

```powershell
# Get comprehensive system overview
.\scripts\Get-SystemInventory.ps1 -Full

# Hardware-specific queries
.\scripts\Get-HardwareInfo.ps1 -Category CPU
.\scripts\Get-HardwareInfo.ps1 -Category GPU -Detailed
.\scripts\Get-HardwareInfo.ps1 -Category Storage -HealthCheck
```

## Core Capabilities

### System Inventory
- Complete hardware enumeration via WMI/CIM
- BIOS/UEFI configuration detection
- Motherboard and chipset identification
- TPM status and capabilities

### Hardware Categories
- **CPU**: Cores, threads, cache, frequency, features (AVX, virtualization)
- **GPU**: Adapters, VRAM, driver versions, display outputs
- **Memory**: DIMMs, speed, type, slots, capacity
- **Storage**: Drives, partitions, health (SMART), volumes
- **Network**: Adapters, MAC, IP config, link speed
- **Audio**: Devices, drivers, endpoints
- **USB**: Controllers, connected devices, power

### Driver Management
- Enumerate installed drivers with versions
- Export driver packages for backup
- Identify unsigned/problematic drivers
- Driver update availability check

### Health & Diagnostics
- SMART data for storage devices
- Temperature sensors (when available)
- Event log analysis for hardware errors
- Performance counter baselines

## Script Reference

| Script | Purpose |
|--------|---------|
| `Get-SystemInventory.ps1` | Full system hardware report |
| `Get-HardwareInfo.ps1` | Category-specific hardware data |
| `Get-DriverInventory.ps1` | Driver enumeration and analysis |
| `Export-DriverPackage.ps1` | Backup drivers to folder |
| `Get-StorageHealth.ps1` | SMART and disk health |
| `Get-SystemPerformance.ps1` | Performance counters and baselines |
| `Test-HardwareHealth.ps1` | Comprehensive health check |

## Output Formats

All scripts support `-OutputFormat` parameter:
- `Object` (default): PowerShell objects for pipeline
- `JSON`: Structured JSON for APIs/storage
- `HTML`: Formatted report with styling
- `CSV`: Tabular export

## Integration Notes

Scripts use CIM cmdlets (preferred) with WMI fallback. Registry queries supplement hardware data where CIM lacks detail. All scripts include:
- Elevation detection with graceful degradation
- Error handling with actionable messages
- Progress indication for long operations
- Verbose logging via `-Verbose`

## References

- [WMI Classes Reference](references/wmi-classes.md) - Common WMI/CIM classes
- [Registry Hardware Paths](references/registry-paths.md) - Hardware registry locations
- [SMART Attributes](references/smart-attributes.md) - Storage health interpretation
