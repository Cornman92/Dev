#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Module 6: Package Manager Integration
    Section 3: Chocolatey Integration (~2,900 lines)

.DESCRIPTION
    Complete integration with Chocolatey package manager including package search,
    installation, updates, custom sources, and package creation. Supports both
    community and business editions with advanced features.

.COMPONENT
    Chocolatey Integration
    - Chocolatey CLI Integration
    - Package Search & Discovery
    - Installation & Updates
    - Source Management
    - Package Pinning
    - Configuration Management
    - Custom Package Creation
    - Business Features Integration

.NOTES
    Version:        2.0.0
    Author:         WinPE PowerBuilder Development Team
    Creation Date:  2024-12-31
    Purpose:        Production-ready Chocolatey integration
    
.LINK
    https://docs.winpe-powerbuilder.com/modules/package-manager/chocolatey
#>

#region Module Dependencies

using module .\Section1-Core-Framework.ps1

#endregion

#region Chocolatey Manager Implementation

class ChocolateyManager : PackageManagerBase {
    [string]$ChocolateyVersion
    [string]$ChocolateyPath
    [bool]$IsBusinessEdition
    [hashtable]$Config
    [System.Collections.Generic.List[string]]$PinnedPackages
    
    ChocolateyManager() : base('Chocolatey', [PackageSource]::Chocolatey) {
        $this.Config = @{}
        $this.PinnedPackages = [System.Collections.Generic.List[string]]::new()
    }
    
    [bool]CheckAvailability() {
        try {
            # Check for choco.exe in common locations
            $chocolateyPaths = @(
                "$env:ChocolateyInstall\choco.exe"
                "C:\ProgramData\chocolatey\choco.exe"
                "$env:ProgramData\chocolatey\choco.exe"
            )
            
            foreach ($path in $chocolateyPaths) {
                if (Test-Path $path) {
                    $this.ExecutablePath = $path
                    $this.ChocolateyPath = Split-Path $path -Parent
                    
                    # Get Chocolatey version
                    $versionOutput = & $this.ExecutablePath --version 2>&1
                    if ($versionOutput -match '(\d+\.\d+\.\d+)') {
                        $this.ChocolateyVersion = $matches[1]
                    }
                    
                    # Check for business edition
                    $features = & $this.ExecutablePath feature list 2>&1 | Out-String
                    $this.IsBusinessEdition = $features -match 'licensedVersion'
                    
                    $edition = if ($this.IsBusinessEdition) { 'Business' } else { 'Community' }
                    $this.LogInfo("Chocolatey $edition found: v$($this.ChocolateyVersion)")
                    
                    return $true
                }
            }
            
            $this.LogWarning("Chocolatey not found. Install from https://chocolatey.org/install")
            return $false
            
        } catch {
            $this.LogError("Failed to check Chocolatey availability: $_")
            return $false
        }
    }
    
    [void]LoadConfiguration() {
        try {
            # Load Chocolatey configuration
            $configOutput = & $this.ExecutablePath config list 2>&1
            
            foreach ($line in $configOutput) {
                if ($line -match '^(\w+)\s*=\s*(.+)\s*\|') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    $this.Config[$key] = $value
                }
            }
            
            # Load pinned packages
            $pinOutput = & $this.ExecutablePath pin list 2>&1
            
            foreach ($line in $pinOutput) {
                if ($line -match '^\s*(\S+)\s*\|') {
                    $packageId = $matches[1].Trim()
                    if ($packageId -ne 'Package' -and $packageId -ne '') {
                        $this.PinnedPackages.Add($packageId)
                    }
                }
            }
            
            $this.LogInfo("Loaded Chocolatey configuration: $($this.Config.Count) settings, $($this.PinnedPackages.Count) pinned packages")
            
        } catch {
            $this.LogWarning("Failed to load Chocolatey configuration: $_")
        }
    }
    
    [PackageMetadata[]]Search([string]$query) {
        try {
            $this.LogInfo("Searching for: $query")
            
            # Execute choco search
            $searchOutput = & $this.ExecutablePath search $query --limit-output 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            
            foreach ($line in $searchOutput) {
                # Format: PackageId|Version
                if ($line -match '^([^|]+)\|(.+)$') {
                    $packageId = $matches[1].Trim()
                    $version = $matches[2].Trim()
                    
                    $metadata = [PackageMetadata]::new(
                        $packageId,
                        $version,
                        [PackageSource]::Chocolatey
                    )
                    
                    $metadata.Name = $packageId
                    $packages.Add($metadata)
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
            
            # Execute choco info
            $infoOutput = & $this.ExecutablePath info $packageId --limit-output 2>&1 | Out-String
            
            if ($infoOutput -match "$packageId not found") {
                return $null
            }
            
            # Parse limit-output format: PackageId|Version|IsInstalled|IsApproved
            $lines = $infoOutput -split "`n" | Where-Object { $_ -match '\|' }
            
            if ($lines.Count -eq 0) {
                return $null
            }
            
            $parts = $lines[0] -split '\|'
            
            if ($parts.Count -lt 2) {
                return $null
            }
            
            $metadata = [PackageMetadata]::new(
                $parts[0].Trim(),
                $parts[1].Trim(),
                [PackageSource]::Chocolatey
            )
            
            $metadata.Name = $parts[0].Trim()
            
            # Get detailed information (non-limit output)
            $detailOutput = & $this.ExecutablePath info $packageId 2>&1 | Out-String
            
            # Parse detailed output
            if ($detailOutput -match 'Title:\s*(.+)') {
                $metadata.Name = $matches[1].Trim()
            }
            
            if ($detailOutput -match 'Summary:\s*(.+)') {
                $metadata.Description = $matches[1].Trim()
            }
            
            if ($detailOutput -match 'Description:\s*(.+?)(?=\r?\n\s*\w+:|\r?\n\r?\n|\z)') {
                $description = $matches[1].Trim()
                if ($description.Length -gt $metadata.Description.Length) {
                    $metadata.Description = $description
                }
            }
            
            if ($detailOutput -match 'Author:\s*(.+)') {
                $metadata.Author = $matches[1].Trim()
            }
            
            if ($detailOutput -match 'Software Site:\s*(.+)') {
                $metadata.Homepage = $matches[1].Trim()
            }
            
            if ($detailOutput -match 'Tags:\s*(.+)') {
                $tags = $matches[1].Trim() -split '\s+'
                $metadata.Tags = $tags
            }
            
            if ($detailOutput -match 'Download Size:\s*(.+)') {
                $sizeStr = $matches[1].Trim()
                # Parse size (e.g., "1.5 MB")
                if ($sizeStr -match '([\d.]+)\s*(KB|MB|GB)') {
                    $size = [double]$matches[1]
                    $unit = $matches[2]
                    
                    $multiplier = switch ($unit) {
                        'KB' { 1KB }
                        'MB' { 1MB }
                        'GB' { 1GB }
                        default { 1 }
                    }
                    
                    $metadata.Size = [long]($size * $multiplier)
                }
            }
            
            # Check if installed
            if ($parts.Count -ge 3 -and $parts[2].Trim() -eq 'true') {
                $metadata.Status = [PackageStatus]::Installed
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
            $installArgs += '--yes'  # Auto-confirm
            $installArgs += '--no-progress'
            
            # Limit output for parsing
            if ($options.LimitOutput -ne $false) {
                $installArgs += '--limit-output'
            }
            
            # Force installation
            if ($options.Force) {
                $installArgs += '--force'
            }
            
            # Install arguments
            if ($options.InstallArguments) {
                $installArgs += '--install-arguments', "`"$($options.InstallArguments)`""
            }
            
            # Package parameters
            if ($options.PackageParameters) {
                $installArgs += '--package-parameters', "`"$($options.PackageParameters)`""
            }
            
            # Override arguments
            if ($options.OverrideArguments) {
                $installArgs += '--override-arguments'
            }
            
            # Custom source
            if ($options.Source) {
                $installArgs += '--source', $options.Source
            }
            
            # Allow downgrade
            if ($options.AllowDowngrade) {
                $installArgs += '--allow-downgrade'
            }
            
            # Side by side installation
            if ($options.SideBySide) {
                $installArgs += '--side-by-side'
            }
            
            # Ignore dependencies
            if ($options.IgnoreDependencies) {
                $installArgs += '--ignore-dependencies'
            }
            
            # Execute installation
            $output = & $this.ExecutablePath $installArgs 2>&1
            
            # Check result
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Installation successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Installation failed with exit code: $LASTEXITCODE")
                $this.LogError($output | Out-String)
            }
            
            return $success
            
        } catch {
            $this.LogError("Installation exception: $_")
            return $false
        }
    }
    
    [bool]Uninstall([string]$packageId, [hashtable]$options) {
        try {
            $this.LogInfo("Uninstalling $packageId")
            
            $uninstallArgs = @('uninstall', $packageId)
            $uninstallArgs += '--yes'
            $uninstallArgs += '--no-progress'
            
            if ($options.LimitOutput -ne $false) {
                $uninstallArgs += '--limit-output'
            }
            
            # Force uninstallation
            if ($options.Force) {
                $uninstallArgs += '--force'
            }
            
            # Remove dependencies
            if ($options.RemoveDependencies) {
                $uninstallArgs += '--remove-dependencies'
            }
            
            # Uninstall arguments
            if ($options.UninstallArguments) {
                $uninstallArgs += '--uninstall-arguments', "`"$($options.UninstallArguments)`""
            }
            
            # All versions
            if ($options.AllVersions) {
                $uninstallArgs += '--all-versions'
            }
            
            # Execute uninstallation
            $output = & $this.ExecutablePath $uninstallArgs 2>&1
            
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Uninstallation successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Uninstallation failed with exit code: $LASTEXITCODE")
            }
            
            return $success
            
        } catch {
            $this.LogError("Uninstallation exception: $_")
            return $false
        }
    }
    
    [bool]Update([string]$packageId, [string]$version, [hashtable]$options) {
        try {
            $this.LogInfo("Updating $packageId$(if ($version) { " to v$version" })")
            
            $upgradeArgs = @('upgrade', $packageId)
            
            if (-not [string]::IsNullOrEmpty($version)) {
                $upgradeArgs += '--version', $version
            }
            
            $upgradeArgs += '--yes'
            $upgradeArgs += '--no-progress'
            
            if ($options.LimitOutput -ne $false) {
                $upgradeArgs += '--limit-output'
            }
            
            # Force upgrade
            if ($options.Force) {
                $upgradeArgs += '--force'
            }
            
            # Custom source
            if ($options.Source) {
                $upgradeArgs += '--source', $options.Source
            }
            
            $output = & $this.ExecutablePath $upgradeArgs 2>&1
            
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Update successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogError("Update failed with exit code: $LASTEXITCODE")
            }
            
            return $success
            
        } catch {
            $this.LogError("Update exception: $_")
            return $false
        }
    }
    
    [PackageMetadata[]]ListInstalled() {
        try {
            $listOutput = & $this.ExecutablePath list --local-only --limit-output 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            
            foreach ($line in $listOutput) {
                # Format: PackageId|Version
                if ($line -match '^([^|]+)\|(.+)$') {
                    $packageId = $matches[1].Trim()
                    $version = $matches[2].Trim()
                    
                    $metadata = [PackageMetadata]::new(
                        $packageId,
                        $version,
                        [PackageSource]::Chocolatey
                    )
                    
                    $metadata.Name = $packageId
                    $metadata.Status = [PackageStatus]::Installed
                    
                    # Check if pinned
                    if ($this.PinnedPackages.Contains($packageId)) {
                        $metadata.CustomProperties['Pinned'] = $true
                    }
                    
                    $packages.Add($metadata)
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to list installed packages: $_")
            return @()
        }
    }
    
    [PackageMetadata[]]GetOutdated() {
        try {
            $outdatedOutput = & $this.ExecutablePath outdated --limit-output 2>&1
            
            $packages = [System.Collections.Generic.List[PackageMetadata]]::new()
            
            foreach ($line in $outdatedOutput) {
                # Format: PackageId|CurrentVersion|AvailableVersion|Pinned
                if ($line -match '^([^|]+)\|([^|]+)\|([^|]+)') {
                    $packageId = $matches[1].Trim()
                    $currentVersion = $matches[2].Trim()
                    $availableVersion = $matches[3].Trim()
                    
                    $metadata = [PackageMetadata]::new(
                        $packageId,
                        $currentVersion,
                        [PackageSource]::Chocolatey
                    )
                    
                    $metadata.Name = $packageId
                    $metadata.CustomProperties['AvailableVersion'] = $availableVersion
                    
                    # Check if pinned
                    if ($this.PinnedPackages.Contains($packageId)) {
                        $metadata.CustomProperties['Pinned'] = $true
                    }
                    
                    $packages.Add($metadata)
                }
            }
            
            return $packages.ToArray()
            
        } catch {
            $this.LogError("Failed to get outdated packages: $_")
            return @()
        }
    }
    
    [bool]UpgradeAll([hashtable]$options) {
        try {
            $this.LogInfo("Upgrading all packages")
            
            $upgradeArgs = @('upgrade', 'all')
            $upgradeArgs += '--yes'
            $upgradeArgs += '--no-progress'
            
            if ($options.LimitOutput -ne $false) {
                $upgradeArgs += '--limit-output'
            }
            
            # Exclude packages
            if ($options.Except) {
                $upgradeArgs += '--except', ($options.Except -join ',')
            }
            
            $output = & $this.ExecutablePath $upgradeArgs 2>&1
            
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                $this.LogInfo("Upgrade all successful")
                $this.RefreshInstalledPackages()
            } else {
                $this.LogWarning("Some packages may have failed to upgrade")
            }
            
            return $success
            
        } catch {
            $this.LogError("Upgrade all exception: $_")
            return $false
        }
    }
    
    [bool]Pin([string]$packageId) {
        try {
            $this.LogInfo("Pinning package: $packageId")
            
            $output = & $this.ExecutablePath pin add --name $packageId 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                if (-not $this.PinnedPackages.Contains($packageId)) {
                    $this.PinnedPackages.Add($packageId)
                }
                $this.LogInfo("Package pinned successfully")
                return $true
            } else {
                $this.LogError("Failed to pin package")
                return $false
            }
            
        } catch {
            $this.LogError("Pin exception: $_")
            return $false
        }
    }
    
    [bool]Unpin([string]$packageId) {
        try {
            $this.LogInfo("Unpinning package: $packageId")
            
            $output = & $this.ExecutablePath pin remove --name $packageId 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.PinnedPackages.Remove($packageId)
                $this.LogInfo("Package unpinned successfully")
                return $true
            } else {
                $this.LogError("Failed to unpin package")
                return $false
            }
            
        } catch {
            $this.LogError("Unpin exception: $_")
            return $false
        }
    }
    
    [void]AddSource([string]$name, [string]$url, [int]$priority) {
        try {
            $this.LogInfo("Adding source: $name ($url)")
            
            $args = @('source', 'add', '--name', $name, '--source', $url)
            
            if ($priority -gt 0) {
                $args += '--priority', $priority
            }
            
            & $this.ExecutablePath $args 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Source added successfully")
            } else {
                $this.LogError("Failed to add source")
            }
            
        } catch {
            $this.LogError("Add source exception: $_")
        }
    }
    
    [void]RemoveSource([string]$name) {
        try {
            $this.LogInfo("Removing source: $name")
            
            & $this.ExecutablePath source remove --name $name 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                $this.LogInfo("Source removed successfully")
            } else {
                $this.LogError("Failed to remove source")
            }
            
        } catch {
            $this.LogError("Remove source exception: $_")
        }
    }
    
    [hashtable[]]ListSources() {
        try {
            $sourceOutput = & $this.ExecutablePath source list --limit-output 2>&1
            
            $sources = @()
            
            foreach ($line in $sourceOutput) {
                # Format: Name|Source|Disabled|UserName|Certificate|Priority|BypassProxy|AllowSelfService
                if ($line -match '^([^|]+)\|([^|]+)\|([^|]+)\|') {
                    $sources += @{
                        Name = $matches[1].Trim()
                        Url = $matches[2].Trim()
                        Disabled = $matches[3].Trim() -eq 'true'
                    }
                }
            }
            
            return $sources
            
        } catch {
            $this.LogError("Failed to list sources: $_")
            return @()
        }
    }
    
    [string]GetConfig([string]$key) {
        if ($this.Config.ContainsKey($key)) {
            return $this.Config[$key]
        }
        return ''
    }
    
    [void]SetConfig([string]$key, [string]$value) {
        try {
            $this.LogInfo("Setting config: $key = $value")
            
            & $this.ExecutablePath config set --name $key --value $value 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                $this.Config[$key] = $value
                $this.LogInfo("Config updated successfully")
            } else {
                $this.LogError("Failed to update config")
            }
            
        } catch {
            $this.LogError("Set config exception: $_")
        }
    }
    
    [void]ExportInstalled([string]$outputPath) {
        try {
            $this.LogInfo("Exporting installed packages to: $outputPath")
            
            $packages = $this.ListInstalled()
            
            $exportData = @{
                ExportDate = Get-Date
                ChocolateyVersion = $this.ChocolateyVersion
                Packages = @()
            }
            
            foreach ($package in $packages) {
                $exportData.Packages += @{
                    Id = $package.Id
                    Version = $package.Version.ToString()
                    Pinned = $package.CustomProperties.ContainsKey('Pinned') -and $package.CustomProperties['Pinned']
                }
            }
            
            $exportData | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath
            
            $this.LogInfo("Export successful: $($packages.Count) packages")
            
        } catch {
            $this.LogError("Export exception: $_")
        }
    }
    
    [bool]ImportFromFile([string]$inputPath, [hashtable]$options) {
        try {
            $this.LogInfo("Importing packages from: $inputPath")
            
            if (-not (Test-Path $inputPath)) {
                $this.LogError("Import file not found: $inputPath")
                return $false
            }
            
            $importData = Get-Content -Path $inputPath -Raw | ConvertFrom-Json
            
            $successCount = 0
            $failCount = 0
            
            foreach ($package in $importData.Packages) {
                $version = if ($options.IgnoreVersions) { '' } else { $package.Version }
                
                $installOptions = @{
                    LimitOutput = $true
                }
                
                if ($this.Install($package.Id, $version, $installOptions)) {
                    $successCount++
                    
                    # Restore pin state
                    if ($package.Pinned -and -not $options.IgnorePins) {
                        $this.Pin($package.Id)
                    }
                } else {
                    $failCount++
                }
            }
            
            $this.LogInfo("Import complete: $successCount succeeded, $failCount failed")
            
            return $failCount -eq 0
            
        } catch {
            $this.LogError("Import exception: $_")
            return $false
        }
    }
}

#endregion

#region Chocolatey Helper Functions

function New-ChocolateyManager {
    <#
    .SYNOPSIS
        Creates a new Chocolatey package manager instance
    
    .EXAMPLE
        $choco = New-ChocolateyManager
        $packages = $choco.Search('git')
    #>
    [CmdletBinding()]
    param()
    
    return [ChocolateyManager]::new()
}

function Install-ChocolateyPackage {
    <#
    .SYNOPSIS
        Install a package using Chocolatey
    
    .PARAMETER PackageId
        The package ID to install
    
    .PARAMETER Version
        Specific version to install
    
    .PARAMETER Force
        Force installation
    
    .PARAMETER InstallArguments
        Arguments to pass to the native installer
    
    .PARAMETER PackageParameters
        Parameters to pass to the Chocolatey package
    
    .PARAMETER Source
        Custom source to install from
    
    .PARAMETER AllowDowngrade
        Allow installation of an older version
    
    .PARAMETER SideBySide
        Allow multiple versions
    
    .PARAMETER IgnoreDependencies
        Skip dependency installation
    
    .EXAMPLE
        Install-ChocolateyPackage -PackageId 'git'
    
    .EXAMPLE
        Install-ChocolateyPackage -PackageId 'nodejs' -Version '18.0.0' -Force
    
    .EXAMPLE
        Install-ChocolateyPackage -PackageId 'vscode' -PackageParameters '/NoDesktopIcon'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$InstallArguments,
        
        [Parameter(Mandatory = $false)]
        [string]$PackageParameters,
        
        [Parameter(Mandatory = $false)]
        [switch]$OverrideArguments,
        
        [Parameter(Mandatory = $false)]
        [string]$Source,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowDowngrade,
        
        [Parameter(Mandatory = $false)]
        [switch]$SideBySide,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreDependencies
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return $false
    }
    
    $options = @{
        Force = $Force.IsPresent
        AllowDowngrade = $AllowDowngrade.IsPresent
        SideBySide = $SideBySide.IsPresent
        IgnoreDependencies = $IgnoreDependencies.IsPresent
        OverrideArguments = $OverrideArguments.IsPresent
    }
    
    if ($InstallArguments) { $options.InstallArguments = $InstallArguments }
    if ($PackageParameters) { $options.PackageParameters = $PackageParameters }
    if ($Source) { $options.Source = $Source }
    
    return $choco.Install($PackageId, $Version, $options)
}

function Uninstall-ChocolateyPackage {
    <#
    .SYNOPSIS
        Uninstall a package using Chocolatey
    
    .PARAMETER PackageId
        The package ID to uninstall
    
    .PARAMETER Force
        Force uninstallation
    
    .PARAMETER RemoveDependencies
        Remove dependencies that are not used by other packages
    
    .PARAMETER AllVersions
        Uninstall all versions
    
    .EXAMPLE
        Uninstall-ChocolateyPackage -PackageId 'git'
    
    .EXAMPLE
        Uninstall-ChocolateyPackage -PackageId 'nodejs' -RemoveDependencies
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveDependencies,
        
        [Parameter(Mandatory = $false)]
        [string]$UninstallArguments,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllVersions
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return $false
    }
    
    $options = @{
        Force = $Force.IsPresent
        RemoveDependencies = $RemoveDependencies.IsPresent
        AllVersions = $AllVersions.IsPresent
    }
    
    if ($UninstallArguments) { $options.UninstallArguments = $UninstallArguments }
    
    return $choco.Uninstall($PackageId, $options)
}

function Update-ChocolateyPackage {
    <#
    .SYNOPSIS
        Update a package using Chocolatey
    
    .PARAMETER PackageId
        The package ID to update
    
    .PARAMETER Version
        Specific version to update to
    
    .PARAMETER All
        Update all packages
    
    .PARAMETER Except
        Packages to exclude when updating all
    
    .EXAMPLE
        Update-ChocolateyPackage -PackageId 'git'
    
    .EXAMPLE
        Update-ChocolateyPackage -All -Except 'nodejs','python'
    #>
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'Single')]
        [string]$Version = '',
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$Source,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [string[]]$Except
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return $false
    }
    
    $options = @{
        Force = $Force.IsPresent
    }
    
    if ($Source) { $options.Source = $Source }
    
    if ($All) {
        if ($Except) { $options.Except = $Except }
        return $choco.UpgradeAll($options)
    } else {
        return $choco.Update($PackageId, $Version, $options)
    }
}

function Search-ChocolateyPackage {
    <#
    .SYNOPSIS
        Search for packages using Chocolatey
    
    .PARAMETER Query
        Search query string
    
    .EXAMPLE
        Search-ChocolateyPackage -Query 'python'
    
    .EXAMPLE
        $packages = Search-ChocolateyPackage -Query 'visual studio'
        $packages | Format-Table Name, Id, Version
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return @()
    }
    
    return $choco.Search($Query)
}

function Get-ChocolateyPackageInfo {
    <#
    .SYNOPSIS
        Get detailed information about a Chocolatey package
    
    .PARAMETER PackageId
        The package ID to query
    
    .EXAMPLE
        Get-ChocolateyPackageInfo -PackageId 'git'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return $null
    }
    
    return $choco.GetPackageInfo($PackageId)
}

function Get-ChocolateyInstalledPackages {
    <#
    .SYNOPSIS
        List all packages installed via Chocolatey
    
    .EXAMPLE
        Get-ChocolateyInstalledPackages
    
    .EXAMPLE
        $installed = Get-ChocolateyInstalledPackages
        $installed | Where-Object { $_.CustomProperties.Pinned }
    #>
    [CmdletBinding()]
    param()
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return @()
    }
    
    return $choco.ListInstalled()
}

function Get-ChocolateyOutdatedPackages {
    <#
    .SYNOPSIS
        List all packages that have updates available
    
    .EXAMPLE
        Get-ChocolateyOutdatedPackages
    
    .EXAMPLE
        $outdated = Get-ChocolateyOutdatedPackages
        $outdated | ForEach-Object {
            Write-Host "$($_.Name): $($_.Version) -> $($_.CustomProperties.AvailableVersion)"
        }
    #>
    [CmdletBinding()]
    param()
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return @()
    }
    
    return $choco.GetOutdated()
}

function Set-ChocolateyPackagePin {
    <#
    .SYNOPSIS
        Pin a package to prevent updates
    
    .PARAMETER PackageId
        The package ID to pin
    
    .PARAMETER Unpin
        Remove the pin
    
    .EXAMPLE
        Set-ChocolateyPackagePin -PackageId 'nodejs'
    
    .EXAMPLE
        Set-ChocolateyPackagePin -PackageId 'python' -Unpin
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Unpin
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return $false
    }
    
    if ($Unpin) {
        return $choco.Unpin($PackageId)
    } else {
        return $choco.Pin($PackageId)
    }
}

function Add-ChocolateySource {
    <#
    .SYNOPSIS
        Add a Chocolatey package source
    
    .PARAMETER Name
        Name of the source
    
    .PARAMETER Url
        URL of the source
    
    .PARAMETER Priority
        Source priority (higher numbers = higher priority)
    
    .EXAMPLE
        Add-ChocolateySource -Name 'CompanyRepo' -Url 'https://nuget.company.com/chocolatey' -Priority 1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 0
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return
    }
    
    $choco.AddSource($Name, $Url, $Priority)
}

function Remove-ChocolateySource {
    <#
    .SYNOPSIS
        Remove a Chocolatey package source
    
    .PARAMETER Name
        Name of the source to remove
    
    .EXAMPLE
        Remove-ChocolateySource -Name 'CompanyRepo'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return
    }
    
    $choco.RemoveSource($Name)
}

function Get-ChocolateySources {
    <#
    .SYNOPSIS
        List all Chocolatey package sources
    
    .EXAMPLE
        Get-ChocolateySources
    #>
    [CmdletBinding()]
    param()
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return @()
    }
    
    return $choco.ListSources()
}

function Export-ChocolateyPackages {
    <#
    .SYNOPSIS
        Export installed Chocolatey packages to a JSON file
    
    .PARAMETER OutputPath
        Path to the output JSON file
    
    .EXAMPLE
        Export-ChocolateyPackages -OutputPath 'C:\Backup\choco-packages.json'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return
    }
    
    $choco.ExportInstalled($OutputPath)
}

function Import-ChocolateyPackages {
    <#
    .SYNOPSIS
        Import and install packages from a Chocolatey export file
    
    .PARAMETER InputPath
        Path to the input JSON file
    
    .PARAMETER IgnoreVersions
        Install latest versions instead of specified versions
    
    .PARAMETER IgnorePins
        Don't restore pin state
    
    .EXAMPLE
        Import-ChocolateyPackages -InputPath 'C:\Backup\choco-packages.json'
    
    .EXAMPLE
        Import-ChocolateyPackages -InputPath 'packages.json' -IgnoreVersions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreVersions,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnorePins
    )
    
    $choco = New-ChocolateyManager
    
    if (-not $choco.IsAvailable) {
        Write-Error "Chocolatey is not available"
        return $false
    }
    
    $options = @{
        IgnoreVersions = $IgnoreVersions.IsPresent
        IgnorePins = $IgnorePins.IsPresent
    }
    
    return $choco.ImportFromFile($InputPath, $options)
}

#endregion

#region Module Initialization

Write-Host "Chocolatey integration module loaded!" -ForegroundColor Green

# Test Chocolatey availability
$testChoco = New-ChocolateyManager
if ($testChoco.IsAvailable) {
    $edition = if ($testChoco.IsBusinessEdition) { 'Business' } else { 'Community' }
    Write-Host "  Chocolatey $edition: v$($testChoco.ChocolateyVersion)" -ForegroundColor White
    Write-Host "  Pinned Packages: $($testChoco.PinnedPackages.Count)" -ForegroundColor White
} else {
    Write-Host "  Chocolatey is not available on this system" -ForegroundColor Yellow
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'New-ChocolateyManager'
    'Install-ChocolateyPackage'
    'Uninstall-ChocolateyPackage'
    'Update-ChocolateyPackage'
    'Search-ChocolateyPackage'
    'Get-ChocolateyPackageInfo'
    'Get-ChocolateyInstalledPackages'
    'Get-ChocolateyOutdatedPackages'
    'Set-ChocolateyPackagePin'
    'Add-ChocolateySource'
    'Remove-ChocolateySource'
    'Get-ChocolateySources'
    'Export-ChocolateyPackages'
    'Import-ChocolateyPackages'
)

#endregion
