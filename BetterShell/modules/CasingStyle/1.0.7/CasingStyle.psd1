@{
    RootModule            = 'CasingStyle.psm1'
    ModuleVersion         = '1.0.7'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '71f09474-9c85-4199-a258-07d7737962db'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module that works with casing of text.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'ConvertTo-CasingStyle'
        'Get-CasingStyle'
        'Split-CasingStyle'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'CasingStyle.psm1'
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
            LicenseUri = 'https://github.com/PSModule/CasingStyle/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/CasingStyle'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/CasingStyle/main/icon/icon.png'
        }
    }
}
