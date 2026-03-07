@{
    # Basic module information
    RootModule        = 'System-Utilities.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = '5c9b7a1d-1234-5678-90ab-cdef12345678'
    Author            = 'C-Man'
    CompanyName       = 'Personal'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'Comprehensive system monitoring and management utilities with enhanced performance and reliability.'
    PowerShellVersion = '5.1'
    
    # Module dependencies
    RequiredModules = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '1.0.0' },
        @{ ModuleName = 'PSScheduledJob' }
    )
    
    # Assemblies that must be loaded
    RequiredAssemblies = @(
        'System.Management',
        'System.ServiceProcess',
        'Microsoft.Update.Session'
    )
    
    # Script files (.ps1) that are run in the caller's environment
    ScriptsToProcess = @('Initialize-Environment.ps1')
    
    # Type files (.ps1xml) to be loaded
    TypesToProcess = @('System.Types.ps1xml')
    
    # Format files (.ps1xml) to be loaded
    FormatsToProcess = @('System.Formats.ps1xml')
    
    # Functions to export
    FunctionsToExport = @(
        # System Information
        'Get-SystemInfo',
        'Get-OSDetails',
        'Get-HardwareInfo',
        'Get-InstalledUpdates',
        'Get-StartupPrograms',
        
        # Network
        'Get-NetworkInfo',
        'Get-NetworkAdapters',
        'Test-NetworkLatency',
        'Get-NetworkStatistics',
        'Get-DNSCache',
        
        # Disk
        'Get-DiskInfo',
        'Get-DiskUsage',
        'Optimize-DiskSpace',
        'Get-DiskHealth',
        'Get-FileSizeAnalysis',
        
        # Process Management
        'Get-RunningProcesses',
        'Optimize-Processes',
        'Find-LockedFiles',
        'Get-ProcessDependencies',
        'Set-ProcessPriority',
        
        # System Maintenance
        'Start-SystemMaintenance',
        'Clear-SystemTemporaryFiles',
        'Optimize-WindowsUpdate',
        'Repair-WindowsImage',
        'Get-SystemHealthReport'
    )
    
    # Aliases to export
    AliasesToExport = @(
        'gsys',
        'gnic',
        'gdisk',
        'gproc',
        'sysmaint'
    )
    
    # List of all files packaged with this module
    FileList = @(
        'System-Utilities.psd1',
        'System-Utilities.psm1',
        'en-US\System-Utilities.psd1',
        'en-US\about_System-Utilities.help.txt',
        'bin\SystemUtilities.dll',
        'formats\*.ps1xml',
        'types\*.ps1xml',
        'private\*.ps1',
        'public\*.ps1'
    )
    
    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for discovery in online galleries
            Tags = @('System', 'Utilities', 'Admin', 'Monitoring', 'Performance', 'Maintenance')
            
            # A URL to the license for this module
            LicenseUri = 'https://opensource.org/licenses/MIT'
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/yourusername/PowerShell-Utilities'
            
            # A URL to an icon representing this module
            IconUri = 'https://raw.githubusercontent.com/yourusername/PowerShell-Utilities/main/icon.png'
            
            # Release notes for this version
            ReleaseNotes = @'
## 2.0.0 - Major Update
- Added comprehensive system monitoring capabilities
- Enhanced performance with parallel processing
- Added disk health checking and optimization
- Improved network diagnostics
- Added system maintenance automation
- Added support for remote management
'@
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update
            RequireLicenseAcceptance = $false
            
            # External dependent modules this module requires
            ExternalModuleDependencies = @('PSScheduledJob', 'PSWorkflow')
            
            # Supported PSEditions
            CompatiblePSEditions = @('Desktop', 'Core')
            
            # Minimum version of the Windows PowerShell engine required by this module
            PowerShellVersion = '5.1'
            
            # Minimum version of the common language runtime (CLR) required by this module
            CLRVersion = '4.0'
        }
    }
    
    # Help info URI of this module
    HelpInfoURI = 'https://github.com/yourusername/PowerShell-Utilities/wiki'
    
    # Default prefix for commands exported from this module
    DefaultCommandPrefix = 'SysUtil'
    
    # Module auto-loading preference
    ModuleList = @('System-Utilities')
    
    # List of all modules packaged with this module
    NestedModules = @('System.Monitoring.psm1', 'System.Maintenance.psm1')
    
    # Processor architecture (None, X86, Amd64) required by this module
    ProcessorArchitecture = 'Amd64'
    
    # Assemblies that must be loaded prior to importing this module
    # PowerShellGalleryModule = @{ 
    #     ModuleName = 'System-Utilities';
    #     RequiredVersion = '2.0.0';
    #     Guid = '5c9b7a1d-1234-5678-90ab-cdef12345678';
    #     ModuleType = 'Script';
    #     Author = 'C-Man';
    #     Description = 'Comprehensive system monitoring and management utilities';
    #     PowerShellVersion = '5.1';
    #     Tags = @('System', 'Utilities', 'Admin');
    #     ProjectUri = 'https://github.com/yourusername/PowerShell-Utilities';
    #     LicenseUri = 'https://opensource.org/licenses/MIT';
    #     ReleaseNotes = 'Major update with enhanced features and performance improvements';
    # }
}
