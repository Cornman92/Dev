# PackageManager.Init.ps1
# Module initialization script

# Set strict mode
Set-StrictMode -Version Latest

# Import required modules
$requiredModules = @(
    @{ Name = 'PackageManagement'; Version = '1.4.7' },
    @{ Name = 'PowerShellGet'; Version = '3.0.0' },
    @{ Name = 'PSFramework'; Version = '1.7.0' },
    @{ Name = 'Pester'; Version = '5.0.0' }
)

foreach ($module in $requiredModules) {
    try {
        $importParams = @{
            Name = $module.Name
            ErrorAction = 'Stop'
            Force = $true
        }
        
        if ($module.Version) {
            $importParams['RequiredVersion'] = $module.Version
        }
        
        # Check if module is already loaded
        if (-not (Get-Module -Name $module.Name -ErrorAction SilentlyContinue)) {
            # Try to import the module
            try {
                Import-Module @importParams
                Write-Verbose "Imported module: $($module.Name) $($module.Version)"
            }
            catch {
                # If import fails, try to install the module
                Write-Warning "Module $($module.Name) not found. Attempting to install..."
                try {
                    Install-Module @importParams -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck
                    Import-Module @importParams
                    Write-Verbose "Installed and imported module: $($module.Name) $($module.Version)"
                }
                catch {
                    $errorMessage = "Failed to install/import required module: $($module.Name). Error: $_"
                    Write-Error $errorMessage
                    throw $errorMessage
                }
            }
        }
    }
    catch {
        $errorMessage = "Error processing module $($module.Name): $_"
        Write-Error $errorMessage
        throw $errorMessage
    }
}

# Set up PSFramework logging
$logPath = Join-Path -Path $PSScriptRoot -ChildPath 'Logs'
if (-not (Test-Path -Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

# Configure logging providers
Set-PSFLoggingProvider -Name logfile -Enabled $true -LogPath $logPath -FileType Log -LogName 'PackageManager-{0:yyyyMMdd}.log' -EnabledLogFileCount 7
Set-PSFLoggingProvider -Name console -Enabled $true
Set-PSFLoggingProvider -Name logfile -Enabled $true

# Set default log level
Set-PSFLoggingInstance -Name PackageManager -InstanceName $env:COMPUTERNAME -Enabled $true -Level Verbose -LogHostOnlyMessage $false -MessageLevel Verbose

# Initialize package sources
$script:PackageSources = @{
    'PSGallery' = @{
        Location = 'https://www.powershellgallery.com/api/v2'
        ProviderName = 'PowerShellGet'
        Trusted = $true
    }
    'Chocolatey' = @{
        Location = 'https://chocolatey.org/api/v2/'
        ProviderName = 'Chocolatey'
        Trusted = $true
    }
    'npm' = @{
        Location = 'https://registry.npmjs.org'
        ProviderName = 'npm'
        Trusted = $true
    }
    'PyPI' = @{
        Location = 'https://pypi.org/pypi'
        ProviderName = 'pip'
        Trusted = $true
    }
    'winget' = @{
        Location = 'https://winget.azureedge.net/cache'
        ProviderName = 'winget'
        Trusted = $true
    }
}

# Register package sources
function Register-PackageSources {
    [CmdletBinding()]
    param()
    
    foreach ($sourceName in $script:PackageSources.Keys) {
        $source = $script:PackageSources[$sourceName]
        
        try {
            # Check if source is already registered
            $existingSource = Get-PackageSource -Name $sourceName -ErrorAction SilentlyContinue
            
            if (-not $existingSource) {
                $registerParams = @{
                    Name = $sourceName
                    Location = $source.Location
                    ProviderName = $source.ProviderName
                    Trusted = $source.Trusted
                    Force = $true
                    ErrorAction = 'Stop'
                }
                
                Register-PackageSource @registerParams | Out-Null
                Write-PSFMessage -Level Verbose -Message "Registered package source: $sourceName"
            }
            else {
                Write-PSFMessage -Level Verbose -Message "Package source already registered: $sourceName"
            }
        }
        catch {
            Write-PSFMessage -Level Warning -Message "Failed to register package source '$sourceName': $_" -ErrorRecord $_
        }
    }
}

# Initialize the module
Write-PSFMessage -Level Verbose -Message "Initializing PackageManager module..."

# Register package sources
Register-PackageSources

# Load all .ps1 files in the Private and Public folders
$privateScripts = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
$publicScripts = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue

# Dot source the files
foreach ($file in @($privateScripts + $publicScripts)) {
    try {
        . $file.FullName
        Write-PSFMessage -Level Verbose -Message "Loaded script: $($file.Name)"
    }
    catch {
        Write-PSFMessage -Level Error -Message "Failed to load script $($file.Name): $_" -ErrorRecord $_
    }
}

# Export public functions
$functionsToExport = @()
foreach ($file in $publicScripts) {
    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $functionsToExport += $functionName
    
    # Export the function
    try {
        Export-ModuleMember -Function $functionName -ErrorAction Stop
        Write-PSFMessage -Level Verbose -Message "Exported function: $functionName"
    }
    catch {
        Write-PSFMessage -Level Warning -Message "Failed to export function $functionName : $_" -ErrorRecord $_
    }
}

# Export aliases
$aliases = @{
    'ipkg' = 'Install-DevPackage'
    'upkg' = 'Update-DevPackage'
    'gpkg' = 'Get-InstalledPackages'
    'spkg' = 'Save-PackageConfig'
    'rpkg' = 'Restore-DevEnvironment'
}

foreach ($alias in $aliases.GetEnumerator()) {
    try {
        Set-Alias -Name $alias.Key -Value $alias.Value -Scope Global -ErrorAction Stop
        Write-PSFMessage -Level Verbose -Message "Set alias: $($alias.Key) -> $($alias.Value)"
    }
    catch {
        Write-PSFMessage -Level Warning -Message "Failed to set alias $($alias.Key): $_" -ErrorRecord $_
    }
}

# Export variables
Export-ModuleMember -Variable 'PackageSources' -Function $functionsToExport

# Initialize default configuration
$script:PackageManagerConfig = @{
    DefaultSource = 'PSGallery'
    DefaultInstallLocation = Join-Path -Path $env:ProgramFiles -ChildPath 'PackageManager'
    LogLevel = 'Verbose'
    EnableTelemetry = $false
    EnableAutoUpdate = $true
}

Write-PSFMessage -Level Important -Message "PackageManager module initialized successfully"

# Clean up
Remove-Variable -Name requiredModules, privateScripts, publicScripts, functionsToExport, aliases -ErrorAction SilentlyContinue
