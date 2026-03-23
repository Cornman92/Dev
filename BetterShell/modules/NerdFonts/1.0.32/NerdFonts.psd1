@{
    RootModule            = 'NerdFonts.psm1'
    ModuleVersion         = '1.0.32'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'c381a710-b8e2-4443-b893-c61d0638ce5b'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module to download and install fonts from NerdFonts.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName      = 'Admin'
            RequiredVersion = '1.1.6'
        }
        @{
            ModuleName      = 'Fonts'
            RequiredVersion = '1.1.21'
        }
    )
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Get-NerdFont'
        'Install-NerdFont'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Get-NerdFonts'
        'Install-NerdFonts'
    )
    ModuleList            = @()
    FileList              = @(
        'FontsData.json'
        'NerdFonts.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'fonts'
                'Linux'
                'MacOS'
                'module'
                'nerdfonts'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/NerdFonts/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/NerdFonts'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/NerdFonts/main/icon/icon.png'
        }
    }
}
