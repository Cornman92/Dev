function Install-DevPackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Package])]
    param (
        [Parameter(Mandatory = $true, 
                  ValueFromPipeline = $true,
                  ValueFromPipelineByPropertyName = $true,
                  Position = 0)]
        [string[]]$Name,
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Version,
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Source,
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -IsValid)) {
                throw "Invalid path: $_"
            }
            return $true
        })]
        [string]$InstallationPath,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$RetryDelay = 5,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$NoDependencies,
        
        [Parameter()]
        [switch]$WhatIf,
        
        [Parameter()]
        [ValidateSet('SilentlyContinue', 'Stop', 'Continue', 'Inquire', 'Ignore', 'Suspend')]
        [string]$ErrorAction = 'Stop'
    )
    
    begin {
        # Set up error handling
        $ErrorActionPreference = $ErrorAction
        $operation = $PSCmdlet.MyInvocation.MyCommand.Name
        $startTime = Get-Date
        $results = [System.Collections.Generic.List[Package]]::new()
        
        # Initialize transaction if not already started
        $transaction = $null
        if (-not $script:CurrentTransaction) {
            $transaction = [PackageTransaction]::new()
            $script:CurrentTransaction = $transaction
            $transaction.Log("Started new transaction: $($transaction.Id)")
        }
        
        # Log start of operation
        Write-PSFMessage -Level Verbose -Message "Starting $operation with parameters: $($PSBoundParameters | ConvertTo-Json -Compress)"
        
        # Validate source if provided
        if ($Source) {
            $sourceObj = Get-PackageSource -Name $Source -ErrorAction SilentlyContinue
            if (-not $sourceObj) {
                $errorMessage = "Package source '$Source' not found. Available sources: $($script:PackageSources.Keys -join ', ')"
                Write-PSFMessage -Level Error -Message $errorMessage
                throw $errorMessage
            }
        }
        
        # Set default installation path if not provided
        if (-not $InstallationPath) {
            $InstallationPath = $script:PackageManagerConfig.DefaultInstallLocation
            Write-PSFMessage -Level Verbose -Message "Using default installation path: $InstallationPath"
        }
        
        # Ensure installation directory exists
        if (-not (Test-Path -Path $InstallationPath)) {
            try {
                New-Item -ItemType Directory -Path $InstallationPath -Force | Out-Null
                Write-PSFMessage -Level Verbose -Message "Created installation directory: $InstallationPath"
            }
            catch {
                $errorMessage = "Failed to create installation directory '$InstallationPath': $_"
                Write-PSFMessage -Level Error -Message $errorMessage -ErrorRecord $_
                throw $errorMessage
            }
        }
    }
    
    process {
        foreach ($packageName in $Name) {
            $attempt = 0
            $success = $false
            $package = $null
            
            # Create package object
            $package = [Package]@{
                Name = $packageName
                Version = $Version
                Source = $Source
                IsInstalled = $false
            }
            
            # Start operation in transaction
            $operation = $transaction.StartOperation('Install', $package)
            
            while ($attempt -lt $RetryCount -and -not $success) {
                $attempt++
                $operation.LogMessage("Attempt $attempt of $RetryCount for package '$packageName'")
                
                try {
                    # Build parameters for Install-Package
                    $installParams = @{
                        Name = $packageName
                        Force = $Force
                        ErrorAction = 'Stop'
                        WhatIf = $WhatIf
                        Confirm = $false
                    }
                    
                    # Add optional parameters if specified
                    if ($Version) { $installParams['RequiredVersion'] = $Version }
                    if ($Source) { $installParams['Source'] = $Source }
                    if ($NoDependencies) { $installParams['SkipDependencies'] = $true }
                    
                    # Set installation path if specified
                    if ($InstallationPath) {
                        $installParams['InstallationPath'] = $InstallationPath
                    }
                    
                    # Log the installation attempt
                    $operation.LogMessage("Installing package with parameters: $($installParams | ConvertTo-Json -Compress)")
                    
                    # Skip actual installation in WhatIf mode
                    if ($WhatIf) {
                        $operation.LogMessage("[WhatIf] Would install package: $packageName")
                        $success = $true
                        $package.IsInstalled = $true
                        $operation.Complete()
                        $results.Add($package)
                        continue
                    }
                    
                    # Install the package
                    $installedPkg = Install-Package @installParams
                    
                    # Update package object with installation details
                    $package.InstalledVersion = $installedPkg.Version
                    $package.IsInstalled = $true
                    $package.ProviderName = $installedPkg.ProviderName
                    $package.Description = $installedPkg.Description
                    
                    # Log success
                    $operation.LogMessage("Successfully installed package: $packageName $($package.InstalledVersion)")
                    $operation.Complete()
                    $success = $true
                    $results.Add($package)
                }
                catch {
                    $errorMessage = $_
                    $operation.LogMessage("Attempt $attempt failed: $errorMessage", 'Warning')
                    
                    # If this was the last attempt, log the error and rethrow
                    if ($attempt -ge $RetryCount) {
                        $errorMessage = "Failed to install package '$packageName' after $RetryCount attempts: $errorMessage"
                        $operation.Fail([System.Exception]::new($errorMessage))
                        Write-PSFMessage -Level Error -Message $errorMessage -ErrorRecord $_
                        
                        if ($ErrorAction -eq 'Stop') {
                            throw $errorMessage
                        }
                    }
                    else {
                        # Wait before retrying
                        $operation.LogMessage("Waiting $RetryDelay seconds before retry...")
                        Start-Sleep -Seconds $RetryDelay
                    }
                }
            }
        }
    }
    
    end {
        # Log completion
        $duration = (Get-Date) - $startTime
        Write-PSFMessage -Level Verbose -Message "$operation completed in $($duration.TotalSeconds) seconds"
        
        # Commit the transaction if we started it
        if ($transaction -and $transaction -eq $script:CurrentTransaction) {
            try {
                $transaction.Commit()
                $script:CurrentTransaction = $null
            }
            catch {
                $script:CurrentTransaction = $null
                throw
            }
        }
        
        # Return the results
        return $results
    }
}

# Set up aliases
Set-Alias -Name ipkg -Value Install-DevPackage -Scope Global -Force

# Export the function
Export-ModuleMember -Function Install-DevPackage -Alias ipkg
