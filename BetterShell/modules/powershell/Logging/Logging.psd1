@{
    RootModule = 'Logging.psm1'
    ModuleVersion = '2.0.0'
    GUID = '22222222-2222-4222-8222-222222222222'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Enhanced logging for Better11 Suite with rotation, structured logging, and multiple output formats.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Start-Better11Log',
        'Write-Better11Log',
        'Rotate-Better11Log',
        'Get-Better11LogHistory',
        'Clear-Better11LogHistory',
        'Get-Better11LogConfig',
        'Set-Better11LogConfig'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Logging')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Enhanced logging module with rotation, structured logging (JSON/CSV), and configurable output formats'
        }
    }
}
