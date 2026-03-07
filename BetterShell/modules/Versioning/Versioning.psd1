@{
    RootModule = 'Versioning.psm1'
    ModuleVersion = '0.1.0'
    GUID = '11111111-1111-4111-8111-111111111111'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-Better11Version', 'Set-Better11Version', 'New-Better11Tag')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Versioning')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Version management for Better11 Suite'
        }
    }
}
