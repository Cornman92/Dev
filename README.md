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
- Your preferred code editor (VS Code recommended)

### Setup

1. Clone or navigate to the repository:
   ```powershell
   cd C:\Dev
   ```

2. Verify Git configuration:
   ```powershell
   git config --list
   ```

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
```

### Development Workflow

1. Create experimental code in `Scratch/`
2. Test thoroughly
3. Move working code to appropriate folder
4. Document and commit changes

## Project Categories

- **Automation** - System automation and task scripts
- **Gaming** - Game development and gaming utilities
- **Utilities** - General-purpose tools and helpers
- **Optimizations** - System performance tweaks

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](LICENSE) for details.
