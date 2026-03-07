@{
    RootModule            = 'Claude.psm1'
    ModuleVersion         = '0.0.2'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '2cd20d59-e110-498d-9c5c-3da87a79a504'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for interacting with Claude API'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Test-PSModuleTest'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'Claude.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'Linux'
                'MacOS'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Claude/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Claude'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Claude/main/icon/icon.png'
        }
    }
}
