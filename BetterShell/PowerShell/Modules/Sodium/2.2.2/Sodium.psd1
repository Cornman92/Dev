@{
    RootModule            = 'Sodium.psm1'
    ModuleVersion         = '2.2.2'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'd71a2d97-d671-4c35-a776-9ee63fda66d6'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for handling Sodium encrypted secrets.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'ConvertFrom-SodiumSealedBox'
        'ConvertTo-SodiumSealedBox'
        'Get-SodiumPublicKey'
        'New-SodiumKeyPair'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'libs/linux-arm64/libsodium.so'
        'libs/linux-arm64/PSModule.Sodium.deps.json'
        'libs/linux-arm64/PSModule.Sodium.dll'
        'libs/linux-arm64/PSModule.Sodium.pdb'
        'libs/linux-x64/libsodium.so'
        'libs/linux-x64/PSModule.Sodium.deps.json'
        'libs/linux-x64/PSModule.Sodium.dll'
        'libs/linux-x64/PSModule.Sodium.pdb'
        'libs/osx-arm64/libsodium.dylib'
        'libs/osx-arm64/PSModule.Sodium.deps.json'
        'libs/osx-arm64/PSModule.Sodium.dll'
        'libs/osx-arm64/PSModule.Sodium.pdb'
        'libs/osx-x64/libsodium.dylib'
        'libs/osx-x64/PSModule.Sodium.deps.json'
        'libs/osx-x64/PSModule.Sodium.dll'
        'libs/osx-x64/PSModule.Sodium.pdb'
        'libs/win-x64/libsodium.dll'
        'libs/win-x64/PSModule.Sodium.deps.json'
        'libs/win-x64/PSModule.Sodium.dll'
        'libs/win-x64/PSModule.Sodium.pdb'
        'libs/win-x86/libsodium.dll'
        'libs/win-x86/PSModule.Sodium.deps.json'
        'libs/win-x86/PSModule.Sodium.dll'
        'libs/win-x86/PSModule.Sodium.pdb'
        'Sodium.psm1'
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
            LicenseUri = 'https://github.com/PSModule/Sodium/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Sodium'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Sodium/main/icon/icon.png'
        }
    }
}
