@{
    RootModule = 'Better11.Install.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567892'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Better11.Install - Package installation abstraction for Better11 Suite'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-AvailablePackageManagers',
        'Install-Better11Package',
        'Test-Better11PackageInstalled',
        'Get-Better11PackageInfo',
        'Install-Better11Packages',
        'Update-Better11Package',
        'Uninstall-Better11Package',
        'Get-Better11PackageUpdates',
        'Search-Better11Package'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Install', 'PackageManager', 'Winget', 'Chocolatey', 'Scoop')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of Better11.Install module'
        }
    }
}
