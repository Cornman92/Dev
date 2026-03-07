@{
    RootModule = 'ModuleTemplate.psm1'
    ModuleVersion = '1.0.0'
    GUID = '00000000-0000-0000-0000-000000000000'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2025 Windows Automation Workspace. All rights reserved.'
    Description = 'Template module - customize this for your module'
    PowerShellVersion = '7.0'
    
    # Functions to export
    FunctionsToExport = @(
        'Get-ModuleFunction1'
    )
    
    # Cmdlets to export (if any)
    CmdletsToExport = @()
    
    # Variables to export (if any)
    VariablesToExport = @()
    
    # Aliases to export (if any)
    AliasesToExport = @()
    
    # Required modules
    RequiredModules = @()
    
    # Required assemblies
    RequiredAssemblies = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Template', 'Module')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Template module - customize for your needs'
        }
    }
}
