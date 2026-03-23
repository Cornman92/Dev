@{
    RootModule            = 'Admin.psm1'
    ModuleVersion         = '1.1.3'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'a325bc11-e13f-42b2-bd57-b3eb1c0db442'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module working with the admin role.'
    PowerShellVersion     = '7.4'
    ProcessorArchitecture = 'None'
    RequiredAssemblies    = @()
    ScriptsToProcess      = @()
    TypesToProcess        = @()
    FormatsToProcess      = @()
    NestedModules         = @()
    FunctionsToExport     = 'Test-Admin'
    CmdletsToExport       = @()
    AliasesToExport       = @(
        'IsAdmin'
        'IsAdministrator'
        'Test-Administrator'
    )
    ModuleList            = @()
    FileList              = 'Admin.psm1'
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'isadmin'
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'sudo'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Admin/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Admin'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Admin/main/icon/icon.png'
        }
    }
}

