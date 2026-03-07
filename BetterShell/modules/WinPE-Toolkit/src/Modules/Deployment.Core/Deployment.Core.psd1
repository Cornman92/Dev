@{
    RootModule        = 'Deployment.Core.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'd3a8e613-6b05-4ed4-8b3d-889f739a9f10'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    Copyright         = '(c) Better11. All rights reserved.'
    PowerShellVersion = '5.1'
    Description       = 'Core utilities, logging, configuration, and safety helpers for the Better11 deployment toolkit.'
    FunctionsToExport = @(
        'Get-DeployRoot',
        'Get-DeployConfigPath',
        'Resolve-DeployPath',
        'New-DeployRunContext',
        'Write-DeployLog',
        'Write-DeployEvent',
        'Write-DeployError',
        'Export-DeployLogs',
        'Rotate-DeployLogs',
        'Write-ProgressDeploy',
        'Get-DeployConfigJson',
        'Test-DeployAdmin',
        'Confirm-DestructiveAction',
        'Invoke-DeployRetry'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

