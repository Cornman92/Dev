<#
.SYNOPSIS
    Module Template - Template for creating new PowerShell modules

.DESCRIPTION
    This is a template file for creating new PowerShell modules in the Dev workspace.
    Copy this file and customize it for your specific module needs.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Template Version: 1.0.0
#>

#region Module Variables

# Module-level variables
$script:ModuleConfig = @{}
$script:LogPath = $null

#endregion

#region Module Initialization

function Initialize-ModuleConfig {
    <#
    .SYNOPSIS
        Initialize module configuration
    #>
    [CmdletBinding()]
    param()
    
    # Load configuration from file or set defaults
    $configPath = Join-Path $PSScriptRoot 'config.json'
    if (Test-Path $configPath) {
        try {
            $script:ModuleConfig = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
        } catch {
            Write-Warning "Failed to load config from $configPath, using defaults"
            $script:ModuleConfig = @{
                DefaultValue = 'default'
            }
        }
    } else {
        $script:ModuleConfig = @{
            DefaultValue = 'default'
        }
    }
}

# Initialize on module import
Initialize-ModuleConfig

#endregion

#region Public Functions

function Get-ModuleFunction1 {
    <#
    .SYNOPSIS
        Brief description of function
    
    .DESCRIPTION
        Detailed description of what the function does, parameters, and return values.
    
    .PARAMETER Parameter1
        Description of parameter1
    
    .PARAMETER Parameter2
        Description of parameter2
    
    .EXAMPLE
        Get-ModuleFunction1 -Parameter1 'value1'
        Description of example
    
    .OUTPUTS
        Description of output type
    
    .NOTES
        Additional notes about the function
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Parameter1,
        
        [Parameter()]
        [int]$Parameter2 = 0
    )
    
    begin {
        Write-Verbose "Starting Get-ModuleFunction1 with Parameter1: $Parameter1"
    }
    
    process {
        try {
            # Function implementation
            $result = @{
                Parameter1 = $Parameter1
                Parameter2 = $Parameter2
                Timestamp = Get-Date
            }
            
            return [PSCustomObject]$result
            
        } catch {
            Write-Error "Error in Get-ModuleFunction1: $($_.Exception.Message)"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Get-ModuleFunction1"
    }
}

#endregion

#region Private Functions

function Invoke-PrivateHelper {
    <#
    .SYNOPSIS
        Private helper function (not exported)
    #>
    [CmdletBinding()]
    param()
    
    # Implementation
}

#endregion

#region Error Handling

function Write-ModuleError {
    <#
    .SYNOPSIS
        Standardized error logging for module
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [Exception]$Exception,
        
        [Parameter()]
        [string]$FunctionName = $MyInvocation.MyCommand.Name
    )
    
    $errorMessage = "[$FunctionName] $Message"
    if ($Exception) {
        $errorMessage += " - Exception: $($Exception.Message)"
    }
    
    Write-Error $errorMessage
}

#endregion

#region Module Cleanup

function Remove-ModuleResources {
    <#
    .SYNOPSIS
        Cleanup module resources
    #>
    [CmdletBinding()]
    param()
    
    # Cleanup resources, close connections, etc.
    $script:ModuleConfig = @{}
    $script:LogPath = $null
}

# Register cleanup on module removal
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-ModuleResources
}

#endregion

# Export public functions
Export-ModuleMember -Function @(
    'Get-ModuleFunction1'
)
