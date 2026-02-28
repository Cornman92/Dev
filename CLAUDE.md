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

## Key Files

| File | Purpose |
|------|---------|
| `.gitattributes` | Enforces CRLF line endings for Windows; marks binary files |
| `.gitignore` | Excludes build outputs, secrets, IDE files, OS files (158 rules) |
| `CONTRIBUTING.md` | Code style, branching, commit format, and PR guidelines |
| `plan.md` | Workspace development roadmap and milestone tracking |
| `cursor.md` | Editor/IDE configuration rules for Cursor and VS Code |
| `TODO.md` | Active task list with status tracking |

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
- Target PowerShell 5.1+ compatibility; prefer 7+ features when possible

### Python
- Follow PEP 8 style guidelines
- Use type hints for function signatures
- Use virtual environments (stored in `.venv/`, gitignored)
- Prefer f-strings over `.format()` or `%` formatting

### General
- Keep scripts modular and single-purpose
- Document all scripts with header comments
- Use meaningful variable and function names
- Test thoroughly in `Scratch/` before production use

## Git Configuration

### Line Endings
- Enforced via `.gitattributes` (not just local git config)
- Windows files (`.ps1`, `.bat`, `.cmd`, `.py`, `.js`, `.md`): CRLF
- Unix scripts (`.sh`, `.bash`): LF
- Binary files (images, archives, executables): no conversion

### Git Hooks (Active)

| Hook | Purpose |
|------|---------|
| `pre-commit` | Scans staged files for hardcoded secrets, API keys, passwords, private keys, and connection strings. Blocks commit on detection. |
| `commit-msg` | Validates conventional commit format: `type: description` or `type(scope): description`. Valid types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. |

### Commit Convention
```
type: brief description

Optional longer description if needed.
```
Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Common Commands

```powershell
# Navigate to workspace
cd C:\Dev

# List current projects
ls CurrentProjects/

# Run a script
.\Scripts\script-name.ps1

# Import a function library
. .\Functions\FunctionName.ps1

# Run pre-commit hook manually
sh .git/hooks/pre-commit
```

## Agent Guidelines

When working in this repository:

1. **Prefer editing existing files** over creating new ones
2. **Use Scratch/** for any experimental or test code
3. **Follow the directory structure** - place files in appropriate folders
4. **Check for existing functions** in `Functions/` before creating new ones
5. **Test changes** before committing
6. **Keep commits atomic** - one logical change per commit
7. **Use conventional commits** - the commit-msg hook enforces this
8. **Never commit secrets** - the pre-commit hook scans for them
9. **Update TODO.md** when completing tasks or discovering new work
10. **Consult plan.md** for current priorities and roadmap context

## Important Notes

- This is a Windows environment (use PowerShell-compatible syntax)
- Line endings are CRLF (enforced via `.gitattributes`)
- Avoid committing sensitive data (credentials, API keys, etc.)
- The `$RECYCLE.BIN/` and `System Volume Information/` folders are system folders and should be ignored
- Git hooks are local to each clone - run setup script after fresh clones
