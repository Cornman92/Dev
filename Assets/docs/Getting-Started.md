# Getting Started with the Dev Workspace

Welcome to the Dev workspace. This guide walks you through setting up, navigating, and using the tools available.

---

## 1. Prerequisites

Before you begin, make sure you have:

- **Windows 10/11**
- **Git for Windows** - [Download](https://git-scm.com/download/win)
- **PowerShell 5.1+** (pre-installed on Windows 10/11) or **PowerShell 7+** (recommended)
- **VS Code** or **Cursor** editor (recommended)

## 2. Initial Setup

### Clone the Repository

```powershell
git clone <repo-url> C:\Dev
cd C:\Dev
```

### Run the Setup Script

The bootstrap script creates all directories, installs git hooks, and verifies your environment:

```powershell
.\Scripts\Setup-Workspace.ps1
```

If you only need to install the git hooks:

```powershell
.\Scripts\Install-GitHooks.ps1
```

## 3. Directory Structure

| Directory | What Goes Here |
|-----------|---------------|
| `Scratch/` | New experiments and test code |
| `Scripts/` | Production-ready automation scripts |
| `Functions/` | Reusable PowerShell function libraries |
| `Modules/` | Complete PowerShell modules |
| `Optimizations/` | System performance scripts |
| `Registry/` | Registry tweaks (.reg and .ps1) |
| `CurrentProjects/` | Active development projects |
| `Assets/` | Images, docs, and media resources |
| `Artifacts/` | Build outputs, exports, and backups |
| `Archive/` | Completed and retired projects |

## 4. Using the Function Library

Import all functions at once:

```powershell
Import-Module .\Functions\Functions.psd1
```

Or dot-source individual functions:

```powershell
. .\Functions\Write-Log.ps1
. .\Functions\Get-SystemInfo.ps1
. .\Functions\Test-AdminPrivilege.ps1
```

### Available Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `Write-Log` | Structured logging | `Write-Log "Started" -Level Info` |
| `Get-SystemInfo` | System inventory | `Get-SystemInfo -Detailed` |
| `Test-AdminPrivilege` | Check admin elevation | `Test-AdminPrivilege -Require` |
| `ConvertTo-HashtableSplat` | Clean splatting helper | `ConvertTo-HashtableSplat $params` |
| `Get-FileHashBatch` | Batch file hashing | `Get-FileHashBatch -Path "C:\Folder"` |

## 5. Running Scripts

All scripts include comment-based help. View help for any script:

```powershell
Get-Help .\Scripts\Get-DiskUsage.ps1 -Full
```

### Quick Reference

```powershell
# System info
.\Scripts\Get-DiskUsage.ps1
.\Scripts\Export-InstalledSoftware.ps1
.\Scripts\Get-StartupPrograms.ps1

# Maintenance
.\Scripts\Clear-TempFiles.ps1 -WhatIf    # preview first
.\Scripts\Clear-TempFiles.ps1             # then run

# Monitoring
.\Scripts\Watch-ProcessMemory.ps1 -ProcessName "chrome" -DurationMinutes 5
.\Scripts\Get-EventLogSummary.ps1 -Hours 24

# Gaming
.\Scripts\Set-GameMode.ps1 -FullOptimize
.\Scripts\Backup-GameSaves.ps1
.\Scripts\Get-GpuInfo.ps1
```

## 6. Git Workflow

### Commit Convention

All commits must use the conventional format (enforced by hook):

```
type: brief description
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

### Security

The pre-commit hook scans for secrets. If it blocks your commit:

1. Review the flagged file and line
2. Remove or externalize the sensitive data
3. Use environment variables for credentials
4. Stage and commit again

## 7. Development Workflow

1. **Experiment** in `Scratch/`
2. **Test** your code thoroughly
3. **Move** working code to the appropriate directory
4. **Document** with comment-based help headers
5. **Commit** with a conventional commit message

## 8. Key Documents

| Document | What It Contains |
|----------|-----------------|
| [CLAUDE.md](../../CLAUDE.md) | Agent guidelines and coding conventions |
| [CONTRIBUTING.md](../../CONTRIBUTING.md) | Code style and PR guidelines |
| [cursor.md](../../cursor.md) | Editor configuration rules |
| [plan.md](../../plan.md) | Development roadmap |
| [TODO.md](../../TODO.md) | Active task tracker |
| [CHANGELOG.md](../../CHANGELOG.md) | Release and change history |

## 9. Running Tests

Tests use the Pester framework:

```powershell
# Install Pester (if needed)
Install-Module -Name Pester -Force -Scope CurrentUser

# Run all tests
Invoke-Pester -Path .\Tests\

# Run a specific test file
Invoke-Pester -Path .\Tests\Write-Log.Tests.ps1 -Output Detailed
```

## 10. Need Help?

- Check `Get-Help <script-name> -Full` for any script
- Read the relevant documentation files listed above
- Open an issue on GitHub for bugs or feature requests
