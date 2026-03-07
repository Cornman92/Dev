# PackageManager.Classes.ps1
# Base classes for PackageManager module

class PackageSource {
    [string]$Name
    [string]$Location
    [string]$ProviderName
    [bool]$IsTrusted
    [bool]$IsRegistered
    [hashtable]$AdditionalParameters = @{}

    PackageSource([string]$Name, [string]$Location, [string]$ProviderName) {
        $this.Name = $Name
        $this.Location = $Location
        $this.ProviderName = $ProviderName
        $this.IsTrusted = $true
        $this.IsRegistered = $false
    }

    [void] Register() {
        try {
            $registerParams = @{
                Name = $this.Name
                Location = $this.Location
                ProviderName = $this.ProviderName
                Force = $true
                ErrorAction = 'Stop'
            }
            
            # Add additional parameters if any
            foreach ($key in $this.AdditionalParameters.Keys) {
                $registerParams[$key] = $this.AdditionalParameters[$key]
            }
            
            Register-PackageSource @registerParams | Out-Null
            $this.IsRegistered = $true
            Write-PSFMessage -Level Verbose -Message "Successfully registered package source: $($this.Name)"
        }
        catch {
            Write-PSFMessage -Level Error -Message "Failed to register package source $($this.Name): $_" -ErrorRecord $_
            throw
        }
    }

    [void] Unregister() {
        try {
            Unregister-PackageSource -Name $this.Name -Force -ErrorAction Stop
            $this.IsRegistered = $false
            Write-PSFMessage -Level Verbose -Message "Successfully unregistered package source: $($this.Name)"
        }
        catch {
            Write-PSFMessage -Level Warning -Message "Failed to unregister package source $($this.Name): $_" -ErrorRecord $_
        }
    }
}

class Package {
    [string]$Name
    [string]$Version
    [string]$Source
    [string]$ProviderName
    [string]$Description
    [bool]$IsInstalled
    [string]$InstalledVersion
    [string]$LatestVersion
    [PackageDependency[]]$Dependencies = @()
    [hashtable]$Metadata = @{}

    Package([string]$Name, [string]$Version, [string]$Source) {
        $this.Name = $Name
        $this.Version = $Version
        $this.Source = $Source
    }

    [string] ToString() {
        return "$($this.Name)@$($this.Version) [$($this.Source)]"
    }
}

class PackageDependency {
    [string]$Name
    [string]$Version
    [string]$Source
    [string]$Type = 'default'  # 'default', 'dev', 'optional', 'peer'

    PackageDependency([string]$Name, [string]$Version, [string]$Source) {
        $this.Name = $Name
        $this.Version = $Version
        $this.Source = $Source
    }

    [string] ToString() {
        return "$($this.Name)@$($this.Version) [$($this.Source)]"
    }
}

class PackageOperation {
    [string]$Operation
    [Package]$Package
    [string]$Status = 'Pending'
    [datetime]$StartTime
    [datetime]$EndTime
    [bool]$Success = $false
    [System.Exception]$Error
    [hashtable]$Parameters = @{}
    [System.Collections.Generic.List[object]]$Logs = [System.Collections.Generic.List[object]]::new()

    PackageOperation([string]$Operation, [Package]$Package) {
        $this.Operation = $Operation
        $this.Package = $Package
        $this.StartTime = [datetime]::UtcNow
    }

    [void] LogMessage([string]$Message, [string]$Level = 'Info') {
        $logEntry = @{
            Timestamp = [datetime]::UtcNow
            Level = $Level
            Message = $Message
        }
        $this.Logs.Add($logEntry)
        
        # Also log to PSFramework if available
        if (Get-Command -Name 'Write-PSFMessage' -ErrorAction SilentlyContinue) {
            Write-PSFMessage -Level $Level -Message $Message
        }
    }

    [void] Complete() {
        $this.EndTime = [datetime]::UtcNow
        $this.Success = $true
        $this.Status = 'Completed'
        $this.LogMessage("Operation '$($this.Operation)' completed successfully for package '$($this.Package)'")
    }

    [void] Fail([System.Exception]$Error) {
        $this.EndTime = [datetime]::UtcNow
        $this.Success = $false
        $this.Status = 'Failed'
        $this.Error = $Error
        $this.LogMessage("Operation '$($this.Operation)' failed for package '$($this.Package)': $($Error.Message)", 'Error')
    }
}

class PackageTransaction {
    [string]$Id = (New-Guid).Guid
    [System.Collections.Generic.List[PackageOperation]]$Operations = [System.Collections.Generic.List[PackageOperation]]::new()
    [datetime]$StartTime = [datetime]::UtcNow
    [datetime]$EndTime
    [bool]$IsCommitted = $false
    [bool]$IsRolledBack = $false
    [hashtable]$Context = @{}

    [PackageOperation] StartOperation([string]$Operation, [Package]$Package) {
        $op = [PackageOperation]::new($Operation, $Package)
        $this.Operations.Add($op)
        $op.LogMessage("Started operation: $Operation")
        return $op
    }

    [void] Commit() {
        try {
            $this.Log("Committing transaction $($this.Id)")
            
            # Execute all operations
            foreach ($op in $this.Operations) {
                try {
                    $op.LogMessage("Executing operation")
                    # Here you would implement the actual operation execution
                    # For now, we'll just mark it as completed
                    $op.Complete()
                }
                catch {
                    $op.Fail($_)
                    throw [System.Exception]::new("Failed to execute operation: $($op.Operation)", $_)
                }
            }
            
            $this.IsCommitted = $true
            $this.EndTime = [datetime]::UtcNow
            $this.Log("Transaction committed successfully")
        }
        catch {
            $this.Log("Error during transaction commit: $_", 'Error')
            $this.Rollback()
            throw
        }
    }

    [void] Rollback() {
        if ($this.IsRolledBack) {
            $this.Log("Transaction already rolled back", 'Warning')
            return
        }

        $this.Log("Starting rollback of transaction $($this.Id)")
        
        # Roll back operations in reverse order
        for ($i = $this.Operations.Count - 1; $i -ge 0; $i--) {
            $op = $this.Operations[$i]
            if ($op.Success) {
                try {
                    $op.LogMessage("Rolling back operation")
                    # Here you would implement the actual rollback logic
                    $op.LogMessage("Rollback completed for operation")
                }
                catch {
                    $op.LogMessage("Error during rollback: $_", 'Error')
                    # Continue with next operation even if rollback fails for one
                }
            }
        }
        
        $this.IsRolledBack = $true
        $this.EndTime = [datetime]::UtcNow
        $this.Log("Transaction rollback completed")
    }

    [void] Log([string]$Message, [string]$Level = 'Info') {
        $timestamp = [datetime]::UtcNow.ToString('o')
        $logMessage = "[$timestamp] [$Level] $Message"
        
        if (Get-Command -Name 'Write-PSFMessage' -ErrorAction SilentlyContinue) {
            Write-PSFMessage -Level $Level -Message $Message
        }
        else {
            Write-Host $logMessage
        }
    }
}

# Export the classes for use in other scripts
Export-ModuleMember -Function * -Alias * -Variable * -Class 'PackageSource', 'Package', 'PackageDependency', 'PackageOperation', 'PackageTransaction'
