# CLAUDE.md - Agent Instructions

## Project Overview

Personal development workspace for C-Man. This repository contains automation scripts, gaming projects, system utilities, and general development work.

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `Archive/` | Archived and completed projects |
| `Artifacts/` | Build outputs, generated files, and compiled binaries |
| `Assets/` | Media files, images, icons, and other resources |
| `CurrentProjects/` | Active development work and ongoing projects |
| `Functions/` | Reusable function libraries (PowerShell, Python, etc.) |
| `Modules/` | Modular components and packages |
| `Optimizations/` | Performance optimization scripts and system tweaks |
| `Registry/` | Windows registry scripts and backups |
| `Scratch/` | Temporary and experimental code (testing area) |
| `Scripts/` | Production automation and utility scripts |

## Development Workflow

1. **New experiments** go in `Scratch/` first
2. **Tested code** moves to appropriate folder (`Scripts/`, `Functions/`, etc.)
3. **Completed projects** are archived to `Archive/`
4. **Build outputs** are stored in `Artifacts/`

## Coding Conventions

### PowerShell
- Use approved verbs (Get-, Set-, New-, etc.)
- Include comment-based help for functions
- Use PascalCase for function names
- Use camelCase for variables

### General
- Keep scripts modular and single-purpose
- Document all scripts with header comments
- Use meaningful variable and function names
- Test thoroughly in `Scratch/` before production use

## Common Commands

```powershell
# Navigate to workspace
cd C:\Dev

# List current projects
ls CurrentProjects/

# Run a script
.\Scripts\script-name.ps1
```

## Agent Guidelines

When working in this repository:

1. **Prefer editing existing files** over creating new ones
2. **Use Scratch/** for any experimental or test code
3. **Follow the directory structure** - place files in appropriate folders
4. **Check for existing functions** in `Functions/` before creating new ones
5. **Test changes** before committing
6. **Keep commits atomic** - one logical change per commit

## Important Notes

- This is a Windows environment (use PowerShell-compatible syntax)
- Line endings should be CRLF (configured via git)
- Avoid committing sensitive data (credentials, API keys, etc.)
- The `$RECYCLE.BIN/` and `System Volume Information/` folders are system folders and should be ignored
