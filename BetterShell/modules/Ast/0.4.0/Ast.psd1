@{
    RootModule            = 'Ast.psm1'
    ModuleVersion         = '0.4.0'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '7c5ac56e-5108-47ba-bbf9-ea3b01222b75'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for using the Abstract Syntax Tree (AST) to analyze any PowerShell code.'
    PowerShellVersion     = '7.4'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Get-ASTCommand'
        'Get-ASTFunction'
        'Get-ASTScript'
        'Get-ASTFunctionAlias'
        'Get-ASTFunctionName'
        'Get-ASTFunctionType'
        'Get-ASTLineComment'
        'Get-ASTScriptCommand'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    ModuleList            = @()
    FileList              = 'Ast.psm1'
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

