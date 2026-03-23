<#
.SYNOPSIS
    Retrieves a list of installed packages with detailed information.

.DESCRIPTION
    The Get-InstalledPackages cmdlet gets the packages that are installed on the local computer. 
    You can filter the results by name, source, or provider, and sort them by various properties.

.PARAMETER Name
    Specifies one or more package names. Wildcards are permitted. The default value is '*' (all packages).

.PARAMETER Source
    Specifies the name of the package source from which to get the packages.

.PARAMETER ProviderName
    Specifies the name of the package provider to use.

.PARAMETER Package
    Specifies a Package object to process. Accepts pipeline input.

.PARAMETER IncludeDependencies
    Includes the package's dependencies in the results.

.PARAMETER AllVersions
    Returns all versions of the specified package. By default, only the latest version is returned.

.PARAMETER Scope
    Specifies the scope of packages to return. Valid values are 'CurrentUser' and 'LocalMachine'.

.PARAMETER Limit
    Specifies the maximum number of packages to return. The default is 100.

.PARAMETER SortBy
    Specifies the property to sort the results by. Valid values are 'Name', 'Version', 'Source', and 'ProviderName'.

.PARAMETER Descending
    Sorts the results in descending order.

.PARAMETER ErrorAction
    Specifies how the cmdlet responds to an error. The default is 'SilentlyContinue'.

.EXAMPLE
    PS C:\> Get-InstalledPackages -Name "PowerShellGet"

    This command gets the installed package named "PowerShellGet".

.EXAMPLE
    PS C:\> Get-InstalledPackages -Source "PSGallery" -SortBy Version -Descending

    This command gets all packages from the PSGallery source and sorts them by version in descending order.

.INPUTS
    System.String[]
    Package[]

.OUTPUTS
    Package[]
#>
function Get-InstalledPackages {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([Package[]])]
    param (
        [Parameter(ParameterSetName = 'ByName',
                 Position = 0,
                 ValueFromPipeline = $true,
                 ValueFromPipelineByPropertyName = $true,
                 HelpMessage = 'Name of the package(s) to retrieve. Supports wildcards.')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name = '*',
        
        [Parameter(ParameterSetName = 'ByName',
                 HelpMessage = 'Name of the package source to filter by.')]
        [string]$Source,
        
        [Parameter(ParameterSetName = 'ByName',
                 HelpMessage = 'Name of the package provider to use (e.g., NuGet, PowerShellGet, Chocolatey).')]
        [ValidateSet('NuGet', 'PowerShellGet', 'Chocolatey', 'MSI', 'Programs', 'msi', 'Programs', '', $null)]
        [string]$ProviderName,
        
        [Parameter(ParameterSetName = 'ByPackage',
                 ValueFromPipeline = $true,
                 HelpMessage = 'Package objects to process.')]
        [ValidateNotNullOrEmpty()]
        [Package[]]$Package,
        
        [Parameter(HelpMessage = 'Include the package dependencies in the results.')]
        [switch]$IncludeDependencies,
        
        [Parameter(HelpMessage = 'Return all versions of each package instead of just the latest.')]
        [switch]$AllVersions,
        
        [Parameter(HelpMessage = 'Scope of the packages to retrieve.')]
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string]$Scope = 'LocalMachine',
        
        [Parameter(HelpMessage = 'Maximum number of packages to return.')]
        [ValidateRange(1, 1000)]
        [int]$Limit = 100,
        
        [Parameter(HelpMessage = 'Property to sort the results by.')]
        [ValidateSet('Name', 'Version', 'Source', 'ProviderName', 'InstallDate', 'Size')]
        [string]$SortBy = 'Name',
        
        [Parameter(HelpMessage = 'Sort in descending order.')]
        [switch]$Descending,
        
        [Parameter(HelpMessage = 'Controls how the command responds to errors.')]
        [ValidateSet('SilentlyContinue', 'Stop', 'Continue', 'Inquire', 'Ignore', 'Suspend')]
        [string]$ErrorAction = 'SilentlyContinue',
        
        [Parameter(HelpMessage = 'Include additional package metadata.')]
        [switch]$IncludeMetadata,
        
        [Parameter(HelpMessage = 'Return results as a formatted table.')]
        [switch]$AsTable
    )
    
    begin {
        # Set up error handling
        $ErrorActionPreference = $ErrorAction
        $operation = $PSCmdlet.MyInvocation.MyCommand.Name
        $startTime = Get-Date
        $results = [System.Collections.Generic.List[Package]]::new()
        
        # Log start of operation
        Write-Verbose -Message "[$operation] Starting operation with parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"
        
        # Initialize package providers if needed
        $availableProviders = @('NuGet', 'PowerShellGet', 'Chocolatey', 'MSI', 'Programs')
        
        if ($ProviderName -and $availableProviders -notcontains $ProviderName) {
            $errorMessage = "Provider '$ProviderName' is not supported. Supported providers: $($availableProviders -join ', ')"
            Write-Error -Message $errorMessage -Category InvalidArgument -ErrorAction Stop
            return
        }
        
        # Build the filter script with enhanced filtering
        $filterScript = {
            param($pkg)
            
            try {
                # Filter by name if specified
                $nameMatch = if ($Name -eq '*' -or -not $Name) { 
                    $true 
                } else { 
                    $Name | Where-Object { $pkg.Name -like $_ } | Select-Object -First 1
                }
                
                # Filter by source if specified
                $sourceMatch = if (-not $Source) { 
                    $true 
                } else { 
                    $pkg.Source -eq $Source 
                }
                
                # Filter by provider if specified
                $providerMatch = if (-not $ProviderName) { 
                    $true 
                } else { 
                    $pkg.ProviderName -eq $ProviderName 
                }
                
                return $nameMatch -and $sourceMatch -and $providerMatch
            }
            catch {
                Write-Warning "Error filtering package '$($pkg.Name)': $_"
                return $false
            }
        }
    }
    
    process {
        try {
            # Handle pipeline input
            if ($PSCmdlet.ParameterSetName -eq 'ByPackage') {
                $packagesToProcess = $Package
            }
            else {
                # Get all installed packages with appropriate parameters
                $getPkgParams = @{
                    ErrorAction = 'Stop'
                    AllVersions = $AllVersions
                }
                
                # Add provider-specific parameters
                if ($ProviderName) {
                    $getPkgParams['ProviderName'] = $ProviderName
                }
                
                # Get packages based on scope
                if ($Scope -eq 'CurrentUser') {
                    $getPkgParams['Scope'] = 'CurrentUser'
                }
                
                # Add scope if specified
                if ($Scope) {
                    $getPkgParams['Scope'] = $Scope
                }
                
                # Get packages from all sources if no specific source is provided
                $sources = if ($Source) { @($Source) } else { $script:PackageSources.Keys }
                $packagesToProcess = @()
                
                foreach ($src in $sources) {
                    try {
                        $getPkgParams['Source'] = $src
                        $pkgs = Get-Package @getPkgParams | Where-Object { & $filterScript $_ }
                        $packagesToProcess += $pkgs
                        
                        # Apply limit if we've reached it
                        if ($packagesToProcess.Count -ge $Limit) {
                            $packagesToProcess = $packagesToProcess | Select-Object -First $Limit
                            break
                        }
                    }
                    catch {
                        Write-PSFMessage -Level Warning -Message "Failed to get packages from source '$src': $_"
                    }
                }
            }
            
            # Process each package
            foreach ($pkg in $packagesToProcess) {
                try {
                    # Create a Package object
                    $package = [Package]@{
                        Name = $pkg.Name
                        Version = $pkg.Version
                        Source = $pkg.Source
                        ProviderName = $pkg.ProviderName
                        Description = $pkg.Description
                        IsInstalled = $true
                        InstalledVersion = $pkg.Version
                    }
                    
                    # Add to results
                    $results.Add($package)
                    
                    # Get dependencies if requested
                    if ($IncludeDependencies) {
                        try {
                            $deps = Get-PackageDependency -Name $pkg.Name -Source $pkg.Source -ErrorAction Stop
                            $package.Dependencies = $deps
                        }
                        catch {
                            Write-PSFMessage -Level Warning -Message "Failed to get dependencies for package '$($pkg.Name)': $_"
                        }
                    }
                    
                    # Check for updates if requested
                    if ($CheckForUpdates) {
                        try {
                            $update = Get-PackageUpdate -Name $pkg.Name -Source $pkg.Source -ErrorAction Stop
                            if ($update) {
                                $package.LatestVersion = $update.Version
                            }
                        }
                        catch {
                            Write-PSFMessage -Level Verbose -Message "Failed to check for updates for package '$($pkg.Name)': $_"
                        }
                    }
                }
                catch {
                    Write-PSFMessage -Level Warning -Message "Error processing package '$($pkg.Name)': $_"
                }
            }
        }
        catch {
            $errorMessage = "Error in $operation : $_"
            Write-PSFMessage -Level Error -Message $errorMessage -ErrorRecord $_
            
            if ($ErrorAction -eq 'Stop') {
                throw $errorMessage
            }
        }
    }
    
    end {
        try {
            # Apply sorting and limit
            $sortedResults = if ($results.Count -gt 0) {
                $sortParams = @{
                    Property = $SortBy
                }
                
                if ($Descending) {
                    $sortParams['Descending'] = $true
                }
                
                # Apply limit after sorting
                $sorted = $results | Sort-Object @sortParams
                if ($Limit -gt 0) {
                    $sorted | Select-Object -First $Limit
                } else {
                    $sorted
                }
            } else {
                $results
            }
            
            # Format output if requested
            if ($AsTable) {
                $output = $sortedResults | Format-Table -AutoSize
                if ($output -is [System.Array] -and $output.Count -eq 0) {
                    Write-Output "No packages found matching the specified criteria."
                } else {
                    $output
                }
            } else {
                $sortedResults
            }
        }
        catch {
            Write-Error -Message "Error processing results: $_" -ErrorAction $ErrorAction
            if ($ErrorAction -eq 'Stop') {
                throw
            }
        }
        finally {
            # Log completion
            $duration = (Get-Date) - $startTime
            Write-Verbose -Message "[$operation] Completed in $($duration.TotalSeconds.ToString('0.00')) seconds. Processed $($results.Count) packages."
        }
    }
}

# Set up aliases
Set-Alias -Name gpkg -Value Get-InstalledPackages -Scope Global -Force

# Export the function
Export-ModuleMember -Function Get-InstalledPackages -Alias gpkg
