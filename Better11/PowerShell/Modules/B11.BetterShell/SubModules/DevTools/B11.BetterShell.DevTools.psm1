#Requires -Version 7.0
using namespace System.Collections.Generic

function Measure-B11ScriptComplexity { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Path)
    $content = Get-Content -Path $Path -Raw; $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    $ifStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.IfStatementAst] }, $true)
    $loops = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.LoopStatementAst] }, $true)
    $tryCatch = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TryStatementAst] }, $true)
    [PSCustomObject]@{ PSTypeName = 'B11.ScriptComplexity'; Path = $Path; Functions = $functions.Count; IfStatements = $ifStatements.Count; Loops = $loops.Count; TryCatch = $tryCatch.Count; TotalLines = ($content -split "`n").Count; CyclomaticComplexity = 1 + $ifStatements.Count + $loops.Count } }

function Get-B11CodeStatistics { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Path, [switch]$Recurse)
    $files = Get-ChildItem -Path $Path -Recurse:$Recurse -Include '*.ps1','*.psm1','*.cs','*.ts','*.js' -File
    $stats = foreach ($ext in ($files | Group-Object Extension)) {
        $totalLines = ($ext.Group | ForEach-Object { (Get-Content $_.FullName).Count } | Measure-Object -Sum).Sum
        [PSCustomObject]@{ Extension = $ext.Name; FileCount = $ext.Count; TotalLines = $totalLines }
    }
    $grandTotal = ($stats | Measure-Object -Property TotalLines -Sum).Sum
    [PSCustomObject]@{ PSTypeName = 'B11.CodeStats'; Path = $Path; ByExtension = $stats; TotalFiles = $files.Count; TotalLines = $grandTotal } }

function Find-B11TodoComments { [CmdletBinding()][OutputType([PSCustomObject[]])] param([Parameter(Mandatory)][string]$Path, [switch]$Recurse, [string[]]$Tags = @('TODO','FIXME','HACK','BUG','XXX'))
    $pattern = ($Tags | ForEach-Object { [regex]::Escape($_) }) -join '|'
    $files = Get-ChildItem -Path $Path -Recurse:$Recurse -Include '*.ps1','*.psm1','*.cs','*.ts' -File
    foreach ($f in $files) { $lines = Get-Content $f.FullName; for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "($pattern)\s*:?\s*(.*)") { [PSCustomObject]@{ PSTypeName = 'B11.TodoComment'; File = $f.Name; Line = $i + 1; Tag = $Matches[1]; Comment = $Matches[2].Trim(); FullPath = $f.FullName } } } } }

function Test-B11ScriptSyntax { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory,ValueFromPipeline)][string[]]$Path)
    process { foreach ($p in $Path) { $errors = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$null, [ref]$errors)
        [PSCustomObject]@{ PSTypeName = 'B11.SyntaxCheck'; Path = $p; IsValid = ($errors.Count -eq 0); ErrorCount = $errors.Count; Errors = @($errors | ForEach-Object { $_.Message }) } } } }

function ConvertTo-B11Base64 { [CmdletBinding()][OutputType([string])] param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path); [Convert]::ToBase64String($bytes) }

function ConvertFrom-B11Base64 { [CmdletBinding(SupportsShouldProcess)][OutputType([void])] param([Parameter(Mandatory)][string]$Base64, [Parameter(Mandatory)][string]$OutputPath)
    if ($PSCmdlet.ShouldProcess($OutputPath, 'Write decoded base64')) { $bytes = [Convert]::FromBase64String($Base64); [System.IO.File]::WriteAllBytes($OutputPath, $bytes) } }

function New-B11ModuleScaffold { [CmdletBinding(SupportsShouldProcess)][OutputType([PSCustomObject])] param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$OutputPath, [string]$Author = 'C-Man', [string[]]$Functions = @())
    if ($PSCmdlet.ShouldProcess($Name, 'Create module scaffold')) {
        $modDir = Join-Path $OutputPath "B11.$Name"; New-Item -Path $modDir -ItemType Directory -Force | Out-Null
        $funcDefs = $Functions | ForEach-Object { "function $_-B11$Name {`n    [CmdletBinding()]`n    [OutputType([PSCustomObject])]`n    param()`n    # TODO: Implement`n}`n" }
        $psm1 = "#Requires -Version 7.0`n`n$($funcDefs -join "`n")`nExport-ModuleMember -Function @($($Functions | ForEach-Object { "'$_-B11$Name'" } | Join-String -Separator ', '))"
        Set-Content -Path (Join-Path $modDir "B11.$Name.psm1") -Value $psm1
        $psd1Content = "@{`n    RootModule = 'B11.$Name.psm1'`n    ModuleVersion = '1.0.0'`n    Author = '$Author'`n    Description = 'B11.$Name module'`n    FunctionsToExport = @($($Functions | ForEach-Object { "'$_-B11$Name'" } | Join-String -Separator ', '))`n}"
        Set-Content -Path (Join-Path $modDir "B11.$Name.psd1") -Value $psd1Content
        $testContent = "Describe 'B11.$Name' { It 'Should import without errors' { { Import-Module (Join-Path `$PSScriptRoot 'B11.$Name.psd1') -Force } | Should -Not -Throw } }"
        Set-Content -Path (Join-Path $modDir "B11.$Name.Tests.ps1") -Value $testContent
        [PSCustomObject]@{ PSTypeName = 'B11.ModuleScaffold'; Name = "B11.$Name"; Path = $modDir; Files = 3 } } }

function Measure-B11CommandPerformance { [CmdletBinding()][OutputType([PSCustomObject])] param([Parameter(Mandatory)][scriptblock]$ScriptBlock, [int]$Iterations = 10, [string]$Name = 'Benchmark')
    $results = 1..$Iterations | ForEach-Object { $sw = [System.Diagnostics.Stopwatch]::StartNew(); & $ScriptBlock | Out-Null; $sw.Stop(); $sw.Elapsed.TotalMilliseconds }
    [PSCustomObject]@{ PSTypeName = 'B11.Benchmark'; Name = $Name; Iterations = $Iterations; MinMs = [math]::Round(($results | Measure-Object -Minimum).Minimum, 2); MaxMs = [math]::Round(($results | Measure-Object -Maximum).Maximum, 2); AvgMs = [math]::Round(($results | Measure-Object -Average).Average, 2); MedianMs = [math]::Round(($results | Sort-Object)[[int]($results.Count / 2)], 2) } }

function Get-B11FunctionList { [CmdletBinding()][OutputType([PSCustomObject[]])] param([Parameter(Mandatory)][string]$Path)
    $content = Get-Content -Path $Path -Raw; $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($f in $functions) { [PSCustomObject]@{ PSTypeName = 'B11.FunctionInfo'; Name = $f.Name; StartLine = $f.Extent.StartLineNumber; EndLine = $f.Extent.EndLineNumber; Parameters = @($f.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }) } } }

function Find-B11UnusedFunctions { [CmdletBinding()][OutputType([PSCustomObject[]])] param([Parameter(Mandatory)][string]$Path, [switch]$Recurse)
    $files = Get-ChildItem -Path $Path -Recurse:$Recurse -Include '*.ps1','*.psm1' -File
    $allFunctions = [List[string]]::new(); $allContent = [System.Text.StringBuilder]::new()
    foreach ($f in $files) { $content = Get-Content $f.FullName -Raw; [void]$allContent.AppendLine($content)
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
        $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) | ForEach-Object { $allFunctions.Add($_.Name) } }
    $fullText = $allContent.ToString()
    foreach ($fn in $allFunctions) { $callPattern = "(?<!function\s)$([regex]::Escape($fn))"; $matches = [regex]::Matches($fullText, $callPattern)
        if ($matches.Count -le 1) { [PSCustomObject]@{ PSTypeName = 'B11.UnusedFunction'; Name = $fn; References = $matches.Count } } } }

function Format-B11Json { [CmdletBinding()][OutputType([string])] param([Parameter(Mandatory,ValueFromPipeline)][string]$Json, [int]$Depth = 100)
    process { $Json | ConvertFrom-Json | ConvertTo-Json -Depth $Depth } }

Export-ModuleMember -Function @(
    'Measure-B11ScriptComplexity', 'Get-B11CodeStatistics', 'Find-B11TodoComments',
    'Test-B11ScriptSyntax', 'ConvertTo-B11Base64', 'ConvertFrom-B11Base64',
    'New-B11ModuleScaffold', 'Measure-B11CommandPerformance', 'Get-B11FunctionList',
    'Find-B11UnusedFunctions', 'Format-B11Json'
)
