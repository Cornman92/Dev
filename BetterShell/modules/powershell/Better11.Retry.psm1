<#
.SYNOPSIS
    Better11.Retry - Retry logic and error handling for Better11 Suite

.DESCRIPTION
    Provides advanced retry logic with exponential backoff, circuit breaker pattern,
    and configurable retry strategies. Integrates with Better11.Core and Core-AutoSuite
    for logging and error handling.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Better11.Retry'
$script:CircuitBreakers = @{}
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
#endregion

#region Retry Strategies

enum RetryStrategy {
    Fixed
    Exponential
    Linear
    Custom
}

#endregion

#region Retry Logic

function Invoke-Better11Retry {
    <#
    .SYNOPSIS
        Executes an action with retry logic
    
    .DESCRIPTION
        Executes a scriptblock with configurable retry logic, including retry count,
        delay strategies, and error filtering.
    
    .PARAMETER Action
        ScriptBlock to execute
    
    .PARAMETER RetryCount
        Maximum number of retry attempts
    
    .PARAMETER RetryDelay
        Initial delay between retries in seconds
    
    .PARAMETER Strategy
        Retry strategy (Fixed, Exponential, Linear, Custom)
    
    .PARAMETER MaxDelay
        Maximum delay between retries in seconds
    
    .PARAMETER BackoffMultiplier
        Multiplier for exponential/linear backoff
    
    .PARAMETER ErrorFilter
        ScriptBlock to determine if an error should trigger a retry
    
    .PARAMETER OnRetry
        ScriptBlock to execute before each retry
    
    .PARAMETER CircuitBreakerKey
        Key for circuit breaker pattern (optional)
    
    .PARAMETER CircuitBreakerThreshold
        Number of failures before opening circuit breaker
    
    .PARAMETER CircuitBreakerTimeout
        Time in seconds before attempting to close circuit breaker
    
    .EXAMPLE
        Invoke-Better11Retry -Action { Get-Process -Name 'NonExistent' } -RetryCount 3 -RetryDelay 1
    
    .EXAMPLE
        Invoke-Better11Retry -Action { Install-Package -Name 'Test' } -RetryCount 5 -Strategy Exponential -MaxDelay 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        
        [Parameter()]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [double]$RetryDelay = 1,
        
        [Parameter()]
        [RetryStrategy]$Strategy = [RetryStrategy]::Exponential,
        
        [Parameter()]
        [double]$MaxDelay = 60,
        
        [Parameter()]
        [double]$BackoffMultiplier = 2,
        
        [Parameter()]
        [scriptblock]$ErrorFilter,
        
        [Parameter()]
        [scriptblock]$OnRetry,
        
        [Parameter()]
        [string]$CircuitBreakerKey,
        
        [Parameter()]
        [int]$CircuitBreakerThreshold = 5,
        
        [Parameter()]
        [int]$CircuitBreakerTimeout = 60
    )
    
    # Check circuit breaker if key provided
    if ($CircuitBreakerKey) {
        $circuitState = Get-Better11CircuitBreakerState -Key $CircuitBreakerKey
        if ($circuitState.State -eq 'Open') {
            $timeSinceOpen = (Get-Date) - $circuitState.OpenedAt
            if ($timeSinceOpen.TotalSeconds -lt $CircuitBreakerTimeout) {
                $remaining = $CircuitBreakerTimeout - $timeSinceOpen.TotalSeconds
                throw "Circuit breaker is open. Retry after $([math]::Round($remaining, 2)) seconds."
            }
            else {
                # Attempt to close circuit breaker
                Set-Better11CircuitBreakerState -Key $CircuitBreakerKey -State 'HalfOpen'
            }
        }
    }
    
    $attempt = 0
    $lastError = $null
    $currentDelay = $RetryDelay
    
    while ($attempt -le $RetryCount) {
        try {
            $result = & $Action
            
            # Success - reset circuit breaker if half-open
            if ($CircuitBreakerKey) {
                $circuitState = Get-Better11CircuitBreakerState -Key $CircuitBreakerKey
                if ($circuitState.State -eq 'HalfOpen') {
                    Set-Better11CircuitBreakerState -Key $CircuitBreakerKey -State 'Closed' -ResetFailureCount
                }
            }
            
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'INFO' -Message "Action succeeded on attempt $($attempt + 1)"
            }
            
            return $result
        }
        catch {
            $lastError = $_
            $shouldRetry = $true
            
            # Check error filter if provided
            if ($ErrorFilter) {
                try {
                    $shouldRetry = & $ErrorFilter $_
                }
                catch {
                    $shouldRetry = $true
                }
            }
            
            if (-not $shouldRetry) {
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'WARN' -Message "Error filter determined not to retry: $($_.Exception.Message)"
                }
                throw
            }
            
            $attempt++
            
            if ($attempt -le $RetryCount) {
                # Calculate delay based on strategy
                $currentDelay = Get-Better11RetryDelay -Strategy $Strategy -Attempt $attempt `
                    -InitialDelay $RetryDelay -MaxDelay $MaxDelay -BackoffMultiplier $BackoffMultiplier
                
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'WARN' -Message "Attempt $attempt failed. Retrying in $([math]::Round($currentDelay, 2)) seconds: $($_.Exception.Message)"
                }
                
                # Execute OnRetry callback if provided
                if ($OnRetry) {
                    try {
                        & $OnRetry -Attempt $attempt -Error $_ -NextDelay $currentDelay
                    }
                    catch {
                        Write-Warning "OnRetry callback failed: $_"
                    }
                }
                
                Start-Sleep -Seconds $currentDelay
            }
            else {
                # All retries exhausted
                if ($CircuitBreakerKey) {
                    $circuitState = Get-Better11CircuitBreakerState -Key $CircuitBreakerKey
                    $newFailureCount = $circuitState.FailureCount + 1
                    
                    if ($newFailureCount -ge $CircuitBreakerThreshold) {
                        Set-Better11CircuitBreakerState -Key $CircuitBreakerKey -State 'Open' -FailureCount $newFailureCount
                    }
                    else {
                        Set-Better11CircuitBreakerState -Key $CircuitBreakerKey -FailureCount $newFailureCount
                    }
                }
                
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'ERROR' -Message "Action failed after $attempt attempts: $($_.Exception.Message)"
                }
                throw
            }
        }
    }
}

function Get-Better11RetryDelay {
    <#
    .SYNOPSIS
        Calculates retry delay based on strategy
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [RetryStrategy]$Strategy,
        
        [Parameter(Mandatory)]
        [int]$Attempt,
        
        [Parameter(Mandatory)]
        [double]$InitialDelay,
        
        [Parameter(Mandatory)]
        [double]$MaxDelay,
        
        [Parameter()]
        [double]$BackoffMultiplier = 2
    )
    
    $delay = switch ($Strategy) {
        ([RetryStrategy]::Fixed) {
            $InitialDelay
        }
        ([RetryStrategy]::Exponential) {
            $InitialDelay * [math]::Pow($BackoffMultiplier, $Attempt - 1)
        }
        ([RetryStrategy]::Linear) {
            $InitialDelay * $Attempt
        }
        ([RetryStrategy]::Custom) {
            $InitialDelay
        }
    }
    
    # Cap at MaxDelay
    if ($delay -gt $MaxDelay) {
        $delay = $MaxDelay
    }
    
    # Add jitter to prevent thundering herd
    $jitter = Get-Random -Minimum 0 -Maximum ($delay * 0.1)
    $delay = $delay + $jitter
    
    return $delay
}

#endregion

#region Circuit Breaker

function Get-Better11CircuitBreakerState {
    <#
    .SYNOPSIS
        Gets the current state of a circuit breaker
    
    .DESCRIPTION
        Returns the current state, failure count, and timestamp for a circuit breaker.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($Key)) {
        $script:CircuitBreakers[$Key] = @{
            State = 'Closed'
            FailureCount = 0
            OpenedAt = $null
        }
    }
    
    return $script:CircuitBreakers[$Key]
}

function Set-Better11CircuitBreakerState {
    <#
    .SYNOPSIS
        Sets the state of a circuit breaker
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,
        
        [Parameter()]
        [ValidateSet('Open', 'Closed', 'HalfOpen')]
        [string]$State,
        
        [Parameter()]
        [int]$FailureCount = -1,
        
        [Parameter()]
        [switch]$ResetFailureCount
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($Key)) {
        $script:CircuitBreakers[$Key] = @{
            State = 'Closed'
            FailureCount = 0
            OpenedAt = $null
        }
    }
    
    if ($State) {
        $script:CircuitBreakers[$Key].State = $State
        if ($State -eq 'Open') {
            $script:CircuitBreakers[$Key].OpenedAt = Get-Date
        }
    }
    
    if ($ResetFailureCount) {
        $script:CircuitBreakers[$Key].FailureCount = 0
    }
    elseif ($FailureCount -ge 0) {
        $script:CircuitBreakers[$Key].FailureCount = $FailureCount
    }
}

function Reset-Better11CircuitBreaker {
    <#
    .SYNOPSIS
        Resets a circuit breaker to closed state
    
    .DESCRIPTION
        Resets a circuit breaker, clearing failure count and setting state to Closed.
    
    .PARAMETER Key
        Circuit breaker key
    
    .EXAMPLE
        Reset-Better11CircuitBreaker -Key 'PackageInstall'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    Set-Better11CircuitBreakerState -Key $Key -State 'Closed' -ResetFailureCount
    if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
        Write-Better11Log -Level 'INFO' -Message "Circuit breaker '$Key' reset to Closed state"
    }
}

#endregion

#region Error Filter Helpers

function New-Better11ErrorFilter {
    <#
    .SYNOPSIS
        Creates an error filter scriptblock
    
    .DESCRIPTION
        Creates a scriptblock that filters errors based on exception type or message pattern.
    
    .PARAMETER ExceptionType
        Full name of exception type to retry on
    
    .PARAMETER MessagePattern
        Regex pattern to match error messages
    
    .PARAMETER ExcludePattern
        Regex pattern to exclude from retries
    
    .EXAMPLE
        $filter = New-Better11ErrorFilter -ExceptionType 'System.IO.IOException' -MessagePattern 'timeout'
    #>
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter()]
        [string]$ExceptionType,
        
        [Parameter()]
        [string]$MessagePattern,
        
        [Parameter()]
        [string]$ExcludePattern
    )
    
    return {
        param($Error)
        
        $shouldRetry = $true
        
        if ($ExceptionType) {
            $errorType = $Error.Exception.GetType().FullName
            if ($errorType -ne $ExceptionType) {
                $shouldRetry = $false
            }
        }
        
        if ($MessagePattern -and $shouldRetry) {
            if ($Error.Exception.Message -notmatch $MessagePattern) {
                $shouldRetry = $false
            }
        }
        
        if ($ExcludePattern -and $shouldRetry) {
            if ($Error.Exception.Message -match $ExcludePattern) {
                $shouldRetry = $false
            }
        }
        
        return $shouldRetry
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Invoke-Better11Retry',
    'Get-Better11RetryDelay',
    'Get-Better11CircuitBreakerState',
    'Set-Better11CircuitBreakerState',
    'Reset-Better11CircuitBreaker',
    'New-Better11ErrorFilter'
)

Export-ModuleMember -Enum RetryStrategy
