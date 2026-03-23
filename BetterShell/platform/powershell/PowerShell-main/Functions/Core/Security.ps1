# Security.ps1 - Security features for PowerShell

# Configuration
$script:SecurityConfig = @{
    ExecutionPolicy = 'RemoteSigned'
    ScriptSigning = $true
    ModuleSignatureCheck = $true
    LogSensitiveCommands = $true
    SensitiveCommands = @('*credential*', '*password*', '*secret*', '*key*', '*token*')
    AllowedModuleSources = @('PSGallery')
    BlockedCommands = @('Invoke-Expression', 'Invoke-RestMethod', 'Invoke-WebRequest')
}

# Initialize security logging
$script:SecurityLog = [System.Collections.Generic.List[object]]::new()
$script:ModuleHashes = @{}

# Security logging function
function Write-SecurityLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [string]$Category = 'Information',
        [hashtable]$Details = @{}
    )
    
    $logEntry = [PSCustomObject]@{
        Timestamp = [DateTime]::UtcNow
        Category = $Category
        Message = $Message
        Details = $Details
        User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Computer = $env:COMPUTERNAME
        ProcessId = $PID
    }
    
    $script:SecurityLog.Add($logEntry)
    
    # Keep log size manageable
    if ($script:SecurityLog.Count -gt 1000) {
        $script:SecurityLog.RemoveAt(0)
    }
}

# Command validation
function Test-CommandSecurity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,
        [Parameter(Mandatory)]
        [System.Management.Automation.CommandInfo]$CommandInfo
    )
    
    # Check for blocked commands
    if ($script:SecurityConfig.BlockedCommands -contains $CommandName) {
        Write-SecurityLog -Message "Blocked command execution" -Category 'Security' -Details @{
            Command = $CommandName
            Reason = 'Command is in blocked commands list'
        }
        return $false
    }
    
    # Check for sensitive commands
    $sensitiveMatch = $script:SecurityConfig.SensitiveCommands | Where-Object { $CommandName -like $_ }
    if ($sensitiveMatch) {
        Write-SecurityLog -Message "Sensitive command executed" -Category 'Warning' -Details @{
            Command = $CommandName
            MatchedPattern = $sensitiveMatch
        }
    }
    
    return $true
}

# Module validation
function Test-ModuleSecurity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [string]$ModulePath
    )
    
    # Check module source
    $moduleSource = (Get-PSRepository | Where-Object { $_.SourceLocation -eq (Split-Path -Parent $ModulePath -ErrorAction SilentlyContinue) }).Name
    if (-not $moduleSource -or ($script:SecurityConfig.AllowedModuleSources -notcontains $moduleSource)) {
        Write-SecurityLog -Message "Module from untrusted source" -Category 'Warning' -Details @{
            Module = $ModuleName
            Source = $moduleSource
            Path = $ModulePath
        }
        return $false
    }
    
    # Check module signature if required
    if ($script:SecurityConfig.ModuleSignatureCheck) {
        $sig = Get-AuthenticodeSignature -FilePath $ModulePath -ErrorAction SilentlyContinue
        if ($sig.Status -ne 'Valid') {
            Write-SecurityLog -Message "Module signature validation failed" -Category 'Security' -Details @{
                Module = $ModuleName
                Path = $ModulePath
                Status = $sig.Status
            }
            return $false
        }
    }
    
    return $true
}

# Initialize security features
function Initialize-Security {
    [CmdletBinding()]
    param()
    
    # Set execution policy
    if ((Get-ExecutionPolicy) -ne $script:SecurityConfig.ExecutionPolicy) {
        Set-ExecutionPolicy -ExecutionPolicy $script:SecurityConfig.ExecutionPolicy -Scope CurrentUser -Force
    }
    
    # Set up command validation
    $ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = {
        param($commandName, $commandLookupEvent)
        
        $command = $commandLookupEvent.CommandLookup
        if ($command -and -not (Test-CommandSecurity -CommandName $commandName -CommandInfo $command)) {
            $commandLookupEvent.StopSearch = $true
            throw "Command execution blocked by security policy: $commandName"
        }
    }
    
    # Set up module validation
    $ExecutionContext.SessionState.InvokeCommand.PreModuleImport = {
        param($module, $moduleName, $baseName, $mode, $options)
        
        $modulePath = $module.Path
        if (-not (Test-ModuleSecurity -ModuleName $moduleName -ModulePath $modulePath)) {
            throw "Module import blocked by security policy: $moduleName"
        }
    }
    
    Write-Verbose "Security features initialized"
}

# Export public functions
export-modulemember -Function @(
    'Write-SecurityLog',
    'Initialize-Security'
)
