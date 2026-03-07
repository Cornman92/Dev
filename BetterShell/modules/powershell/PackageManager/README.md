# Package Manager Module

A centralized package management solution for the Dev workspace, providing consistent package management across all projects.

## Features

- **Unified Package Management**: Manage packages from multiple sources (PowerShell Gallery, Chocolatey, NuGet)
- **Simple Commands**: Intuitive cmdlets for common package operations
- **Dependency Tracking**: Keep track of all installed packages across the workspace
- **Update Management**: Easily check for and apply package updates

## Installation

1. Place the `PackageManager` folder in your PowerShell modules directory

2. Import the module in your PowerShell profile or scripts:

   ```powershell
   Import-Module PackageManager -Force
   ```

## Usage

### Initialize the Package Manager

```powershell
Initialize-PackageManager
```

### Install a Package

```powershell
# Install from default source (PSGallery)
Install-DevPackage -Name "Pester"

# Install specific version
Install-DevPackage -Name "Pester" -Version "5.3.3"

# Install from specific source
Install-DevPackage -Name "git" -Source "Chocolatey"
```

### Update Packages

```powershell
# Update a specific package
Update-DevPackage -Name "Pester"

# Check for available updates
Get-PackageUpdates
```

### List Installed Packages

```powershell
# List all installed packages
Get-InstalledPackages

# Filter by source
Get-InstalledPackages | Where-Object { $_.Source -eq "PSGallery" }
```

## Best Practices

1. **Version Pinning**: Always specify versions for production dependencies
2. **Source Control**: Track your package requirements in version control
3. **Regular Updates**: Schedule regular checks for package updates
4. **Documentation**: Document package dependencies in your project's README

## Contributing

Contributions are welcome! Please follow the standard fork and pull request workflow.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
