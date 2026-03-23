<#
.SYNOPSIS
    Golden Image Application Installation Module

.DESCRIPTION
    Handles application installation via Chocolatey and Winget

.NOTES
    Extracted from Create-GoldenImage.ps1 for modularization
#>

function Install-GIChocolatey {
    <#
    .SYNOPSIS
        Installs Chocolatey if not already installed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Logger
    )
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $Logger.Write('INFO', 'Chocolatey is already installed.')
        return
    }
    
    $Logger.Write('INFO', 'Installing Chocolatey...')
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $Logger.Write('INFO', 'Chocolatey installed successfully.')
    } else {
        throw "Failed to install Chocolatey."
    }
}

function Install-ChocoPackageGroup {
    <#
    .SYNOPSIS
        Installs a group of Chocolatey packages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages,
        
        [Parameter(Mandatory)]
        [object]$Logger
    )
    
    foreach ($package in $Packages) {
        try {
            $Logger.Write('INFO', "Installing Chocolatey package: $package")
            choco install $package -y --no-progress
            if ($LASTEXITCODE -eq 0) {
                $Logger.Write('INFO', "Successfully installed: $package")
            } else {
                $Logger.Write('WARN', "Failed to install: $package")
            }
        } catch {
            $Logger.Write('WARN', "Error installing $package : $_")
        }
    }
}

function Install-WingetPackageGroup {
    <#
    .SYNOPSIS
        Installs a group of Winget packages
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages,
        
        [Parameter(Mandatory)]
        [object]$Logger
    )
    
    foreach ($package in $Packages) {
        try {
            $Logger.Write('INFO', "Installing Winget package: $package")
            winget install --id $package --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                $Logger.Write('INFO', "Successfully installed: $package")
            } else {
                $Logger.Write('WARN', "Failed to install: $package")
            }
        } catch {
            $Logger.Write('WARN', "Error installing $package : $_")
        }
    }
}

function Invoke-GIAppInstall {
    <#
    .SYNOPSIS
        Main application installation function
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,
        
        [Parameter(Mandatory)]
        [object]$Logger
    )
    
    if (-not $Config.Apps) {
        $Logger.Write('INFO', 'No application configuration found. Skipping app installation.')
        return
    }
    
    # Install Chocolatey if needed
    if ($Config.Apps.UseChocolatey) {
        Install-GIChocolatey -Logger $Logger
    }
    
    # Install Chocolatey packages
    if ($Config.Apps.ChocolateyPackages) {
        $allPackages = @()
        if ($Config.Apps.ChocolateyPackages.Dev) {
            $allPackages += $Config.Apps.ChocolateyPackages.Dev
        }
        if ($Config.Apps.ChocolateyPackages.Gaming) {
            $allPackages += $Config.Apps.ChocolateyPackages.Gaming
        }
        if ($Config.Apps.ChocolateyPackages.Utilities) {
            $allPackages += $Config.Apps.ChocolateyPackages.Utilities
        }
        
        if ($allPackages.Count -gt 0) {
            Install-ChocoPackageGroup -Packages $allPackages -Logger $Logger
        }
    }
    
    # Install Winget packages
    if ($Config.Apps.WingetPackages) {
        $allPackages = @()
        if ($Config.Apps.WingetPackages.Dev) {
            $allPackages += $Config.Apps.WingetPackages.Dev
        }
        if ($Config.Apps.WingetPackages.Gaming) {
            $allPackages += $Config.Apps.WingetPackages.Gaming
        }
        if ($Config.Apps.WingetPackages.Utilities) {
            $allPackages += $Config.Apps.WingetPackages.Utilities
        }
        
        if ($allPackages.Count -gt 0) {
            Install-WingetPackageGroup -Packages $allPackages -Logger $Logger
        }
    }
}

Export-ModuleMember -Function @(
    'Install-GIChocolatey',
    'Install-ChocoPackageGroup',
    'Install-WingetPackageGroup',
    'Invoke-GIAppInstall'
)

