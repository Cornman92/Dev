@{
    RootModule        = 'Deployment.Cloud.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'd1e2f3a4-b5c6-7d8e-9f0a-1b2c3d4e5f6a'
    Author            = 'Better11 Toolkit'
    CompanyName       = 'Better11'
    PowerShellVersion = '5.1'
    Description       = 'Cloud deployment support for Azure and AWS.'
    RequiredModules   = @('Deployment.Core', 'Deployment.TaskSequence')
    FunctionsToExport = @(
        'Deploy-ToAzure',
        'Deploy-ToAws',
        'Create-AzureVm',
        'Create-AwsInstance',
        'Upload-ToAzureStorage',
        'Upload-ToS3'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}

