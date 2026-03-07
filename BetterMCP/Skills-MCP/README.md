# Claude Skills & MCP Servers

**Version**: 1.0  
**Status**: 100% Complete  
**Last Updated**: February 3, 2026

---

## Overview

This collection provides AI-accessible interfaces for Windows system management, enabling Claude and other LLMs to interact with Windows systems through well-defined skills and MCP (Model Context Protocol) servers.

---

## Architecture

```
Skills-MCP/
├── skills/
│   ├── windows-hardware-config/     # Hardware configuration skill
│   ├── windows-image-servicing/     # Image servicing skill
│   ├── widt-drivers/                # Driver management skill
│   ├── widt-wim/                    # WIM operations skill
│   ├── widt-winpe/                  # WinPE builder skill
│   ├── widt-unattend/               # Answer file skill
│   ├── widt-iso/                    # Boot media skill
│   └── widt-osd/                    # OS deployment skill
│
└── mcp-servers/
    ├── windows-hardware-mcp/        # Hardware MCP server
    └── windows-image-servicing-mcp/ # Image servicing MCP server
```

---

## Skills Summary

| Skill | Size | Functions | Description |
|-------|------|-----------|-------------|
| windows-hardware-config | 27KB | 25 | Hardware inventory, driver management, system health |
| windows-image-servicing | 53KB | 30+ | DISM operations, WIM servicing, package management |
| widt-drivers | 27KB | 18 | Driver repository, hardware detection, injection |
| widt-wim | 53KB | 28 | WIM operations, compression, servicing |
| widt-winpe | 57KB | 24 | WinPE creation, component management |
| widt-unattend | 57KB | 30 | Answer file generation, validation |
| widt-iso | 32KB | 20 | Bootable media creation |
| widt-osd | 47KB | 36 | OS deployment, disk prep, boot config |

**Total**: 273KB, 211+ functions

---

## Skill Details

### windows-hardware-config

Hardware inventory and configuration management.

**Capabilities**:
- CPU, memory, disk, GPU information retrieval
- Driver backup and restore operations
- Hardware health monitoring (S.M.A.R.T., temperatures)
- Device management (enable, disable, update)
- System baseline creation

**Key Functions**:
```
get_cpu_info
get_memory_info
get_disk_info
get_gpu_info
get_network_adapters
backup_drivers
restore_drivers
get_problem_devices
get_system_health
create_hardware_report
```

### windows-image-servicing

Windows image servicing operations.

**Capabilities**:
- Online and offline DISM operations
- WIM mounting and unmounting
- Driver injection for offline images
- Package and feature management
- AppX provisioning
- Image repair and health checks

**Key Functions**:
```
mount_wim_image
dismount_wim_image
add_offline_drivers
remove_offline_drivers
enable_offline_feature
disable_offline_feature
add_offline_package
remove_offline_package
get_offline_packages
get_offline_features
repair_online_image
check_image_health
```

### widt-drivers

Comprehensive driver management.

**Capabilities**:
- Driver inventory and information
- Repository management
- Hardware detection
- Online and offline injection
- Package creation

### widt-wim

WIM image operations.

**Capabilities**:
- Image information and indexing
- Mount/dismount operations
- Capture and apply
- Format conversion (WIM ↔ ESD)
- Splitting and merging

### widt-winpe

WinPE environment builder.

**Capabilities**:
- Environment creation
- Component management
- Driver and script injection
- Startup customization
- ISO generation

### widt-unattend

Unattended installation configuration.

**Capabilities**:
- Answer file creation
- Setting configuration
- Disk configuration
- Domain join setup
- Post-install commands

### widt-iso

Bootable media creation.

**Capabilities**:
- ISO creation
- USB boot media
- Multiboot support
- UEFI/Legacy modes

### widt-osd

Operating system deployment.

**Capabilities**:
- Disk preparation
- Image application
- Boot configuration
- Driver injection
- Sysprep operations

---

## MCP Server Details

### windows-hardware-mcp

TypeScript-based MCP server for hardware operations.

**Installation**:
```bash
cd mcp-servers/windows-hardware-mcp
npm install
npm run build
```

**Tools**:
```typescript
// 25+ tools available
get_cpu_info
get_memory_info
get_disk_info
get_gpu_info
get_network_adapters
get_system_health
backup_all_drivers
backup_drivers_by_class
restore_driver_backup
get_problem_devices
enable_device
disable_device
update_device_driver
get_driver_info
get_installed_drivers
get_driver_updates
export_hardware_report
get_smart_status
get_temperatures
create_hardware_baseline
compare_hardware_baseline
get_usb_devices
get_pci_devices
get_battery_status
run_hardware_diagnostics
```

**Claude Desktop Configuration**:
```json
{
  "mcpServers": {
    "windows-hardware": {
      "command": "node",
      "args": ["path/to/windows-hardware-mcp/dist/index.js"]
    }
  }
}
```

### windows-image-servicing-mcp

TypeScript-based MCP server for image servicing.

**Installation**:
```bash
cd mcp-servers/windows-image-servicing-mcp
npm install
npm run build
```

**Tools**:
```typescript
// 30+ tools available
mount_wim
dismount_wim
get_wim_info
add_offline_drivers
remove_offline_drivers
get_offline_drivers
enable_offline_feature
disable_offline_feature
get_offline_features
add_offline_package
remove_offline_package
get_offline_packages
add_offline_capability
get_offline_capabilities
get_mounted_images
optimize_mounted_image
export_wim_index
apply_wim
capture_wim
repair_online_image
check_online_health
get_online_packages
get_online_features
cleanup_component_store
remove_provisioned_appx
get_provisioned_appx
set_edition
get_edition_info
export_unattend_template
validate_unattend
```

**Claude Desktop Configuration**:
```json
{
  "mcpServers": {
    "windows-image-servicing": {
      "command": "node",
      "args": ["path/to/windows-image-servicing-mcp/dist/index.js"]
    }
  }
}
```

---

## Integration Examples

### Using Skills with Claude

```markdown
User: I need to check the health of my system drives.

Claude: I'll use the windows-hardware-config skill to check your drive health.

[Uses get_smart_status tool]

Your system has 2 drives:
- Samsung SSD 970 EVO (C:): Healthy - 98% life remaining
- WD Blue 2TB (D:): Healthy - 1 reallocated sector (monitor)

Would you like me to create a full hardware health report?
```

### Using MCP Servers

```markdown
User: Mount the Windows 11 install.wim and add network drivers.

Claude: I'll mount the image and inject the drivers.

[Uses mount_wim tool]
Mounted install.wim index 1 to C:\Mount

[Uses add_offline_drivers tool]
Added 12 network drivers to the mounted image

[Uses dismount_wim tool]
Saved changes and dismounted image

The Windows 11 image now has your network drivers injected.
```

---

## Requirements

### Skills
- Claude with skill support
- PowerShell 7.4+
- Administrator privileges

### MCP Servers
- Node.js 18+
- TypeScript
- PowerShell 7.4+
- Administrator privileges

---

## Integration with Better11

Skills and MCP servers use the same PowerShell modules as Better11:

```
Better11.Drivers ←→ windows-hardware-config, widt-drivers
Better11.DeploymentTools ←→ windows-image-servicing, widt-*
WindowsOps.* ←→ Various skills
WIDT.* ←→ widt-* skills
```

---

## License

MIT License
