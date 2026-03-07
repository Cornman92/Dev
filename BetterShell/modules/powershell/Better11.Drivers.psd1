@{
    RootModule = 'Better11.Drivers.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567894'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Better11.Drivers - Driver management for Better11 Suite'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-Better11Hardware',
        'Get-Better11DriverStatus',
        'Install-Better11Driver',
        'Install-Better11DriverFromPath',
        'Install-Better11DriverFromWindowsUpdate',
        'Backup-Better11Drivers',
        'Restore-Better11Drivers',
        'Update-Better11Drivers',
        'Get-Better11DriverRecommendations',
        'Scan-Better11Drivers'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Drivers', 'Hardware', 'Windows')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of Better11.Drivers module'
        }
    }
}
