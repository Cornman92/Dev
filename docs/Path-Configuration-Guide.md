# 🔧 GaymerPC Path Configuration Guide**Complete guide to path
personalization and environment setup**## 📋 Overview

GaymerPC uses a dynamic path resolution system that allows the entire suite to
  be portable and personalized for any user's system
This guide explains how paths are configured, resolved, and used throughout
  the system.

## 🌍 Environment Variables

### Core Environment Variables

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `GAYMERPC_ROOT `| Main GaymerPC installation directory |`D:\OneDrive\C-Man\Dev\GaymerPC`|
|`GAYMERPC_CORE`| Core modules and frameworks path |`D:\OneDrive\C-Man\Dev\GaymerPC\Core`|
|`GAYMERPC_SCRIPTS`| PowerShell automation scripts path |`D:\OneDrive\C-Man\Dev\GaymerPC\Scripts`|
|`GAYMERPC_CONFIG`| Configuration files path |`D:\OneDrive\C-Man\Dev\GaymerPC\Core\Config`|
|`GAYMERPC_LOGS`| System logs and monitoring data path |`D:\OneDrive\C-Man\Dev\GaymerPC\Core\Logs`|
|`GAYMERPC_CACHE`| Performance cache and temporary files path |`D:\OneDrive\C-Man\Dev\GaymerPC\Core\Cache`|
|`GAYMERPC_PYTHON`| Python executable path |`C:\Python313\python.exe`|

### User Profile Variables

| Variable | Description | Value |
|----------|-------------|-------|
|`GAYMERPC_USER`| User's full name |`Connor O`|
|`GAYMERPC_ALIAS`| User's alias/nickname |`C-Man`|
|`GAYMERPC_EMAIL`| User's email address |`<Saymoner88@gmail.com>`|
|`GAYMERPC_SYSTEM`| Operating system |`Windows 11 Pro 24H2`|

### Hardware Profile Variables

| Variable | Description | Value |
|----------|-------------|-------|
|`GAYMERPC_CPU`| CPU model |`Intel Core i5-9600K`|
|`GAYMERPC_GPU`| GPU model |`NVIDIA GeForce RTX 3060 Ti`|
|`GAYMERPC_RAM`| RAM specification |`32GB DDR4-3200`|

## 🚀 Environment Setup

### Automatic Setup

```powershell

## Run the environment setup script

.\Scripts\Setup-Environment.ps1 -SetUserWide

## Verify the setup

.\Scripts\Initialize-GaymerPC.ps1

```text

### Manual Setup

```powershell

## Set environment variables manually

$env:GAYMERPC_ROOT = "D:\OneDrive\C-Man\Dev\GaymerPC"
$env:GAYMERPC_CORE = "$env:GAYMERPC_ROOT\Core"
$env:GAYMERPC_SCRIPTS = "$env:GAYMERPC_ROOT\Scripts"
$env:GAYMERPC_CONFIG = "$env:GAYMERPC_ROOT\Core\Config"
$env:GAYMERPC_LOGS = "$env:GAYMERPC_ROOT\Core\Logs"
$env:GAYMERPC_CACHE = "$env:GAYMERPC_ROOT\Core\Cache"

## Update Python path

$env:PYTHONPATH = "$env:GAYMERPC_ROOT;$env:PYTHONPATH"

```text

## 📁 Directory Structure

### Standard GaymerPC Layout

```text

GaymerPC/
├── __init__.py                 # Root package initialization

├── Core/                       # Core modules and frameworks

│   ├── __init__.py
│   ├── Config/                 # Configuration files

│   ├── Logs/                   # System logs

│   ├── Cache/                  # Performance cache

│   ├── Performance/            # Performance framework

│   ├── Dashboards/             # System dashboards

│   ├── Monitoring/             # System monitoring

│   ├── Integration/            # Cross-suite integration

│   ├── Automation/             # Automation framework

│   ├── AI/                     # AI/ML components

│   ├── Data/                   # Data management

│   ├── Database/               # Database components

│   ├── Orchestration/          # System orchestration

│   ├── Scripts/                # Core PowerShell scripts

│   ├── Launchers/              # Application launchers

│   ├── Development/            # Development tools

│   ├── Plugins/                # Plugin system

│   └── TUI/                    # Text user interfaces

├── Scripts/                    # Main PowerShell scripts

├── Gaming-Suite/               # Gaming optimization suite

├── Automation-Suite/           # Automation and workflows

├── System-Performance-Suite/   # Performance monitoring

├── Development-Suite/          # Development tools

├── AI-Command-Center/          # AI and ML components

├── Analytics-Suite/            # Analytics and reporting

├── Data-Management-Suite/      # File and data management

├── Windows-Deployment-Suite/   # System deployment tools

├── Cloud-Hub/                  # Cloud integration

├── Security-Suite/             # Security and monitoring

├── Multimedia-Suite/           # Media processing

├── Benchmark-Suite/            # Performance benchmarking

├── Tests/                      # Test suites

└── Docs/                       # Documentation

```text

## 🐍 Python Path Resolution

### Package Structure

Each suite is a proper Python package with `__init__.py`files that define:

- Suite-specific paths and configurations

- Module imports and exports

- Cross-suite communication interfaces

### Import Patterns

#### Core Imports

```python

## Import from GaymerPC root package

import GaymerPC
from GaymerPC import get_user_profile, get_path

## Import from Core modules

from Core.Performance import performance_framework
from Core.Config import load_config
from Core.Dashboards import unified_dashboard

```text

### Suite Imports

```python

## Import from specific suites

from Gaming-Suite.Core import gaming_profile_manager
from Automation-Suite.AI-Workflows import workflow_engine
from System-Performance-Suite.Monitoring import system_monitor
from Development-Suite.Tools import dependency_optimizer

```text

### Cross-Suite Imports

```python

## Import across suite boundaries

from Analytics-Suite.Gaming import gaming_analytics_engine
from AI-Command-Center.Core import async_ai_assistant
from Data-Management-Suite import async_file_manager

```text

### Dynamic Path Resolution

```python

## Get paths dynamically

from GaymerPC import get_path

core_path = get_path("core")
config_path = get_path("config")
logs_path = get_path("logs")

## Use in file operations

import os
from pathlib import Path

log_file = Path(logs_path) / "application.log"
config_file = Path(config_path) / "settings.yaml"

```text

## 🔧 PowerShell Path Resolution

### Dynamic Path Variables

```powershell

## Get GaymerPC root from environment or script location

if ($env:GAYMERPC_ROOT) {
    $script:GaymerPCRoot = $env:GAYMERPC_ROOT
} else {
    $script:GaymerPCRoot = Split-Path $PSScriptRoot -Parent
}

## Construct paths using Join-Path

$logFile = Join-Path $script:GaymerPCRoot "Core\Logs\SystemIntegration.log"
$configFile = Join-Path $script:GaymerPCRoot "Core\Config\unified_config.yaml"
$pythonScript = Join-Path $script:GaymerPCRoot
"Gaming-Suite\Core\gaming_profile_manager.py"

```text

### Environment Integration

```powershell

## Set Python path for subprocesses

$env:PYTHONPATH = Join-Path $script:GaymerPCRoot ";$env:PYTHONPATH"

## Launch Python modules with proper path

& $script:PythonPath $pythonScript

## Create directories if they don't exist

$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

```text

## ⚙️ Configuration Files

### YAML Configuration

```yaml

## Core/Config/unified_config.yaml

user:
  name: "Connor O"
  alias: "C-Man"

system:
  paths:
    gaymerpc_root: "$env:GAYMERPC_ROOT"
    gaymerpc_core: "$env:GAYMERPC_CORE"
    gaymerpc_scripts: "$env:GAYMERPC_SCRIPTS"
    projects: "$env:GAYMERPC_ROOT"
    documents: "$env:USERPROFILE\\Documents"

```text

### JSON Configuration

```json

{
  "gaymerpc": {
    "root_path": "$env:GAYMERPC_ROOT",
    "core_path": "$env:GAYMERPC_CORE",
    "scripts_path": "$env:GAYMERPC_SCRIPTS"
  },
  "user": {
    "name": "Connor O (C-Man)",
    "email": "<Saymoner88@gmail.com>"
  }
}

```text

### XML Configuration

```xml

<?xml version="1.0" encoding="UTF-8"?>
<gaymerpc_settings>
  <gaymerpc>
    <root_path>$env:GAYMERPC_ROOT</root_path>
    <core_path>$env:GAYMERPC_CORE</core_path>
    <scripts_path>$env:GAYMERPC_SCRIPTS</scripts_path>
  </gaymerpc>
</gaymerpc_settings>

```text

## 🔄 Path Resolution Order

### 1. Environment Variables (Highest Priority)

- Check for `GAYMERPC_ROOT`environment variable

- Use if set and valid path exists

### 2. Script Location (Fallback)

- Use`Split-Path $PSScriptRoot -Parent`for PowerShell

- Use`Path(__file__).parent`for Python

### 3. Default Locations (Last Resort)

- Windows:`C:\GaymerPC`- User
- Documents:`$env:USERPROFILE\Documents\GaymerPC`## 🧪 Testing Path
- Configuration

### PowerShell Testing

```powershell

## Test environment variables

Write-Host "GAYMERPC_ROOT: $env:GAYMERPC_ROOT"
Write-Host "GAYMERPC_CORE: $env:GAYMERPC_CORE"
Write-Host "GAYMERPC_SCRIPTS: $env:GAYMERPC_SCRIPTS"

## Test path resolution

$gaymerpcRoot = if ($env:GAYMERPC_ROOT) { $env:GAYMERPC_ROOT } else {
Split-Path $PSScriptRoot -Parent }
Write-Host "Resolved GaymerPC Root: $gaymerpcRoot"

## Test directory structure

$corePath = Join-Path $gaymerpcRoot "Core"
$scriptsPath = Join-Path $gaymerpcRoot "Scripts"
Write-Host "Core exists: $(Test-Path $corePath)"
Write-Host "Scripts exists: $(Test-Path $scriptsPath)"

```text

### Python Testing

```python

## Test GaymerPC package import

try:
    import GaymerPC
    print(f"GaymerPC Root: {GaymerPC.__gaymerpc_root__}")
    print(f"Core Path: {GaymerPC.__core_path__}")
    print(f"Config Path: {GaymerPC.__config_path__}")
except ImportError as e:
    print(f"Import error: {e}")

## Test path functions

from GaymerPC import get_path
core_path = get_path("core")
print(f"Core path: {core_path}")

## Test directory structure (2)

from pathlib import Path
core_dir = Path(core_path)
print(f"Core directory exists: {core_dir.exists()}")

```text

## 🚨 Troubleshooting

### Common Issues

#### 1. Environment Variables Not Set

```powershell

## Solution: Run setup script

.\Scripts\Setup-Environment.ps1 -SetUserWide

```text

### 2. Python Import Errors

```python

## Solution: Check PYTHONPATH

import sys
print("Python Path:")
for path in sys.path:
    print(f"  {path}")

```text

### 3. Missing Directories

```powershell

## Solution: Create required directories

$requiredDirs = @(
    "$env:GAYMERPC_ROOT\Core\Logs",
    "$env:GAYMERPC_ROOT\Core\Cache",
    "$env:GAYMERPC_ROOT\Core\Temp"
)

foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force
    }
}

```text

### 4. Path Resolution Failures

```powershell

## Solution: Debug path resolution

$gaymerpcRoot = if ($env:GAYMERPC_ROOT) {
    $env:GAYMERPC_ROOT
} else {
    Split-Path $PSScriptRoot -Parent
}

Write-Host "GaymerPC Root: $gaymerpcRoot"
Write-Host "Root exists: $(Test-Path $gaymerpcRoot)"

```text

### Validation Script

```powershell

## Run comprehensive path validation

.\Scripts\Initialize-GaymerPC.ps1 -TestIntegration

```text

## 📚 Best Practices

### 1. Always Use Dynamic Paths

- Never hardcode paths in scripts or configuration files

- Use environment variables for user-specific paths

- Use relative paths within suites when possible

### 2. Consistent Path Construction

```powershell

## Good: Use Join-Path

$logFile = Join-Path $script:GaymerPCRoot "Core\Logs\SystemIntegration.log"

## Bad: String concatenation

$logFile = "$script:GaymerPCRoot\Core\Logs\SystemIntegration.log"

```text

### 3. Environment Variable Fallbacks

```powershell

## Good: Check environment variable first

if ($env:GAYMERPC_ROOT) {
    $script:GaymerPCRoot = $env:GAYMERPC_ROOT
} else {
    $script:GaymerPCRoot = Split-Path $PSScriptRoot -Parent
}

## Bad: Only use script location

$script:GaymerPCRoot = Split-Path $PSScriptRoot -Parent

```text

### 4. Directory Creation

```powershell

## Good: Create directories as needed

$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

## Bad: Assume directories exist

$logFile = Join-Path $script:GaymerPCRoot "Core\Logs\SystemIntegration.log"

```text

### 5. Cross-Platform Compatibility

```powershell

## Good: Use Path class for cross-platform compatibility

[System.IO.Path]::Combine($gaymerpcRoot, "Core", "Logs", "SystemIntegration.log")

## Good: Use PowerShell Join-Path

Join-Path $gaymerpcRoot "Core\Logs\SystemIntegration.log"

```text

## 🔗 Related Documentation

- [Main README](README.md) - Overview and quick start

- [Environment Setup](Environment-Setup.md) - Detailed setup instructions

- [Python Integration](Python-Integration.md) - Python package structure

- [PowerShell Integration](PowerShell-Integration.md) - PowerShell automation

- [Configuration Guide](Configuration-Guide.md) - Configuration management

---

* GaymerPC Path Configuration Guide v1.0.0*
