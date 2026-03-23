<#
.SYNOPSIS
    Better11.Install - Package installation abstraction for Better11 Suite

.DESCRIPTION
    Provides package installation functionality with support for multiple package managers
    (Winget, Chocolatey, Scoop) and custom installers. Integrates with Core-AutoSuite
    and Better11.Core for logging and error handling.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Better11.Install'
#endregion

#region Module Initialization
# Import Better11.Core for common functionality
$better11CorePath = Join-Path $PSScriptRoot 'Better11.Core.psm1'
if (Test-Path $better11CorePath) {
    try {
        Import-Module $better11CorePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not import Better11.Core: $_"
    }
}

# Try to import Core-AutoSuite if available
$coreAutoSuitePath = Join-Path $PSScriptRoot '..\..\Windows-Automation-Station\workflows\Core\Core-AutoSuite.psm1'
if (Test-Path $coreAutoSuitePath) {
    try {
        Import-Module $coreAutoSuitePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not import Core-AutoSuite: $_"
    }
}
#endregion

#region Package Manager Detection

function Get-AvailablePackageManagers {
    <#
    .SYNOPSIS
        Gets list of available package managers on the system
    
    .DESCRIPTION
        Detects which package managers (Winget, Chocolatey, Scoop) are installed
        and available for use.
    
    .EXAMPLE
        Get-AvailablePackageManagers
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    $managers = @{
        Winget = $false
        Chocolatey = $false
        Scoop = $false
    }
    
    # Check Winget
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        try {
            $version = & winget --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $managers.Winget = $true
                $managers.WingetVersion = $version
            }
        }
        catch {
            # Winget not available
        }
    }
    
    # Check Chocolatey
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if ($choco) {
        try {
            $version = & choco --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $managers.Chocolatey = $true
                $managers.ChocolateyVersion = $version
            }
        }
        catch {
            # Chocolatey not available
        }
    }
    
    # Check Scoop
    $scoop = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoop) {
        try {
            $version = & scoop --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $managers.Scoop = $true
                $managers.ScoopVersion = $version
            }
        }
        catch {
            # Scoop not available
        }
    }
    
    return $managers
}

#endregion

#region Package Installation

function Install-Better11Package {
    <#
    .SYNOPSIS
        Installs a package using the specified package manager
    
    .DESCRIPTION
        Installs a package using Winget, Chocolatey, Scoop, or a custom installer.
        Supports retry logic and comprehensive error handling.
    
    .PARAMETER PackageName
        Name or ID of the package to install
    
    .PARAMETER Method
        Package manager to use (Winget, Chocolatey, Scoop, Custom)
    
    .PARAMETER CustomInstallerPath
        Path to custom installer executable (required if Method is Custom)
    
    .PARAMETER CustomInstallerArgs
        Arguments to pass to custom installer
    
    .PARAMETER RetryCount
        Number of retry attempts on failure
    
    .PARAMETER RetryDelaySeconds
        Delay between retries in seconds
    
    .PARAMETER WhatIf
        Show what would be installed without actually installing
    
    .EXAMPLE
        Install-Better11Package -PackageName 'Google.Chrome' -Method 'Winget'
    
    .EXAMPLE
        Install-Better11Package -PackageName 'notepadplusplus' -Method 'Chocolatey' -RetryCount 3
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop', 'Custom')]
        [string]$Method = 'Winget',
        
        [Parameter()]
        [string]$CustomInstallerPath,
        
        [Parameter()]
        [hashtable]$CustomInstallerArgs = @{},
        
        [Parameter()]
        [int]$RetryCount = 0,
        
        [Parameter()]
        [int]$RetryDelaySeconds = 5,
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    # Use Core-AutoSuite if available
    if (Get-Command 'Install-AutoSuitePackage' -ErrorAction SilentlyContinue) {
        $logger = $null
        if (Get-Variable -Name 'script:Logger' -ErrorAction SilentlyContinue) {
            $logger = $script:Logger
        }
        
        if ($WhatIf) {
            Write-Host "WhatIf: Would install $PackageName via $Method"
            return $true
        }
        
        return Install-AutoSuitePackage -PackageName $PackageName -Method $Method `
            -CustomInstallerPath $CustomInstallerPath -CustomInstallerArgs $CustomInstallerArgs -Logger $logger
    }
    
    # Fallback implementation
    $actionName = "Install Package: $PackageName via $Method"
    
    if ($WhatIf) {
        Write-Host "WhatIf: Would install $PackageName via $Method"
        return $true
    }
    
    if ($PSCmdlet.ShouldProcess($PackageName, "Install package via $Method")) {
        if (Get-Command 'Invoke-Better11Action' -ErrorAction SilentlyContinue) {
            return Invoke-Better11Action -Name $actionName -Action {
                Install-Better11PackageInternal -PackageName $PackageName -Method $Method `
                    -CustomInstallerPath $CustomInstallerPath -CustomInstallerArgs $CustomInstallerArgs
            } -RetryCount $RetryCount -RetryDelaySeconds $RetryDelaySeconds
        }
        else {
            return Install-Better11PackageInternal -PackageName $PackageName -Method $Method `
                -CustomInstallerPath $CustomInstallerPath -CustomInstallerArgs $CustomInstallerArgs
        }
    }
    
    return $false
}

function Install-Better11PackageInternal {
    <#
    .SYNOPSIS
        Internal function to perform package installation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter(Mandatory)]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop', 'Custom')]
        [string]$Method,
        
        [Parameter()]
        [string]$CustomInstallerPath,
        
        [Parameter()]
        [hashtable]$CustomInstallerArgs = @{}
    )
    
    try {
        switch ($Method) {
            'Winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    throw "Winget is not installed or not in PATH"
                }
                
                Write-Verbose "Installing $PackageName via Winget"
                $output = & winget install --id $PackageName --silent --accept-package-agreements --accept-source-agreements 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    $errorOutput = $output | Out-String
                    throw "Winget installation failed with exit code $LASTEXITCODE : $errorOutput"
                }
                
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'INFO' -Message "Successfully installed $PackageName via Winget"
                }
                return $true
            }
            
            'Chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    throw "Chocolatey is not installed or not in PATH"
                }
                
                Write-Verbose "Installing $PackageName via Chocolatey"
                $output = & choco install $PackageName -y 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    $errorOutput = $output | Out-String
                    throw "Chocolatey installation failed with exit code $LASTEXITCODE : $errorOutput"
                }
                
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'INFO' -Message "Successfully installed $PackageName via Chocolatey"
                }
                return $true
            }
            
            'Scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    throw "Scoop is not installed or not in PATH"
                }
                
                Write-Verbose "Installing $PackageName via Scoop"
                $output = & scoop install $PackageName 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    $errorOutput = $output | Out-String
                    throw "Scoop installation failed with exit code $LASTEXITCODE : $errorOutput"
                }
                
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'INFO' -Message "Successfully installed $PackageName via Scoop"
                }
                return $true
            }
            
            'Custom' {
                if (-not $CustomInstallerPath) {
                    throw "CustomInstallerPath is required when Method is Custom"
                }
                
                if (-not (Test-Path $CustomInstallerPath)) {
                    throw "Custom installer not found: $CustomInstallerPath"
                }
                
                Write-Verbose "Installing $PackageName via custom installer: $CustomInstallerPath"
                
                $processArgs = @()
                foreach ($key in $CustomInstallerArgs.Keys) {
                    $processArgs += "/$key"
                    $processArgs += $CustomInstallerArgs[$key]
                }
                
                $process = Start-Process -FilePath $CustomInstallerPath -ArgumentList $processArgs -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -ne 0) {
                    throw "Custom installer failed with exit code $($process.ExitCode)"
                }
                
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'INFO' -Message "Successfully installed $PackageName via custom installer"
                }
                return $true
            }
        }
    }
    catch {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'ERROR' -Message "Failed to install $PackageName via $Method : $_"
        }
        Write-Error "Failed to install $PackageName via $Method : $_"
        throw
    }
}

#endregion

#region Package Query

function Test-Better11PackageInstalled {
    <#
    .SYNOPSIS
        Checks if a package is installed
    
    .DESCRIPTION
        Checks if a package is installed using the specified package manager.
    
    .PARAMETER PackageName
        Name or ID of the package to check
    
    .PARAMETER Method
        Package manager to use for checking
    
    .EXAMPLE
        Test-Better11PackageInstalled -PackageName 'Google.Chrome' -Method 'Winget'
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop', 'Custom')]
        [string]$Method = 'Winget'
    )
    
    # Use Core-AutoSuite if available
    if (Get-Command 'Test-AutoSuitePackageInstalled' -ErrorAction SilentlyContinue) {
        return Test-AutoSuitePackageInstalled -PackageName $PackageName -Method $Method
    }
    
    try {
        switch ($Method) {
            'Winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    return $false
                }
                
                $result = & winget list --id $PackageName 2>&1
                return $LASTEXITCODE -eq 0 -and ($result -match $PackageName)
            }
            
            'Chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    return $false
                }
                
                $result = & choco list --local-only $PackageName 2>&1
                return ($result -match $PackageName) -and ($LASTEXITCODE -eq 0)
            }
            
            'Scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    return $false
                }
                
                $result = & scoop list $PackageName 2>&1
                return ($result -match $PackageName) -and ($LASTEXITCODE -eq 0)
            }
            
            'Custom' {
                # Custom check logic would need to be implemented per-installer
                Write-Warning "Custom package check not implemented"
                return $false
            }
        }
    }
    catch {
        Write-Verbose "Error checking package installation: $_"
        return $false
    }
}

function Get-Better11PackageInfo {
    <#
    .SYNOPSIS
        Gets information about a package
    
    .DESCRIPTION
        Retrieves information about a package from the specified package manager.
    
    .PARAMETER PackageName
        Name or ID of the package
    
    .PARAMETER Method
        Package manager to query
    
    .EXAMPLE
        Get-Better11PackageInfo -PackageName 'Google.Chrome' -Method 'Winget'
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop')]
        [string]$Method = 'Winget'
    )
    
    $info = @{
        Name = $PackageName
        Method = $Method
        Installed = $false
        Version = $null
        Available = $false
    }
    
    try {
        switch ($Method) {
            'Winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    return $info
                }
                
                # Check if installed
                $installed = Test-Better11PackageInstalled -PackageName $PackageName -Method 'Winget'
                $info.Installed = $installed
                
                # Get package info
                $result = & winget show --id $PackageName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $info.Available = $true
                    # Parse version from output
                    if ($result -match 'Version:\s+(\S+)') {
                        $info.Version = $matches[1]
                    }
                }
            }
            
            'Chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    return $info
                }
                
                $installed = Test-Better11PackageInstalled -PackageName $PackageName -Method 'Chocolatey'
                $info.Installed = $installed
                
                $result = & choco info $PackageName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $info.Available = $true
                    if ($result -match '(\d+\.\d+\.\d+)') {
                        $info.Version = $matches[1]
                    }
                }
            }
            
            'Scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    return $info
                }
                
                $installed = Test-Better11PackageInstalled -PackageName $PackageName -Method 'Scoop'
                $info.Installed = $installed
                
                $result = & scoop info $PackageName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $info.Available = $true
                    if ($result -match 'Version:\s+(\S+)') {
                        $info.Version = $matches[1]
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Error getting package info: $_"
    }
    
    return $info
}

#endregion

#region Batch Operations

function Install-Better11Packages {
    <#
    .SYNOPSIS
        Installs multiple packages
    
    .DESCRIPTION
        Installs multiple packages with support for concurrent installation
        and progress tracking.
    
    .PARAMETER Packages
        Array of package names or hashtables with PackageName and Method
    
    .PARAMETER Method
        Default package manager to use if not specified per-package
    
    .PARAMETER MaxConcurrency
        Maximum number of concurrent installations
    
    .PARAMETER WhatIf
        Show what would be installed without actually installing
    
    .EXAMPLE
        Install-Better11Packages -Packages @('Google.Chrome', 'Mozilla.Firefox') -Method 'Winget'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [array]$Packages,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop', 'Custom')]
        [string]$Method = 'Winget',
        
        [Parameter()]
        [int]$MaxConcurrency = 3,
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    $results = @{
        Successful = @()
        Failed = @()
        Total = $Packages.Count
    }
    
    if ($WhatIf) {
        Write-Host "WhatIf: Would install $($Packages.Count) packages via $Method"
        foreach ($package in $Packages) {
            $packageName = if ($package -is [hashtable]) { $package.PackageName } else { $package }
            Write-Host "  - $packageName"
        }
        return $results
    }
    
    $jobs = @()
    $completed = 0
    
    foreach ($package in $Packages) {
        $packageName = if ($package -is [hashtable]) { $package.PackageName } else { $package }
        $packageMethod = if ($package -is [hashtable] -and $package.Method) { $package.Method } else { $Method }
        
        # Wait if we've reached max concurrency
        while ($jobs.Count -ge $MaxConcurrency) {
            $jobs = $jobs | Where-Object { $_.State -eq 'Running' }
            Start-Sleep -Milliseconds 100
        }
        
        $job = Start-Job -ScriptBlock {
            param($Name, $Meth)
            Import-Module $using:PSScriptRoot\Better11.Install.psm1 -Force
            try {
                Install-Better11Package -PackageName $Name -Method $Meth -ErrorAction Stop
                return @{ Success = $true; Package = $Name }
            }
            catch {
                return @{ Success = $false; Package = $Name; Error = $_.Exception.Message }
            }
        } -ArgumentList $packageName, $packageMethod
        
        $jobs += $job
    }
    
    # Wait for all jobs to complete
    $jobs | Wait-Job | Out-Null
    
    # Collect results
    foreach ($job in $jobs) {
        $result = Receive-Job $job
        if ($result.Success) {
            $results.Successful += $result.Package
        }
        else {
            $results.Failed += @{
                Package = $result.Package
                Error = $result.Error
            }
        }
        Remove-Job $job
    }
    
    return $results
}

#endregion

#region Package Updates & Management

function Update-Better11Package {
    <#
    .SYNOPSIS
        Updates an installed package
    
    .DESCRIPTION
        Updates a package to the latest version using the specified package manager.
    
    .PARAMETER PackageName
        Name or ID of the package to update
    
    .PARAMETER Method
        Package manager to use
    
    .PARAMETER WhatIf
        Show what would be updated without actually updating
    
    .EXAMPLE
        Update-Better11Package -PackageName 'Google.Chrome' -Method 'Winget'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop')]
        [string]$Method = 'Winget',
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    if ($WhatIf) {
        Write-Host "WhatIf: Would update $PackageName via $Method"
        return $true
    }
    
    if ($PSCmdlet.ShouldProcess($PackageName, "Update package via $Method")) {
        try {
            switch ($Method) {
                'Winget' {
                    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                        throw "Winget is not installed or not in PATH"
                    }
                    
                    $output = & winget upgrade --id $PackageName --silent --accept-package-agreements --accept-source-agreements 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Winget update failed with exit code $LASTEXITCODE"
                    }
                }
                
                'Chocolatey' {
                    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                        throw "Chocolatey is not installed or not in PATH"
                    }
                    
                    $output = & choco upgrade $PackageName -y 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Chocolatey update failed with exit code $LASTEXITCODE"
                    }
                }
                
                'Scoop' {
                    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                        throw "Scoop is not installed or not in PATH"
                    }
                    
                    $output = & scoop update $PackageName 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Scoop update failed with exit code $LASTEXITCODE"
                    }
                }
            }
            
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'INFO' -Message "Successfully updated $PackageName via $Method"
            }
            return $true
        }
        catch {
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'ERROR' -Message "Failed to update $PackageName via $Method : $_"
            }
            Write-Error "Failed to update $PackageName via $Method : $_"
            throw
        }
    }
    
    return $false
}

function Uninstall-Better11Package {
    <#
    .SYNOPSIS
        Uninstalls a package
    
    .DESCRIPTION
        Uninstalls a package using the specified package manager.
    
    .PARAMETER PackageName
        Name or ID of the package to uninstall
    
    .PARAMETER Method
        Package manager to use
    
    .PARAMETER WhatIf
        Show what would be uninstalled without actually uninstalling
    
    .EXAMPLE
        Uninstall-Better11Package -PackageName 'Google.Chrome' -Method 'Winget'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop')]
        [string]$Method = 'Winget',
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    if ($WhatIf) {
        Write-Host "WhatIf: Would uninstall $PackageName via $Method"
        return $true
    }
    
    if ($PSCmdlet.ShouldProcess($PackageName, "Uninstall package via $Method")) {
        try {
            switch ($Method) {
                'Winget' {
                    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                        throw "Winget is not installed or not in PATH"
                    }
                    
                    $output = & winget uninstall --id $PackageName --silent 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Winget uninstall failed with exit code $LASTEXITCODE"
                    }
                }
                
                'Chocolatey' {
                    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                        throw "Chocolatey is not installed or not in PATH"
                    }
                    
                    $output = & choco uninstall $PackageName -y 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Chocolatey uninstall failed with exit code $LASTEXITCODE"
                    }
                }
                
                'Scoop' {
                    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                        throw "Scoop is not installed or not in PATH"
                    }
                    
                    $output = & scoop uninstall $PackageName 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Scoop uninstall failed with exit code $LASTEXITCODE"
                    }
                }
            }
            
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'INFO' -Message "Successfully uninstalled $PackageName via $Method"
            }
            return $true
        }
        catch {
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'ERROR' -Message "Failed to uninstall $PackageName via $Method : $_"
            }
            Write-Error "Failed to uninstall $PackageName via $Method : $_"
            throw
        }
    }
    
    return $false
}

function Get-Better11PackageUpdates {
    <#
    .SYNOPSIS
        Gets list of packages with available updates
    
    .DESCRIPTION
        Checks for available updates for installed packages.
    
    .PARAMETER Method
        Package manager to check
    
    .EXAMPLE
        Get-Better11PackageUpdates -Method 'Winget'
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop')]
        [string]$Method = 'Winget'
    )
    
    $updates = @()
    
    try {
        switch ($Method) {
            'Winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    return $updates
                }
                
                $output = & winget upgrade 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Parse winget output (simplified - would need more robust parsing)
                    $lines = $output | Where-Object { $_ -match '^\s+\S+\s+\S+\s+\S+\s+\S+' }
                    foreach ($line in $lines) {
                        if ($line -match '(\S+)\s+(\S+)\s+(\S+)\s+(\S+)') {
                            $updates += [PSCustomObject]@{
                                PackageName = $matches[1]
                                InstalledVersion = $matches[2]
                                AvailableVersion = $matches[3]
                                Source = $matches[4]
                                Method = 'Winget'
                            }
                        }
                    }
                }
            }
            
            'Chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    return $updates
                }
                
                $output = & choco outdated 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Parse chocolatey output
                    $lines = $output | Where-Object { $_ -match '^\S+\s+\|\s+\S+\s+\|\s+\S+' }
                    foreach ($line in $lines) {
                        if ($line -match '(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)') {
                            $updates += [PSCustomObject]@{
                                PackageName = $matches[1]
                                InstalledVersion = $matches[2]
                                AvailableVersion = $matches[3]
                                Source = 'Chocolatey'
                                Method = 'Chocolatey'
                            }
                        }
                    }
                }
            }
            
            'Scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    return $updates
                }
                
                $output = & scoop status 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Parse scoop output
                    $lines = $output | Where-Object { $_ -match '^\s+\S+:\s+\S+\s+->\s+\S+' }
                    foreach ($line in $lines) {
                        if ($line -match '(\S+):\s+(\S+)\s+->\s+(\S+)') {
                            $updates += [PSCustomObject]@{
                                PackageName = $matches[1]
                                InstalledVersion = $matches[2]
                                AvailableVersion = $matches[3]
                                Source = 'Scoop'
                                Method = 'Scoop'
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Error checking for updates: $_"
    }
    
    return $updates
}

function Search-Better11Package {
    <#
    .SYNOPSIS
        Searches for packages
    
    .DESCRIPTION
        Searches for packages in the specified package manager repository.
    
    .PARAMETER Query
        Search query
    
    .PARAMETER Method
        Package manager to search
    
    .PARAMETER Limit
        Maximum number of results to return
    
    .EXAMPLE
        Search-Better11Package -Query 'chrome' -Method 'Winget'
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        
        [Parameter()]
        [ValidateSet('Winget', 'Chocolatey', 'Scoop')]
        [string]$Method = 'Winget',
        
        [Parameter()]
        [int]$Limit = 20
    )
    
    $results = @()
    
    try {
        switch ($Method) {
            'Winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    return $results
                }
                
                $output = & winget search $Query --limit $Limit 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Parse winget search output (simplified)
                    $lines = $output | Where-Object { $_ -match '^\s+\S+\s+\S+\s+\S+' }
                    foreach ($line in $lines) {
                        if ($line -match '(\S+)\s+(\S+)\s+(\S+)') {
                            $results += [PSCustomObject]@{
                                PackageName = $matches[1]
                                Id = $matches[1]
                                Version = $matches[2]
                                Source = $matches[3]
                                Method = 'Winget'
                            }
                        }
                    }
                }
            }
            
            'Chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    return $results
                }
                
                $output = & choco search $Query --limit-output 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $packages = $output | Where-Object { $_ -notmatch '^Chocolatey' }
                    foreach ($package in $packages) {
                        $results += [PSCustomObject]@{
                            PackageName = $package.Trim()
                            Id = $package.Trim()
                            Version = $null
                            Source = 'Chocolatey'
                            Method = 'Chocolatey'
                        }
                    }
                }
            }
            
            'Scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    return $results
                }
                
                $output = & scoop search $Query 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $lines = $output | Where-Object { $_ -match '^\s+\S+' }
                    foreach ($line in $lines) {
                        $packageName = $line.Trim()
                        $results += [PSCustomObject]@{
                            PackageName = $packageName
                            Id = $packageName
                            Version = $null
                            Source = 'Scoop'
                            Method = 'Scoop'
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Error searching packages: $_"
    }
    
    return $results
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-AvailablePackageManagers',
    'Install-Better11Package',
    'Test-Better11PackageInstalled',
    'Get-Better11PackageInfo',
    'Install-Better11Packages',
    'Update-Better11Package',
    'Uninstall-Better11Package',
    'Get-Better11PackageUpdates',
    'Search-Better11Package'
)
