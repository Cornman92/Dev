@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess   = 'Network.psm1'
    
    # Version number of this module
    ModuleVersion     = '1.1.0'
    
    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d'
    
    # Author of this module
    Author            = 'Your Name'
    
    # Company or vendor of this module
    CompanyName       = 'Your Organization'
    
    # Copyright statement for this module
    Copyright         = '(c) 2025 Your Organization. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'Provides network diagnostics, scanning, and management functions for Windows systems.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Minimum version of the .NET Framework required by this module
    DotNetFrameworkVersion = '4.7.2'
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion       = '4.0'
    
    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @('System.Net', 'System.Net.Sockets', 'System.Net.Ping')
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess   = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Test-NetworkConnectivity',
        'Test-NetworkConnection',
        'Start-PortScan',
        'Get-NetworkAdapter',
        'Clear-DnsClientCache'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Network', 'Diagnostics', 'PortScan', 'TCP', 'Ping', 'DNS', 'Troubleshooting')
            
            # A URL to the license for this module.
            LicenseUri = 'https://your-organization.com/license'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://your-organization.com/powershell/network'
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
1.1.0 - Enhanced Network Diagnostics
- Added Test-NetworkConnection for comprehensive network diagnostics
- Improved performance with better .NET integration
- Enhanced error handling and reporting
- Added support for traceroute functionality
- Optimized port scanning with better thread management

1.0.0 - Initial Release
- Basic network connectivity testing
- Port scanning capabilities
- Network adapter information
- DNS cache management
'@
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
