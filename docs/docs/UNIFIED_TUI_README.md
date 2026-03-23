# 🎮 GaymerPC Master GUI/TUI

## Complete Unified Development Suite

The**GaymerPC Master GUI/TUI**provides both graphical (GUI) and terminal
(TUI) interfaces for all GaymerPC development
tools with unified navigation and personalized paths for Windows 11 Pro x64
Gaming PC environments

>**⚠️ Note**: This document describes the legacy unified TUI. For the
latest Master GUI/TUI interface, see [Master GUI
Guide](MASTER_GUI_GUIDE.md) .

## 🚀 Quick Start

### Launch Options

#### 1. PowerShell Launcher (Recommended)

```powershell

## Launch in new PowerShell window

.\Show-UnifiedTUI.ps1

## Keep window open after exit

.\Show-UnifiedTUI.ps1 -NoExit

## Custom Python path

.\Show-UnifiedTUI.ps1 -PythonPath "C:\Python313\python.exe"

```text

### 2. Batch File Launcher

```cmd

Launch-UnifiedTUI.bat

```text

#### 3. Direct Python Launch

```bash

python unified_tui.py

```text

## 🎯 Interface Overview

### Main Menu (Keyboard Shortcuts 1-6)

-**🏠 Main Menu**- Overview and navigation hub

-**1️⃣ 📁 File Manager**- Advanced file operations

-**2️⃣ 🎯 GaymerPC Suite**- Development tools and automation

-**3️⃣ ⚙️ Environment Config**- Multi-environment management

-**4️⃣ 🔧 Ownership Toolkit**- PowerShell module management

-**5️⃣ 🚀 Electron App**- Electron development workflow

-**6️⃣ 📂 Unified File Manager**- Enhanced file management

### Navigation

-**🖱️ Mouse Clicks**- Click any button to navigate

-**⌨️ Keyboard Shortcuts**- Press 1-6 for direct access

-**Escape Key**- Go back to previous menu

-**Q Key**- Quit application

-**Modern Textual UI**- Sleek, responsive interface

### Quick Actions

-**🧪 Run Tests**- Execute test suites

-**📊 System Info**- Show system diagnostics

-**❓ Help**- Display keyboard shortcuts

## 📋 Submenu Details

### File Manager (1)

- 🔍 Search Files

- 📋 Copy/Move/Delete Files

- 🔍 Find Duplicates

- 🧹 Clean Up Files

- 📊 File Statistics

- 📁 Browse Directory

- 🗂️ Organize Files

### GaymerPC Suite (2)

- 🤖 Automation Tools (scripts, scheduled tasks, jobs)

- 📁 File Management (backup, duplicates, compare)

- 🔧 System Tools (optimize, info, cache clearing)

### Environment Config (3)

- 📋 List/Switch/Create/Edit/Delete configurations

- 📊 Show configuration status

### Ownership Toolkit (4)

- 📦 Install/Remove/List modules

- 🔍 Find modules

- 📝 Create/Execute scripts

### Electron App (5)

- 📦 Install dependencies

- 🏗️ Build application

- 🎯 Run development server

- 🧪 Run tests

- 🔍 Lint code

- 📊 Show package info

### Unified File Manager (6)

- 📁 Browse/Search/Analyze files

- 🗂️ Batch operations

- 💾 Backup & sync

- 🧹 Maintenance

## 🔧 Technical Details

### Requirements

-**Python 3.8+**with Textual framework

-**PowerShell 5.1+**(for launcher scripts)

-**Windows 10/11**(for shortcuts and launchers)

### File Structure

```text

D:\OneDrive\C-Man\Dev\
├── 🎯 unified_tui.py              # Main unified TUI

├── 🐍 Show-UnifiedTUI.ps1         # PowerShell launcher

├── 📜 Launch-UnifiedTUI.bat       # Batch launcher

└── 📖 UNIFIED_TUI_README.md       # This documentation

```text

### Environment Setup

The PowerShell launcher automatically:

- ✅ Detects Python installation

- ✅ Validates TUI script existence

- ✅ Sets proper working directory

- ✅ Launches in dedicated PowerShell window

- ✅ Handles errors gracefully

## 📊 Usage Examples

### Example 1: Quick File Operations

1. Press**1**or click**File Manager**2. Click**🔍 Search Files**3. Enter
search pattern

2. Results display in console

### Example 2: Electron Development

1. Press**5**or click**Electron App**2. Click**📦 Install Dependencies**3.
Wait for completion

2. Click**🏗️ Build Application**### Example 3: System Maintenance

3. Press**2**or click**GaymerPC Suite**2. Click**🔧 System Tools**3.
Click**⚡ Optimize System**## 💡 Tips

-**Keyboard shortcuts**are fastest for power users

-**Mouse navigation**is intuitive for beginners

-**Console output**shows detailed feedback

-**Escape key**always returns to previous menu

-**Q key**quits from anywhere

## 🚀 Future Enhancements

The unified TUI provides a foundation for:

-**Real tool implementations**(currently placeholders)

-**Additional modules**and tools

-**Configuration persistence**-**Plugin system**for extensibility

-**Cross-platform support**---
** 🎯 Ready to revolutionize your development workflow with the Unified
GaymerPC TUI!**
