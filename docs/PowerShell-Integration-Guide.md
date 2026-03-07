# PowerShell Environment Integration Guide

## Overview

The Golden Image SetupBootstrapper now includes comprehensive PowerShell environment integration, combining the power of **PS Profile v2.1.0** and **Ownership Toolkit** to create an optimized development environment.

## Features

### 🔧 **PowerShell Profile Integration**

#### **Optimized PowerShell Profile**
- **Performance Optimizations**: Disabled telemetry, optimized module loading
- **Enhanced Prompt**: Git branch display, command status indicators
- **Custom Aliases**: Common commands (ll, la, grep, .., ...)
- **Utility Functions**: System info, command checking, environment updates
- **Golden Image Integration**: Automatic module loading and welcome messages

#### **Development Environment Setup**
- **Module Installation**: PowerShellGet, PSReadLine, and essential modules
- **Git Configuration**: Standardized Git settings for optimal development
- **VS Code Integration**: PowerShell-specific settings and configurations
- **Directory Structure**: Organized PowerShell modules, scripts, and binaries

#### **Module Performance Optimization**
- **Cache Management**: Clear PowerShell module cache for improved performance
- **Path Optimization**: Prioritized module loading paths
- **Auto-loading**: Intelligent module auto-loading configuration

### 🛠️ **Ownership Toolkit Integration**

#### **Toolkit Management**
- **Path Integration**: Automatic addition to PATH and PSModulePath
- **Script Execution**: Direct access to Ownership Toolkit utilities
- **TUI Support**: Launch Ownership Toolkit Terminal User Interface
- **Status Monitoring**: Real-time toolkit availability and status

#### **Optimization Scripts**
- **Profile Optimization**: Advanced PowerShell performance tuning
- **Development Tools**: Automated development environment setup
- **Performance Analysis**: Module loading and execution analysis

## Configuration

### **GoldenImageConfig.json Settings**

```json
{
  "PowerShellIntegration": {
    "EnablePSProfileIntegration": true,
    "BackupExistingProfile": true,
    "SetupDevEnvironment": true,
    "OptimizeModuleLoading": true,
    "EnableOwnershipToolkit": true,
    "ToolkitPath": "D:\\OneDrive\\Dev\\GaymerPC\\apps\\OwnershipToolkit\\OwnershipToolkit"
  }
}
```

### **Configuration Options**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `EnablePSProfileIntegration` | boolean | true | Enable PS Profile v2.1.0 installation |
| `BackupExistingProfile` | boolean | true | Backup existing PowerShell profile before installation |
| `SetupDevEnvironment` | boolean | true | Install and configure development tools |
| `OptimizeModuleLoading` | boolean | true | Optimize PowerShell module performance |
| `EnableOwnershipToolkit` | boolean | true | Enable Ownership Toolkit integration |
| `ToolkitPath` | string | - | Path to Ownership Toolkit installation |

## Installation and Usage

### **Automatic Installation**

The PowerShell integration is automatically executed during the SetupBootstrapper when:

1. **Phase is set to 'Personalization' or 'All'**
2. **PowerShellIntegration is enabled in configuration**
3. **Required tools are available**

```powershell
# Run with PowerShell integration
.\SetupBootstrapper.ps1 -Phase All -EnablePSProfileIntegration

# Run with Ownership Toolkit only
.\SetupBootstrapper.ps1 -Phase Personalization -EnableOwnershipToolkit

# Skip PowerShell integration
.\SetupBootstrapper.ps1 -Phase All -SkipPowerShellIntegration
```

### **Manual Integration**

#### **PowerShell Profile Manager**

```powershell
# Initialize profile manager
$profileConfig = @{
    EnablePSProfileIntegration = $true
    BackupExistingProfile = $true
    SetupDevEnvironment = $true
    OptimizeModuleLoading = $true
}

$profileManager = [PowerShellProfileManager]::new($logger, $profileConfig)
$profileManager.InstallPSProfile()

# Get profile status
$status = $profileManager.GetProfileStatus()
```

#### **Ownership Toolkit Manager**

```powershell
# Initialize toolkit manager
$toolkitConfig = @{
    EnableOwnershipToolkit = $true
    ToolkitPath = "D:\Path\To\OwnershipToolkit"
    SetupDevEnvironment = $true
}

$toolkitManager = [OwnershipToolkitManager]::new($logger, $toolkitConfig)
$toolkitManager.RunToolkitOptimization()

# Launch TUI
$toolkitManager.LaunchToolkitTUI()

# Get toolkit status
$status = $toolkitManager.GetToolkitStatus()
```

## Generated PowerShell Profile

### **Profile Features**

The installed PowerShell profile includes:

#### **Performance Settings**
```powershell
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'
$env:POWERSHELL_UPDATECHECK = 'Off'
$PSModuleAutoLoadingPreference = 'ModuleNotFound'
```

#### **Enhanced Prompt**
- **Command Status**: Green for success, red for failure
- **Git Integration**: Current branch display
- **Path Display**: Home directory (~) substitution
- **Visual Indicators**: Arrow character with status coloring

#### **Custom Aliases**
```powershell
Set-Alias ll Get-ChildItem -Force
Set-Alias la Get-ChildItem -Force -Option All
Set-Alias grep Select-String -Force
Set-Alias .. Set-Location -Force -ArgumentList ..
Set-Alias ... Set-Location -Force -ArgumentList ../..
```

#### **Utility Functions**
- `Get-SystemInfo`: OS, version, uptime, memory, disk information
- `Test-CommandExists`: Check if command is available
- `Update-Environment`: Refresh PATH environment variable
- `Show-Welcome`: Display system information on startup

#### **Enhanced Tab Completion**
```powershell
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineKeyHandler -Key Tab -Function Complete
```

## Development Environment

### **Installed Components**

#### **PowerShell Modules**
- **PowerShellGet**: Package management and repository access
- **PSReadLine**: Enhanced command line editing experience

#### **Git Configuration**
```bash
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf true
git config --global core.eol lf
```

#### **VS Code Settings**
```json
{
  "powershell.integratedConsole.showOnStartup": false,
  "powershell.integratedConsole.focusConsoleOnExecute": false,
  "editor.formatOnSave": true,
  "editor.tabSize": 4,
  "editor.insertSpaces": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "terminal.integrated.shell.windows": "powershell.exe"
}
```

#### **Directory Structure**
```
C:\Users\%USERNAME%\
├── Documents\
│   └── PowerShell\
│       ├── Modules\
│       ├── Scripts\
│       └── Backup\
├── .config\
│   └── powershell\
└── bin\
```

## Ownership Toolkit Integration

### **Available Scripts**

The Ownership Toolkit provides numerous utility scripts:

#### **Profile Management**
- `Optimize-Profile.ps1`: Profile performance optimization
- `Setup-DevEnvironment.ps1`: Development environment setup

#### **System Administration**
- `Cleanup-Workspace.ps1`: Workspace cleanup utilities
- `Set-WindowsTerminal.ps1`: Windows Terminal configuration
- `Set-VSCodeSettings.ps1`: VS Code configuration

#### **Testing and Validation**
- `Test-FileSystem.ps1`: File system testing
- `Test-NetworkConnection.ps1`: Network connectivity tests
- `Run-AllTests.ps1`: Comprehensive test suite

#### **Development Tools**
- `winget-install.ps1`: Package installation automation
- `Image-Factory.ps1`: System image creation tools

### **TUI Access**

Launch the Ownership Toolkit Terminal User Interface:

```powershell
# Automatic via SetupBootstrapper
.\SetupBootstrapper.ps1 -Phase Personalization -EnableOwnershipToolkit

# Manual launch
$toolkitManager.LaunchToolkitTUI()

# Direct execution
& "D:\Path\To\OwnershipToolkit\Show-OwnershipTUI.ps1"
```

## Troubleshooting

### **Common Issues**

#### **Profile Installation Fails**
- **Cause**: Insufficient permissions or existing profile conflicts
- **Solution**: Run as administrator or enable backup option
- **Log**: Check SetupBootstrapper logs for detailed error messages

#### **Ownership Toolkit Not Found**
- **Cause**: Incorrect toolkit path in configuration
- **Solution**: Update `ToolkitPath` in GoldenImageConfig.json
- **Verification**: Ensure toolkit directory contains `Show-OwnershipTUI.ps1`

#### **Module Installation Issues**
- **Cause**: Network connectivity or repository access problems
- **Solution**: Check internet connection and PowerShell Gallery access
- **Alternative**: Manual module installation via `Install-Module`

#### **Performance Issues**
- **Cause**: Large module cache or inefficient loading paths
- **Solution**: Enable module optimization and clear cache
- **Command**: `Clear-ModuleCache` (available in optimized profile)

### **Debug Mode**

Enable debug logging for detailed troubleshooting:

```powershell
.\SetupBootstrapper.ps1 -Phase All -LogLevel Debug -EnablePSProfileIntegration
```

### **Recovery Options**

#### **Profile Backup Restoration**
```powershell
# Find latest backup
$backupDir = Get-ChildItem "$env:USERPROFILE\Documents\PowerShell\Backup" | 
    Sort-Object Name -Descending | Select-Object -First 1

# Restore profile
Copy-Item "$backupDir\Microsoft.PowerShell_profile.ps1" $PROFILE -Force
```

#### **Reset to Default**
```powershell
# Remove custom profile
Remove-Item $PROFILE -Force -ErrorAction SilentlyContinue

# Restart PowerShell to load default profile
```

## Performance Optimization

### **Module Loading Optimization**

1. **Path Prioritization**: User modules prioritized over system modules
2. **Cache Management**: Automatic cache clearing during optimization
3. **Auto-loading**: Intelligent module auto-loading based on usage patterns

### **Profile Performance**

1. **Lazy Loading**: Heavy operations deferred until needed
2. **Error Handling**: Graceful degradation for missing dependencies
3. **Memory Management**: Optimized variable and function loading

### **Startup Time Reduction**

- **Telemetry Disabled**: Reduced Windows PowerShell startup overhead
- **Progress Preference**: Optimized for script execution
- **Strict Mode**: Improved error detection and performance

## Advanced Configuration

### **Custom Profile Modifications**

The generated profile can be customized by editing:

```powershell
$profilePath = $PROFILE.CurrentUserAllHosts
notepad $profilePath
```

### **Additional Modules**

Add custom modules to the profile:

```powershell
# Add to profile after installation
Import-Module CustomModule -ErrorAction SilentlyContinue
```

### **Environment Variables**

Set custom environment variables:

```powershell
# Add to profile
$env:CUSTOM_VAR = "CustomValue"
```

## Integration with Other Features

### **Security Integration**
- **Profile Security**: Signed scripts and execution policies
- **Module Verification**: Hash validation for loaded modules
- **Access Control**: Restricted module loading paths

### **Cloud Integration**
- **Profile Sync**: Cloud-based profile synchronization
- **Module Backup**: Automatic backup to cloud storage
- **Settings Sync**: Cross-environment configuration sync

### **Monitoring Integration**
- **Performance Metrics**: Profile loading time tracking
- **Usage Analytics**: Module and command usage statistics
- **Health Monitoring**: Profile integrity and performance monitoring

## Best Practices

### **Profile Management**
1. **Regular Backups**: Enable automatic profile backups
2. **Version Control**: Store profile in Git repository
3. **Testing**: Test profile changes in isolated environment first

### **Module Management**
1. **Selective Loading**: Only load required modules
2. **Regular Updates**: Keep modules updated for security and performance
3. **Documentation**: Document custom modules and functions

### **Development Environment**
1. **Consistent Configuration**: Maintain consistent settings across machines
2. **Team Standards**: Establish team-wide development standards
3. **Automation**: Automate repetitive setup tasks

## Support and Maintenance

### **Regular Maintenance Tasks**

1. **Profile Cleanup**: Remove unused functions and aliases
2. **Module Updates**: Update installed PowerShell modules
3. **Performance Review**: Monitor profile loading performance
4. **Backup Verification**: Ensure backup systems are working

### **Getting Help**

- **SetupBootstrapper Logs**: Check detailed execution logs
- **PowerShell Help**: Use `Get-Help` for function documentation
- **Community Forums**: PowerShell and Ownership Toolkit communities
- **Documentation**: Refer to this guide and tool-specific documentation

---

**This integration provides a comprehensive, optimized PowerShell environment that enhances productivity while maintaining security and performance standards.**
