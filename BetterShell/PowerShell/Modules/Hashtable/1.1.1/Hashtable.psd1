@{
    RootModule            = 'Hashtable.psm1'
    ModuleVersion         = '1.1.1'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '9516d67e-59fd-41b9-8187-3b6a53761e1a'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module that simplifies some interaction with Hashtables.'
    PowerShellVersion     = '7.4'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'ConvertFrom-Hashtable'
        'ConvertTo-HashTable'
        'Export-Hashtable'
        'Format-Hashtable'
        'Import-Hashtable'
        'Merge-Hashtable'
        'Remove-HashtableEntry'
    )
    CmdletsToExport       = @()
    AliasesToExport       = @(
        'Join-Hashtable'
    )
    ModuleList            = @()
    FileList              = 'Hashtable.psm1'
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'Linux'
                'MacOS'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Hashtable/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Hashtable'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Hashtable/main/icon/icon.png'
        }
    }
}

