@{
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-1234-5678-90ab-cdef12345678'
    
    # Author of this module
    Author = 'Dev Workspace Administrator'
    
    # Company or vendor of this module
    CompanyName = 'Dev Workspace'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Dev Workspace. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Centralized package management for Dev workspace'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ ModuleName = 'PackageManagement'; ModuleVersion = '1.4.7' },
        @{ ModuleName = 'PowerShellGet'; ModuleVersion = '2.2.5' }
    )
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Install-DevPackage',
        'Update-DevPackage',
        'Get-InstalledPackages',
        'Get-PackageUpdates',
        'Initialize-PackageManager'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('PackageManagement', 'Automation', 'DevTools')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of the centralized package management module.'
        }
    }
}
