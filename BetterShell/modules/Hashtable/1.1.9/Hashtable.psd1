@{
    RootModule            = 'Hashtable.psm1'
    ModuleVersion         = '1.1.9'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '5a34aaa7-22a1-4745-8a0f-9e2d175cb41b'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module that simplifies some interaction with Hashtables.'
    PowerShellVersion     = '5.1'
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
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Join-Hashtable'
    )
    ModuleList            = @()
    FileList              = @(
        'Hashtable.psm1'
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
            LicenseUri = 'https://github.com/PSModule/Hashtable/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Hashtable'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Hashtable/main/icon/icon.png'
        }
    }
}
