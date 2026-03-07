@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Core.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')
    
    # ID used to uniquely identify this module
    GUID = 'a0e8f8b1-1234-5678-90ab-cdef12345678'
    
    # Author of this module
    Author = 'C-Man'
    
    # Company or vendor of this module
    CompanyName = 'C-Man'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Core PowerShell module containing shared functions and utilities'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Write-ModuleLog',
        'Test-AdminRequirement',
        'Get-FileHashString',
        'Test-IsAdmin',
        'Start-TimedOperation',
        'Stop-TimedOperation',
        'Measure-CommandPerformance',
        'Test-NetworkConnection',
        'Get-FormattedSize',
        'ConvertTo-Base64',
        'ConvertFrom-Base64',
        'Test-ValidPath',
        'Get-TempFilePath',
        'Invoke-WithRetry',
        'Test-IsWindows',
        'Test-IsLinux',
        'Test-IsMacOS',
        'Get-OperatingSystem',
        'Get-EnvironmentInfo',
        'Test-IsElevated',
        'Get-ProcessOwner'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Core', 'Utilities', 'Shared', 'Common')
            
            # A URL to the license for this module.
            # LicenseUri = ''
            
            # A URL to the main website for this project.
            # ProjectUri = ''
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            # ReleaseNotes = ''
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = 'Core'
}
