@{
    RootModule            = 'Ast.psm1'
    ModuleVersion         = '0.4.9'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '3309e4b7-5770-4937-b5ce-4a80a09f5103'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for using the Abstract Syntax Tree (AST) to analyze any PowerShell code.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Get-AstCommand'
        'Get-AstFunction'
        'Get-AstFunctionAlias'
        'Get-AstFunctionName'
        'Get-AstFunctionType'
        'Get-AstLineComment'
        'Get-AstScript'
        'Get-AstScriptCommand'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'Ast.psm1'
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
            LicenseUri = 'https://github.com/PSModule/Ast/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Ast'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Ast/main/icon/icon.png'
        }
    }
}
