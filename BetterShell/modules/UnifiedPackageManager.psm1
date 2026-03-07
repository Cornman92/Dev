#Requires -Version 5.1

<#
.SYNOPSIS
    Unified Package Management Module for Better11 Suite
.DESCRIPTION
    Abstraction layer for WinGet, Chocolatey, and Scoop package managers
.AUTHOR
    Better11 Development Team
.VERSION
    1.0.0
#>

#region Package Manager Detection

function Get-PackageManager {
    <#
    .SYNOPSIS
        Detects available package managers
    .DESCRIPTION
        Checks for WinGet, Chocolatey, and Scoop installations and capabilities
    .EXAMPLE
        Get-PackageManager -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )
    
    $managers = @{
        WinGet = Test-WinGetAvailability
        Chocolatey = Test-ChocolateyAvailability
        Scoop = Test-ScoopAvailability
    }
    
    if ($Detailed) {
        foreach ($mgr in $managers.Keys) {
            if ($managers[$mgr].Available) {
                $managers[$mgr].InstalledPackages = Get-InstalledPackages -Manager $mgr
            }
        }
    }
    
    return [PSCustomObject]$managers
}

function Test-WinGetAvailability {
    [CmdletBinding()]
    param()
    
    try {
        $winget = Get-Command winget -ErrorAction Stop
        $version = winget --version
        
        return @{
            Available = $true
            Version = $version
            Path = $winget.Source
            Priority = 1
        }
    }
    catch {
        return @{
            Available = $false
            Message = "WinGet not found. Install from Microsoft Store."
        }
    }
}

function Test-ChocolateyAvailability {
    [CmdletBinding()]
    param()
    
    try {
        $choco = Get-Command choco -ErrorAction Stop
        $version = choco --version
        
        return @{
            Available = $true
            Version = $version
            Path = $choco.Source
            Priority = 2
        }
    }
    catch {
        return @{
            Available = $false
            Message = "Chocolatey not found. Install from chocolatey.org"
        }
    }
}

function Test-ScoopAvailability {
    [CmdletBinding()]
    param()
    
    try {
        $scoop = Get-Command scoop -ErrorAction Stop
        $version = scoop --version
        
        return @{
            Available = $true
            Version = $version.Substring(0, $version.IndexOf(' '))
            Path = $scoop.Source
            Priority = 3
        }
    }
    catch {
        return @{
            Available = $false
            Message = "Scoop not found. Install from scoop.sh"
        }
    }
}

#endregion

#region Unified Package Operations

function Find-Package {
    <#
    .SYNOPSIS
        Searches for packages across all package managers
    .DESCRIPTION
        Unified search interface for WinGet, Chocolatey, and Scoop
    .EXAMPLE
        Find-Package -Name "git" -AllManagers
    .EXAMPLE
        Find-Package -Name "visual studio code" -Manager WinGet
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,
        
        [ValidateSet('WinGet', 'Chocolatey', 'Scoop', 'Auto')]
        [string]$Manager = 'Auto',
        
        [switch]$AllManagers,
        [switch]$Exact
    )
    
    $results = @()
    
    if ($Manager -eq 'Auto' -or $AllManagers) {
        $managers = Get-PackageManager
        $availableManagers = $managers.PSObject.Properties | 
            Where-Object { $_.Value.Available } | 
            Sort-Object { $_.Value.Priority }
    }
    else {
        $availableManagers = @($Manager)
    }
    
    foreach ($mgr in $availableManagers) {
        $mgrName = if ($mgr -is [string]) { $mgr } else { $mgr.Name }
        
        Write-Verbose "Searching in $mgrName..."
        
        $packages = switch ($mgrName) {
            'WinGet' { Search-WinGetPackage -Name $Name -Exact:$Exact }
            'Chocolatey' { Search-ChocolateyPackage -Name $Name -Exact:$Exact }
            'Scoop' { Search-ScoopPackage -Name $Name -Exact:$Exact }
        }
        
        if ($packages) {
            $results += $packages | ForEach-Object {
                $_ | Add-Member -NotePropertyName Manager -NotePropertyValue $mgrName -PassThru
            }
        }
        
        if (-not $AllManagers -and $results.Count -gt 0) {
            break
        }
    }
    
    return $results | Sort-Object Manager, Name
}

function Install-UnifiedPackage {
    <#
    .SYNOPSIS
        Installs packages using the best available manager
    .DESCRIPTION
        Intelligently selects and uses the appropriate package manager
    .EXAMPLE
        Install-UnifiedPackage -Name "Git.Git" -Manager WinGet
    .EXAMPLE
        Install-UnifiedPackage -Name "git" -PreferredManager WinGet -Fallback
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,
        
        [ValidateSet('WinGet', 'Chocolatey', 'Scoop', 'Auto')]
        [string]$PreferredManager = 'Auto',
        
        [switch]$Fallback,
        [switch]$Force,
        [switch]$Silent,
        [string]$Version
    )
    
    begin {
        $managers = Get-PackageManager
        $results = @()
    }
    
    process {
        foreach ($pkg in $Name) {
            Write-Verbose "Processing package: $pkg"
            
            $manager = if ($PreferredManager -eq 'Auto') {
                Select-BestPackageManager -PackageName $pkg -Managers $managers
            }
            else {
                if ($managers.$PreferredManager.Available) {
                    $PreferredManager
                }
                else {
                    Write-Warning "$PreferredManager not available"
                    Select-BestPackageManager -PackageName $pkg -Managers $managers
                }
            }
            
            if (-not $manager) {
                $results += [PSCustomObject]@{
                    Package = $pkg
                    Status = 'Failed'
                    Message = 'No package manager available'
                    Manager = 'None'
                }
                continue
            }
            
            $installResult = switch ($manager) {
                'WinGet' {
                    Install-WinGetPackage -Name $pkg -Force:$Force -Silent:$Silent -Version $Version
                }
                'Chocolatey' {
                    Install-ChocolateyPackage -Name $pkg -Force:$Force -Silent:$Silent -Version $Version
                }
                'Scoop' {
                    Install-ScoopPackage -Name $pkg -Force:$Force -Version $Version
                }
            }
            
            if ($installResult.Success -or -not $Fallback) {
                $results += $installResult
            }
            else {
                # Try fallback managers
                $otherManagers = @('WinGet', 'Chocolatey', 'Scoop') | Where-Object { $_ -ne $manager -and $managers.$_.Available }
                
                foreach ($fallbackMgr in $otherManagers) {
                    Write-Verbose "Trying fallback manager: $fallbackMgr"
                    
                    $fallbackResult = switch ($fallbackMgr) {
                        'WinGet' { Install-WinGetPackage -Name $pkg -Force:$Force -Silent:$Silent }
                        'Chocolatey' { Install-ChocolateyPackage -Name $pkg -Force:$Force -Silent:$Silent }
                        'Scoop' { Install-ScoopPackage -Name $pkg -Force:$Force }
                    }
                    
                    if ($fallbackResult.Success) {
                        $results += $fallbackResult
                        break
                    }
                }
            }
        }
    }
    
    end {
        return $results
    }
}

function Update-UnifiedPackage {
    <#
    .SYNOPSIS
        Updates installed packages across all managers
    .DESCRIPTION
        Updates packages from WinGet, Chocolatey, and Scoop
    .EXAMPLE
        Update-UnifiedPackage -All
    .EXAMPLE
        Update-UnifiedPackage -Name "git" -Manager WinGet
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Name,
        
        [ValidateSet('WinGet', 'Chocolatey', 'Scoop', 'All')]
        [string]$Manager = 'All',
        
        [switch]$All,
        [switch]$Force
    )
    
    $results = @()
    $managers = Get-PackageManager
    
    $managersToUpdate = if ($Manager -eq 'All') {
        $managers.PSObject.Properties | Where-Object { $_.Value.Available } | Select-Object -ExpandProperty Name
    }
    else {
        @($Manager)
    }
    
    foreach ($mgr in $managersToUpdate) {
        Write-Host "Updating packages in $mgr..." -ForegroundColor Cyan
        
        $updateResult = switch ($mgr) {
            'WinGet' {
                if ($All) {
                    Update-AllWinGetPackages -Force:$Force
                }
                else {
                    foreach ($pkg in $Name) {
                        Update-WinGetPackage -Name $pkg -Force:$Force
                    }
                }
            }
            'Chocolatey' {
                if ($All) {
                    Update-AllChocolateyPackages -Force:$Force
                }
                else {
                    foreach ($pkg in $Name) {
                        Update-ChocolateyPackage -Name $pkg -Force:$Force
                    }
                }
            }
            'Scoop' {
                if ($All) {
                    Update-AllScoopPackages
                }
                else {
                    foreach ($pkg in $Name) {
                        Update-ScoopPackage -Name $pkg
                    }
                }
            }
        }
        
        $results += $updateResult
    }
    
    return $results
}

function Remove-UnifiedPackage {
    <#
    .SYNOPSIS
        Uninstalls packages from any manager
    .DESCRIPTION
        Removes packages with automatic manager detection
    .EXAMPLE
        Remove-UnifiedPackage -Name "git" -Manager WinGet
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Name,
        
        [ValidateSet('WinGet', 'Chocolatey', 'Scoop', 'Auto')]
        [string]$Manager = 'Auto',
        
        [switch]$Force
    )
    
    process {
        foreach ($pkg in $Name) {
            if ($PSCmdlet.ShouldProcess($pkg, "Uninstall package")) {
                $mgr = if ($Manager -eq 'Auto') {
                    Get-PackageManagerForPackage -PackageName $pkg
                }
                else {
                    $Manager
                }
                
                if (-not $mgr) {
                    Write-Warning "Could not determine manager for: $pkg"
                    continue
                }
                
                switch ($mgr) {
                    'WinGet' { Remove-WinGetPackage -Name $pkg -Force:$Force }
                    'Chocolatey' { Remove-ChocolateyPackage -Name $pkg -Force:$Force }
                    'Scoop' { Remove-ScoopPackage -Name $pkg }
                }
            }
        }
    }
}

function Get-InstalledPackages {
    <#
    .SYNOPSIS
        Lists installed packages from all managers
    .DESCRIPTION
        Retrieves comprehensive list of installed packages
    .EXAMPLE
        Get-InstalledPackages -Manager WinGet
    .EXAMPLE
        Get-InstalledPackages -AllManagers | Export-Csv packages.csv
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('WinGet', 'Chocolatey', 'Scoop', 'All')]
        [string]$Manager = 'All',
        
        [switch]$AllManagers,
        [switch]$IncludeUpgradable
    )
    
    if ($AllManagers) { $Manager = 'All' }
    
    $packages = @()
    
    if ($Manager -in @('WinGet', 'All')) {
        $packages += Get-WinGetInstalledPackages -IncludeUpgradable:$IncludeUpgradable
    }
    
    if ($Manager -in @('Chocolatey', 'All')) {
        $packages += Get-ChocolateyInstalledPackages -IncludeUpgradable:$IncludeUpgradable
    }
    
    if ($Manager -in @('Scoop', 'All')) {
        $packages += Get-ScoopInstalledPackages -IncludeUpgradable:$IncludeUpgradable
    }
    
    return $packages | Sort-Object Manager, Name
}

#endregion

#region WinGet Functions

function Search-WinGetPackage {
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$Exact
    )
    
    try {
        $cmd = if ($Exact) {
            "winget search `"$Name`" --exact"
        }
        else {
            "winget search `"$Name`""
        }
        
        $output = Invoke-Expression $cmd 2>&1 | Where-Object { $_ -is [string] }
        
        # Parse WinGet output
        $packages = @()
        $headerPassed = $false
        
        foreach ($line in $output) {
            if ($line -match '^-+') {
                $headerPassed = $true
                continue
            }
            
            if ($headerPassed -and $line.Trim()) {
                $parts = $line -split '\s{2,}'
                if ($parts.Count -ge 2) {
                    $packages += [PSCustomObject]@{
                        Name = $parts[0].Trim()
                        Id = $parts[1].Trim()
                        Version = if ($parts.Count -ge 3) { $parts[2].Trim() } else { 'N/A' }
                        Source = 'WinGet'
                    }
                }
            }
        }
        
        return $packages
    }
    catch {
        Write-Error "WinGet search failed: $_"
        return @()
    }
}

function Install-WinGetPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force,
        [switch]$Silent,
        [string]$Version
    )
    
    try {
        $args = @('install', '--id', $Name, '--accept-source-agreements', '--accept-package-agreements')
        
        if ($Force) { $args += '--force' }
        if ($Silent) { $args += '--silent' }
        if ($Version) { $args += '--version', $Version }
        
        if ($PSCmdlet.ShouldProcess($Name, "Install via WinGet")) {
            $result = & winget @args 2>&1
            
            return [PSCustomObject]@{
                Package = $Name
                Manager = 'WinGet'
                Status = if ($LASTEXITCODE -eq 0) { 'Success' } else { 'Failed' }
                Message = $result -join "`n"
                Success = $LASTEXITCODE -eq 0
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Package = $Name
            Manager = 'WinGet'
            Status = 'Failed'
            Message = $_.Exception.Message
            Success = $false
        }
    }
}

function Update-WinGetPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Update via WinGet")) {
        $args = @('upgrade', '--id', $Name)
        if ($Force) { $args += '--force' }
        
        & winget @args
    }
}

function Update-AllWinGetPackages {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess("All WinGet packages", "Update")) {
        $args = @('upgrade', '--all')
        if ($Force) { $args += '--force' }
        
        & winget @args
    }
}

function Remove-WinGetPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Uninstall via WinGet")) {
        $args = @('uninstall', '--id', $Name)
        if ($Force) { $args += '--force' }
        
        & winget @args
    }
}

function Get-WinGetInstalledPackages {
    [CmdletBinding()]
    param(
        [switch]$IncludeUpgradable
    )
    
    try {
        $output = winget list 2>&1 | Where-Object { $_ -is [string] }
        
        $packages = @()
        $headerPassed = $false
        
        foreach ($line in $output) {
            if ($line -match '^-+') {
                $headerPassed = $true
                continue
            }
            
            if ($headerPassed -and $line.Trim()) {
                $parts = $line -split '\s{2,}'
                if ($parts.Count -ge 2) {
                    $pkg = [PSCustomObject]@{
                        Name = $parts[0].Trim()
                        Id = $parts[1].Trim()
                        Version = if ($parts.Count -ge 3) { $parts[2].Trim() } else { 'N/A' }
                        Manager = 'WinGet'
                    }
                    
                    if ($IncludeUpgradable -and $parts.Count -ge 4) {
                        $pkg | Add-Member -NotePropertyName AvailableVersion -NotePropertyValue $parts[3].Trim()
                        $pkg | Add-Member -NotePropertyName Upgradable -NotePropertyValue ($parts[3].Trim() -ne '')
                    }
                    
                    $packages += $pkg
                }
            }
        }
        
        return $packages
    }
    catch {
        Write-Error "Failed to get WinGet packages: $_"
        return @()
    }
}

#endregion

#region Chocolatey Functions

function Search-ChocolateyPackage {
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$Exact
    )
    
    try {
        $args = @('search', $Name)
        if ($Exact) { $args += '--exact' }
        
        $output = & choco @args 2>&1 | Where-Object { $_ -is [string] }
        
        $packages = $output | Where-Object { $_ -match '^\S+\s+\S+' } | ForEach-Object {
            $parts = $_ -split '\s+', 2
            [PSCustomObject]@{
                Name = $parts[0]
                Version = $parts[1]
                Source = 'Chocolatey'
            }
        }
        
        return $packages
    }
    catch {
        Write-Error "Chocolatey search failed: $_"
        return @()
    }
}

function Install-ChocolateyPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force,
        [switch]$Silent,
        [string]$Version
    )
    
    try {
        $args = @('install', $Name, '-y')
        
        if ($Force) { $args += '--force' }
        if ($Version) { $args += '--version', $Version }
        
        if ($PSCmdlet.ShouldProcess($Name, "Install via Chocolatey")) {
            $result = & choco @args 2>&1
            
            return [PSCustomObject]@{
                Package = $Name
                Manager = 'Chocolatey'
                Status = if ($LASTEXITCODE -eq 0) { 'Success' } else { 'Failed' }
                Message = $result -join "`n"
                Success = $LASTEXITCODE -eq 0
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Package = $Name
            Manager = 'Chocolatey'
            Status = 'Failed'
            Message = $_.Exception.Message
            Success = $false
        }
    }
}

function Update-ChocolateyPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Update via Chocolatey")) {
        $args = @('upgrade', $Name, '-y')
        if ($Force) { $args += '--force' }
        
        & choco @args
    }
}

function Update-AllChocolateyPackages {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess("All Chocolatey packages", "Update")) {
        $args = @('upgrade', 'all', '-y')
        if ($Force) { $args += '--force' }
        
        & choco @args
    }
}

function Remove-ChocolateyPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Uninstall via Chocolatey")) {
        $args = @('uninstall', $Name, '-y')
        if ($Force) { $args += '--force' }
        
        & choco @args
    }
}

function Get-ChocolateyInstalledPackages {
    [CmdletBinding()]
    param(
        [switch]$IncludeUpgradable
    )
    
    try {
        $output = choco list --local-only 2>&1 | Where-Object { $_ -is [string] }
        
        $packages = $output | Where-Object { $_ -match '^\S+\s+\S+' } | ForEach-Object {
            $parts = $_ -split '\s+', 2
            [PSCustomObject]@{
                Name = $parts[0]
                Version = $parts[1]
                Manager = 'Chocolatey'
            }
        }
        
        return $packages
    }
    catch {
        Write-Error "Failed to get Chocolatey packages: $_"
        return @()
    }
}

#endregion

#region Scoop Functions

function Search-ScoopPackage {
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$Exact
    )
    
    try {
        $output = scoop search $Name 2>&1 | Where-Object { $_ -is [string] }
        
        $packages = $output | Where-Object { $_ -match '^\s+\S+' } | ForEach-Object {
            $name = $_.Trim() -replace '\s.*$'
            [PSCustomObject]@{
                Name = $name
                Source = 'Scoop'
            }
        }
        
        return $packages
    }
    catch {
        Write-Error "Scoop search failed: $_"
        return @()
    }
}

function Install-ScoopPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [switch]$Force,
        [string]$Version
    )
    
    try {
        if ($PSCmdlet.ShouldProcess($Name, "Install via Scoop")) {
            $args = @('install', $Name)
            if ($Force) { $args += '--force' }
            
            $result = & scoop @args 2>&1
            
            return [PSCustomObject]@{
                Package = $Name
                Manager = 'Scoop'
                Status = if ($LASTEXITCODE -eq 0) { 'Success' } else { 'Failed' }
                Message = $result -join "`n"
                Success = $LASTEXITCODE -eq 0
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            Package = $Name
            Manager = 'Scoop'
            Status = 'Failed'
            Message = $_.Exception.Message
            Success = $false
        }
    }
}

function Update-ScoopPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Update via Scoop")) {
        scoop update $Name
    }
}

function Update-AllScoopPackages {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("All Scoop packages", "Update")) {
        scoop update *
    }
}

function Remove-ScoopPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Uninstall via Scoop")) {
        scoop uninstall $Name
    }
}

function Get-ScoopInstalledPackages {
    [CmdletBinding()]
    param(
        [switch]$IncludeUpgradable
    )
    
    try {
        $output = scoop list 2>&1 | Where-Object { $_ -is [string] }
        
        $packages = $output | Where-Object { $_ -match '^\s+\S+' } | ForEach-Object {
            $parts = $_.Trim() -split '\s+'
            [PSCustomObject]@{
                Name = $parts[0]
                Version = if ($parts.Count -ge 2) { $parts[1] } else { 'N/A' }
                Manager = 'Scoop'
            }
        }
        
        return $packages
    }
    catch {
        Write-Error "Failed to get Scoop packages: $_"
        return @()
    }
}

#endregion

#region Helper Functions

function Select-BestPackageManager {
    [CmdletBinding()]
    param(
        [string]$PackageName,
        [hashtable]$Managers
    )
    
    # Try to find package in each manager and select the best
    $available = $Managers.GetEnumerator() | 
        Where-Object { $_.Value.Available } | 
        Sort-Object { $_.Value.Priority }
    
    foreach ($mgr in $available) {
        $found = switch ($mgr.Key) {
            'WinGet' { Search-WinGetPackage -Name $PackageName -Exact }
            'Chocolatey' { Search-ChocolateyPackage -Name $PackageName -Exact }
            'Scoop' { Search-ScoopPackage -Name $PackageName -Exact }
        }
        
        if ($found) {
            return $mgr.Key
        }
    }
    
    # If not found, return highest priority available manager
    return $available[0].Key
}

function Get-PackageManagerForPackage {
    [CmdletBinding()]
    param(
        [string]$PackageName
    )
    
    $installed = Get-InstalledPackages -AllManagers
    $package = $installed | Where-Object { $_.Name -eq $PackageName -or $_.Id -eq $PackageName } | Select-Object -First 1
    
    return $package.Manager
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-PackageManager',
    'Find-Package',
    'Install-UnifiedPackage',
    'Update-UnifiedPackage',
    'Remove-UnifiedPackage',
    'Get-InstalledPackages'
)
