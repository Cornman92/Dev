# PackageManager.psm1
# Centralized package management for Dev workspace

# Initialize package sources
$script:PackageSources = @{
    'PSGallery' = 'https://www.powershellgallery.com/api/v2'
    'Chocolatey' = 'https://chocolatey.org/api/v2/'
    'NuGet' = 'https://api.nuget.org/v3/index.json'
}

# Register package sources if not already registered
function Register-PackageSources {
    [CmdletBinding()]
    param()
    
    foreach ($source in $script:PackageSources.GetEnumerator()) {
        $existingSource = Get-PackageSource -Name $source.Key -ErrorAction SilentlyContinue
        
        if (-not $existingSource) {
            try {
                Register-PackageSource -Name $source.Key -Location $source.Value -ProviderName 'NuGet' -Trusted -Force | Out-Null
                Write-Host "Registered package source: $($source.Key)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to register package source $($source.Key): $_"
            }
        }
    }
}

# Install a package
function Install-DevPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [string]$Version,
        
        [ValidateSet('PSGallery', 'Chocolatey', 'NuGet')]
        [string]$Source = 'PSGallery',
        
        [switch]$Force
    )
    
    try {
        $params = @{
            Name = $Name
            Source = $Source
            Force = $Force
            ErrorAction = 'Stop'
        }
        
        if ($Version) {
            $params['RequiredVersion'] = $Version
        }
        
        Install-Package @params
        Write-Host "Successfully installed $Name" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install $Name : $_"
    }
}

# Update a package
function Update-DevPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [ValidateSet('PSGallery', 'Chocolatey', 'NuGet')]
        [string]$Source = 'PSGallery'
    )
    
    try {
        Update-Package -Name $Name -Source $Source -ErrorAction Stop
        Write-Host "Successfully updated $Name" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update $Name : $_"
    }
}

# List installed packages
function Get-InstalledPackages {
    [CmdletBinding()]
    param()
    
    $packages = @()
    
    # Get packages from all sources
    foreach ($source in $script:PackageSources.Keys) {
        try {
            $pkgs = Get-Package -Source $source -ErrorAction SilentlyContinue
            $packages += $pkgs | Select-Object @{Name='Source';Expression={$source}}, Name, Version
        }
        catch {
            Write-Warning "Failed to get packages from $source : $_"
        }
    }
    
    return $packages | Sort-Object Source, Name
}

# Check for package updates
function Get-PackageUpdates {
    [CmdletBinding()]
    param()
    
    $updates = @()
    
    foreach ($source in $script:PackageSources.Keys) {
        try {
            $updates += Find-Package -Source $source -AllVersions -ErrorAction SilentlyContinue | 
                        Where-Object { $_.Version -ne $_.InstalledVersion } |
                        Select-Object @{Name='Source';Expression={$source}}, Name, Version, @{Name='InstalledVersion';Expression={$_.InstalledVersion}}
        }
        catch {
            Write-Warning "Failed to check for updates from $source : $_"
        }
    }
    
    return $updates | Sort-Object Source, Name
}

# Initialize module
function Initialize-PackageManager {
    [CmdletBinding()]
    param()
    
    # Register package sources
    Register-PackageSources
    
    # Import required modules
    $requiredModules = @('PackageManagement', 'PowerShellGet')
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
        }
        Import-Module $module -Force
    }
    
    Write-Host "Package Manager initialized successfully" -ForegroundColor Green
}

# Export public functions
export-modulemember -Function Install-DevPackage, Update-DevPackage, Get-InstalledPackages, Get-PackageUpdates, Initialize-PackageManager

# Initialize on module import
Initialize-PackageManager
