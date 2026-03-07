# PSPowerUtils.psm1 - Main module file for PSPowerUtils
# Requires -Version 5.1
#Requires -RunAsAdministrator

# Set strict mode for better coding practices
Set-StrictMode -Version Latest

# Define module variables
$script:ModuleName = 'PSPowerUtils'
$script:ModuleVersion = '1.0.0'
$script:ModuleRoot = $PSScriptRoot
$script:IsLoaded = $false

# Define module directories
$script:CoreDir = Join-Path -Path $script:ModuleRoot -ChildPath 'Core'
$script:SystemDir = Join-Path -Path $script:ModuleRoot -ChildPath 'System'
$script:ProductivityDir = Join-Path -Path $script:ModuleRoot -ChildPath 'Productivity'

# Create required directories if they don't exist
$requiredDirs = @($script:CoreDir, $script:SystemDir, $script:ProductivityDir)
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path -Path $dir)) {
        try {
            New-Item -Path $dir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Verbose "[$($script:ModuleName)] Created directory: $dir"
        }
        catch {
            Write-Error "[$($script:ModuleName)] Failed to create directory '$dir': $_"
            throw
        }
    }
}

# Function to initialize the module
function Initialize-Module {
    [CmdletBinding()]
    param()
    
    if ($script:IsLoaded) {
        Write-Verbose "[$($script:ModuleName)] Module is already initialized"
        return
    }
    
    Write-Verbose "[$($script:ModuleName)] Initializing module..."
    
    try {
        # Import core modules
        $coreModules = @(
            'ErrorHandling.psm1',
            'Performance.psm1',
            'Security.psm1',
            'Productivity.psm1'
        )
        
        foreach ($module in $coreModules) {
            $modulePath = Join-Path -Path $script:CoreDir -ChildPath $module
            if (Test-Path -Path $modulePath) {
                try {
                    Import-Module -Name $modulePath -Force -ErrorAction Stop
                    Write-Verbose "[$($script:ModuleName)] Imported core module: $module"
                }
                catch {
                    Write-Error "[$($script:ModuleName)] Failed to import core module '$module': $_"
                    throw
                }
            }
            else {
                Write-Warning "[$($script:ModuleName)] Core module not found: $modulePath"
            }
        }
        
        # Import system modules
        $systemModules = @(
            'SystemInfo.psm1'
        )
        
        foreach ($module in $systemModules) {
            $modulePath = Join-Path -Path $script:SystemDir -ChildPath $module
            if (Test-Path -Path $modulePath) {
                try {
                    # Import the module
                    Import-Module -Name $modulePath -Force -ErrorAction Stop
                    
                    # Import the module manifest to get the exported functions
                    $manifestPath = [System.IO.Path]::ChangeExtension($modulePath, '.psd1')
                    if (Test-Path -Path $manifestPath) {
                        $manifest = Import-PowerShellDataFile -Path $manifestPath -ErrorAction Stop
                        
                        # Export the functions from this module
                        if ($manifest.FunctionsToExport) {
                            Export-ModuleMember -Function $manifest.FunctionsToExport -ErrorAction SilentlyContinue
                            Write-Verbose "[$($script:ModuleName)] Exported functions from $module: $($manifest.FunctionsToExport -join ', ')"
                        }
                    }
                    
                    Write-Verbose "[$($script:ModuleName)] Imported system module: $module"
                }
                catch {
                    Write-Error "[$($script:ModuleName)] Failed to import system module '$module': $_"
                    throw
                }
            }
            else {
                Write-Warning "[$($script:ModuleName)] System module not found: $modulePath"
            }
        }
        
        # Set module as loaded
        $script:IsLoaded = $true
        Write-Verbose "[$($script:ModuleName)] Module initialization completed successfully"
    }
    catch {
        Write-Error "[$($script:ModuleName)] Failed to initialize module: $_"
        throw
    }
}

# Function to get module status
function Get-ModuleStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    [PSCustomObject]@{
        ModuleName = $script:ModuleName
        ModuleVersion = $script:ModuleVersion
        IsLoaded = $script:IsLoaded
        ModuleRoot = $script:ModuleRoot
        CoreModules = @(Get-ChildItem -Path $script:CoreDir -Filter '*.psm1' -File).Name
        SystemModules = @(Get-ChildItem -Path $script:SystemDir -Filter '*.psm1' -File).Name
        ProductivityModules = @(Get-ChildItem -Path $script:ProductivityDir -Filter '*.psm1' -File).Name
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-ModuleStatus'
)

# Initialize the module when imported
$ExecutionContext.SessionState.Module.OnRemove = {
    Write-Verbose "[$($script:ModuleName)] Module is being unloaded"
    $script:IsLoaded = $false
}

# Initialize the module
Initialize-Module
