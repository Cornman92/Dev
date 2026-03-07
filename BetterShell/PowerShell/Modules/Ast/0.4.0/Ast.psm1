[CmdletBinding()]
param()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Test-ModuleManifest -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"
#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [Core]
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - Processing folder"
#region    [functions] - [public] - [Core] - [Get-ASTCommand]
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - [Get-ASTCommand] - Importing"
function Get-AstCommand {
    <#
        .SYNOPSIS
        Retrieves command Ast (Abstract Syntax Tree) elements from a PowerShell script or Ast object.

        .DESCRIPTION
        This function extracts and returns command Ast elements from a specified PowerShell script file,
        script content, or an existing Ast object. The function supports multiple input methods, including
        direct script text, file paths, or existing Ast objects. It also provides an option to search nested
        functions and script block expressions.

        .EXAMPLE
        Get-AstCommand -Path "C:\Scripts\MyScript.ps1"

        Output:
        ```powershell
        Ast    : {@{Name=Get-Process; Extent=...}, @{Name=Write-Host; Extent=...}}
        Tokens : {...}
        Errors : {}
        ```

        Parses the specified script file and extracts command Ast elements.

        .EXAMPLE
        Get-AstCommand -Script "Get-Process; Write-Host 'Hello'"

        Output:
        ```powershell
        Ast    : {@{Name=Get-Process; Extent=...}, @{Name=Write-Host; Extent=...}}
        Tokens : {...}
        Errors : {}
        ```

        Parses the provided script content and extracts command Ast elements.

        .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseInput("Get-Process", [ref]$null, [ref]$null)
        Get-AstCommand -Ast $ast

        Output:
        ```powershell
        Ast    : {@{Name=Get-Process; Extent=...}}
        Tokens : {...}
        Errors : {}
        ```

        Extracts command Ast elements from a manually parsed Ast object.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Returns an object containing extracted Ast elements, tokens, and errors.

        .LINK
        https://psmodule.io/Ast/Functions/Core/Get-AstCommand/
    #>
    [CmdletBinding(DefaultParameterSetName = 'Ast')]
    param (
        # The name of the command to search for. Defaults to all commands ('*').
        [Parameter()]
        [string] $Name = '*',

        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script,

        # An existing Ast object to search.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Ast'
        )]
        [System.Management.Automation.Language.Ast] $Ast,

        # Search nested functions and script block expressions.
        [Parameter()]
        [switch] $Recurse
    )

    begin {}

    process {
        $scriptAst = @()
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $scriptAst += (Get-AstScript -Path $Path).Ast
            }
            'Script' {
                $scriptAst += (Get-AstScript -Script $Script).Ast
            }
            'Ast' {
                $scriptAst += $Ast
            }
        }

        # Extract function definitions
        $ast = foreach ($astItem in $scriptAst) {
            $astItem.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $Recurse) |
                Where-Object { $_.Name -like $Name }
        }
    }

    end {
        [pscustomobject]@{
            Ast    = @($ast)
            Tokens = $scriptAst.tokens
            Errors = $scriptAst.errors
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - [Get-ASTCommand] - Done"
#endregion [functions] - [public] - [Core] - [Get-ASTCommand]
#region    [functions] - [public] - [Core] - [Get-ASTFunction]
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - [Get-ASTFunction] - Importing"
function Get-AstFunction {
    <#
        .SYNOPSIS
        Retrieves function definitions from a PowerShell script or Ast.

        .DESCRIPTION
        This function extracts function definitions from a given PowerShell script file, script content,
        or an existing Ast (Abstract Syntax Tree) object. It supports searching by function name
        and can optionally search within nested functions and script block expressions.

        .EXAMPLE
        Get-AstFunction -Path "C:\Scripts\MyScript.ps1"

        Output:
        ```powershell
        Ast    : {FunctionDefinitionAst, FunctionDefinitionAst}
        Tokens : {...}
        Errors : {}
        ```

        Retrieves function definitions from the specified script file.

        .EXAMPLE
        Get-AstFunction -Script "$scriptContent"

        Output:
        ```powershell
        Ast    : {FunctionDefinitionAst}
        Tokens : {...}
        Errors : {}
        ```

        Parses and retrieves function definitions from the provided script content.

        .EXAMPLE
        $ast = Get-AstScript -Path "C:\Scripts\MyScript.ps1" | Select-Object -ExpandProperty Ast
        Get-AstFunction -Ast $ast

        Output:
        ```powershell
        Ast    : {FunctionDefinitionAst}
        Tokens : {...}
        Errors : {}
        ```

        Extracts function definitions from an existing Ast object.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Contains Ast objects, tokenized script content, and parsing errors if any.

        .LINK
        https://psmodule.io/Ast/Functions/Core/Get-AstFunction
    #>
    [CmdletBinding(DefaultParameterSetName = 'Ast')]
    param (
        # The name of the function to search for. Defaults to all functions ('*').
        [Parameter()]
        [string] $Name = '*',

        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script,

        # An existing Ast object to search.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Ast'
        )]
        [System.Management.Automation.Language.Ast] $Ast,

        # Search nested functions and script block expressions.
        [Parameter()]
        [switch] $Recurse
    )

    begin {}

    process {
        $scriptAst = @()
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $scriptAst += (Get-AstScript -Path $Path).Ast
            }
            'Script' {
                $scriptAst += (Get-AstScript -Script $Script).Ast
            }
            'Ast' {
                $scriptAst += $Ast
            }
        }

        # Extract function definitions
        $ast = foreach ($astItem in $scriptAst) {
            $astItem.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $Recurse) |
                Where-Object { $_.Name -like $Name }
        }
    }

    end {
        [pscustomobject]@{
            Ast    = @($ast)
            Tokens = $scriptAst.tokens
            Errors = $scriptAst.errors
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - [Get-ASTFunction] - Done"
#endregion [functions] - [public] - [Core] - [Get-ASTFunction]
#region    [functions] - [public] - [Core] - [Get-ASTScript]
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - [Get-ASTScript] - Importing"
function Get-AstScript {
    <#
        .SYNOPSIS
        Parses a PowerShell script or script file and returns its abstract syntax tree (Ast).

        .DESCRIPTION
        The Get-AstScript function parses a PowerShell script or script file and returns its abstract syntax tree (Ast),
        along with tokens and errors encountered during parsing. This function can be used to analyze the structure
        of a script by specifying either the script content directly or the path to a script file.

        .EXAMPLE
        Get-AstScript -Path "C:\\Scripts\\example.ps1"

        Output:
        ```powershell
        Ast    : [System.Management.Automation.Language.ScriptBlockAst]
        Tokens : {Token1, Token2, ...}
        Errors : {Error1, Error2, ...}
        ```

        Parses the PowerShell script located at "C:\\Scripts\\example.ps1" and returns its Ast, tokens, and any parsing errors.

        .EXAMPLE
        Get-AstScript -Script "Write-Host 'Hello World'"

        Output:
        ```powershell
        Ast    : [System.Management.Automation.Language.ScriptBlockAst]
        Tokens : {Token1, Token2, ...}
        Errors : {}
        ```

        Parses the provided PowerShell script string and returns its Ast, tokens, and any parsing errors.

        .OUTPUTS
        PSCustomObject

        .NOTES
        The returned custom object contains the following properties:
        - `Ast` - [System.Management.Automation.Language.ScriptBlockAst]. The abstract syntax tree (Ast) of the parsed script.
        - `Tokens` - [System.Management.Automation.Language.Token[]]. The tokens generated during parsing.
        - `Errors` - [System.Management.Automation.Language.ParseError[]]. Any parsing errors encountered.

        .LINK
        https://psmodule.io/Ast/Functions/Core/Get-AstScript/
    #>
    [outputType([System.Management.Automation.Language.ScriptBlockAst])]
    [CmdletBinding()]
    param (
        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script
    )

    begin {}

    process {
        $tokens = $null
        $errors = $null
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
            }
            'Script' {
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($Script, [ref]$tokens, [ref]$errors)
            }
        }
        [pscustomobject]@{
            Ast    = $ast
            Tokens = $tokens
            Errors = $errors
        }
    }

    end {}
}
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - [Get-ASTScript] - Done"
#endregion [functions] - [public] - [Core] - [Get-ASTScript]
Write-Debug "[$scriptName] - [functions] - [public] - [Core] - Done"
#endregion [functions] - [public] - [Core]
#region    [functions] - [public] - [Functions]
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - Processing folder"
#region    [functions] - [public] - [Functions] - [Get-ASTFunctionAlias]
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - [Get-ASTFunctionAlias] - Importing"
function Get-AstFunctionAlias {
    <#
        .SYNOPSIS
        Retrieves function aliases from a PowerShell script or file.

        .DESCRIPTION
        This function parses a PowerShell script or file to extract function definitions
        and identify any aliases assigned to them via the `[Alias()]` attribute.
        It supports searching by function name and allows recursive searching
        within nested functions and script blocks.

        .EXAMPLE
        Get-AstFunctionAlias -Path "C:\Scripts\MyScript.ps1" -Name "Get-User"

        Output:
        ```powershell
        Name       Alias
        ----       -----
        Get-User   {RetrieveUser, FetchUser}
        ```

        Retrieves aliases assigned to the function `Get-User` within the specified script file.

        .EXAMPLE
        Get-AstFunctionAlias -Script $scriptContent -Recurse

        Output:
        ```powershell
        Name       Alias
        ----       -----
        Get-Data   {FetchData, RetrieveData}
        ```

        Searches for function aliases within the provided script content, including nested functions.

        .OUTPUTS
        PSCustomObject

        .NOTES
        An object containing the function name and its associated aliases.

        .LINK
        https://psmodule.io/Ast/Functions/Functions/Get-AstFunctionAlias
    #>
    [CmdletBinding()]
    param (
        # The name of the command to search for. Defaults to all commands ('*').
        [Parameter()]
        [string] $Name = '*',

        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script,

        # Search nested functions and script block expressions.
        [Parameter()]
        [switch] $Recurse
    )

    begin {}

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $functionAst = Get-AstFunction -Name $Name -Path $Path -Recurse:$Recurse
            }
            'Script' {
                $functionAst = Get-AstFunction -Name $Name -Script $Script -Recurse:$Recurse
            }
        }

        # Process each function and extract aliases
        $functionAst.Ast | ForEach-Object {
            $funcName = $_.Name
            $funcAttributes = $_.Body.FindAll({ $args[0] -is [System.Management.Automation.Language.AttributeAst] }, $true) | Where-Object {
                $_.Parent -is [System.Management.Automation.Language.ParamBlockAst]
            }
            $aliasAttr = $funcAttributes | Where-Object { $_.TypeName.Name -eq 'Alias' }

            if ($aliasAttr) {
                $aliases = $aliasAttr.PositionalArguments | ForEach-Object { $_.ToString().Trim('"', "'") }
                [PSCustomObject]@{
                    Name  = $funcName
                    Alias = $aliases
                }
            }
        } | Where-Object { $_.Name -like $Name }
    }

    end {}
}
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - [Get-ASTFunctionAlias] - Done"
#endregion [functions] - [public] - [Functions] - [Get-ASTFunctionAlias]
#region    [functions] - [public] - [Functions] - [Get-ASTFunctionName]
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - [Get-ASTFunctionName] - Importing"
function Get-AstFunctionName {
    <#
        .SYNOPSIS
        Retrieves the names of functions from an abstract syntax tree (Ast) in a PowerShell script.

        .DESCRIPTION
        Parses a PowerShell script file or script content to extract function names using an abstract syntax tree (Ast).
        The function supports searching by name, parsing from a file path, or directly from a script string. It can also
        search within nested functions and script block expressions when the -Recurse switch is used.

        .EXAMPLE
        Get-AstFunctionName -Path "C:\Scripts\example.ps1"

        Output:
        ```powershell
        Get-Data
        Set-Configuration
        ```

        Extracts function names from the specified PowerShell script file.

        .EXAMPLE
        Get-AstFunctionName -Script "function Test-Function { param($x) Write-Host $x }"

        Output:
        ```powershell
        Test-Function
        ```

        Extracts function names from the given script string.

        .EXAMPLE
        Get-AstFunctionName -Path "C:\Scripts\example.ps1" -Recurse

        Output:
        ```powershell
        Get-Data
        Set-Configuration
        Helper-Function
        ```

        Extracts function names from the specified script file, including nested functions.

        .OUTPUTS
        System.String

        .NOTES
        The name of each function found in the PowerShell script.

        .LINK
        https://psmodule.io/Ast/Functions/Functions/Get-AstFunctionName/
    #>

    [CmdletBinding()]
    param (
        # The name of the command to search for. Defaults to all commands ('*').
        [Parameter()]
        [string] $Name = '*',

        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script,

        # Search nested functions and script block expressions.
        [Parameter()]
        [switch] $Recurse
    )

    begin {}

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $functionAst = Get-AstFunction -Name $Name -Path $Path -Recurse:$Recurse
            }
            'Script' {
                $functionAst = Get-AstFunction -Name $Name -Script $Script -Recurse:$Recurse
            }
        }

        # Process each function and extract the name
        $functionAst.Ast | ForEach-Object {
            $_.Name
        }
    }

    end {}
}
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - [Get-ASTFunctionName] - Done"
#endregion [functions] - [public] - [Functions] - [Get-ASTFunctionName]
#region    [functions] - [public] - [Functions] - [Get-ASTFunctionType]
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - [Get-ASTFunctionType] - Importing"
function Get-AstFunctionType {
    <#
        .SYNOPSIS
        Retrieves the type of an abstract syntax tree (Ast) function.

        .DESCRIPTION
        Parses a PowerShell script file or script content to determine the type of function present.
        The function classifies functions as `Function`, `Filter`, `Workflow`, or `Configuration`.
        It supports searching for specific function names and can process nested functions if required.

        .EXAMPLE
        Get-AstFunctionType -Path "C:\Scripts\MyScript.ps1"

        Output:
        ```powershell
        Name   Type
        ----   ----
        Test1  Function
        Test2  Filter
        ```

        Parses the specified script file and identifies function types.

        .EXAMPLE
        Get-AstFunctionType -Script "function Test { param() Write-Output 'Hello' }"

        Output:
        ```powershell
        Name  Type
        ----  ----
        Test Function
        ```

        Parses the provided script content and determines the function type.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Represents the function name and its determined type.

        .LINK
        https://psmodule.io/Ast/Functions/Functions/Get-AstFunctionType/
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        # The name of the command to search for. Defaults to all commands ('*').
        [Parameter()]
        [string] $Name = '*',

        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script,

        # Search nested functions and script block expressions.
        [Parameter()]
        [switch] $Recurse
    )

    begin {}

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $functionAst = Get-AstFunction -Name $Name -Path $Path -Recurse:$Recurse
            }
            'Script' {
                $functionAst = Get-AstFunction -Name $Name -Script $Script -Recurse:$Recurse
            }
        }

        $functionAst.Ast | ForEach-Object {
            $type = if ($_.IsWorkflow) {
                'Workflow'
            } elseif ($_.IsConfiguration) {
                'Configuration'
            } elseif ($_.IsFilter) {
                'Filter'
            } else {
                'Function'
            }
            [pscustomobject]@{
                Name = $_.Name
                Type = $type
            }
        }
    }

    end {}
}
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - [Get-ASTFunctionType] - Done"
#endregion [functions] - [public] - [Functions] - [Get-ASTFunctionType]
Write-Debug "[$scriptName] - [functions] - [public] - [Functions] - Done"
#endregion [functions] - [public] - [Functions]
#region    [functions] - [public] - [Lines]
Write-Debug "[$scriptName] - [functions] - [public] - [Lines] - Processing folder"
#region    [functions] - [public] - [Lines] - [Get-ASTLineComment]
Write-Debug "[$scriptName] - [functions] - [public] - [Lines] - [Get-ASTLineComment] - Importing"
filter Get-AstLineComment {
    <#
        .SYNOPSIS
        Extracts comment tokens from a given line of PowerShell code.

        .DESCRIPTION
        This function parses a given line of PowerShell code and extracts comment tokens.
        It utilizes the PowerShell parser to analyze the input and return tokens that match
        the specified kind, defaulting to 'Comment'.

        .EXAMPLE
        "# This is a comment" | Get-AstLineComment

        Output:
        ```powershell
        Kind    : Comment
        Text    : # This is a comment
        ```

        Extracts the comment token from the input PowerShell line.

        .OUTPUTS
        System.Management.Automation.Language.Token[]

        .NOTES
        An array of tokens representing comments extracted from the input line.

        .LINK
        https://psmodule.io/Ast/Functions/Lines/Get-AstLineComment/
    #>
    [OutputType([System.Management.Automation.Language.Token[]])]
    [CmdletBinding()]
    param (
        # Input line of PowerShell code from which to extract the comment.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string] $Line ,

        # The type of comment to extract.
        [Parameter()]
        [string] $Kind = 'Comment'
    )

    # Parse the line using the PowerShell parser to obtain its tokens.
    $tokens = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$null)

    # Find comment token(s) in the line.
    ($tokens | Where-Object { $_.Kind -eq $Kind })
}
Write-Debug "[$scriptName] - [functions] - [public] - [Lines] - [Get-ASTLineComment] - Done"
#endregion [functions] - [public] - [Lines] - [Get-ASTLineComment]
Write-Debug "[$scriptName] - [functions] - [public] - [Lines] - Done"
#endregion [functions] - [public] - [Lines]
#region    [functions] - [public] - [Scripts]
Write-Debug "[$scriptName] - [functions] - [public] - [Scripts] - Processing folder"
#region    [functions] - [public] - [Scripts] - [Get-ASTScriptCommand]
Write-Debug "[$scriptName] - [functions] - [public] - [Scripts] - [Get-ASTScriptCommand] - Importing"
function Get-AstScriptCommand {
    <#
        .SYNOPSIS
        Retrieves the commands used within a specified PowerShell script.

        .DESCRIPTION
        Analyzes a given PowerShell script and extracts all command invocations.
        Optionally includes call operators (& and .) in the results.
        Returns details such as command name, position, and file reference.

        .EXAMPLE
        Get-AstScriptCommand -Path "C:\Scripts\example.ps1"

        Extracts and lists all commands found in the specified PowerShell script.

        .EXAMPLE
        Get-AstScriptCommand -Path "C:\Scripts\example.ps1" -IncludeCallOperators

        Extracts all commands, including those executed with call operators (& and .).

        .LINK
        https://psmodule.io/Ast/Functions/Scripts/Get-AstScriptCommand/
    #>
    [CmdletBinding(DefaultParameterSetName = 'Ast')]
    param (
        # The name of the function to search for. Defaults to all functions ('*').
        [Parameter()]
        [string] $Name = '*',

        # The path to the PowerShell script file to be parsed.
        # Validate using Test-Path
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Path'
        )]
        [string] $Path,

        # The PowerShell script to be parsed.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Script'
        )]
        [string] $Script,

        # An existing Ast object to search.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Ast'
        )]
        [System.Management.Automation.Language.Ast] $Ast,

        # Search nested functions and script block expressions.
        [Parameter()]
        [switch] $Recurse,

        # Include call operators in the results, i.e. & and .
        [Parameter()]
        [switch] $IncludeCallOperators
    )

    begin {}

    process {
        $scriptAst = @()
        switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $scriptAst += (Get-AstScript -Path $Path).Ast
            }
            'Script' {
                $scriptAst += (Get-AstScript -Script $Script).Ast
            }
            'Ast' {
                $scriptAst += $Ast
            }
        }

        # Gather CommandAsts
        $commandAst = $scriptAst.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $Recurse)

        if (-not $IncludeCallOperators) {
            $commandAst = $commandAst | Where-Object { $_.InvocationOperator -notin 'Ampersand', 'Dot' }
        }

        $commandAst | ForEach-Object {
            $invocationOperator = switch ($_.InvocationOperator) {
                'Ampersand' { '&' }
                'Dot' { '.' }
            }
            $_.CommandElements[0].Extent | Where-Object { $_.Text -like $Name } | ForEach-Object {
                [pscustomobject]@{
                    Name              = [string]::IsNullOrEmpty($invocationOperator) ? $_.Text : $invocationOperator
                    StartLineNumber   = $_.StartLineNumber
                    StartColumnNumber = $_.StartColumnNumber
                    EndLineNumber     = $_.EndLineNumber
                    EndColumnNumber   = $_.EndColumnNumber
                    File              = $_.File
                }
            }
        }
    }

    end {}
}
Write-Debug "[$scriptName] - [functions] - [public] - [Scripts] - [Get-ASTScriptCommand] - Done"
#endregion [functions] - [public] - [Scripts] - [Get-ASTScriptCommand]
Write-Debug "[$scriptName] - [functions] - [public] - [Scripts] - Done"
#endregion [functions] - [public] - [Scripts]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'Get-ASTCommand'
        'Get-ASTFunction'
        'Get-ASTScript'
        'Get-ASTFunctionAlias'
        'Get-ASTFunctionName'
        'Get-ASTFunctionType'
        'Get-ASTLineComment'
        'Get-ASTScriptCommand'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

