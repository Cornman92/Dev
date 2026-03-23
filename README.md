# Dev Workspace

Personal development environment for automation scripts, gaming projects, system utilities, and general development.

## Directory Structure

```
Dev/
├── Archive/          # Archived and completed projects
├── Artifacts/        # Build outputs and generated files
├── Assets/           # Media, images, and resources
├── CurrentProjects/  # Active development work
├── Functions/        # Reusable function libraries
├── Modules/          # Modular components and packages
├── Optimizations/    # Performance optimization scripts
├── Registry/         # Windows registry scripts
├── Scratch/          # Temporary/experimental code
└── Scripts/          # Production automation scripts
```

## Getting Started

### Prerequisites

- Windows 10/11
- Git for Windows
- PowerShell 5.1+ (or PowerShell Core 7+)
- Your preferred code editor (VS Code or Cursor recommended)

### Setup

1. Clone the repository:
   ```powershell
   git clone <repo-url> C:\Dev
   cd C:\Dev
   ```

2. Verify git hooks are in place:
   ```powershell
   ls .git/hooks/pre-commit
   ls .git/hooks/commit-msg
   ```
   If hooks are missing after a fresh clone, copy them from a teammate or re-run the setup script (see `Scripts/` when available).

3. Start developing:
   - New experiments go in `Scratch/`
   - Production scripts go in `Scripts/`
   - Reusable functions go in `Functions/`

## Usage

### Running Scripts

```powershell
# Run a script from the Scripts folder
.\Scripts\script-name.ps1

# Import a function module
Import-Module .\Modules\ModuleName

# Dot-source a function library
. .\Functions\FunctionName.ps1
```

### Development Workflow

1. Create experimental code in `Scratch/`
2. Test thoroughly
3. Move working code to appropriate folder
4. Document and commit changes

## Tooling

| Tool | Purpose |
|------|---------|
| `.gitattributes` | Enforces CRLF line endings; marks binary files |
| `.gitignore` | Excludes 158 patterns across 9 categories |
| `pre-commit` hook | Scans for secrets, API keys, and credentials before commits |
| `commit-msg` hook | Validates conventional commit format (`type: description`) |

### Commit Convention

All commits follow the conventional commit format:

```
type: brief description

Optional body with more detail.
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Project Categories

- **Automation** - System automation and task scripts
- **Gaming** - Game development and gaming utilities
- **Utilities** - General-purpose tools and helpers
- **Optimizations** - System performance tweaks

## Key Documents

| Document | Purpose |
|----------|---------|
| [CLAUDE.md](CLAUDE.md) | Agent instructions and coding conventions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Code style, branching, and PR guidelines |
| [cursor.md](cursor.md) | Editor/IDE configuration rules |
| [plan.md](plan.md) | Workspace development roadmap |
| [TODO.md](TODO.md) | Active task list with status tracking |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](LICENSE) for details.
