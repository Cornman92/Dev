---
description: Create robust Windows automation scripts with proper error handling and logging
---

# Windows Automation Script Workflow

Complete workflow for developing Windows automation scripts with proper structure, error handling, and testing.

## Prerequisites
- PowerShell 5.1+ or PowerShell 7+
- Administrator access (for many automation tasks)
- VS Code with PowerShell extension

## Steps

### 1. Create Script Structure
// turbo
```powershell
$scriptName = "[ScriptName]"
$scriptPath = "e:\OneDrive\Dev\Scripts\$scriptName.ps1"

# Create script from template
New-Item -Path $scriptPath -ItemType File -Force
```

### 2. Use Standard Script Template
```powershell
#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Brief description of what the script does
    
.DESCRIPTION
    Detailed description of the script functionality,
    including any prerequisites or dependencies.
    
.PARAMETER ParameterName
    Description of the parameter
    
.EXAMPLE
    .\[ScriptName].ps1 -ParameterName "Value"
    Description of what this example does
    
.NOTES
    Author: Your Name
    Date: $(Get-Date -Format 'yyyy-MM-dd')
    Version: 1.0.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Minimal', 'Normal', 'Verbose')]
    [string]$LogLevel = 'Normal'
)

#region Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:LogPath = Join-Path $PSScriptRoot "logs\$scriptName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
#endregion

#region Logging Functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $script:LogPath -Value $logMessage
    
    switch ($Level) {
        'ERROR' { Write-Error $Message }
        'WARN'  { Write-Warning $Message }
        'DEBUG' { Write-Verbose $Message }
        default { Write-Host $Message }
    }
}
#endregion

#region Main Functions
function Initialize-Script {
    Write-Log "Starting $scriptName..."
    Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"
    Write-Log "Running as: $([Environment]::UserName)"
    
    # Verify prerequisites
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
}

function Invoke-MainLogic {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    # Your main logic here
    if ($PSCmdlet.ShouldProcess("Target", "Action")) {
        # Perform the action
    }
}

function Complete-Script {
    param([bool]$Success = $true)
    
    if ($Success) {
        Write-Log "Script completed successfully."
    } else {
        Write-Log "Script completed with errors." -Level 'WARN'
    }
}
#endregion

#region Main Execution
try {
    Initialize-Script
    Invoke-MainLogic
    Complete-Script -Success $true
}
catch {
    Write-Log "Fatal error: $_" -Level 'ERROR'
    Write-Log $_.ScriptStackTrace -Level 'DEBUG'
    Complete-Script -Success $false
    exit 1
}
#endregion
```

### 3. Common Automation Patterns

**Registry Operations:**
```powershell
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = 'String'
    )
    
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}
```

**File System Operations:**
```powershell
function Copy-ItemSafe {
    param([string]$Source, [string]$Destination)
    
    if (Test-Path $Source) {
        $destDir = Split-Path $Destination -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item -Path $Source -Destination $Destination -Force
    } else {
        Write-Log "Source not found: $Source" -Level 'WARN'
    }
}
```

**Service Management:**
```powershell
function Set-ServiceState {
    param(
        [string]$ServiceName,
        [ValidateSet('Running', 'Stopped')]
        [string]$State
    )
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($State -eq 'Running') {
            Start-Service $ServiceName
        } else {
            Stop-Service $ServiceName -Force
        }
    }
}
```

### 4. Create Pester Tests
```powershell
# tests/[ScriptName].Tests.ps1
BeforeAll {
    . "$PSScriptRoot\..\Scripts\[ScriptName].ps1" -WhatIf
}

Describe '[ScriptName] Script' {
    Context 'Parameter Validation' {
        It 'Should accept valid LogLevel values' {
            { .\[ScriptName].ps1 -LogLevel 'Verbose' -WhatIf } | Should -Not -Throw
        }
    }
    
    Context 'Function Tests' {
        It 'Should create log directory if not exists' {
            # Test logging functionality
        }
    }
}
```

// turbo
### 5. Validate with PSScriptAnalyzer
```powershell
Invoke-ScriptAnalyzer -Path "e:\OneDrive\Dev\Scripts\[ScriptName].ps1" -Severity Warning
```

### 6. Test Execution
```powershell
# Dry run (WhatIf mode)
.\Scripts\[ScriptName].ps1 -WhatIf

# Verbose execution
.\Scripts\[ScriptName].ps1 -Verbose

# Full execution
.\Scripts\[ScriptName].ps1 -Force
```

## Best Practices

- **Always use `-WhatIf`**: Support `SupportsShouldProcess` for destructive operations
- **Validate input**: Use `[ValidateSet()]`, `[ValidatePattern()]`, etc.
- **Log everything**: Create audit trail for troubleshooting
- **Handle errors gracefully**: Use try/catch with meaningful error messages
- **Test as non-admin first**: Verify what fails before running as admin
- **Backup before modify**: Create backups of files/registry before changes

## Security Considerations

- Never hardcode credentials
- Use `Get-Credential` or Windows Credential Manager
- Validate paths to prevent injection attacks
- Use `-Confirm` for destructive operations
- Check execution policy requirements

## Quick Commands
```powershell
# Run with transcript (full logging)
Start-Transcript -Path ".\transcript.log"
.\Scripts\[ScriptName].ps1
Stop-Transcript

# Check script signature
Get-AuthenticodeSignature .\Scripts\[ScriptName].ps1

# Sign script (if you have a certificate)
Set-AuthenticodeSignature .\Scripts\[ScriptName].ps1 -Certificate $cert
```
