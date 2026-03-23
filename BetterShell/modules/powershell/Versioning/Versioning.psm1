<#
.SYNOPSIS
    Better11.Versioning - Version management for Better11 Suite

.DESCRIPTION
    Provides version management functionality including getting, setting, and incrementing
    version numbers. Integrates with project.json for version tracking.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

function Get-Better11Version {
    <#
    .SYNOPSIS
        Gets the current Better11 version from project.json
    
    .DESCRIPTION
        Retrieves the version number from the project.json configuration file.
    
    .PARAMETER ProjectJson
        Path to project.json file. Defaults to standard location.
    
    .EXAMPLE
        Get-Better11Version
    
    .EXAMPLE
        Get-Better11Version -ProjectJson "C:\Custom\project.json"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string]$ProjectJson = (Join-Path $PSScriptRoot '..\..\Config\project.json')
    )
    
    try {
        if (-not (Test-Path $ProjectJson)) {
            throw 'project.json not found'
        }
        
        $project = Get-Content $ProjectJson -Raw | ConvertFrom-Json
        return $project.version
    }
    catch {
        Write-Error "Failed to get Better11 version: $_"
        throw
    }
}

function Set-Better11Version {
    <#
    .SYNOPSIS
        Sets or increments the Better11 version
    
    .DESCRIPTION
        Updates the version in project.json. Can increment (patch, minor, major) or set a specific version.
    
    .PARAMETER Mode
        Version update mode: patch, minor, major, or set
    
    .PARAMETER Value
        Specific version to set (required when Mode is 'set')
    
    .PARAMETER ProjectJson
        Path to project.json file. Defaults to standard location.
    
    .EXAMPLE
        Set-Better11Version -Mode patch
    
    .EXAMPLE
        Set-Better11Version -Mode set -Value "1.2.3"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('patch', 'minor', 'major', 'set')]
        [string]$Mode,
        
        [Parameter()]
        [string]$Value,
        
        [Parameter()]
        [string]$ProjectJson = (Join-Path $PSScriptRoot '..\..\Config\project.json')
    )
    
    try {
        if (-not (Test-Path $ProjectJson)) {
            throw 'project.json not found'
        }
        
        $project = Get-Content $ProjectJson -Raw | ConvertFrom-Json
        $currentVersion = $project.version
        $parts = $currentVersion.Split('.')
        
        $newVersion = switch ($Mode) {
            'set' {
                if (-not $Value) {
                    throw "Value parameter is required when Mode is 'set'"
                }
                $Value
            }
            'patch' {
                '{0}.{1}.{2}' -f $parts[0], $parts[1], ([int]$parts[2] + 1)
            }
            'minor' {
                '{0}.{1}.0' -f $parts[0], ([int]$parts[1] + 1)
            }
            'major' {
                '{0}.0.0' -f ([int]$parts[0] + 1)
            }
        }
        
        $project.version = $newVersion
        $project | ConvertTo-Json -Depth 8 | Set-Content $ProjectJson
        
        Write-Verbose "Version updated from $currentVersion to $newVersion"
        return $newVersion
    }
    catch {
        Write-Error "Failed to set Better11 version: $_"
        throw
    }
}

function New-Better11Tag {
    <#
    .SYNOPSIS
        Creates a git tag for the current version
    
    .DESCRIPTION
        Creates a git tag with the specified version and optional message.
        Pushes the tag to the remote repository if git is available.
    
    .PARAMETER Version
        Version string for the tag. If not specified, uses current version from project.json.
    
    .PARAMETER Message
        Tag message. Defaults to "Better11 Suite {Version}"
    
    .EXAMPLE
        New-Better11Tag
    
    .EXAMPLE
        New-Better11Tag -Version "1.2.3" -Message "Release 1.2.3"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [string]$Version,
        
        [Parameter()]
        [string]$Message
    )
    
    try {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Warning "Git is not available. Cannot create tag."
            return $false
        }
        
        if (-not $Version) {
            $Version = Get-Better11Version
        }
        
        if (-not $Message) {
            $Message = "Better11 Suite $Version"
        }
        
        # Create annotated tag
        $tagResult = & git tag -a $Version -m $Message 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create git tag: $tagResult"
            return $false
        }
        
        # Push tag to remote
        $pushResult = & git push origin $Version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Tag created locally but failed to push to remote: $pushResult"
            return $true
        }
        
        Write-Verbose "Created and pushed git tag: $Version"
        return $true
    }
    catch {
        Write-Error "Failed to create git tag: $_"
        return $false
    }
}

Export-ModuleMember -Function Get-Better11Version, Set-Better11Version, New-Better11Tag
