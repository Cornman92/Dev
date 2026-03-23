@{
    RootModule            = 'Fonts.psm1'
    ModuleVersion         = '1.1.26'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'b6e7e61f-f8f5-4b0a-9fdd-f74a3311be0d'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for managing fonts.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName      = 'Admin'
            RequiredVersion = '1.1.6'
        }
    )
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Get-Font'
        'Install-Font'
        'Uninstall-Font'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Get-Fonts'
        'Install-Fonts'
        'Uninstall-Fonts'
    )
    ModuleList            = @()
    FileList              = @(
        'Fonts.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'fonts'
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Fonts/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Fonts'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Fonts/main/icon/icon.png'
        }
    }
}
