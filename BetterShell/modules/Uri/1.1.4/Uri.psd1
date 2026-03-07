@{
    RootModule            = 'Uri.psm1'
    ModuleVersion         = '1.1.4'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '56931104-ef2d-406b-808f-37930f0abecf'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A powershell module that works with URIs (RFC3986)'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'ConvertFrom-UriQueryString'
        'ConvertTo-UriQueryString'
        'Get-Uri'
        'New-Uri'
        'Test-Uri'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'Uri.psm1'
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
            LicenseUri = 'https://github.com/PSModule/Uri/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Uri'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Uri/main/icon/icon.png'
        }
    }
}
