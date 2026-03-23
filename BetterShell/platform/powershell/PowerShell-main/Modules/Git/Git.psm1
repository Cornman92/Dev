<#
.SYNOPSIS
    Git module provides enhanced Git workflow functions for PowerShell.
.DESCRIPTION
    This module contains functions that simplify common Git operations and provide
    additional functionality on top of the Git command line interface.
.NOTES
    File Name      : Git.psm1
    Author         : Your Name
    Prerequisite   : PowerShell 5.1 or later, Git
    Copyright      : (c) 2025, Your Organization. All rights reserved.
#>

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Private Functions

<#
.SYNOPSIS
    Executes a Git command and handles the output.
.INTERNAL
#>
function Invoke-GitCommand {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string[]]$Arguments,
        
        [string]$WorkingDirectory = (Get-Location).Path,
        
        [switch]$SuppressOutput,
        
        [switch]$ThrowOnError
    )
    
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'git'
        $psi.Arguments = $Arguments -join ' '
        $psi.WorkingDirectory = $WorkingDirectory
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        
        $output = [System.Collections.ArrayList]::new()
        $errorOutput = [System.Text.StringBuilder]::new()
        
        $outputScope = if ($SuppressOutput) { $null } else { 1 }
        
        $eventOutput = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
            if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
                if ($event.MessageData.Output) {
                    [void]$event.MessageData.Output.Add($EventArgs.Data)
                }
                if ($event.MessageData.Scope) {
                    Write-Output $EventArgs.Data
                }
            }
        } -MessageData @{ Output = $output; Scope = $outputScope }
        
        $eventError = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
            if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
                [void]$errorOutput.AppendLine($EventArgs.Data)
                if ($event.MessageData.Scope) {
                    Write-Error $EventArgs.Data
                }
            }
        } -MessageData @{ Scope = $outputScope }
        
        [void]$process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        
        $process.WaitForExit()
        
        if ($process.ExitCode -ne 0 -and $ThrowOnError) {
            throw "Git command failed with exit code $($process.ExitCode): $($errorOutput.ToString())"
        }
        
        return $output
    }
    catch {
        Write-Error "Error executing Git command: $_"
        throw
    }
    finally {
        # Clean up event handlers
        if ($eventOutput) { Unregister-Event -SourceIdentifier $eventOutput.Name -ErrorAction SilentlyContinue }
        if ($eventError) { Unregister-Event -SourceIdentifier $eventError.Name -ErrorAction SilentlyContinue }
        if ($process) { $process.Dispose() }
    }
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Initializes a new Git repository with standard configuration.
.DESCRIPTION
    Creates a new Git repository with recommended settings and optional initial commit.
.EXAMPLE
    New-GitRepository -Path ".\MyProject" -InitializeReadme -GitIgnore "VisualStudio" -License "MIT"
#>
function New-GitRepository {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter(Position=0)]
        [string]$Path = ".",
        
        [switch]$InitializeReadme,
        
        [ValidateSet('None', 'VisualStudio', 'Node', 'Python', 'Windows', 'Linux', 'macOS')]
        [string]$GitIgnore,
        
        [ValidateSet('None', 'MIT', 'Apache-2.0', 'GPL-3.0', 'BSD-3-Clause')]
        [string]$License,
        
        [string]$InitialCommitMessage = "Initial commit"
    )
    
    try {
        # Resolve the full path
        $Path = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        
        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $Path)) {
            if ($PSCmdlet.ShouldProcess($Path, "Create directory")) {
                New-Item -Path $Path -ItemType Directory -Force | Out-Null
            }
        }
        
        # Initialize Git repository
        if ($PSCmdlet.ShouldProcess($Path, "Initialize Git repository")) {
            Push-Location -Path $Path
            
            try {
                Invoke-GitCommand -Arguments 'init' -WorkingDirectory $Path -SuppressOutput
                
                # Create .gitignore if specified
                if ($GitIgnore -and $GitIgnore -ne 'None') {
                    $gitignoreUrl = "https://raw.githubusercontent.com/github/gitignore/main/$GitIgnore.gitignore"
                    try {
                        Invoke-WebRequest -Uri $gitignoreUrl -OutFile "$Path\.gitignore" -ErrorAction Stop
                        Invoke-GitCommand -Arguments 'add', '.gitignore' -WorkingDirectory $Path -SuppressOutput
                    }
                    catch {
                        Write-Warning "Failed to download .gitignore template: $_"
                    }
                }
                
                # Create README.md if requested
                if ($InitializeReadme) {
                    $readmeContent = @"
# $(Split-Path -Path $Path -Leaf)

Project description goes here.

## Getting Started

Instructions for getting started with the project.

## Prerequisites

- List of prerequisites

## Installation

Step-by-step installation instructions.

## Usage

Examples of how to use the project.

## License

This project is licensed under the $($License) License - see the LICENSE file for details.
"@
                    $readmeContent | Out-File -FilePath "$Path\README.md" -Encoding utf8
                    Invoke-GitCommand -Arguments 'add', 'README.md' -WorkingDirectory $Path -SuppressOutput
                }
                
                # Create LICENSE file if specified
                if ($License -and $License -ne 'None') {
                    $licenseYear = (Get-Date).Year
                    $licenseText = switch ($License) {
                        'MIT' { @"
MIT License

Copyright (c) $licenseYear $(whoami)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@ }
                        # Add other license templates as needed
                        default { "$License License - See https://choosealicense.com/licenses/ for details." }
                    }
                    
                    $licenseText | Out-File -FilePath "$Path\LICENSE" -Encoding utf8
                    Invoke-GitCommand -Arguments 'add', 'LICENSE' -WorkingDirectory $Path -SuppressOutput
                }
                
                # Initial commit
                if ($InitializeReadme -or $GitIgnore -or $License) {
                    Invoke-GitCommand -Arguments 'commit', '-m', $InitialCommitMessage -WorkingDirectory $Path -SuppressOutput
                    Write-Host "Git repository initialized with initial commit." -ForegroundColor Green
                }
                else {
                    Write-Host "Git repository initialized. No initial commit created." -ForegroundColor Yellow
                }
                
                return Get-Item -Path $Path
            }
            finally {
                Pop-Location
            }
        }
    }
    catch {
        Write-Error "Failed to initialize Git repository: $_"
        throw
    }
}

<#
.SYNOPSIS
    Gets the current Git repository status in a structured format.
.DESCRIPTION
    Returns detailed information about the current Git repository status including
    branch information, working directory status, and remote information.
#>
function Get-GitStatus {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param()
    
    try {
        $branch = Invoke-GitCommand -Arguments 'rev-parse', '--abbrev-ref', 'HEAD' -SuppressOutput -ThrowOnError
        $upstream = Invoke-GitCommand -Arguments 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}' -SuppressOutput -ErrorAction SilentlyContinue
        $status = Invoke-GitCommand -Arguments 'status', '--porcelain=2', '--branch' -SuppressOutput -ThrowOnError
        
        $result = [PSCustomObject]@{
            Branch = $branch
            Upstream = if ($upstream) { $upstream } else { $null }
            HasChanges = $false
            StagedChanges = @()
            UnstagedChanges = @()
            UntrackedFiles = @()
            Ahead = 0
            Behind = 0
        }
        
        foreach ($line in $status) {
            if ($line.StartsWith('# branch.oid')) {
                # Branch information
                $result.Branch = $branch
            }
            elseif ($line.StartsWith('# branch.ab')) {
                # Ahead/behind information
                $ab = $line -split '\s+'
                $result.Ahead = [int]($ab[2] -replace '\+', '')
                $result.Behind = [int]($ab[3] -replace '-', '')
            }
            elseif (-not $line.StartsWith('#')) {
                # File status
                $statusCode = $line.Substring(0, 2).Trim()
                $filePath = $line.Substring(3)
                
                switch -Wildcard ($statusCode) {
                    'A' { $result.StagedChanges += $filePath }  # Added
                    'M' { $result.StagedChanges += $filePath }  # Modified
                    'D' { $result.StagedChanges += $filePath }  # Deleted
                    'R' { $result.StagedChanges += $filePath }  # Renamed
                    'C' { $result.StagedChanges += $filePath }  # Copied
                    '??' { $result.UntrackedFiles += $filePath } # Untracked
                    default {
                        if ($statusCode -match '^.[MD]$') {
                            $result.UnstagedChanges += $filePath
                        }
                    }
                }
                
                if ($statusCode -ne '??') {
                    $result.HasChanges = $true
                }
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to get Git status: $_"
        throw
    }
}

<#
.SYNOPSIS
    Creates a new Git branch and checks it out.
.DESCRIPTION
    Creates a new branch from the current branch and checks it out.
#>
function New-GitBranch {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        
        [string]$BaseBranch,
        
        [switch]$Track,
        
        [switch]$Force
    )
    
    try {
        $args = @('checkout')
        if ($Force) { $args += '--force' }
        if ($BaseBranch) { $args += $BaseBranch }
        
        $args += '-b', $Name
        if ($Track) { $args += '--track' }
        
        if ($PSCmdlet.ShouldProcess($Name, "Create and checkout Git branch")) {
            Invoke-GitCommand -Arguments $args -ThrowOnError
            Write-Host "Switched to branch '$Name'" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to create branch: $_"
        throw
    }
}

<#
.SYNOPSIS
    Commits changes to the Git repository with a formatted message.
.DESCRIPTION
    Stages all changes and creates a commit with a formatted message.
#>
function Submit-GitCommit {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        
        [string[]]$Paths = @('.'),
        
        [switch]$Amend,
        
        [switch]$NoVerify,
        
        [switch]$All
    )
    
    try {
        # Stage changes
        $stageArgs = @('add')
        if ($All) {
            $stageArgs += '--all'
        }
        $stageArgs += $Paths
        
        Invoke-GitCommand -Arguments $stageArgs -ThrowOnError
        
        # Create commit
        $commitArgs = @('commit')
        if ($Amend) { $commitArgs += '--amend' }
        if ($NoVerify) { $commitArgs += '--no-verify' }
        $commitArgs += '-m', $Message
        
        if ($PSCmdlet.ShouldProcess($Message, "Create Git commit")) {
            Invoke-GitCommand -Arguments $commitArgs -ThrowOnError
            
            # Show commit summary
            $status = Get-GitStatus
            $ahead = if ($status.Ahead -gt 0) { " ($($status.Ahead) ahead)" } else { "" }
            Write-Host "[$(git rev-parse --short HEAD)] $Message" -ForegroundColor Green
            Write-Host "  $($status.Branch)$ahead" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Error "Failed to create commit: $_"
        throw
    }
}

# Export public functions
Export-ModuleMember -Function New-GitRepository, Get-GitStatus, New-GitBranch, Submit-GitCommit
