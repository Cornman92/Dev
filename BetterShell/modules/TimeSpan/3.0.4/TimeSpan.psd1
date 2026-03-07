@{
    RootModule            = 'TimeSpan.psm1'
    ModuleVersion         = '3.0.4'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '05764973-9d31-4556-96d6-dee59207c1ad'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for working with TimeSpans'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Format-TimeSpan'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'TimeSpan.psm1'
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
            LicenseUri = 'https://github.com/PSModule/TimeSpan/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/TimeSpan'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/TimeSpan/main/icon/icon.png'
        }
    }
}
