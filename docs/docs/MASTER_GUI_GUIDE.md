# 🎮 GaymerPC Master GUI/TUI - Complete User Guide

## Overview

The**GaymerPC Master GUI/TUI**is the unified interface for all GaymerPC
development tools and modules. It provides
both graphical (GUI) and terminal (TUI) interfaces with personalized paths
for Windows 11 Pro x64 Gaming PC
environments.

## 🚀 Quick Start

### Launch Options

#### 1. Batch File Launcher (Easiest)

```cmd

## GUI Mode (Recommended for beginners)

Launch-MasterGUI.bat gui

## TUI Mode (For terminal users)

Launch-MasterGUI.bat tui

## Auto Mode (Automatically chooses best interface)

Launch-MasterGUI.bat

```text

### 2. PowerShell Launcher (Advanced)

```powershell

## Basic launch

.\Launch-MasterGUI.ps1

## Specify mode and options

.\Launch-MasterGUI.ps1 -Mode gui -NoExit -InstallDeps

## Custom workspace path

.\Launch-MasterGUI.ps1 -Workspace "D:\Custom\Path" -Mode tui

```text

### 3. Direct Python Launch

```bash

## GUI Mode

python Master_GUI.py --mode gui

## TUI Mode

python Master_GUI.py --mode tui

## Auto Mode (default)

python Master_GUI.py

```text

## 🖥️ GUI Mode Interface

### Main Window Layout

```text

┌─────────────────────────────────────────────────────────────┐
│ 🎮 GaymerPC Master Development Suite                        │
│ Workspace: D:\OneDrive\C-Man\Dev                           │
├─────────────────────┬───────────────────────────────────────┤
│ 📋 Available Modules│ ⚡ Quick Actions & Info               │
│                     │                                       │
│ 1. 📁 File Manager  │ [Run Tests] [System Info]            │
│ Advanced file ops   │ [Update Deps] [Build All]            │
│                     │ [Clean Workspace] [Backup]           │
│ 2. 🎯 GaymerPC Suite│ [Open VS Code] [Open PowerShell]     │
│ Development tools   │                                       │
│                     │ 💻 System Information                │
│ 3. ⚙️ Environment   │ ┌─────────────────────────────────┐   │
│ Multi-env config    │ │ 🖥️ System: Windows 11 Pro x64  │   │
│                     │ │ 🎮 Target: Gaming PC Dev Env   │   │
│ 4. 🔧 Ownership     │ │ 📁 Workspace: D:\OneDrive\...  │   │
│ PowerShell modules  │ │ 🐍 Python: python              │   │
│                     │ │ 💻 PowerShell: powershell.exe  │   │
│ 5. 🚀 Electron App  │ │ 📝 VS Code: code               │   │
│ Desktop app dev     │ │                                 │   │
│                     │ │ 📊 Modules: 8 Available        │   │
│ 6. 🛠️ System Tools  │ │ ⚡ Actions: 8 Available        │   │
│ System admin        │ │ 🕒 Last Updated: 2025-01-...  │   │
│                     │ └─────────────────────────────────┘   │
│ 7. 📊 Project Mgr   │                                       │
│ Project monitoring  │                                       │
│                     │                                       │
│ 8. 🔒 Security Suite│                                       │
│ Security management │                                       │
├─────────────────────┴───────────────────────────────────────┤
│ 📺 Console Output                                           │
│ [12:34:56] 🎮 GaymerPC Master GUI started successfully!   │
│ [12:34:56] 💡 Use number keys 1-8 for quick module access  │
│ [12:34:56] ❓ Press F1 for help                           │
└─────────────────────────────────────────────────────────────┘
│ Press number keys 1-8 for quick module access | F1: Help | Ctrl+Q: Quit
└─────────────────────────────────────────────────────────────┘

```text

### Navigation Methods

#### 🖱️ Mouse Navigation

-**Click module buttons**to launch specific tools

-**Click quick action buttons**for immediate tasks

-**Scroll console output**to view command results

-**Resize windows**for optimal layout

#### ⌨️ Keyboard Shortcuts

-**1-8**: Launch modules directly (1=File Manager, 2=GaymerPC Suite, etc.)

-**F1**: Show help dialog

-**Ctrl+Q**: Quit application

-**Escape**: Quit application

-**Tab**: Navigate between interface elements

### Module Details

#### 1. 📁 File Manager**Purpose**: Advanced file operations with ML-powered organization**Features**

- 🔍**Search Files**: Pattern matching, size filters, date filters

- 📋**File Operations**: Copy, move, delete, rename files and directories

- 🔍**Find Duplicates**: Detect and manage duplicate files

- 🧹**Clean Up Files**: Remove temporary and unnecessary files

- 📊**File Statistics**: Analyze disk usage and file patterns

- 📁**Browse Directory**: Interactive directory navigation

- 🗂️**Organize Files**: ML-powered file classification and organization

#### 2. 🎯 GaymerPC Suite**Purpose**: Development tools and automation**Features**

- 🤖**Automation Tools**: Scripts, scheduled tasks, background jobs

- 📁**File Management**: Backup, duplicates, file comparison

- 🔧**System Tools**: System optimization, cache clearing, performance tuning

- 📊**Monitoring**: Real-time system monitoring and alerts

#### 3. ⚙️ Environment Config**Purpose**: Multi-environment configuration management**Features**

- 📋**Configuration Management**: Create, edit, and manage configurations

- 🔄**Environment Switching**: Switch between development, staging, production

- ✅**Validation**: Validate configuration files and settings

- 📊**Status Display**: Show current environment status

#### 4. 🔧 Ownership Toolkit**Purpose**: PowerShell module management and development**Features**

- 📦**Module Management**: Install, remove, update PowerShell modules

- 🔍**Module Discovery**: Find and search available modules

- 📝**Script Creation**: Create and execute PowerShell scripts

- 🧪**Testing**: Test modules and scripts

#### 5. 🚀 Electron App**Purpose**: Electron development workflow and tools**Features**

- 📦**Dependency Management**: Install and update dependencies

- 🏗️**Build System**: Build applications for multiple platforms

- 🎯**Development Server**: Launch development servers

- 🧪**Testing**: Run application tests

- 🔍**Linting**: Code quality checks

#### 6. 🛠️ System Tools**Purpose**: System administration and optimization**Features**

- ⚡**Performance Optimization**: System performance tuning

- 🔒**Security Management**: Security configuration and monitoring

- 🧹**Maintenance**: System cleanup and maintenance tasks

- 📊**Monitoring**: System health and performance monitoring

#### 7. 📊 Project Manager**Purpose**: Project discovery and health monitoring**Features**

- 🔍**Project Discovery**: Find and catalog projects

- 💚**Health Monitoring**: Monitor project health and status

- 📈**Analytics**: Project analytics and reporting

- 📋**Reporting**: Generate project reports

#### 8. 🔒 Security Suite**Purpose**: Security and compliance management**Features**

- 🔍**Audit**: Security auditing and compliance checks

- 📋**Compliance**: Compliance management and reporting

- 🚨**Threat Detection**: Advanced threat detection

- 📊**Reporting**: Security reports and dashboards

### Quick Actions

#### 🧪 Run Tests

Executes the comprehensive test suite for all projects

#### 📊 System Info

Displays detailed system information and diagnostics

#### 📦 Update Dependencies

Updates all project dependencies (Python, PowerShell, npm)

#### 🏗️ Build All

Builds all projects in the workspace

#### 🧹 Clean Workspace

Removes temporary files, caches, and build artifacts

#### 💾 Backup Workspace

Creates a timestamped backup of the entire workspace

#### 📝 Open VS Code

Launches VS Code with the workspace loaded

#### 💻 Open PowerShell

Opens a new PowerShell window in the workspace directory

## 💻 TUI Mode Interface

### Features

-**Textual Framework**: Modern terminal-based interface

-**Keyboard Navigation**: Full keyboard control

-**Responsive Layout**: Adapts to terminal size

-**Cross-platform**: Works on any terminal environment

### Navigation

-**Arrow Keys**: Navigate between options

-**Enter**: Select option

-**Tab**: Switch between sections

-**Q**: Quit application

-**H**: Show help

### Layout

```text

┌─────────────────────────────────────────────────────────────┐
│ 🎮 GaymerPC Master TUI                                      │
├─────────────────────┬───────────────────────────────────────┤
│ 📋 Available Modules│ ⚡ Quick Actions                      │
│                     │                                       │
│ 1. 📁 File Manager  │ [Run Tests]                          │
│ 2. 🎯 GaymerPC Suite│ [System Info]                        │
│ 3. ⚙️ Environment   │ [Update Dependencies]                │
│ 4. 🔧 Ownership     │ [Build All]                          │
│ 5. 🚀 Electron App  │ [Clean Workspace]                    │
│ 6. 🛠️ System Tools  │ [Backup Workspace]                   │
│ 7. 📊 Project Mgr   │ [Open VS Code]                       │
│ 8. 🔒 Security Suite│ [Open PowerShell]                    │
│                     │                                       │
│ [Q] Quit [H] Help   │                                       │
├─────────────────────┴───────────────────────────────────────┤
│ Press Q to quit, H for help, or use arrow keys to navigate  │
└─────────────────────────────────────────────────────────────┘

```text

## ⚙️ Configuration

### Personalized Paths

The Master GUI/TUI is configured with personalized paths for Windows 11 Pro
x64 Gaming PC:

```python

## Workspace Configuration

workspace_root = "D:\\OneDrive\\C-Man\\Dev"
gaymerpc_root = "D:\\OneDrive\\C-Man\\Dev\\GaymerPC"
config_root = "D:\\OneDrive\\C-Man\\Dev\\config"
docs_root = "D:\\OneDrive\\C-Man\\Dev\\docs"
ownership_toolkit = "D:\\OneDrive\\C-Man\\Dev\\OwnershipToolkit"

## Executable Paths

python_path = "python"           # Auto-detected

powershell_path = "powershell.exe"
code_path = "code"               # VS Code

```text

### Customization

You can customize the Master GUI/TUI by:

1.**Modifying Module Definitions**: Edit the `modules`dictionary
in`Master_GUI.py`2.**Adding Quick Actions**: Add new actions to
the`quick_actions`dictionary

3.**Changing Paths**: Update paths in the launcher scripts

4.**Customizing Appearance**: Modify colors, fonts, and layout in the GUI code

## 🐛 Troubleshooting

### Common Issues

#### Python Not Found

```text

❌ Python not found. Please install Python 3.8+ or specify path with -PythonPath
💡 Download Python from: <<https://www.python.org/downloads>/>

```text**Solution**:

1. Install Python 3.8+ from python.org

2. Add Python to PATH during installation

3. Or specify custom path: `.\Launch-MasterGUI.ps1 -PythonPath
"C:\Python313\python.exe"`#### PowerShell Execution Policy

```text

❌ PowerShell execution policy prevents script execution

```text**Solution**:

```powershell

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

```text

#### Missing Dependencies

```text

❌ Module 'textual' not found

```text**Solution**:

```bash

## Install dependencies automatically

.\Launch-MasterGUI.ps1 -InstallDeps

## Or install manually

pip install textual rich click psutil

```text

### Workspace Not Found

```text

❌ Workspace not found: D:\OneDrive\C-Man\Dev

```text**Solution**:

1. Ensure the workspace path is correct

2. Or specify custom path: `.\Launch-MasterGUI.ps1 -Workspace
"D:\Your\Path"`### Debug Mode

Enable debug mode for detailed error information:

```powershell

## PowerShell debug mode

$VerbosePreference = "Continue"
.\Launch-MasterGUI.ps1 -Verbose

## Python debug mode

python Master_GUI.py --verbose

```text

## 📞 Support

### Getting Help

1.**F1 Key**: Press F1 in GUI mode for built-in help

2.**Documentation**: Check the `docs/`folder for detailed guides

3.**Console Output**: Monitor the console output panel for error messages

4.**Log Files**: Check for log files in the workspace directory

### Reporting Issues

When reporting issues, please include:

- Operating system version

- Python version

- PowerShell version

- Error messages from console output

- Steps to reproduce the issue

### Feature Requests

To request new features:

1. Describe the desired functionality

2. Explain the use case

3. Suggest implementation approach (if applicable)

## 🔄 Updates and Maintenance

### Updating the Master GUI/TUI

```bash

## Update from repository

git pull origin main

## Update dependencies

.\Launch-MasterGUI.ps1 -InstallDeps

## Test the updated system

python Master_GUI.py --test

```text

### Backup and Restore

```bash

## Create backup

Launch-MasterGUI.bat gui

## Click "Backup Workspace" in Quick Actions

## Or use command line

robocopy "D:\OneDrive\C-Man\Dev" "D:\Backups\GaymerPC_Backup" /E /XD
node_modules .git

```text

---
** 🎮 Ready to revolutionize your development workflow with the GaymerPC
Master GUI/TUI!**For more information, visit the main documentation in the
` docs/` folder.
