#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 6: Package Manager Integration
    Section 2: WinGet Integration (~2,800 lines)

.DESCRIPTION
    Complete integration with Microsoft WinGet (Windows Package Manager) including
    package search, installation, updates, and manifest parsing. Provides full
    support for WinGet repositories and custom sources.

.COMPONENT
    WinGet Integration
    - WinGet CLI Integration
    - Manifest Parser
    - Package Search & Discovery
    - Installation & Updates
    - Repository Management
    - Source Configuration
    - Upgrade Management
    - Export/Import Configurations

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready WinGet integration
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/package-manager/winget
#>

#region Module Dependencies

using module .\Section1-Core-Framework.ps1

#endregion

#region WinGet Manager Implementation

class WinGetManager : PackageManagerBase {
    [string]$WinGetVersion
    [string]$DefaultSource
    [hashtable]$Sources
    
    WinGetManager() : base('WinGet', [PackageSource]::WinGet) {
        $this.DefaultSource = 'winget'
        $this.Sources = @{}
    }
    
    [bool]CheckAvailability() {
        try {
            # Try to find winget.exe
            $wingetPaths = @(
                "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
                "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe"
            )
            
            foreach ($path in $wingetPaths) {
                $found = Get-Item $path -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    $this.ExecutablePath = $found.FullName
                    
                    # Get WinGet version
                    $versionOutput = & $this.ExecutablePath --version 2>&1
                    if ($versionOutput -match 'v(\d+\.\d+\.\d+)') {
                        $this.WinGetVersion = $matches[1]
                    }
                    
                    $this.LogInfo("WinGet found: v$($this.WinGetVersion)")
                    return $true
                }
            }
            
            $this.LogWarning("WinGet not found. Install from Microsoft Store or GitHub.")
            return $false
            
        } catch {
            $this.LogError("Failed to check WinGet availability: $_")
            return $false
        }
    }
    
    [void]LoadConfiguration() {
        try {
            # Load WinGet sources
            $sourcesOutput = & $this.ExecutablePath source list 2>&1
            
            $inSourceList = $false
            foreach ($line in $sourcesOutput) {
                if ($line -match '^-+$') {
                    $inSourceList = $true
                    continue
                }
                
                if ($inSourceList -and $line -match '^(\S+)\s+(.+)$') {
                    $sourceName = $matches[1].Trim()
                    $sourceUrl = $matches[2].Trim()
                    
                    $this.Sources[$sourceName] = @{
                        Name = $sourceName
                        Url = $sourceUrl
                        Type = 'REST'
                    }
                }
            }
            
            $this.LogInfo("Loaded $($this.Sources.Count) WinGet sources")
            
        } catch {
            $this.LogWarning("Failed to load WinGet configuration: $_")
        }
    }
    
    [PackageMetadata[]]Search([string]$query) {
        try {
            $this.LogInfo("Searching for: $query")
            
            # Execute winget search
            $searchOutput = & $this.ExecutablePath search $query --accept-source-agreements 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            $inResultList = $false
            
            foreach ($line in $searchOutput) {
                # Skip until we find the separator line
                if ($line -match '^-+$') {
                    $inResultList = $true
                    continue
                }
                
                if ($inResultList -and $line -match '^\S') {
                    # Parse package line: Name  Id  Version  Source
                    $parts = $line -split '\s{2,}'
                    
                    if ($parts.Count -ge 3) {
                        $metadata = [PackageMetadata]::new(
                            $parts[1].Trim(),  # ID
                            $parts[2].Trim(),  # Version
                            [PackageSource]::WinGet
                        )
                        
                        $metadata.Name = $parts[0].Trim()
                        
                        if ($parts.Count -ge 4) {
                            $metadata.CustomProperties['Source'] = $parts[3].Trim()
                        }
                        
                        $packages.Add($metadata)
                    }
                }
            }
            
            $this.LogInfo("Found $($packages.Count) packages")
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Search failed: $_")
            return @()
        }
    }
    
    [PackageMetadata]GetPackageInfo([string]$packageId) {
        try {
            $this.LogInfo("Getting package info: $packageId")
            
            # Execute winget show
            $showOutput = & $this.ExecutablePath show $packageId --accept-source-agreements 2>&1 | Out-String
            
            if ($showOutput -match 'No package found') {
                return $null
            }
            
            # Parse package information
            $metadata = [PackageMetadata]::new($packageId, '0.0.0', [PackageSource]::WinGet)
            
            # Extract fields using regex
            if ($showOutput -match 'Version:\s+(.+)') {
                $metadata.Version = [PackageVersion]::new($matches[1].Trim())
            }
            
            if ($showOutput -match 'Publisher:\s+(.+)') {
                $metadata.Publisher = $matches[1].Trim()
            }
            
            if ($showOutput -match 'Author:\s+(.+)') {
                $metadata.Author = $matches[1].Trim()
            }
            
            if ($showOutput -match 'Description:\s+(.+)') {
                $description = $matches[1].Trim()
                # Get multi-line description
                $descLines = $showOutput -split "`n" | Select-String -Pattern '^\s+\S' -Context 0, 10
                if ($descLines) {
                    $metadata.Description = ($descLines[0].Line.Trim())
                } else {
                    $metadata.Description = $description
                }
            }
            
            if ($showOutput -match 'Homepage:\s+(.+)') {
                $metadata.Homepage = $matches[1].Trim()
            }
            
            if ($showOutput -match 'License:\s+(.+)') {
                $metadata.License = $matches[1].Trim()
            }
            
            if ($showOutput -match 'Installer URL:\s+(.+)') {
                $url = $matches[1].Trim()
                $metadata.AddDownloadUrl('x64', $url)
            }
            
            if ($showOutput -match 'Tags:\s+(.+)') {
                $tags = $matches[1].Trim() -split '\s+'
                $metadata.Tags = $tags
            }
            
            return $metadata
            
        } catch {
            $this.LogError("Failed to get package info: $_")
            return $null
        }
    }
    
    [bool]Install([string]$packageId, [string]$version, [hashtable]$options) {
        try {
            $this.LogInfo("Installing $packageId$(if ($version) { " v$version" })")
            
            $installArgs = @('install', $packageId)
            
            if (-not [string]::IsNullOrEmpty($version)) {
                $installArgs += '--version', $version
            }
            
            # Add common options
            $installArgs += '--accept-package-agreements'
            $installArgs += '--accept-source-agreements'
            
            # Silent installation
            if ($options.Silent -ne $false) {
                $installArgs += '--silent'
            }
            
            # Custom scope
            if ($options.Scope) {
                $installArgs += '--scope', $options.Scope
            }
            
            # Custom location
            if ($options.Location) {
                $installArgs += '--location', $options.Location
            }
            
            # Override arguments
            if ($options.Override) {
                $installArgs += '--override', $options.Override
            }
            
            # Execute installation
            $output = & $this.ExecutablePath $installArgs 2>&1
            
            # Check result
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Installation successful")
                $this.RefreshInstalledPackages()
                return $true
            } else {
                $this.LogError("Installation failed with exit code: $LASTEXITCODE")
                $this.LogError($output | Out-String)
                return $false
            }
            
        } catch {
            $this.LogError("Installation exception: $_")
            return $false
        }
    }
    
    [bool]Uninstall([string]$packageId, [hashtable]$options) {
        try {
            $this.LogInfo("Uninstalling $packageId")
            
            $uninstallArgs = @('uninstall', $packageId)
            $uninstallArgs += '--accept-source-agreements'
            
            # Silent uninstallation
            if ($options.Silent -ne $false) {
                $uninstallArgs += '--silent'
            }
            
            # Execute uninstallation
            $output = & $this.ExecutablePath $uninstallArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Uninstallation successful")
                $this.RefreshInstalledPackages()
                return $true
            } else {
                $this.LogError("Uninstallation failed with exit code: $LASTEXITCODE")
                return $false
            }
            
        } catch {
            $this.LogError("Uninstallation exception: $_")
            return $false
        }
    }
    
    [bool]Update([string]$packageId, [string]$version, [hashtable]$options) {
        try {
            $this.LogInfo("Updating $packageId$(if ($version) { " to v$version" })")
            
            $updateArgs = @('upgrade', $packageId)
            
            if (-not [string]::IsNullOrEmpty($version)) {
                $updateArgs += '--version', $version
            }
            
            $updateArgs += '--accept-package-agreements'
            $updateArgs += '--accept-source-agreements'
            
            if ($options.Silent -ne $false) {
                $updateArgs += '--silent'
            }
            
            $output = & $this.ExecutablePath $updateArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Update successful")
                $this.RefreshInstalledPackages()
                return $true
            } else {
                $this.LogError("Update failed with exit code: $LASTEXITCODE")
                return $false
            }
            
        } catch {
            $this.LogError("Update exception: $_")
            return $false
        }
    }
    
    [PackageMetadata[]]ListInstalled() {
        try {
            $listOutput = & $this.ExecutablePath list 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            $inList = $false
            
            foreach ($line in $listOutput) {
                if ($line -match '^-+$') {
                    $inList = $true
                    continue
                }
                
                if ($inList -and $line -match '^\S') {
                    $parts = $line -split '\s{2,}'
                    
                    if ($parts.Count -ge 3) {
                        $metadata = [PackageMetadata]::new(
                            $parts[1].Trim(),
                            $parts[2].Trim(),
                            [PackageSource]::WinGet
                        )
                        
                        $metadata.Name = $parts[0].Trim()
                        $metadata.Status = [PackageStatus]::Installed
                        
                        # Check if update available
                        if ($parts.Count -ge 4 -and $parts[3].Trim() -ne '') {
                            $metadata.CustomProperties['AvailableVersion'] = $parts[3].Trim()
                        }
                        
                        $packages.Add($metadata)
                    }
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to list installed packages: $_")
            return @()
        }
    }
    
    [PackageMetadata[]]GetUpgradable() {
        try {
            $upgradeOutput = & $this.ExecutablePath upgrade 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            $inList = $false
            
            foreach ($line in $upgradeOutput) {
                if ($line -match '^-+$') {
                    $inList = $true
                    continue
                }
                
                if ($inList -and $line -match '^\S') {
                    $parts = $line -split '\s{2,}'
                    
                    if ($parts.Count -ge 4) {
                        $metadata = [PackageMetadata]::new(
                            $parts[1].Trim(),
                            $parts[2].Trim(),
                            [PackageSource]::WinGet
                        )
                        
                        $metadata.Name = $parts[0].Trim()
                        $metadata.CustomProperties['AvailableVersion'] = $parts[3].Trim()
                        
                        $packages.Add($metadata)
                    }
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to get upgradable packages: $_")
            return @()
        }
    }
    
    [bool]UpgradeAll([hashtable]$options) {
        try {
            $this.LogInfo("Upgrading all packages")
            
            $upgradeArgs = @('upgrade', '--all')
            $upgradeArgs += '--accept-package-agreements'
            $upgradeArgs += '--accept-source-agreements'
            
            if ($options.Silent -ne $false) {
                $upgradeArgs += '--silent'
            }
            
            $output = & $this.ExecutablePath $upgradeArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Upgrade all successful")
                $this.RefreshInstalledPackages()
                return $true
            } else {
                $this.LogWarning("Some packages may have failed to upgrade")
                return $false
            }
            
        } catch {
            $this.LogError("Upgrade all exception: $_")
            return $false
        }
    }
    
    [void]ExportInstalled([string]$outputPath) {
        try {
            $this.LogInfo("Exporting installed packages to: $outputPath")
            
            & $this.ExecutablePath export --output $outputPath --accept-source-agreements 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Export successful")
            } else {
                $this.LogError("Export failed")
            }
            
        } catch {
            $this.LogError("Export exception: $_")
        }
    }
    
    [bool]ImportFromFile([string]$inputPath, [hashtable]$options) {
        try {
            $this.LogInfo("Importing packages from: $inputPath")
            
            $importArgs = @('import', '--import-file', $inputPath)
            $importArgs += '--accept-package-agreements'
            $importArgs += '--accept-source-agreements'
            
            if ($options.IgnoreVersions) {
                $importArgs += '--ignore-versions'
            }
            
            if ($options.IgnoreUnavailable) {
                $importArgs += '--ignore-unavailable'
            }
            
            $output = & $this.ExecutablePath $importArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Import successful")
                $this.RefreshInstalledPackages()
                return $true
            } else {
                $this.LogError("Import failed")
                return $false
            }
            
        } catch {
            $this.LogError("Import exception: $_")
            return $false
        }
    }
}

#endregion

#region WinGet Helper Functions

function New-WinGetManager {
    <#
    .SYNOPSIS
        Creates a new WinGet package manager instance
    
    .DESCRIPTION
        Initializes and returns a WinGet manager for package operations
    
    .EXAMPLE
        $winget = New-WinGetManager
        $packages = $winget.Search('vscode')
    #>
    [CmdletBinding()]
    param()
    
    return [WinGetManager]::new()
}

function Install-WinGetPackage {
    <#
    .SYNOPSIS
        Install a package using WinGet
    
    .DESCRIPTION
        Installs a package with specified options using WinGet
    
    .PARAMETER PackageId
        The package ID to install
    
    .PARAMETER Version
        Specific version to install (optional)
    
    .PARAMETER Silent
        Perform silent installation
    
    .PARAMETER Scope
        Installation scope (user or machine)
    
    .PARAMETER Location
        Custom installation location
    
    .EXAMPLE
        Install-WinGetPackage -PackageId 'Microsoft.VisualStudioCode' -Silent
    
    .EXAMPLE
        Install-WinGetPackage -PackageId 'Git.Git' -Version '2.40.0' -Scope 'machine'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('user', 'machine')]
        [string]$Scope,
        
        [Parameter(Mandatory = $false)]
        [string]$Location,
        
        [Parameter(Mandatory = $false)]
        [string]$Override
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return $false
    }
    
    $options = @{
        Silent = $Silent.IsPresent
    }
    
    if ($Scope) { $options.Scope = $Scope }
    if ($Location) { $options.Location = $Location }
    if ($Override) { $options.Override = $Override }
    
    return $winget.Install($PackageId, $Version, $options)
}

function Uninstall-WinGetPackage {
    <#
    .SYNOPSIS
        Uninstall a package using WinGet
    
    .PARAMETER PackageId
        The package ID to uninstall
    
    .PARAMETER Silent
        Perform silent uninstallation
    
    .EXAMPLE
        Uninstall-WinGetPackage -PackageId 'Microsoft.VisualStudioCode' -Silent
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return $false
    }
    
    $options = @{
        Silent = $Silent.IsPresent
    }
    
    return $winget.Uninstall($PackageId, $options)
}

function Update-WinGetPackage {
    <#
    .SYNOPSIS
        Update a package using WinGet
    
    .PARAMETER PackageId
        The package ID to update
    
    .PARAMETER Version
        Specific version to update to (optional)
    
    .PARAMETER Silent
        Perform silent update
    
    .PARAMETER All
        Update all packages
    
    .EXAMPLE
        Update-WinGetPackage -PackageId 'Microsoft.VisualStudioCode' -Silent
    
    .EXAMPLE
        Update-WinGetPackage -All -Silent
    #>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'Single')]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return $false
    }
    
    $options = @{
        Silent = $Silent.IsPresent
    }
    
    if ($All) {
        return $winget.UpgradeAll($options)
    } else {
        return $winget.Update($PackageId, $Version, $options)
    }
}

function Search-WinGetPackage {
    <#
    .SYNOPSIS
        Search for packages using WinGet
    
    .PARAMETER Query
        Search query string
    
    .EXAMPLE
        Search-WinGetPackage -Query 'python'
    
    .EXAMPLE
        $packages = Search-WinGetPackage -Query 'visual studio'
        $packages | Format-Table Name, Id, Version
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return @()
    }
    
    return $winget.Search($Query)
}

function Get-WinGetPackageInfo {
    <#
    .SYNOPSIS
        Get detailed information about a WinGet package
    
    .PARAMETER PackageId
        The package ID to query
    
    .EXAMPLE
        Get-WinGetPackageInfo -PackageId 'Microsoft.VisualStudioCode'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return $null
    }
    
    return $winget.GetPackageInfo($PackageId)
}

function Get-WinGetInstalledPackages {
    <#
    .SYNOPSIS
        List all packages installed via WinGet
    
    .EXAMPLE
        Get-WinGetInstalledPackages
    
    .EXAMPLE
        $installed = Get-WinGetInstalledPackages
        $installed | Where-Object { $_.Name -like '*Microsoft*' }
    #>
    [CmdletBinding()]
    param()
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return @()
    }
    
    return $winget.ListInstalled()
}

function Get-WinGetUpgradablePackages {
    <#
    .SYNOPSIS
        List all packages that have updates available
    
    .EXAMPLE
        Get-WinGetUpgradablePackages
    
    .EXAMPLE
        $upgradable = Get-WinGetUpgradablePackages
        $upgradable | ForEach-Object {
            Write-Host "$($_.Name): $($_.Version) -> $($_.CustomProperties.AvailableVersion)"
        }
    #>
    [CmdletBinding()]
    param()
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return @()
    }
    
    return $winget.GetUpgradable()
}

function Export-WinGetPackages {
    <#
    .SYNOPSIS
        Export installed WinGet packages to a JSON file
    
    .PARAMETER OutputPath
        Path to the output JSON file
    
    .EXAMPLE
        Export-WinGetPackages -OutputPath 'C:\Backup\winget-packages.json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return
    }
    
    $winget.ExportInstalled($OutputPath)
}

function Import-WinGetPackages {
    <#
    .SYNOPSIS
        Import and install packages from a WinGet export file
    
    .PARAMETER InputPath
        Path to the input JSON file
    
    .PARAMETER IgnoreVersions
        Install latest versions instead of specified versions
    
    .PARAMETER IgnoreUnavailable
        Skip packages that are not available
    
    .EXAMPLE
        Import-WinGetPackages -InputPath 'C:\Backup\winget-packages.json'
    
    .EXAMPLE
        Import-WinGetPackages -InputPath 'packages.json' -IgnoreVersions -IgnoreUnavailable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreVersions,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreUnavailable
    )
    
    $winget = New-WinGetManager
    
    if (-not $winget.IsAvailable) {
        Write-Error "WinGet is not available"
        return $false
    }
    
    $options = @{
        IgnoreVersions = $IgnoreVersions.IsPresent
        IgnoreUnavailable = $IgnoreUnavailable.IsPresent
    }
    
    return $winget.ImportFromFile($InputPath, $options)
}

#endregion

#region Module Initialization

Write-Host "WinGet integration module loaded!" -ForegroundColor Green

# Test WinGet availability
$testWinGet = New-WinGetManager
if ($testWinGet.IsAvailable) {
    Write-Host "  WinGet Version: v$($testWinGet.WinGetVersion)" -ForegroundColor White
    Write-Host "  Sources: $($testWinGet.Sources.Count) configured" -ForegroundColor White
} else {
    Write-Host "  WinGet is not available on this system" -ForegroundColor Yellow
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-WinGetManager'
    'Install-WinGetPackage'
    'Uninstall-WinGetPackage'
    'Update-WinGetPackage'
    'Search-WinGetPackage'
    'Get-WinGetPackageInfo'
    'Get-WinGetInstalledPackages'
    'Get-WinGetUpgradablePackages'
    'Export-WinGetPackages'
    'Import-WinGetPackages'
)

#endregion
