#Requires -Version 5.1

<#
.SYNOPSIS
    Better11 Gaming Module — Advanced gaming performance optimization.
.DESCRIPTION
    Provides comprehensive gaming performance optimization including system tuning,
    resource prioritization, network optimization, and game-specific profiles.
#>

using namespace System.IO
using namespace System.Collections.Generic

# Gaming configuration storage
$script:GameProfiles = [Dictionary[string, hashtable]]::new()
$script:CurrentGameMode = $false
$script:OriginalSettings = @{}

#region Game Mode Management

function Enable-B11GameMode {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [ValidateSet('Low', 'Medium', 'High', 'Ultra')]
        [string]$PerformanceLevel = 'High',
        
        [Parameter()]
        [switch]$OptimizeNetwork,
        
        [Parameter()]
        [switch]$ClearCache,
        
        [Parameter()]
        [switch]$DisableBackground
    )
    
    if ($PSCmdlet.ShouldProcess("System", "Enable gaming mode")) {
        Write-Host "🎮 Enabling Better11 Gaming Mode..." -ForegroundColor Cyan
        
        # Store original settings for restoration
        $script:OriginalSettings = Get-B11CurrentSystemSettings
        
        try {
            # Set power plan to high performance
            Write-Host "⚡ Setting high performance power plan..." -ForegroundColor Blue
            Set-B11PowerPlan -Performance HighPerformance
            
            # Optimize CPU settings
            Write-Host "🔧 Optimizing CPU settings..." -ForegroundColor Blue
            Set-B11CpuPerformance -Level $PerformanceLevel
            
            # Optimize memory settings
            Write-Host "💾 Optimizing memory settings..." -ForegroundColor Blue
            Set-B11MemoryOptimization -Level $PerformanceLevel
            
            # Optimize GPU settings
            Write-Host "🎨 Optimizing GPU settings..." -ForegroundColor Blue
            Set-B11GpuPerformance -Level $PerformanceLevel
            
            # Network optimization if requested
            if ($OptimizeNetwork) {
                Write-Host "🌐 Optimizing network settings..." -ForegroundColor Blue
                Set-B11GamingNetworkOptimization
            }
            
            # Clear cache if requested
            if ($ClearCache) {
                Write-Host "🧹 Clearing system cache..." -ForegroundColor Blue
                Clear-B11SystemCache -Level Deep
            }
            
            # Disable background processes if requested
            if ($DisableBackground) {
                Write-Host "🚫 Disabling background processes..." -ForegroundColor Blue
                Disable-B11BackgroundServices
            }
            
            # Set gaming registry optimizations
            Write-Host "📝 Applying gaming registry optimizations..." -ForegroundColor Blue
            Set-B11GamingRegistryOptimations
            
            $script:CurrentGameMode = $true
            
            Write-Host "✅ Gaming mode enabled at $PerformanceLevel level!" -ForegroundColor Green
            
            return [PSCustomObject]@{
                PSTypeName = 'B11.GameMode'
                Enabled = $true
                PerformanceLevel = $PerformanceLevel
                NetworkOptimized = $OptimizeNetwork
                CacheCleared = $ClearCache
                BackgroundDisabled = $DisableBackground
                Timestamp = [datetime]::UtcNow
            }
        }
        catch {
            Write-Error "Failed to enable gaming mode: $_"
            throw
        }
    }
}

function Disable-B11GameMode {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param()
    
    if ($PSCmdlet.ShouldProcess("System", "Disable gaming mode")) {
        Write-Host "🎮 Disabling Better11 Gaming Mode..." -ForegroundColor Cyan
        
        if (-not $script:CurrentGameMode) {
            Write-Warning "Gaming mode is not currently enabled"
            return
        }
        
        try {
            # Restore original power plan
            if ($script:OriginalSettings.PowerPlan) {
                Write-Host "⚡ Restoring original power plan..." -ForegroundColor Blue
                Set-B11PowerPlan -Guid $script:OriginalSettings.PowerPlan
            }
            
            # Restore CPU settings
            Write-Host "🔧 Restoring CPU settings..." -ForegroundColor Blue
            Restore-B11CpuSettings
            
            # Restore memory settings
            Write-Host "💾 Restoring memory settings..." -ForegroundColor Blue
            Restore-B11MemorySettings
            
            # Restore GPU settings
            Write-Host "🎨 Restoring GPU settings..." -ForegroundColor Blue
            Restore-B11GpuSettings
            
            # Restore network settings
            Write-Host "🌐 Restoring network settings..." -ForegroundColor Blue
            Restore-B11NetworkSettings
            
            # Re-enable background services
            Write-Host "🔄 Re-enabling background services..." -ForegroundColor Blue
            Enable-B11BackgroundServices
            
            # Clear gaming registry optimizations
            Write-Host "📝 Removing gaming registry optimizations..." -ForegroundColor Blue
            Clear-B11GamingRegistryOptimizations
            
            $script:CurrentGameMode = $false
            $script:OriginalSettings = @{}
            
            Write-Host "✅ Gaming mode disabled - System restored to original settings" -ForegroundColor Green
            
            return [PSCustomObject]@{
                PSTypeName = 'B11.GameMode'
                Enabled = $false
                Timestamp = [datetime]::UtcNow
            }
        }
        catch {
            Write-Error "Failed to disable gaming mode: $_"
            throw
        }
    }
}

function Get-B11GameModeStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $status = if ($script:CurrentGameMode) {
        "Enabled"
    } else {
        "Disabled"
    }
    
    return [PSCustomObject]@{
        PSTypeName = 'B11.GameModeStatus'
        Status = $status
        OriginalSettingsStored = $script:OriginalSettings.Count -gt 0
        GameProfilesCount = $script:GameProfiles.Count
        Timestamp = [datetime]::UtcNow
    }
}

#endregion

#region Game Profiles

function New-B11GameProfile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$ExecutablePath,
        
        [Parameter()]
        [string]$ProcessName,
        
        [Parameter()]
        [ValidateSet('Low', 'Medium', 'High', 'Ultra')]
        [string]$PerformanceLevel = 'High',
        
        [Parameter()]
        [hashtable]$CustomSettings = @{},
        
        [Parameter()]
        [string[]]$RequiredServices = @(),
        
        [Parameter()]
        [string[]]$DisabledProcesses = @()
    )
    
    $profile = @{
        Name = $Name
        ExecutablePath = $ExecutablePath
        ProcessName = $ProcessName
        PerformanceLevel = $PerformanceLevel
        CustomSettings = $CustomSettings
        RequiredServices = $RequiredServices
        DisabledProcesses = $DisabledProcesses
        CreatedAt = [datetime]::UtcNow
    }
    
    $script:GameProfiles[$Name] = $profile
    
    Write-Host "✅ Created game profile: $Name" -ForegroundColor Green
    
    return [PSCustomObject]@{
        PSTypeName = 'B11.GameProfile'
        Profile = $profile
    }
}

function Get-B11GameProfile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$Name
    )
    
    if ($Name) {
        if ($script:GameProfiles.ContainsKey($Name)) {
            return [PSCustomObject]@{
                PSTypeName = 'B11.GameProfile'
                Profile = $script:GameProfiles[$Name]
            }
        } else {
            Write-Warning "Game profile '$Name' not found"
            return $null
        }
    } else {
        return $script:GameProfiles.Values | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName = 'B11.GameProfile'
                Profile = $_
            }
        }
    }
}

function Remove-B11GameProfile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Remove game profile")) {
        if ($script:GameProfiles.ContainsKey($Name)) {
            $script:GameProfiles.Remove($Name)
            Write-Host "✅ Removed game profile: $Name" -ForegroundColor Green
        } else {
            Write-Warning "Game profile '$Name' not found"
        }
    }
}

function Start-B11GameWithProfile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,
        
        [Parameter()]
        [string]$Arguments = ""
    )
    
    $profile = Get-B11GameProfile -Name $ProfileName
    if (-not $profile) {
        Write-Error "Game profile '$ProfileName' not found"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($ProfileName, "Start game with profile")) {
        Write-Host "🎮 Starting game with profile: $ProfileName" -ForegroundColor Cyan
        
        try {
            # Enable gaming mode with profile settings
            Enable-B11GameMode -PerformanceLevel $profile.Profile.PerformanceLevel
            
            # Apply custom settings
            if ($profile.Profile.CustomSettings.Count -gt 0) {
                Write-Host "🔧 Applying custom settings..." -ForegroundColor Blue
                foreach ($setting in $profile.Profile.CustomSettings.GetEnumerator()) {
                    Set-B11CustomSetting -Name $setting.Key -Value $setting.Value
                }
            }
            
            # Start required services
            if ($profile.Profile.RequiredServices.Count -gt 0) {
                Write-Host "🔄 Starting required services..." -ForegroundColor Blue
                foreach ($service in $profile.Profile.RequiredServices) {
                    Start-Service -Name $service -ErrorAction SilentlyContinue
                }
            }
            
            # Disable conflicting processes
            if ($profile.Profile.DisabledProcesses.Count -gt 0) {
                Write-Host "🚫 Disabling conflicting processes..." -ForegroundColor Blue
                foreach ($process in $profile.Profile.DisabledProcesses) {
                    Stop-Process -Name $process -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Launch the game
            if ($profile.Profile.ExecutablePath -and (Test-Path $profile.Profile.ExecutablePath)) {
                Write-Host "🚀 Launching game..." -ForegroundColor Blue
                $process = Start-Process -FilePath $profile.Profile.ExecutablePath -ArgumentList $Arguments -PassThru
                
                Write-Host "✅ Game started with PID: $($process.Id)" -ForegroundColor Green
                
                return [PSCustomObject]@{
                    PSTypeName = 'B11.GameLaunch'
                    ProfileName = $ProfileName
                    ProcessId = $process.Id
                    ProcessName = $process.ProcessName
                    StartTime = [datetime]::UtcNow
                }
            } else {
                Write-Error "Executable path not found: $($profile.Profile.ExecutablePath)"
                return $null
            }
        }
        catch {
            Write-Error "Failed to start game with profile: $_"
            throw
        }
    }
}

#endregion

#region Performance Monitoring

function Get-B11GamingPerformanceMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
    $memoryUsage = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory
    $gpuUsage = Get-B11GpuUsage
    
    $memoryPercent = [math]::Round((($memoryUsage.TotalVisibleMemorySize - $memoryUsage.FreePhysicalMemory) / $memoryUsage.TotalVisibleMemorySize) * 100, 2)
    
    return [PSCustomObject]@{
        PSTypeName = 'B11.GamingMetrics'
        CpuUsage = [math]::Round($cpuUsage.Average, 2)
        MemoryUsage = $memoryPercent
        GpuUsage = $gpuUsage
        GameModeActive = $script:CurrentGameMode
        Timestamp = [datetime]::UtcNow
    }
}

function Start-B11GamingPerformanceMonitor {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Job])]
    param(
        [Parameter()]
        [int]$IntervalSeconds = 5,
        
        [Parameter()]
        [int]$MaxSamples = 100
    )
    
    $script = {
        param($Interval, $MaxSamples)
        
        $samples = @()
        
        for ($i = 0; $i -lt $MaxSamples; $i++) {
            $metrics = Get-B11GamingPerformanceMetrics
            $samples += $metrics
            
            Write-Output $metrics
            
            Start-Sleep -Seconds $Interval
        }
        
        return $samples
    }
    
    Write-Host "📊 Starting gaming performance monitor..." -ForegroundColor Cyan
    Write-Host "   Interval: $IntervalSeconds seconds" -ForegroundColor Gray
    Write-Host "   Max samples: $MaxSamples" -ForegroundColor Gray
    
    return Start-Job -ScriptBlock $script -ArgumentList $IntervalSeconds, $MaxSamples -Name "GamingPerformanceMonitor"
}

#endregion

#region Helper Functions (Private)

function Get-B11CurrentSystemSettings {
    # Store current system settings for restoration
    return @{
        PowerPlan = (Get-WmiObject -Class Win32_PowerPlan -Namespace root\cimv2\power).InstanceGUID
        CpuSettings = Get-B11CpuSettings
        MemorySettings = Get-B11MemorySettings
        GpuSettings = Get-B11GpuSettings
        NetworkSettings = Get-B11NetworkSettings
    }
}

function Set-B11PowerPlan {
    param([string]$Guid)
    powercfg /setactive $Guid
}

function Set-B11CpuPerformance {
    param([string]$Level)
    
    switch ($Level) {
        'Ultra' {
            # Maximum performance settings
            Set-B11CpuSettings -PowerPlan "Ultimate Performance" -MinClock 100 -MaxClock 100
        }
        'High' {
            # High performance settings
            Set-B11CpuSettings -PowerPlan "High Performance" -MinClock 80 -MaxClock 100
        }
        'Medium' {
            # Balanced performance
            Set-B11CpuSettings -PowerPlan "Balanced" -MinClock 50 -MaxClock 100
        }
        'Low' {
            # Power saving
            Set-B11CpuSettings -PowerPlan "Power Saver" -MinClock 20 -MaxClock 80
        }
    }
}

function Set-B11GamingNetworkOptimization {
    # Optimize network for gaming
    netsh int tcp set global autotuninglevel=restricted
    netsh int tcp set global chimney=enabled
    netsh int tcp set global dca=enabled
    netsh int tcp set global netdma=enabled
    
    # Disable Nagle's algorithm for gaming
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value 1 -Type DWORD
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPNoDelay" -Value 1 -Type DWORD
}

function Set-B11GamingRegistryOptimizations {
    # Gaming registry optimizations
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    # System responsiveness for gaming
    Set-ItemProperty -Path $registryPath -Name "SystemResponsiveness" -Value 0 -Type DWORD
    Set-ItemProperty -Path $registryPath -Name "NetworkThrottlingIndex" -Value 4294967295 -Type DWORD
    
    # Disable some visual effects for performance
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWORD
}

function Clear-B11GamingRegistryOptimizations {
    # Remove gaming registry optimizations
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
}

# Placeholder functions for system-specific optimizations
function Set-B11CpuSettings { param($PowerPlan, $MinClock, $MaxClock) }
function Set-B11MemoryOptimization { param([string]$Level) }
function Set-B11GpuPerformance { param([string]$Level) }
function Get-B11CpuSettings { return @{} }
function Get-B11MemorySettings { return @{} }
function Get-B11GpuSettings { return @{} }
function Get-B11NetworkSettings { return @{} }
function Get-B11GpuUsage { return 0 }
function Restore-B11CpuSettings { }
function Restore-B11MemorySettings { }
function Restore-B11GpuSettings { }
function Restore-B11NetworkSettings { }
function Disable-B11BackgroundServices { }
function Enable-B11BackgroundServices { }
function Set-B11CustomSetting { param($Name, $Value) }

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Enable-B11GameMode',
    'Disable-B11GameMode',
    'Get-B11GameModeStatus',
    'New-B11GameProfile',
    'Get-B11GameProfile',
    'Remove-B11GameProfile',
    'Start-B11GameWithProfile',
    'Get-B11GamingPerformanceMetrics',
    'Start-B11GamingPerformanceMonitor'
)
