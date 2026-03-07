@{
    RootModule = 'Better11.Core.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567891'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Better11.Core - Core functionality for the Better11 Suite'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-Better11Config',
        'Get-Better11DefaultConfig',
        'Set-Better11Config',
        'Initialize-Better11Logger',
        'Write-Better11Log',
        'Test-Better11Prerequisites',
        'Get-Better11ModulePath',
        'Import-Better11Module',
        'Invoke-Better11Action',
        'Test-Better11AdminRights',
        'Assert-Better11AdminRights',
        'Get-Better11SystemInfo',
        'Test-Better11NetworkConnectivity',
        'Get-Better11ModuleHealth',
        'Clear-Better11Cache'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Core', 'Configuration', 'Logging')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of Better11.Core module'
        }
    }
}
