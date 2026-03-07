function Update-DevPackage {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByName')]
    [OutputType([Package[]])]
    param (
        [Parameter(ParameterSetName = 'ByName',
                  Position = 0,
                  ValueFromPipeline = $true,
                  ValueFromPipelineByPropertyName = $true)]
        [string[]]$Name = '*',
        
        [Parameter(ParameterSetName = 'ByPackage',
                 ValueFromPipeline = $true)]
        [Package[]]$Package,
        
        [Parameter()]
        [string]$Source,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$RetryDelay = 5,
        
        [Parameter()]
        [switch]$Force,
        
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
    }
    
    process {
        try {
            # Handle pipeline input
            if ($PSCmdlet.ParameterSetName -eq 'ByPackage') {
                $packagesToUpdate = $Package
            }
            else {
                # Get installed packages matching the name pattern
                $packagesToUpdate = Get-InstalledPackages -Name $Name -Source $Source -ErrorAction Stop
            }
            
            if (-not $packagesToUpdate) {
                Write-PSFMessage -Level Warning -Message "No packages found matching the specified criteria"
                return
            }
            
            foreach ($pkg in $packagesToUpdate) {
                $attempt = 0
                $success = $false
                
                # Create a package object for the update
                $package = [Package]@{
                    Name = $pkg.Name
                    Version = $pkg.Version
                    Source = $pkg.Source
                    ProviderName = $pkg.ProviderName
                    IsInstalled = $true
                }
                
                # Start operation in transaction
                $operation = $transaction.StartOperation('Update', $package)
                
                while ($attempt -lt $RetryCount -and -not $success) {
                    $attempt++
                    $operation.LogMessage("Attempt $attempt of $RetryCount for package '$($package.Name)'")
                    
                    try {
                        # Build parameters for Update-Package
                        $updateParams = @{
                            Name = $package.Name
                            Force = $Force
                            ErrorAction = 'Stop'
                            WhatIf = $WhatIf
                            Confirm = $false
                        }
                        
                        # Add optional parameters if specified
                        if ($Source) { $updateParams['Source'] = $Source }
                        
                        # Log the update attempt
                        $operation.LogMessage("Updating package with parameters: $($updateParams | ConvertTo-Json -Compress)")
                        
                        # Skip actual update in WhatIf mode
                        if ($WhatIf) {
                            $operation.LogMessage("[WhatIf] Would update package: $($package.Name)")
                            $package.IsInstalled = $true
                            $operation.Complete()
                            $results.Add($package)
                            $success = $true
                            continue
                        }
                        
                        # Update the package
                        $updatedPkg = Update-Package @updateParams
                        
                        # Update package object with new version
                        $package.InstalledVersion = $updatedPkg.Version
                        $package.IsInstalled = $true
                        $package.ProviderName = $updatedPkg.ProviderName
                        
                        # Log success
                        $operation.LogMessage("Successfully updated package: $($package.Name) to version $($package.InstalledVersion)")
                        $operation.Complete()
                        $results.Add($package)
                        $success = $true
                    }
                    catch {
                        $errorMessage = $_
                        $operation.LogMessage("Attempt $attempt failed: $errorMessage", 'Warning')
                        
                        # If this was the last attempt, log the error and rethrow
                        if ($attempt -ge $RetryCount) {
                            $errorMessage = "Failed to update package '$($package.Name)' after $RetryCount attempts: $errorMessage"
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
        catch {
            $errorMessage = "Error in $operation : $_"
            Write-PSFMessage -Level Error -Message $errorMessage -ErrorRecord $_
            throw $errorMessage
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
Set-Alias -Name upkg -Value Update-DevPackage -Scope Global -Force

# Export the function
Export-ModuleMember -Function Update-DevPackage -Alias upkg
