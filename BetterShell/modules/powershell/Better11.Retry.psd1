@{
    RootModule = 'Better11.Retry.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567893'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Better11.Retry - Retry logic and error handling for Better11 Suite'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Invoke-Better11Retry',
        'Get-Better11RetryDelay',
        'Get-Better11CircuitBreakerState',
        'Set-Better11CircuitBreakerState',
        'Reset-Better11CircuitBreaker',
        'New-Better11ErrorFilter'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Retry', 'ErrorHandling', 'CircuitBreaker')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of Better11.Retry module'
        }
    }
}
