[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidAssignmentToAutomaticVariable', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
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
#region    [functions] - [public] - [completers]
Write-Debug "[$scriptName] - [functions] - [public] - [completers] - Importing"
Register-ArgumentCompleter -CommandName Get-NerdFont, Install-NerdFont -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter
    Get-NerdFont -Verbose:$false | Select-Object -ExpandProperty Name | Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new("'$_'", $_, 'ParameterValue', $_) }
}
Write-Debug "[$scriptName] - [functions] - [public] - [completers] - Done"
#endregion [functions] - [public] - [completers]
#region    [functions] - [public] - [Get-NerdFont]
Write-Debug "[$scriptName] - [functions] - [public] - [Get-NerdFont] - Importing"
function Get-NerdFont {
    <#
        .SYNOPSIS
        Get NerdFonts list

        .DESCRIPTION
        Get NerdFonts list, filtered by name, from the latest release.

        .EXAMPLE
        Get-NerdFonts

        Get all the NerdFonts.

        .EXAMPLE
        Get-NerdFonts -Name 'FiraCode'

        Get the NerdFont with the name 'FiraCode'.

        .EXAMPLE
        Get-NerdFonts -Name '*Code'

        Get the NerdFont with the name ending with 'Code'.

        .LINK
        https://psmodule.io/NerdFonts/Functions/Get-NerdFont

        .NOTES
        More information about the NerdFonts can be found at:
        [NerdFonts](https://www.nerdfonts.com/) | [GitHub](https://github.com/ryanoasis/nerd-fonts)
    #>
    [Alias('Get-NerdFonts')]
    [OutputType([System.Object[]])]
    [CmdletBinding()]
    param (
        # Name of the NerdFont to get
        [Parameter()]
        [SupportsWildcards()]
        [string] $Name = '*'
    )

    Write-Verbose 'Selecting assets by:'
    Write-Verbose "Name:    [$Name]"
    $script:NerdFonts | Where-Object { $_.Name -like $Name }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Get-NerdFont] - Done"
#endregion [functions] - [public] - [Get-NerdFont]
#region    [functions] - [public] - [Install-NerdFont]
Write-Debug "[$scriptName] - [functions] - [public] - [Install-NerdFont] - Importing"
#Requires -Modules @{ ModuleName = 'Fonts'; RequiredVersion = '1.1.21' }
#Requires -Modules @{ ModuleName = 'Admin'; RequiredVersion = '1.1.6' }

function Install-NerdFont {
    <#
        .SYNOPSIS
        Installs Nerd Fonts to the system.

        .DESCRIPTION
        Installs Nerd Fonts to the system.

        .EXAMPLE
        Install-NerdFont -Name 'Fira Code'

        Installs the font 'Fira Code' to the current user.

        .EXAMPLE
        Install-NerdFont -Name 'Ubuntu*'

        Installs all fonts that match the pattern 'Ubuntu*' to the current user.

        .EXAMPLE
        Install-NerdFont -Name 'Fira Code' -Scope AllUsers

        Installs the font 'Fira Code' to all users. This requires to be run as administrator.

        .EXAMPLE
        Install-NerdFont -All

        Installs all Nerd Fonts to the current user.

        .LINK
        https://psmodule.io/NerdFonts/Functions/Install-NerdFont

        .NOTES
        More information about the NerdFonts can be found at:
        [NerdFonts](https://www.nerdfonts.com/) | [GitHub](https://github.com/ryanoasis/nerd-fonts)
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'ByName',
        SupportsShouldProcess
    )]
    [Alias('Install-NerdFonts')]
    param(
        # Specify the name of the NerdFont(s) to install.
        [Parameter(
            ParameterSetName = 'ByName',
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name,

        # Specify to install all NerdFont(s).
        [Parameter(
            ParameterSetName = 'All',
            Mandatory
        )]
        [switch] $All,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string] $Scope = 'CurrentUser',

        # Force will overwrite existing fonts
        [Parameter()]
        [switch] $Force
    )

    begin {
        if ($Scope -eq 'AllUsers' -and -not (IsAdmin)) {
            $errorMessage = @'
Administrator rights are required to install fonts.
Please run the command again with elevated rights (Run as Administrator) or provide '-Scope CurrentUser' to your command."
'@
            throw $errorMessage
        }
        $nerdFontsToInstall = @()

        $guid = (New-Guid).Guid
        $tempPath = Join-Path -Path $HOME -ChildPath "NerdFonts-$guid"
        if (-not (Test-Path -Path $tempPath -PathType Container)) {
            Write-Verbose "Create folder [$tempPath]"
            $null = New-Item -Path $tempPath -ItemType Directory
        }
    }

    process {
        if ($All) {
            $nerdFontsToInstall = $script:NerdFonts
        } else {
            foreach ($fontName in $Name) {
                $nerdFontsToInstall += $script:NerdFonts | Where-Object { $_.Name -like $fontName }
            }
        }

        Write-Verbose "[$Scope] - Installing [$($nerdFontsToInstall.count)] fonts"

        foreach ($nerdFont in $nerdFontsToInstall) {
            $URL = $nerdFont.URL
            $fontName = $nerdFont.Name
            $downloadFileName = Split-Path -Path $URL -Leaf
            $downloadPath = Join-Path -Path $tempPath -ChildPath $downloadFileName

            Write-Verbose "[$fontName] - Downloading to [$downloadPath]"
            if ($PSCmdlet.ShouldProcess("[$fontName] to [$downloadPath]", 'Download')) {
                Invoke-WebRequest -Uri $URL -OutFile $downloadPath -RetryIntervalSec 5 -MaximumRetryCount 5
            }

            $extractPath = Join-Path -Path $tempPath -ChildPath $fontName
            Write-Verbose "[$fontName] - Extract to [$extractPath]"
            if ($PSCmdlet.ShouldProcess("[$fontName] to [$extractPath]", 'Extract')) {
                Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
                Remove-Item -Path $downloadPath -Force
            }

            Write-Verbose "[$fontName] - Install to [$Scope]"
            if ($PSCmdlet.ShouldProcess("[$fontName] to [$Scope]", 'Install font')) {
                Install-Font -Path $extractPath -Scope $Scope -Force:$Force
                Remove-Item -Path $extractPath -Force -Recurse
            }
        }
    }

    end {
        Write-Verbose "Remove folder [$tempPath]"
    }

    clean {
        Remove-Item -Path $tempPath -Force
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Install-NerdFont] - Done"
#endregion [functions] - [public] - [Install-NerdFont]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]
#region    [variables] - [private]
Write-Debug "[$scriptName] - [variables] - [private] - Processing folder"
#region    [variables] - [private] - [NerdFonts]
Write-Debug "[$scriptName] - [variables] - [private] - [NerdFonts] - Importing"
$script:NerdFonts = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'FontsData.json') | ConvertFrom-Json
Write-Debug "[$scriptName] - [variables] - [private] - [NerdFonts] - Done"
#endregion [variables] - [private] - [NerdFonts]
Write-Debug "[$scriptName] - [variables] - [private] - Done"
#endregion [variables] - [private]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'Get-NerdFont'
        'Install-NerdFont'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

