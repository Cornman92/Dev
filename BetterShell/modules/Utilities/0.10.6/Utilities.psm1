[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidAssignmentToAutomaticVariable', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidLongLines', '', Justification = 'Contains long links.')]
[CmdletBinding()]
param()

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Import-PowerShellDataFile -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"

if ($PSEdition -eq 'Desktop') {
    $IsWindows = $true
}

#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [Boolean]
Write-Debug "[$scriptName] - [functions] - [public] - [Boolean] - Processing folder"
#region    [functions] - [public] - [Boolean] - [ConvertTo-Boolean]
Write-Debug "[$scriptName] - [functions] - [public] - [Boolean] - [ConvertTo-Boolean] - Importing"
filter ConvertTo-Boolean {
    <#
        .SYNOPSIS
        Convert string to boolean.

        .DESCRIPTION
        Convert string to boolean.

        .EXAMPLE
        ConvertTo-Boolean -String 'true'

        True

        Convert string to boolean.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        # The string to be converted to boolean.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $String
    )

    switch -regex ($String.Trim()) {
        '^(1|true|yes|on|enabled)$' { $true }
        default { $false }
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Boolean] - [ConvertTo-Boolean] - Done"
#endregion [functions] - [public] - [Boolean] - [ConvertTo-Boolean]
Write-Debug "[$scriptName] - [functions] - [public] - [Boolean] - Done"
#endregion [functions] - [public] - [Boolean]
#region    [functions] - [public] - [Files]
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - Processing folder"
#region    [functions] - [public] - [Files] - [Get-FileInfo]
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - [Get-FileInfo] - Importing"
function Get-FileInfo {
    <#
        .SYNOPSIS
        Get file information

        .DESCRIPTION
        Get file information

        .EXAMPLE
        Get-FileInfo -Path 'C:\temp\test.txt'

        Gets detailed information about the file.

        .NOTES
        Supported OS: Windows
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        # The path to the file.
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error 'Path does not exist' -ErrorAction Stop
    }

    $Item = Get-Item -Path $Path

    #If item is directory, fail
    if ($Item.PSIsContainer) {
        Write-Error 'Path is a directory' -ErrorAction Stop
    }

    $shell = New-Object -ComObject Shell.Application
    $shellFolder = $shell.Namespace($Item.Directory.FullName)
    $shellFile = $shellFolder.ParseName($Item.name)

    $fileDetails = New-Object pscustomobject

    foreach ($i in 0..1000) {
        $propertyName = $shellfolder.GetDetailsOf($null, $i)
        $propertyValue = $shellfolder.GetDetailsOf($shellfile, $i)
        if (-not [string]::IsNullOrEmpty($propertyValue)) {
            Write-Verbose "[$propertyName] - [$propertyValue]"
            $fileDetails | Add-Member -MemberType NoteProperty -Name $propertyName -Value $propertyValue
        }
    }
    return $fileDetails
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - [Get-FileInfo] - Done"
#endregion [functions] - [public] - [Files] - [Get-FileInfo]
#region    [functions] - [public] - [Files] - [Remove-EmptyFolder]
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - [Remove-EmptyFolder] - Importing"
function Remove-EmptyFolder {
    <#
        .SYNOPSIS
        Removes empty folders under the folder specified

        .DESCRIPTION
        Removes empty folders under the folder specified

        .EXAMPLE
        Remove-EmptyFolder -Path .

        Removes empty folders under the current path and outputs the results to the console.
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the folder to be cleaned
        [Parameter(Mandatory)]
        [string] $Path
    )

    Get-ChildItem -Path $Path -Recurse -Directory | ForEach-Object {
        if ($null -eq (Get-ChildItem $_.FullName -Force -Recurse)) {
            Write-Verbose "Removing empty folder: [$($_.FullName)]"
            if ($PSCmdlet.ShouldProcess("folder [$($_.FullName)]", 'Remove')) {
                Remove-Item $_.FullName -Force
            }
        }
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - [Remove-EmptyFolder] - Done"
#endregion [functions] - [public] - [Files] - [Remove-EmptyFolder]
#region    [functions] - [public] - [Files] - [Show-FileContent]
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - [Show-FileContent] - Importing"
function Show-FileContent {
    <#
        .SYNOPSIS
        Prints the content of a file with line numbers in front of each line.

        .DESCRIPTION
        Prints the content of a file with line numbers in front of each line.

        .EXAMPLE
        $Path = 'C:\Utilities\Show-FileContent.ps1'
        Show-FileContent -Path $Path

        Shows the content of the file with line numbers in front of each line.
    #>
    [CmdletBinding()]
    param (
        # The path to the file to show the content of.
        [Parameter(Mandatory)]
        [string] $Path
    )

    $content = Get-Content -Path $Path
    $lineNumber = 1
    $columnSize = $content.Count.ToString().Length
    # Foreach line print the line number in front of the line with [    ] around it.
    # The linenumber should dynamically adjust to the number of digits with the length of the file.
    foreach ($line in $content) {
        $lineNumberFormatted = $lineNumber.ToString().PadLeft($columnSize)
        Write-Host "[$lineNumberFormatted] $line"
        $lineNumber++
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - [Show-FileContent] - Done"
#endregion [functions] - [public] - [Files] - [Show-FileContent]
Write-Debug "[$scriptName] - [functions] - [public] - [Files] - Done"
#endregion [functions] - [public] - [Files]
#region    [functions] - [public] - [Git]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - Processing folder"
#region    [functions] - [public] - [Git] - [Clear-GitRepo]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Clear-GitRepo] - Importing"
function Clear-GitRepo {
    <#
        .SYNOPSIS
        Clear a Git repository of all branches except main

        .DESCRIPTION
        Clear a Git repository of all branches except main

        .EXAMPLE
        Clear-GitRepo

        Clear a Git repository of all branches except main
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param()

    git fetch --all --prune
    (git branch).Trim() | Where-Object { $_ -notmatch 'main|\*' } | ForEach-Object { git branch $_ --delete --force }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Clear-GitRepo] - Done"
#endregion [functions] - [public] - [Git] - [Clear-GitRepo]
#region    [functions] - [public] - [Git] - [Invoke-GitSquash]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Invoke-GitSquash] - Importing"
function Invoke-GitSquash {
    <#
        .SYNOPSIS
        Squash all commits on a branch into a single commit

        .DESCRIPTION
        Squash all commits on a branch into a single commit

        .EXAMPLE
        Invoke-GitSquash

        Squash all commits on a branch into a single commit
    #>
    [OutputType([void])]
    [CmdletBinding()]
    [Alias('Squash-Main')]
    param(
        # The commit message to use for the squashed commit
        [Parameter()]
        [string] $CommitMessage = 'Squash',

        # The branch to squash
        [Parameter()]
        [string] $BranchName = 'main',

        # Temporary branch name
        [Parameter()]
        [string] $TempBranchName = 'init'
    )

    git fetch --all --prune
    $gitHightFrom2ndCommit = [int](git rev-list --count --first-parent $BranchName) - 1
    git reset HEAD~$gitHightFrom2ndCommit
    git checkout -b $TempBranchName
    git add .
    git commit -m "$CommitMessage"
    git push --set-upstream origin $TempBranchName
    git checkout $BranchName
    git push --force
    git checkout $TempBranchName
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Invoke-GitSquash] - Done"
#endregion [functions] - [public] - [Git] - [Invoke-GitSquash]
#region    [functions] - [public] - [Git] - [Invoke-SquashBranch]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Invoke-SquashBranch] - Importing"
function Invoke-SquashBranch {
    <#
        .SYNOPSIS
        Squash a branch to a single commit

        .DESCRIPTION
        Squash a branch to a single commit

        .EXAMPLE
        Invoke-SquashBranch
    #>
    [Alias('Squash-Branch')]
    [CmdletBinding()]
    param(
        # The name of the branch to squash
        [Parameter()]
        [string] $BranchName = 'main'
    )
    git reset $(git merge-base $BranchName $(git branch --show-current))
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Invoke-SquashBranch] - Done"
#endregion [functions] - [public] - [Git] - [Invoke-SquashBranch]
#region    [functions] - [public] - [Git] - [Reset-GitRepo]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Reset-GitRepo] - Importing"
function Reset-GitRepo {
    <#
        .SYNOPSIS
        Reset a Git repository to the upstream branch

        .DESCRIPTION
        Reset a Git repository to the upstream branch

        .EXAMPLE
        Reset-GitRepo

        Reset a Git repository to the upstream branch
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The upstream repository to reset to
        [Parameter()]
        [string] $Upstream = 'upstream',

        # The branch to reset
        [Parameter()]
        [string] $Branch = 'main',

        # Whether to push the reset
        [Parameter()]
        [switch] $Push
    )

    git fetch $Upstream
    git checkout $Branch
    if ($PSCmdlet.ShouldProcess("git repo", "Reset")) {
        git reset --hard $Upstream/$Branch
    }

    if ($Push) {
        if ($PSCmdlet.ShouldProcess("git changes to origin", "Push")) {
            git push origin $Branch --force
        }
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Reset-GitRepo] - Done"
#endregion [functions] - [public] - [Git] - [Reset-GitRepo]
#region    [functions] - [public] - [Git] - [Restore-GitRepo]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Restore-GitRepo] - Importing"
function Restore-GitRepo {
    <#
        .SYNOPSIS
        Restore a Git repository with upstream

        .DESCRIPTION
        Restore a Git repository with upstream

        .EXAMPLE
        Restore-GitRepo
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param(
        # The name of the branch to squash
        [Parameter()]
        [string] $BranchName = 'main'
    )

    git remote add upstream https://github.com/Azure/ResourceModules.git
    git fetch upstream
    git restore --source upstream/$BranchName * ':!*global.variables.*' ':!settings.json*'
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Restore-GitRepo] - Done"
#endregion [functions] - [public] - [Git] - [Restore-GitRepo]
#region    [functions] - [public] - [Git] - [Sync-GitRepo]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Sync-GitRepo] - Importing"
function Sync-GitRepo {
    <#
        .SYNOPSIS
        Sync a Git repository with upstream

        .DESCRIPTION
        Sync a Git repository with upstream

        .EXAMPLE
        Sync-GitRepo
    #>
    [Alias('Sync-Git')]
    [OutputType([void])]
    [CmdletBinding()]
    param()
    git fetch upstream --prune
    git pull
    git push
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Sync-GitRepo] - Done"
#endregion [functions] - [public] - [Git] - [Sync-GitRepo]
#region    [functions] - [public] - [Git] - [Sync-Repo]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Sync-Repo] - Importing"
function Sync-Repo {
    <#
        .SYNOPSIS
        Sync a Git repository with upstream

        .DESCRIPTION
        Sync a Git repository with upstream

        .EXAMPLE
        Sync-Repo
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param()
    git checkout main
    git pull
    git remote update origin --prune
    git branch -vv | Select-String -Pattern ': gone]' | ForEach-Object { $_.toString().Trim().Split(' ')[0] } | ForEach-Object { git branch -D $_ }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - [Sync-Repo] - Done"
#endregion [functions] - [public] - [Git] - [Sync-Repo]
Write-Debug "[$scriptName] - [functions] - [public] - [Git] - Done"
#endregion [functions] - [public] - [Git]
#region    [functions] - [public] - [PowerShell]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - Processing folder"
#region    [functions] - [public] - [PowerShell] - [Module]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - Processing folder"
#region    [functions] - [public] - [PowerShell] - [Module] - [Add-ModuleManifestData]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Add-ModuleManifestData] - Importing"
function Add-ModuleManifestData {
    <#
        .SYNOPSIS
        Add data to a module manifest file property

        .DESCRIPTION
        This function adds data to a module manifest file property.
        If the property doesn't exist, it will be created.
        If it does exist, the new data will be appended to the existing data.

        .EXAMPLE
        Add-ModuleManifestData -Path 'MyModule.psd1' -RequiredModules 'pester', 'platyPS'

        Adds the modules 'pester' and 'platyPS' to the RequiredModules property of the module manifest file 'MyModule.psd1'.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path,

        # Modules that must be imported into the global environment prior to importing this module.
        [Parameter()]
        [Object[]] $RequiredModules,

        # Compatible editions of PowerShell.
        [Parameter()]
        [string[]] $CompatiblePSEditions,

        # Assemblies that must be loaded prior to importing this module.
        [Parameter()]
        [string[]] $RequiredAssemblies,

        # Script files (.ps1) that are run in the caller's environment prior to importing this module.
        [Parameter()]
        [string[]] $ScriptsToProcess,

        # Type files (.ps1xml) to be loaded when importing this module.
        [Parameter()]
        [string[]] $TypesToProcess,

        # Format files (.ps1xml) to be loaded when importing this module.
        [Parameter()]
        [string[]] $FormatsToProcess,

        # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess.
        [Parameter()]
        [Object[]] $NestedModules,

        # Functions to export from this module, for best performance, do not use wildcards and do not
        # delete the entry, use an empty array if there are no functions to export.
        [Parameter()]
        [string[]] $FunctionsToExport,

        # Cmdlets to export from this module, for best performance, do not use wildcards and do not
        # delete the entry, use an empty array if there are no cmdlets to export.
        [Parameter()]
        [string[]] $CmdletsToExport,

        # Variables to export from this module.
        [Parameter()]
        [string[]] $VariablesToExport,

        # Aliases to export from this module, for best performance, do not use wildcards and do not
        # delete the entry, use an empty array if there are no aliases to export.
        [Parameter()]
        [string[]] $AliasesToExport,

        # DSC resources to export from this module.
        [Parameter()]
        [string[]] $DscResourcesToExport,

        # List of all modules packaged with this module.
        [Parameter()]
        [Object[]] $ModuleList,

        # List of all files packaged with this module.
        [Parameter()]
        [string[]] $FileList,

        # Tags applied to this module. These help with module discovery in online galleries.
        [Parameter()]
        [string[]] $Tags,

        # External dependent modules of this module.
        [Parameter()]
        [string[]] $ExternalModuleDependencies
    )

    $moduleManifest = Get-ModuleManifest -Path $Path
    $changes = @{}

    if ($RequiredModules) {
        $RequiredModules += $moduleManifest.RequiredModules
        $changes.RequiredModules = $RequiredModules
    }
    if ($RequiredAssemblies) {
        $RequiredAssemblies += $moduleManifest.RequiredAssemblies
        $changes.RequiredAssemblies = $RequiredAssemblies
    }
    if ($CompatiblePSEditions) {
        $CompatiblePSEditions += $moduleManifest.CompatiblePSEditions
        $changes.CompatiblePSEditions = $CompatiblePSEditions
    }
    if ($ScriptsToProcess) {
        $ScriptsToProcess += $moduleManifest.ScriptsToProcess
        $changes.ScriptsToProcess = $ScriptsToProcess
    }
    if ($TypesToProcess) {
        $TypesToProcess += $moduleManifest.TypesToProcess
        $changes.TypesToProcess = $TypesToProcess
    }
    if ($FormatsToProcess) {
        $FormatsToProcess += $moduleManifest.FormatsToProcess
        $changes.FormatsToProcess = $FormatsToProcess
    }
    if ($NestedModules) {
        $NestedModules += $moduleManifest.NestedModules
        $changes.NestedModules = $NestedModules
    }
    if ($FunctionsToExport) {
        $FunctionsToExport += $moduleManifest.FunctionsToExport
        $changes.FunctionsToExport = $FunctionsToExport
    }
    if ($CmdletsToExport) {
        $CmdletsToExport += $moduleManifest.CmdletsToExport
        $changes.CmdletsToExport = $CmdletsToExport
    }
    if ($VariablesToExport) {
        $VariablesToExport += $moduleManifest.VariablesToExport
        $changes.VariablesToExport = $VariablesToExport
    }
    if ($AliasesToExport) {
        $AliasesToExport += $moduleManifest.AliasesToExport
        $changes.AliasesToExport = $AliasesToExport
    }
    if ($DscResourcesToExport) {
        $DscResourcesToExport += $moduleManifest.DscResourcesToExport
        $changes.DscResourcesToExport = $DscResourcesToExport
    }
    if ($ModuleList) {
        $ModuleList += $moduleManifest.ModuleList
        $changes.ModuleList = $ModuleList
    }
    if ($FileList) {
        $FileList += $moduleManifest.FileList
        $changes.FileList = $FileList
    }
    if ($Tags) {
        $Tags += $moduleManifest.PrivateData.PSData.Tags
        $changes.Tags = $Tags
    }
    if ($ExternalModuleDependencies) {
        $ExternalModuleDependencies += $moduleManifest.PrivateData.PSData.ExternalModuleDependencies
        $changes.ExternalModuleDependencies = $ExternalModuleDependencies
    }

    foreach ($key in $changes.GetEnumerator().Name) {
        $changes[$key] = $changes[$key] | Sort-Object -Unique | Where-Object { $_ | IsNotNullOrEmpty }
    }

    Set-ModuleManifest -Path $Path @changes

}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Add-ModuleManifestData] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Add-ModuleManifestData]
#region    [functions] - [public] - [PowerShell] - [Module] - [Add-PSModulePath]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Add-PSModulePath] - Importing"
function Add-PSModulePath {
    <#
        .SYNOPSIS
        Adds a path to the PSModulePath environment variable.

        .DESCRIPTION
        Adds a path to the PSModulePath environment variable.
        For Linux and macOS, the path delimiter is ':' and for Windows it is ';'.

        .EXAMPLE
        Add-PSModulePath -Path 'C:\Users\user\Documents\WindowsPowerShell\Modules'

        Adds the path 'C:\Users\user\Documents\WindowsPowerShell\Modules' to the PSModulePath environment variable.
    #>
    [CmdletBinding()]
    param(
        # Path to the folder where the module source code is located.
        [Parameter(Mandatory)]
        [string] $Path
    )
    $PSModulePathSeparator = [System.IO.Path]::PathSeparator

    $env:PSModulePath += "$PSModulePathSeparator$Path"

    Write-Verbose 'PSModulePath:'
    $env:PSModulePath.Split($PSModulePathSeparator) | ForEach-Object {
        Write-Verbose " - [$_]"
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Add-PSModulePath] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Add-PSModulePath]
#region    [functions] - [public] - [PowerShell] - [Module] - [Export-PowerShellDataFile]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Export-PowerShellDataFile] - Importing"
#Requires -Modules @{ ModuleName = 'Hashtable'; ModuleVersion = '1.1.1' }

function Export-PowerShellDataFile {
    <#
        .SYNOPSIS
        Export a hashtable to a .psd1 file.

        .DESCRIPTION
        This function exports a hashtable to a .psd1 file. It also formats the .psd1 file using the Format-ModuleManifest cmdlet.

        .EXAMPLE
        Export-PowerShellDataFile -Hashtable @{ Name = 'MyModule'; ModuleVersion = '1.0.0' } -Path 'MyModule.psd1'
    #>
    [CmdletBinding()]
    param (
        # The hashtable to export to a .psd1 file.
        [Parameter(Mandatory)]
        [object] $Hashtable,

        # The path of the .psd1 file to export.
        [Parameter(Mandatory)]
        [string] $Path,

        # Force the export, even if the file already exists.
        [Parameter()]
        [switch] $Force
    )

    $content = Format-Hashtable -Hashtable $Hashtable
    $content | Out-File -FilePath $Path -Force:$Force
    Format-ModuleManifest -Path $Path
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Export-PowerShellDataFile] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Export-PowerShellDataFile]
#region    [functions] - [public] - [PowerShell] - [Module] - [Format-ModuleManifest]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Format-ModuleManifest] - Importing"
function Format-ModuleManifest {
    <#
        .SYNOPSIS
        Formats a module manifest file.

        .DESCRIPTION
        This function formats a module manifest file, by removing comments and empty lines,
        and then formatting the file using the `Invoke-Formatter` function.

        .EXAMPLE
        Format-ModuleManifest -Path 'C:\MyModule\MyModule.psd1'
    #>
    [CmdletBinding()]
    param(
        # Path to the module manifest file.
        [Parameter(Mandatory)]
        [string] $Path
    )

    $Utf8BomEncoding = New-Object System.Text.UTF8Encoding $true

    $manifestContent = Get-Content -Path $Path
    $manifestContent = $manifestContent | ForEach-Object { $_ -replace '#.*' }
    $manifestContent = $manifestContent | ForEach-Object { $_.TrimEnd() }
    $manifestContent = $manifestContent | Where-Object { $_ | IsNotNullOrEmpty }
    [System.IO.File]::WriteAllLines($Path, $manifestContent, $Utf8BomEncoding)
    $manifestContent = Get-Content -Path $Path -Raw

    $content = Invoke-Formatter -ScriptDefinition $manifestContent

    # Ensure exactly one empty line at the end
    $content = $content.TrimEnd([System.Environment]::NewLine) + [System.Environment]::NewLine

    [System.IO.File]::WriteAllText($Path, $content, $Utf8BomEncoding)
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Format-ModuleManifest] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Format-ModuleManifest]
#region    [functions] - [public] - [PowerShell] - [Module] - [Get-ModuleManifest]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Get-ModuleManifest] - Importing"
function Get-ModuleManifest {
    <#
        .SYNOPSIS
        Get the module manifest.

        .DESCRIPTION
        Get the module manifest as a path, file info, content, or hashtable.

        .EXAMPLE
        Get-PSModuleManifest -Path 'src/PSModule/PSModule.psd1' -As Hashtable
    #>
    [OutputType([string], [System.IO.FileInfo], [System.Collections.Hashtable], [System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding()]
    param(
        # Path to the module manifest file.
        [Parameter(Mandatory)]
        [string] $Path,

        # The format of the output.
        [Parameter()]
        [ValidateSet('FileInfo', 'Content', 'Hashtable')]
        [string] $As = 'Hashtable'
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Warning 'No manifest file found.'
        return $null
    }
    Write-Verbose "Found manifest file [$Path]"

    switch ($As) {
        'FileInfo' {
            return Get-Item -Path $Path
        }
        'Content' {
            return Get-Content -Path $Path
        }
        'Hashtable' {
            $manifest = [System.Collections.Specialized.OrderedDictionary]@{}
            $psData = [System.Collections.Specialized.OrderedDictionary]@{}
            $privateData = [System.Collections.Specialized.OrderedDictionary]@{}
            $tempManifest = Import-PowerShellDataFile -Path $Path
            if ($tempManifest.ContainsKey('PrivateData')) {
                $tempPrivateData = $tempManifest.PrivateData
                if ($tempPrivateData.ContainsKey('PSData')) {
                    $tempPSData = $tempPrivateData.PSData
                    $tempPrivateData.Remove('PSData')
                }
            }

            $psdataOrder = @(
                'Tags'
                'LicenseUri'
                'ProjectUri'
                'IconUri'
                'ReleaseNotes'
                'Prerelease'
                'RequireLicenseAcceptance'
                'ExternalModuleDependencies'
            )
            foreach ($key in $psdataOrder) {
                if (($null -ne $tempPSData) -and ($tempPSData.ContainsKey($key))) {
                    $psData.$key = $tempPSData.$key
                }
            }
            if ($psData.Count -gt 0) {
                $privateData.PSData = $psData
            } else {
                $privateData.Remove('PSData')
            }
            foreach ($key in $tempPrivateData.Keys) {
                $privateData.$key = $tempPrivateData.$key
            }

            $manifestOrder = @(
                'RootModule'
                'ModuleVersion'
                'CompatiblePSEditions'
                'GUID'
                'Author'
                'CompanyName'
                'Copyright'
                'Description'
                'PowerShellVersion'
                'PowerShellHostName'
                'PowerShellHostVersion'
                'DotNetFrameworkVersion'
                'ClrVersion'
                'ProcessorArchitecture'
                'RequiredModules'
                'RequiredAssemblies'
                'ScriptsToProcess'
                'TypesToProcess'
                'FormatsToProcess'
                'NestedModules'
                'FunctionsToExport'
                'CmdletsToExport'
                'VariablesToExport'
                'AliasesToExport'
                'DscResourcesToExport'
                'ModuleList'
                'FileList'
                'HelpInfoURI'
                'DefaultCommandPrefix'
                'PrivateData'
            )
            foreach ($key in $manifestOrder) {
                if ($tempManifest.ContainsKey($key)) {
                    $manifest.$key = $tempManifest.$key
                }
            }
            if ($privateData.Count -gt 0) {
                $manifest.PrivateData = $privateData
            } else {
                $manifest.Remove('PrivateData')
            }

            return $manifest
        }
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Get-ModuleManifest] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Get-ModuleManifest]
#region    [functions] - [public] - [PowerShell] - [Module] - [Invoke-PruneModule]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Invoke-PruneModule] - Importing"
#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.3' }

function Invoke-PruneModule {
    <#
        .SYNOPSIS
        Remove all but the newest version of a module

        .DESCRIPTION
        Remove all but the newest version of a module

        .EXAMPLE
        Invoke-PruneModule -Name 'Az.*' -Scope CurrentUser
    #>
    [OutputType([void])]
    [CmdletBinding()]
    [Alias('Prune-Module')]
    param (
        # Name of the module(s) to prune
        [Parameter()]
        [string[]] $Name = '*',

        # Scope of the module(s) to prune
        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser'
    )

    if ($Scope -eq 'AllUsers' -and -not (IsAdmin)) {
        $message = 'Administrator rights are required to uninstall modules for all users. Please run the command again with' +
        " elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."

        throw $message
    }

    $UpdateableModules = Get-InstalledModule | Where-Object Name -Like "$Name"
    $UpdateableModuleNames = $UpdateableModules.Name | Sort-Object -Unique
    foreach ($UpdateableModuleName in $UpdateableModuleNames) {
        $UpdateableModule = $UpdateableModules | Where-Object Name -EQ $UpdateableModuleName | Sort-Object -Property Version -Descending
        Write-Verbose "[$($UpdateableModuleName)] - Found [$($UpdateableModule.Count)]"

        $NewestModule = $UpdateableModule | Select-Object -First 1
        Write-Verbose "[$($UpdateableModuleName)] - Newest [$($NewestModule.Version -join ', ')]"

        $OutdatedModules = $UpdateableModule | Select-Object -Skip 1
        Write-Verbose "[$($UpdateableModuleName)] - Outdated [$($OutdatedModules.Version -join ', ')]"

        foreach ($OutdatedModule in $OutdatedModules) {
            Write-Verbose "[$($UpdateableModuleName)] - [$($OutdatedModule.Version)] - Removing"
            $OutdatedModule | Remove-Module -Force
            Write-Verbose "[$($UpdateableModuleName)] - [$($OutdatedModule.Version)] - Uninstalling"
            Uninstall-Module -Name $OutdatedModule.Name -RequiredVersion -Force
            try {
                $OutdatedModule.ModuleBase | Remove-Item -Force -Recurse -ErrorAction Stop
            } catch {
                Write-Warning "[$($UpdateableModuleName)] - [$($OutdatedModule.Version)] - Failed to remove [$($OutdatedModule.ModuleBase)]"
                continue
            }
        }
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Invoke-PruneModule] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Invoke-PruneModule]
#region    [functions] - [public] - [PowerShell] - [Module] - [Invoke-ReinstallModule]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Invoke-ReinstallModule] - Importing"
#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.3' }

function Invoke-ReinstallModule {
    <#
        .SYNOPSIS
        Reinstalls module into a given scope.

        .DESCRIPTION
        Reinstalls module into a given scope. This is useful when you want to reinstall or clean up your module versions.
        With this command you always get the newest available version of the module and all the previous version wiped out.

        .PARAMETER Name
        The name of the module to be reinstalled. Wildcards are supported.

        .PARAMETER Scope
        The scope of the module to will be reinstalled to.

        .EXAMPLE
        Reinstall-Module -Name Pester -Scope CurrentUser

        Reinstall Pester module for the current user.

        .EXAMPLE
        Reinstall-Module -Scope CurrentUser

        Reinstall all reinstallable modules into the current user.
    #>
    [CmdletBinding()]
    [Alias('Reinstall-Module')]
    param (
        # Name of the module(s) to reinstall
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # Scope of the module(s) to reinstall
        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string[]] $Scope = 'CurrentUser'
    )

    if ($Scope -eq 'AllUsers' -and -not (IsAdmin)) {
        $message = 'Administrator rights are required to uninstall modules for all users. Please run the command again with' +
        " elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."

        throw $message
    }

    $modules = Get-InstalledModule | Where-Object Name -Like "$Name"
    Write-Verbose "Found [$($modules.Count)] modules"

    $modules | ForEach-Object {
        if ($_.name -eq 'Pester') {
            Uninstall-Pester -All
            continue
        }
        Uninstall-Module -Name $_ -AllVersions -Force -ErrorAction SilentlyContinue
    }

    $modules.Name | ForEach-Object {
        Install-Module -Name $_ -Scope $Scope -Force
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Invoke-ReinstallModule] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Invoke-ReinstallModule]
#region    [functions] - [public] - [PowerShell] - [Module] - [Set-ModuleManifest]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Set-ModuleManifest] - Importing"
filter Set-ModuleManifest {
    <#
        .SYNOPSIS
        Sets the values of a module manifest file.

        .DESCRIPTION
        This function sets the values of a module manifest file.
        Very much like the Update-ModuleManifest function, but allows values to be missing.

        .EXAMPLE
        Set-ModuleManifest -Path 'C:\MyModule\MyModule.psd1' -ModuleVersion '1.0.0'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Function does not change state.'
    )]
    [CmdletBinding()]
    param(
        # Path to the module manifest file.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $Path,

        #Script module or binary module file associated with this manifest.
        [Parameter()]
        [AllowNull()]
        [string] $RootModule,

        #Version number of this module.
        [Parameter()]
        [AllowNull()]
        [Version] $ModuleVersion,

        # Supported PSEditions.
        [Parameter()]
        [AllowNull()]
        [string[]] $CompatiblePSEditions,

        # ID used to uniquely identify this module.
        [Parameter()]
        [AllowNull()]
        [guid] $GUID,

        # Author of this module.
        [Parameter()]
        [AllowNull()]
        [string] $Author,

        # Company or vendor of this module.
        [Parameter()]
        [AllowNull()]
        [string] $CompanyName,

        # Copyright statement for this module.
        [Parameter()]
        [AllowNull()]
        [string] $Copyright,

        # Description of the functionality provided by this module.
        [Parameter()]
        [AllowNull()]
        [string] $Description,

        # Minimum version of the PowerShell engine required by this module.
        [Parameter()]
        [AllowNull()]
        [Version] $PowerShellVersion,

        # Name of the PowerShell host required by this module.
        [Parameter()]
        [AllowNull()]
        [string] $PowerShellHostName,

        # Minimum version of the PowerShell host required by this module.
        [Parameter()]
        [AllowNull()]
        [version] $PowerShellHostVersion,

        # Minimum version of Microsoft .NET Framework required by this module.
        # This prerequisite is valid for the PowerShell Desktop edition only.
        [Parameter()]
        [AllowNull()]
        [Version] $DotNetFrameworkVersion,

        # Minimum version of the common language runtime (CLR) required by this module.
        # This prerequisite is valid for the PowerShell Desktop edition only.
        [Parameter()]
        [AllowNull()]
        [Version] $ClrVersion,

        # Processor architecture (None,X86, Amd64) required by this module
        [Parameter()]
        [AllowNull()]
        [System.Reflection.ProcessorArchitecture] $ProcessorArchitecture,

        # Modules that must be imported into the global environment prior to importing this module.
        [Parameter()]
        [AllowNull()]
        [Object[]] $RequiredModules,

        # Assemblies that must be loaded prior to importing this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $RequiredAssemblies,

        # Script files (.ps1) that are run in the caller's environment prior to importing this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $ScriptsToProcess,

        # Type files (.ps1xml) to be loaded when importing this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $TypesToProcess,

        # Format files (.ps1xml) to be loaded when importing this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $FormatsToProcess,

        # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess.
        [Parameter()]
        [AllowNull()]
        [Object[]] $NestedModules,

        # Functions to export from this module, for best performance, do not use wildcards and do not
        # delete the entry, use an empty array if there are no functions to export.
        [Parameter()]
        [AllowNull()]
        [string[]] $FunctionsToExport,

        # Cmdlets to export from this module, for best performance, do not use wildcards and do not
        # delete the entry, use an empty array if there are no cmdlets to export.
        [Parameter()]
        [AllowNull()]
        [string[]] $CmdletsToExport,

        # Variables to export from this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $VariablesToExport,

        # Aliases to export from this module, for best performance, do not use wildcards and do not
        # delete the entry, use an empty array if there are no aliases to export.
        [Parameter()]
        [AllowNull()]
        [string[]] $AliasesToExport,

        # DSC resources to export from this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $DscResourcesToExport,

        # List of all modules packaged with this module.
        [Parameter()]
        [AllowNull()]
        [Object[]] $ModuleList,

        # List of all files packaged with this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $FileList,

        # Tags applied to this module. These help with module discovery in online galleries.
        [Parameter()]
        [AllowNull()]
        [string[]] $Tags,

        # A URL to the license for this module.
        [Parameter()]
        [AllowNull()]
        [uri] $LicenseUri,

        # A URL to the main site for this project.
        [Parameter()]
        [AllowNull()]
        [uri] $ProjectUri,

        # A URL to an icon representing this module.
        [Parameter()]
        [AllowNull()]
        [uri] $IconUri,

        # ReleaseNotes of this module.
        [Parameter()]
        [AllowNull()]
        [string] $ReleaseNotes,

        # Prerelease string of this module.
        [Parameter()]
        [AllowNull()]
        [string] $Prerelease,

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save.
        [Parameter()]
        [AllowNull()]
        [bool] $RequireLicenseAcceptance,

        # External dependent modules of this module.
        [Parameter()]
        [AllowNull()]
        [string[]] $ExternalModuleDependencies,

        # HelpInfo URI of this module.
        [Parameter()]
        [AllowNull()]
        [String] $HelpInfoURI,

        # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
        [Parameter()]
        [AllowNull()]
        [string] $DefaultCommandPrefix,

        # Private data to pass to the module specified in RootModule/ModuleToProcess.
        # This may also contain a PSData hashtable with additional module metadata used by PowerShell.
        [Parameter()]
        [AllowNull()]
        [object] $PrivateData
    )

    $outManifest = [ordered]@{}
    $outPSData = [ordered]@{}
    $outPrivateData = [ordered]@{}

    $tempManifest = Get-ModuleManifest -Path $Path
    if ($tempManifest.Keys.Contains('PrivateData')) {
        $tempPrivateData = $tempManifest.PrivateData
        if ($tempPrivateData.Keys.Contains('PSData')) {
            $tempPSData = $tempPrivateData.PSData
            $tempPrivateData.Remove('PSData')
        }
    }

    $psdataOrder = @(
        'Tags'
        'LicenseUri'
        'ProjectUri'
        'IconUri'
        'ReleaseNotes'
        'Prerelease'
        'RequireLicenseAcceptance'
        'ExternalModuleDependencies'
    )
    foreach ($key in $psdataOrder) {
        if (($null -ne $tempPSData) -and $tempPSData.Keys.Contains($key)) {
            $outPSData[$key] = $tempPSData[$key]
        }
        if ($PSBoundParameters.Keys.Contains($key)) {
            if ($null -eq $PSBoundParameters[$key]) {
                $outPSData.Remove($key)
            } else {
                $outPSData[$key] = $PSBoundParameters[$key]
            }
        }
    }

    if ($outPSData.Count -gt 0) {
        $outPrivateData.PSData = $outPSData
    } else {
        $outPrivateData.Remove('PSData')
    }
    foreach ($key in $tempPrivateData.Keys) {
        $outPrivateData[$key] = $tempPrivateData[$key]
    }
    foreach ($key in $PrivateData.Keys) {
        $outPrivateData[$key] = $PrivateData[$key]
    }

    $manifestOrder = @(
        'RootModule'
        'ModuleVersion'
        'CompatiblePSEditions'
        'GUID'
        'Author'
        'CompanyName'
        'Copyright'
        'Description'
        'PowerShellVersion'
        'PowerShellHostName'
        'PowerShellHostVersion'
        'DotNetFrameworkVersion'
        'ClrVersion'
        'ProcessorArchitecture'
        'RequiredModules'
        'RequiredAssemblies'
        'ScriptsToProcess'
        'TypesToProcess'
        'FormatsToProcess'
        'NestedModules'
        'FunctionsToExport'
        'CmdletsToExport'
        'VariablesToExport'
        'AliasesToExport'
        'DscResourcesToExport'
        'ModuleList'
        'FileList'
        'HelpInfoURI'
        'DefaultCommandPrefix'
        'PrivateData'
    )
    foreach ($key in $manifestOrder) {
        if ($tempManifest.Keys.Contains($key)) {
            $outManifest[$key] = $tempManifest[$key]
        }
        if ($PSBoundParameters.Keys.Contains($key)) {
            if ($null -eq $PSBoundParameters[$key]) {
                $outManifest.Remove($key)
            } else {
                $outManifest[$key] = $PSBoundParameters[$key]
            }
        }
    }
    if ($outPrivateData.Count -gt 0) {
        $outManifest['PrivateData'] = $outPrivateData
    } else {
        $outManifest.Remove('PrivateData')
    }

    $sectionsToSort = @(
        'CompatiblePSEditions',
        'RequiredAssemblies',
        'ScriptsToProcess',
        'TypesToProcess',
        'FormatsToProcess',
        'FunctionsToExport',
        'CmdletsToExport',
        'VariablesToExport',
        'AliasesToExport',
        'DscResourcesToExport',
        'ModuleList',
        'FileList'
    )

    foreach ($section in $sectionsToSort) {
        if ($outManifest.Contains($section) -and $null -ne $outManifest[$section]) {
            $outManifest[$section] = @($outManifest[$section] | Sort-Object)
        }
    }

    $objectSectionsToSort = @('RequiredModules', 'NestedModules')
    foreach ($section in $objectSectionsToSort) {
        if ($outManifest.Contains($section) -and $null -ne $outManifest[$section]) {
            $sortedObjects = $outManifest[$section] | Sort-Object -Property {
                if ($_ -is [hashtable]) {
                    $_['ModuleName']
                } elseif ($_ -is [Microsoft.PowerShell.Commands.ModuleSpecification]) {
                    $_.Name
                } elseif ($_ -is [string]) {
                    $_
                } else {
                    throw "Unsupported type '$($_.GetType().Name)' in module manifest."
                }
            }

            $formattedModules = foreach ($item in $sortedObjects) {
                if ($item -is [Microsoft.PowerShell.Commands.ModuleSpecification]) {
                    $hash = [ordered]@{}
                    $hash['ModuleName'] = $item.Name
                    if ($item.RequiredVersion) {
                        $hash['RequiredVersion'] = $item.RequiredVersion.ToString()
                    } elseif ($item.Version) {
                        $hash['ModuleVersion'] = $item.Version.ToString()
                    } elseif ($item.MaximumVersion) {
                        $hash['MaximumVersion'] = $item.MaximumVersion.ToString()
                    }

                    if ($hash.Count -eq 1) {
                        # Simplify if only ModuleName
                        $hash.ModuleName
                    } else {
                        $hash
                    }
                } elseif ($item -is [hashtable]) {
                    # Recreate as ordered hashtable explicitly
                    $orderedItem = [ordered]@{}
                    if ($item.ContainsKey('ModuleName')) {
                        $orderedItem['ModuleName'] = $item['ModuleName']
                    }
                    if ($item.RequiredVersion) {
                        $orderedItem['RequiredVersion'] = $item.RequiredVersion
                    }
                    if ($item.ModuleVersion) {
                        $orderedItem['ModuleVersion'] = $item.ModuleVersion
                    }
                    if ($item.MaximumVersion) {
                        $orderedItem['MaximumVersion'] = $item.MaximumVersion
                    }
                    $orderedItem
                } elseif ($item -is [string]) {
                    $item
                }
            }

            $outManifest[$section] = @($formattedModules)
        }
    }




    if ($outPrivateData.Contains('PSData')) {
        if ($outPrivateData.PSData.Contains('ExternalModuleDependencies') -and $null -ne $outPrivateData.PSData.ExternalModuleDependencies) {
            $outPrivateData.PSData.ExternalModuleDependencies = @($outPrivateData.PSData.ExternalModuleDependencies | Sort-Object)
        }
        if ($outPrivateData.PSData.Contains('Tags') -and $null -ne $outPrivateData.PSData.Tags) {
            $outPrivateData.PSData.Tags = @($outPrivateData.PSData.Tags | Sort-Object)
        }
    }

    Remove-Item -Path $Path -Force
    Export-PowerShellDataFile -Hashtable $outManifest -Path $Path
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Set-ModuleManifest] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Set-ModuleManifest]
#region    [functions] - [public] - [PowerShell] - [Module] - [Set-ScriptFileRequirement]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Set-ScriptFileRequirement] - Importing"
#Requires -Modules @{ ModuleName = 'Ast'; RequiredVersion = '0.4.0' }

function Set-ScriptFileRequirement {
    <#
        .SYNOPSIS
        Sets correct module requirements for PowerShell scripts, ignoring local functions, [Alias()] attributes,
        Set-Alias-based aliases, and the '.' or '&' operators in the same folder.

        .DESCRIPTION
        This function can process either a single .ps1 file or an entire folder (recursively).
        It uses two phases:

        Phase 1 (Collection):
        - Parse each file to gather local function names, [Alias("...")] attributes, and Set-Alias definitions.

        Phase 2 (Analysis):
        - Parse each file again to find commands that need external modules.
        - Skips:
          * Locally defined functions
          * Aliases that map to local functions
          * Module paths that reside in the same folder
          * Special operators '.' and '&'
        - Inserts `#Requires` lines for any truly external modules.
        - Appends `#FIX:` comments for commands that are not resolved.

        .EXAMPLE
        PS> Set-ScriptFileRequirement -Path "C:\MyScripts"
        Recursively scans C:\MyScripts, updates #Requires lines in each .ps1 file.

        .EXAMPLE
        PS> Set-ScriptFileRequirement -Path "./Scripts/Deploy.ps1" -Debug
        Processes only the Deploy.ps1 file, displaying debug messages with internal
        processing details.

        .NOTES
        - Operators '.' (dot-sourcing) and '&' (call operator) are explicitly ignored,
        since they are not actual commands that map to modules.
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # A path to either a single .ps1 file or a folder.
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string] $Path
    )

    # Check if folder or file
    $item = Get-Item -Path $Path
    $isDirectory = $item.PSIsContainer
    if ($isDirectory) {
        Write-Verbose "Collecting all '*.ps1' and '*.psm1' files from directory '$Path' recursively..."
        $ps1Files = Get-ChildItem -Path $Path -Include '*.ps1', '*.psm1' -File -Recurse
        $rootFolderPath = (Resolve-Path -Path $Path).ProviderPath
    } else {
        if ([IO.Path]::GetExtension($Path) -ne '.ps1') {
            throw "Path '$Path' does not reference a .ps1 file or directory."
        }
        $ps1Files = @( $item )
        Write-Verbose "Processing single file: $Path"
        $rootFolderPath = Split-Path -Path (Resolve-Path -Path $Path).ProviderPath
    }

    Write-Verbose 'Gathering local functions and aliases from the script(s)...'
    $localFunctions = @()
    $localAliases = @()

    foreach ($file in $ps1Files) {
        Write-Verbose "Gathering info from file: [$($file.FullName)]"
        $functionName = Get-AstFunctionName -Path $file.FullName
        Write-Verbose " - Name: $functionName"
        $localFunctions += $functionName
        Get-FunctionAlias -Path $file.FullName | Select-Object -ExpandProperty Alias | ForEach-Object {
            $functionAlias = $_
            Write-Verbose " - Alias: $functionAlias"
            $localAliases += $functionAlias
        }
    }

    Write-Verbose 'Gathering built-in modules'
    $builtInModule = Get-Module -ListAvailable | Where-Object { $_.ModuleBase -like "$($PSHOME)\Modules*" }

    Write-Verbose 'Gathering installed modules via Get-InstalledPSResource'
    $installedResources = Get-InstalledPSResource

    Write-Verbose 'Analyzing commands in files'
    # $file = $ps1Files[6]
    foreach ($file in $ps1Files) {
        $requiredModules = @{}

        Write-Verbose "Analyzing file: [$($file.FullName)]"
        $functionNames = Get-AstFunctionName -Path $file.FullName
        $scriptCommands = Get-AstScriptCommand -Path $file.FullName
        Write-Verbose " - Found $($scriptCommands.Count) commands"
        # $command = $scriptCommands[0]
        foreach ($command in $scriptCommands) {
            $commandName = $command.Name
            $lineNumber = $command.StartLineNumber
            Write-Verbose "   - Command: $commandName (L:$lineNumber)"

            # Skip if the command is a call to self (recursive)
            if ($functionNames -contains $commandName ) {
                Write-Verbose "     - Skipping - $commandName is a function in the file"
                continue
            }

            # Skip if it's a local function or alias
            if ($localFunctions -contains $commandName -or $localAliases -contains $commandName) {
                Write-Verbose "     - Skipping - $commandName is a local function or alias"
                continue
            }

            # Attempt external resolution
            $foundCommands = Get-Command $commandName -ErrorAction SilentlyContinue
            Write-Verbose "     - Found $($foundCommands.Count) matches"

            if ($foundCommands.Count -eq 0) {
                Write-Verbose '     - Command not found, attempting to resolve...'

                $foundSuggestions = Find-Command -Name $commandName -ErrorAction SilentlyContinue -Debug:$false -Verbose:$false
                if ($foundSuggestions) {
                    $sortedSuggestions = $foundSuggestions | Sort-Object {
                        if ($_ -and $_.PSGetModuleInfo -and $_.PSGetModuleInfo.PublishedDate) {
                            return $_.PSGetModuleInfo.PublishedDate
                        } else {
                            return [datetime]::MinValue
                        }
                    } -Descending

                    $moduleNamesOrdered = New-Object System.Collections.Generic.List[string]
                    foreach ($suggestion in $sortedSuggestions) {
                        if (-not $moduleNamesOrdered.Contains($suggestion.ModuleName)) {
                            [void]$moduleNamesOrdered.Add($suggestion.ModuleName)
                        }
                    }
                    $suggestText = 'Suggestions: ' + ($moduleNamesOrdered -join ', ')
                } else {
                    $suggestText = '(No suggestions found)'
                }

                # Write a comment to the line so that it can be fixed manually
                $fileLines = Get-Content -Path $file.FullName
                $lineIndex = $lineNumber - 1
                Write-Verbose "     - Processing [$($fileLines[$lineIndex])]"
                $fileLines[$lineIndex] = $fileLines[$lineIndex].Replace(($fileLines[$lineIndex] | Get-LineComment), '').TrimEnd()
                $comment = " #FIXME: Add '#Requires -Modules' for [$commandName] $suggestText"
                $fileLines[$lineIndex] += $comment
                Write-Verbose '     - Adding a FIXME comment, so user can fix manually'
                $null = $fileLines | Set-Content -Path $file.FullName
            }
            # $foundCommand = $foundCommands[0]
            foreach ($foundCommand in $foundCommands) {
                Write-Verbose "     - Found command: $($foundCommand.Name) in module: $($foundCommand.ModuleName)@$($foundCommand.Version)"

                # Skip if it is a built-in module
                if ($foundCommand.ModuleName -in $builtInModule.Name) {
                    Write-Verbose "     - Skipping - $commandName is a built-in command"
                    continue
                }

                # If module is running locally, find the verison and add it to the requiredModules list
                if ($installedResources.Name -contains $foundCommand.ModuleName) {
                    $possibleVersions = $installedResources | Where-Object { $_.Name -eq $foundCommand.ModuleName } | Sort-Object Version -Descending
                    $highestVersion = $possibleVersions[0].Version.ToString()

                    Write-Debug "Found module '$($foundCommand.ModuleName)' with version '$highestVersion'"

                    # Check if module is already in requiredModules, if not add it, if it is, check if the version is higher
                    if (-not $requiredModules.ContainsKey($foundCommand.ModuleName)) {
                        $requiredModules[$foundCommand.ModuleName] = $highestVersion
                        continue
                    }

                    $existingVersion = [Version]$requiredModules[$foundCommand.ModuleName]
                    $newVersion = [Version]$highestVersion
                    if ($newVersion -gt $existingVersion) {
                        $requiredModules[$foundCommand.ModuleName] = $newVersion.ToString()
                    }
                } else {
                    Write-Debug ("Module '{0}' is inside '{1}', skipping as local." -f $foundCommand.ModuleName, $rootFolderPath)
                }
            }
        }

        # Read the content and remove lines that match "#Requires -Modules"
        $content = Get-Content $file.FullName | Where-Object { $_ -notmatch '^#Requires\s+-Modules' }

        # Remove leading and trailing empty lines
        $trimmedContent = $content -join "`n" -replace '^\s*\n+', '' -replace '\n+\s*$', '' -split "`n"

        # Write the cleaned content back to the file
        $trimmedContent | Set-Content $file.FullName

        # Build #Requires lines (alphabetically)
        $requiresToAdd = foreach ($moduleName in ($requiredModules.Keys | Sort-Object)) {
            $modVersion = $requiredModules[$moduleName]
            "#Requires -Modules @{ ModuleName = '$moduleName'; RequiredVersion = '$modVersion' }"
        }
        $requiresToAdd = @($requiresToAdd)

        $fileLines = Get-Content -Path $file.FullName
        $mergedList = [System.Collections.ArrayList]::new()

        if ($requiresToAdd.Count -gt 0) {
            Write-Debug ("Adding {0} #Requires lines to file '{1}'." -f $requiresToAdd.Count, $file.FullName)
            $mergedList.AddRange($requiresToAdd)
            $null = $mergedList.Add('')
        }

        $mergedList.AddRange($fileLines)
        $finalLines = $mergedList

        Write-Verbose "Updating file: $($file.FullName)"
        if ($PSCmdlet.ShouldProcess('file', 'Write changes')) {
            $null = $finalLines | Out-File -LiteralPath $file.FullName -Encoding utf8BOM
        }
    }

    Write-Verbose 'All .ps1 files processed.'
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Set-ScriptFileRequirement] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Set-ScriptFileRequirement]
#region    [functions] - [public] - [PowerShell] - [Module] - [Uninstall-Pester]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Uninstall-Pester] - Importing"
function Uninstall-Pester {
    <#
        .SYNOPSIS
        Uninstall Pester 3 from Program Files and Program Files (x86)

        .DESCRIPTION
        Uninstall Pester 3 from Program Files and Program Files (x86). This is useful
        when you want to install Pester 4 and you have Pester 3 installed.

        .PARAMETER All

        .EXAMPLE
        Uninstall-Pester

        Uninstall Pester 3 from Program Files and Program Files (x86).

        .EXAMPLE
        Uninstall-Pester -All

        Completely remove all built-in Pester 3 installations.
    #>
    [OutputType([String])]
    [CmdletBinding()]
    param (
        # Completely remove all built-in Pester 3 installations
        [Parameter()]
        [switch] $All
    )

    $pesterPaths = foreach ($programFiles in ($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        $path = "$programFiles\WindowsPowerShell\Modules\Pester"
        if ($null -ne $programFiles -and (Test-Path $path)) {
            if ($All) {
                Get-Item $path
            } else {
                Get-ChildItem "$path\3.*"
            }
        }
    }

    if (-not $pesterPaths) {
        "There are no Pester$(if (-not $all) {' 3'}) installations in Program Files and Program Files (x86) doing nothing."
        return
    }

    foreach ($pesterPath in $pesterPaths) {
        takeown /F $pesterPath /A /R
        icacls $pesterPath /reset
        # grant permissions to Administrators group, but use SID to do
        # it because it is localized on non-us installations of Windows
        icacls $pesterPath /grant '*S-1-5-32-544:F' /inheritance:d /T
        Remove-Item -Path $pesterPath -Recurse -Force -Confirm:$false
    }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - [Uninstall-Pester] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module] - [Uninstall-Pester]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Module] - Done"
#endregion [functions] - [public] - [PowerShell] - [Module]
#region    [functions] - [public] - [PowerShell] - [Object]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Object] - Processing folder"
#region    [functions] - [public] - [PowerShell] - [Object] - [Copy-Object]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Object] - [Copy-Object] - Importing"
filter Copy-Object {
    <#
        .SYNOPSIS
        Copy an object

        .DESCRIPTION
        Copy an object

        .EXAMPLE
        $Object | Copy-Object

        Copy an object
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param (
        # Object to copy
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Object] $InputObject
    )

    $InputObject | ConvertTo-Json -Depth 100 | ConvertFrom-Json

}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Object] - [Copy-Object] - Done"
#endregion [functions] - [public] - [PowerShell] - [Object] - [Copy-Object]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - [Object] - Done"
#endregion [functions] - [public] - [PowerShell] - [Object]
Write-Debug "[$scriptName] - [functions] - [public] - [PowerShell] - Done"
#endregion [functions] - [public] - [PowerShell]
#region    [functions] - [public] - [String]
Write-Debug "[$scriptName] - [functions] - [public] - [String] - Processing folder"
#region    [functions] - [public] - [String] - [Test-IsNotNullOrEmpty]
Write-Debug "[$scriptName] - [functions] - [public] - [String] - [Test-IsNotNullOrEmpty] - Importing"
filter Test-IsNotNullOrEmpty {
    <#
        .SYNOPSIS
        Test if an object is not null or empty

        .DESCRIPTION
        Test if an object is not null or empty

        .EXAMPLE
        '' | Test-IsNotNullOrEmpty

        False
    #>
    [OutputType([bool])]
    [Cmdletbinding()]
    [Alias('IsNotNullOrEmpty')]
    param(
        # Object to test
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [AllowNull()]
        [object] $Object
    )
    return -not ($Object | IsNullOrEmpty)

}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [String] - [Test-IsNotNullOrEmpty] - Done"
#endregion [functions] - [public] - [String] - [Test-IsNotNullOrEmpty]
#region    [functions] - [public] - [String] - [Test-IsNullOrEmpty]
Write-Debug "[$scriptName] - [functions] - [public] - [String] - [Test-IsNullOrEmpty] - Importing"
filter Test-IsNullOrEmpty {
    <#
        .SYNOPSIS
        Test if an object is null or empty

        .DESCRIPTION
        Test if an object is null or empty

        .EXAMPLE
        '' | IsNullOrEmpty

        True
    #>
    [OutputType([bool])]
    [Cmdletbinding()]
    [Alias('IsNullOrEmpty')]
    param(
        # The object to test
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [AllowNull()]
        [object] $Object
    )

    try {
        if (-not ($PSBoundParameters.ContainsKey('Object'))) {
            Write-Debug 'Object was never passed, meaning its empty or null.'
            return $true
        }
        if ($null -eq $Object) {
            Write-Debug 'Object is null'
            return $true
        }
        Write-Debug "Object is: $($Object.GetType().Name)"
        if ($Object -eq 0) {
            Write-Debug 'Object is 0'
            return $true
        }
        if ($Object.Length -eq 0) {
            Write-Debug 'Object is empty array or string'
            return $true
        }
        if ($Object.GetType() -eq [string]) {
            if ([string]::IsNullOrWhiteSpace($Object)) {
                Write-Debug 'Object is empty string'
                return $true
            } else {
                Write-Debug 'Object is not an empty string'
                return $false
            }
        }
        if ($Object.Count -eq 0) {
            Write-Debug 'Object count is 0'
            return $true
        }
        if (-not $Object) {
            Write-Debug 'Object evaluates to false'
            return $true
        }
        if (($Object.GetType().Name -ne 'PSCustomObject')) {
            Write-Debug 'Casting object to PSCustomObject'
            $Object = [PSCustomObject]$Object
        }
        if (($Object.GetType().Name -eq 'PSCustomObject')) {
            Write-Debug 'Object is PSCustomObject'
            if ($Object -eq (New-Object -TypeName PSCustomObject)) {
                Write-Debug 'Object is similar to empty PSCustomObject'
                return $true
            }
            if (($Object.psobject.Properties).Count | Test-IsNullOrEmpty) {
                Write-Debug 'Object has no properties'
                return $true
            }
        }
    } catch {
        Write-Debug 'Object triggered exception'
        return $true
    }

    Write-Debug 'Object is not null or empty'
    return $false
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [String] - [Test-IsNullOrEmpty] - Done"
#endregion [functions] - [public] - [String] - [Test-IsNullOrEmpty]
Write-Debug "[$scriptName] - [functions] - [public] - [String] - Done"
#endregion [functions] - [public] - [String]
#region    [functions] - [public] - [Windows]
Write-Debug "[$scriptName] - [functions] - [public] - [Windows] - Processing folder"
#region    [functions] - [public] - [Windows] - [Set-WindowsSetting]
Write-Debug "[$scriptName] - [functions] - [public] - [Windows] - [Set-WindowsSetting] - Importing"
filter Set-WindowsSetting {
    <#
        .SYNOPSIS
        Set a Windows setting

        .DESCRIPTION
        Set a or multiple Windows setting(s).

        .NOTES
        Supported OS: Windows
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Show file extensions in Windows Explorer
        [Parameter()]
        [switch] $ShowFileExtension,

        # Show hidden files in Windows Explorer
        [Parameter()]
        [switch] $ShowHiddenFiles
    )

    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($PSCmdlet.ShouldProcess("'ShowFileExtension' to [$ShowFileExtension]", 'Set')) {
        $hideFileExt = if ($ShowFileExtension) { 0 } else { 1 }
        Set-ItemProperty -Path $path -Name HideFileExt -Value $hideFileExt
    }

    if ($PSCmdlet.ShouldProcess("'ShowHiddenFiles' to [$ShowFileExtension]", 'Set')) {
        $hiddenFiles = if ($ShowHiddenFiles) { 1 } else { 2 }
        Set-ItemProperty -Path $path -Name Hidden -Value $hiddenFiles
    }

    # Refresh File Explorer
    $Shell = New-Object -ComObject Shell.Application
    $Shell.Windows() | ForEach-Object { $_.Refresh() }
}

#SkipTest:FunctionTest:Will add a test for this function in a future PR
Write-Debug "[$scriptName] - [functions] - [public] - [Windows] - [Set-WindowsSetting] - Done"
#endregion [functions] - [public] - [Windows] - [Set-WindowsSetting]
Write-Debug "[$scriptName] - [functions] - [public] - [Windows] - Done"
#endregion [functions] - [public] - [Windows]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]
#region    [common]
Write-Debug "[$scriptName] - [common] - Importing"
$env:DocsPath = [environment]::GetFolderPath('MyDocuments')
$env:CommonDocsPath = [environment]::GetFolderPath('CommonDocuments')
$env:DesktopPath = [environment]::GetFolderPath('Desktop')
$env:CommonDesktopPath = [environment]::GetFolderPath('CommonDesktop')
#$shellApplication = New-Object -ComObject Shell.Application
#$DownloadPath = $shellApplication.NameSpace('shell:Downloads').Self.Path
$env:StartMenuPath = [environment]::GetFolderPath('StartMenu')
$env:CommonStartMenuPath = [environment]::GetFolderPath('CommonStartMenu')
$env:FontsPath = [environment]::GetFolderPath('Fonts')
$env:IPConfigFilePath = "$([Environment]::GetFolderPath('MyDocuments'))\IPConfig.json"
Write-Debug "[$scriptName] - [common] - Done"
#endregion [common]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'ConvertTo-Boolean'
        'Get-FileInfo'
        'Remove-EmptyFolder'
        'Show-FileContent'
        'Clear-GitRepo'
        'Invoke-GitSquash'
        'Invoke-SquashBranch'
        'Reset-GitRepo'
        'Restore-GitRepo'
        'Sync-GitRepo'
        'Sync-Repo'
        'Add-ModuleManifestData'
        'Add-PSModulePath'
        'Export-PowerShellDataFile'
        'Format-ModuleManifest'
        'Get-ModuleManifest'
        'Invoke-PruneModule'
        'Invoke-ReinstallModule'
        'Set-ModuleManifest'
        'Set-ScriptFileRequirement'
        'Uninstall-Pester'
        'Copy-Object'
        'Test-IsNotNullOrEmpty'
        'Test-IsNullOrEmpty'
        'Set-WindowsSetting'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

