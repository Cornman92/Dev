@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess   = 'Git.psm1'
    
    # Version number of this module
    ModuleVersion     = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID              = 'b1c2d3e4-f5a6-4b5c-8d7e-9f0a1b2c3d4e'
    
    # Author of this module
    Author            = 'Your Name'
    
    # Company or vendor of this module
    CompanyName       = 'Your Organization'
    
    # Copyright statement for this module
    Copyright         = '(c) 2025 Your Organization. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'Provides enhanced Git workflow functions for PowerShell with improved error handling and usability.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of the .NET Framework required by this module
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion       = '4.0'
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules  = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess   = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'New-GitRepository',
        'Get-GitStatus',
        'New-GitBranch',
        'Submit-GitCommit'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Git', 'VersionControl', 'Development', 'Productivity')
            
            # A URL to the license for this module.
            LicenseUri = 'https://your-organization.com/license'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://your-organization.com/powershell/git'
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
1.0.0 - Initial release with basic Git workflow functions
- New-GitRepository: Initialize new Git repositories with standard configuration
- Get-GitStatus: Get detailed repository status
- New-GitBranch: Create and switch to new branches
- Submit-GitCommit: Create commits with proper formatting
'@
        } # End of PSData hashtable
    } # End of PrivateData hashtable
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
    
    # External module dependencies
    # ExternalModuleDependencies = @('Git')
}
