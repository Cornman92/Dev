@{
    RootModule        = 'Deployment.Optimization.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '1f11fd36-46b1-4d7e-8771-83a979b8c475'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Post-setup optimization, debloat, and personalization module for Better11 deployment toolkit.'
    RequiredModules   = @('Deployment.Core')
    FunctionsToExport = @(
        'Get-OptimizationProfiles',
        'Get-OptimizationProfile',
        'Invoke-OptimizationProfile',
        'Invoke-OptimizationAction',
        'Get-DebloatProfile',
        'Invoke-DebloatProfile',
        'Set-PersonalizationProfile'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

