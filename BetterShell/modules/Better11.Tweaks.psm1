<#
.SYNOPSIS
    Better11.Tweaks - System tweaks and optimizations for Better11 Suite

.DESCRIPTION
    Provides system tweaks, registry modifications, and performance optimizations
    for Windows systems. Includes pre-built profiles for gaming, performance, and privacy.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Better11.Tweaks'
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

#region Registry Operations

function Set-Better11RegistryValue {
    <#
    .SYNOPSIS
        Sets a registry value with backup and error handling
    
    .DESCRIPTION
        Sets a registry value, optionally creating the key if it doesn't exist.
        Supports backup before modification.
    
    .PARAMETER Path
        Registry path (e.g., 'HKLM:\Software\Better11')
    
    .PARAMETER Name
        Value name
    
    .PARAMETER Value
        Value to set
    
    .PARAMETER Type
        Registry value type (String, DWord, QWord, Binary, etc.)
    
    .PARAMETER CreateKey
        Create the registry key if it doesn't exist
    
    .PARAMETER Backup
        Backup the value before modification
    
    .EXAMPLE
        Set-Better11RegistryValue -Path 'HKLM:\Software\Better11' -Name 'TestValue' -Value 'Test' -Type String
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [object]$Value,
        
        [Parameter()]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'String',
        
        [Parameter()]
        [switch]$CreateKey,
        
        [Parameter()]
        [switch]$Backup
    )
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set registry value")) {
        try {
            # Create key if needed
            if (-not (Test-Path $Path)) {
                if ($CreateKey) {
                    New-Item -Path $Path -Force | Out-Null
                }
                else {
                    throw "Registry path does not exist: $Path"
                }
            }
            
            # Backup if requested
            if ($Backup) {
                $backupValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
                if ($backupValue) {
                    $backupPath = Join-Path $env:TEMP "Better11_RegistryBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                    reg.exe export $Path $backupPath /y | Out-Null
                    if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                        Write-Better11Log -Level 'INFO' -Message "Registry backup created: $backupPath"
                    }
                }
            }
            
            # Set the value
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
            
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'INFO' -Message "Set registry value: $Path\$Name = $Value"
            }
            
            return $true
        }
        catch {
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'ERROR' -Message "Failed to set registry value: $_"
            }
            Write-Error "Failed to set registry value: $_"
            throw
        }
    }
    
    return $false
}

function Get-Better11RegistryValue {
    <#
    .SYNOPSIS
        Gets a registry value
    
    .DESCRIPTION
        Retrieves a registry value, returning null if not found.
    
    .PARAMETER Path
        Registry path
    
    .PARAMETER Name
        Value name
    
    .EXAMPLE
        Get-Better11RegistryValue -Path 'HKLM:\Software\Better11' -Name 'TestValue'
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    try {
        if (-not (Test-Path $Path)) {
            return $null
        }
        
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($value) {
            return $value.$Name
        }
        
        return $null
    }
    catch {
        Write-Verbose "Failed to get registry value: $_"
        return $null
    }
}

#endregion

#region Pre-built Tweaks

function Apply-Better11GamingTweaks {
    <#
    .SYNOPSIS
        Applies gaming performance tweaks
    
    .DESCRIPTION
        Applies a set of registry tweaks optimized for gaming performance.
    
    .PARAMETER WhatIf
        Show what would be changed without making changes
    
    .EXAMPLE
        Apply-Better11GamingTweaks
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$WhatIf
    )
    
    $tweaks = @(
        @{
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            Name = 'DisablePagingExecutive'
            Value = 1
            Type = 'DWord'
            Description = 'Disable paging executive for better performance'
        },
        @{
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
            Name = 'Win32PrioritySeparation'
            Value = 38
            Type = 'DWord'
            Description = 'Optimize for programs (gaming)'
        },
        @{
            Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'
            Name = 'AppCaptureEnabled'
            Value = 0
            Type = 'DWord'
            Description = 'Disable Game DVR'
        },
        @{
            Path = 'HKCU:\System\GameConfigStore'
            Name = 'GameDVR_Enabled'
            Value = 0
            Type = 'DWord'
            Description = 'Disable Game DVR (alternative location)'
        }
    )
    
    $applied = 0
    foreach ($tweak in $tweaks) {
        if ($WhatIf) {
            Write-Host "WhatIf: Would set $($tweak.Path)\$($tweak.Name) = $($tweak.Value) ($($tweak.Description))"
        }
        else {
            try {
                Set-Better11RegistryValue -Path $tweak.Path -Name $tweak.Name `
                    -Value $tweak.Value -Type $tweak.Type -CreateKey -Backup
                $applied++
            }
            catch {
                Write-Warning "Failed to apply tweak: $($tweak.Description) - $_"
            }
        }
    }
    
    if (-not $WhatIf) {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'INFO' -Message "Applied $applied gaming tweaks"
        }
    }
    
    return $applied
}

function Apply-Better11PerformanceTweaks {
    <#
    .SYNOPSIS
        Applies general performance tweaks
    
    .DESCRIPTION
        Applies registry tweaks for general system performance optimization.
    
    .PARAMETER WhatIf
        Show what would be changed without making changes
    
    .EXAMPLE
        Apply-Better11PerformanceTweaks
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$WhatIf
    )
    
    $tweaks = @(
        @{
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
            Name = 'NtfsDisableLastAccessUpdate'
            Value = 1
            Type = 'DWord'
            Description = 'Disable last access time updates for better disk performance'
        },
        @{
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
            Name = 'IRPStackSize'
            Value = 30
            Type = 'DWord'
            Description = 'Increase IRP stack size for network performance'
        },
        @{
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
            Name = 'EnablePrefetcher'
            Value = 1
            Type = 'DWord'
            Description = 'Enable prefetcher'
        }
    )
    
    $applied = 0
    foreach ($tweak in $tweaks) {
        if ($WhatIf) {
            Write-Host "WhatIf: Would set $($tweak.Path)\$($tweak.Name) = $($tweak.Value) ($($tweak.Description))"
        }
        else {
            try {
                Set-Better11RegistryValue -Path $tweak.Path -Name $tweak.Name `
                    -Value $tweak.Value -Type $tweak.Type -CreateKey -Backup
                $applied++
            }
            catch {
                Write-Warning "Failed to apply tweak: $($tweak.Description) - $_"
            }
        }
    }
    
    if (-not $WhatIf) {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'INFO' -Message "Applied $applied performance tweaks"
        }
    }
    
    return $applied
}

function Apply-Better11PrivacyTweaks {
    <#
    .SYNOPSIS
        Applies privacy-focused tweaks
    
    .DESCRIPTION
        Applies registry tweaks to enhance privacy and reduce telemetry.
    
    .PARAMETER WhatIf
        Show what would be changed without making changes
    
    .EXAMPLE
        Apply-Better11PrivacyTweaks
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$WhatIf
    )
    
    $tweaks = @(
        @{
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
            Name = 'AllowTelemetry'
            Value = 0
            Type = 'DWord'
            Description = 'Disable telemetry'
        },
        @{
            Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
            Name = 'AllowTelemetry'
            Value = 0
            Type = 'DWord'
            Description = 'Disable telemetry (policy)'
        },
        @{
            Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
            Name = 'Enabled'
            Value = 0
            Type = 'DWord'
            Description = 'Disable advertising ID'
        }
    )
    
    $applied = 0
    foreach ($tweak in $tweaks) {
        if ($WhatIf) {
            Write-Host "WhatIf: Would set $($tweak.Path)\$($tweak.Name) = $($tweak.Value) ($($tweak.Description))"
        }
        else {
            try {
                Set-Better11RegistryValue -Path $tweak.Path -Name $tweak.Name `
                    -Value $tweak.Value -Type $tweak.Type -CreateKey -Backup
                $applied++
            }
            catch {
                Write-Warning "Failed to apply tweak: $($tweak.Description) - $_"
            }
        }
    }
    
    if (-not $WhatIf) {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'INFO' -Message "Applied $applied privacy tweaks"
        }
    }
    
    return $applied
}

#endregion

#region Custom Tweak Management

function New-Better11Tweak {
    <#
    .SYNOPSIS
        Creates a custom tweak definition
    
    .DESCRIPTION
        Creates a hashtable representing a custom registry tweak.
    
    .PARAMETER Path
        Registry path
    
    .PARAMETER Name
        Value name
    
    .PARAMETER Value
        Value to set
    
    .PARAMETER Type
        Registry value type
    
    .PARAMETER Description
        Description of the tweak
    
    .EXAMPLE
        $tweak = New-Better11Tweak -Path 'HKLM:\Software\Test' -Name 'TestValue' -Value 1 -Type DWord -Description 'Test tweak'
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [object]$Value,
        
        [Parameter(Mandatory)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type,
        
        [Parameter()]
        [string]$Description = ''
    )
    
    return @{
        Path = $Path
        Name = $Name
        Value = $Value
        Type = $Type
        Description = $Description
    }
}

function Apply-Better11Tweaks {
    <#
    .SYNOPSIS
        Applies a collection of tweaks
    
    .DESCRIPTION
        Applies multiple tweaks from an array of tweak definitions.
    
    .PARAMETER Tweaks
        Array of tweak hashtables
    
    .PARAMETER WhatIf
        Show what would be changed without making changes
    
    .EXAMPLE
        $tweaks = @($tweak1, $tweak2)
        Apply-Better11Tweaks -Tweaks $tweaks
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [array]$Tweaks,
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    $applied = 0
    $failed = 0
    
    foreach ($tweak in $Tweaks) {
        if ($WhatIf) {
            Write-Host "WhatIf: Would set $($tweak.Path)\$($tweak.Name) = $($tweak.Value)"
        }
        else {
            try {
                Set-Better11RegistryValue -Path $tweak.Path -Name $tweak.Name `
                    -Value $tweak.Value -Type $tweak.Type -CreateKey -Backup
                $applied++
            }
            catch {
                Write-Warning "Failed to apply tweak: $($tweak.Description) - $_"
                $failed++
            }
        }
    }
    
    if (-not $WhatIf) {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'INFO' -Message "Applied $applied tweaks, $failed failed"
        }
    }
    
    return @{
        Applied = $applied
        Failed = $failed
        Total = $Tweaks.Count
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Set-Better11RegistryValue',
    'Get-Better11RegistryValue',
    'Apply-Better11GamingTweaks',
    'Apply-Better11PerformanceTweaks',
    'Apply-Better11PrivacyTweaks',
    'New-Better11Tweak',
    'Apply-Better11Tweaks'
)
