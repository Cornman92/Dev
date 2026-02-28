<#
.SYNOPSIS
    Collects and returns key system information.

.DESCRIPTION
    Gathers OS version, CPU, memory, disk, network, and uptime
    information into a structured object. Useful for diagnostics,
    inventory, and health checks.

.PARAMETER Detailed
    Include additional details like running processes count,
    installed hotfixes, and network adapter info.

.EXAMPLE
    Get-SystemInfo
    Returns basic system information as a PSCustomObject.

.EXAMPLE
    Get-SystemInfo -Detailed | Format-List
    Returns detailed system information in list format.

.EXAMPLE
    Get-SystemInfo | ConvertTo-Json | Out-File "system-report.json"
    Exports system info as JSON.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
function Get-SystemInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$Detailed
    )

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

    # Calculate uptime
    $uptime = (Get-Date) - $os.LastBootUpTime

    # Disk info (local fixed drives only)
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        [PSCustomObject]@{
            Drive     = $_.DeviceID
            SizeGB    = [math]::Round($_.Size / 1GB, 2)
            FreeGB    = [math]::Round($_.FreeSpace / 1GB, 2)
            UsedPct   = if ($_.Size -gt 0) { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1) } else { 0 }
        }
    }

    $info = [PSCustomObject]@{
        ComputerName   = $env:COMPUTERNAME
        UserName       = $env:USERNAME
        OS             = $os.Caption
        OSVersion      = $os.Version
        OSBuild        = $os.BuildNumber
        Architecture   = $os.OSArchitecture
        CPU            = $cpu.Name.Trim()
        CPUCores       = $cpu.NumberOfCores
        CPUThreads     = $cpu.NumberOfLogicalProcessors
        TotalMemoryGB  = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        FreeMemoryGB   = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        UptimeDays     = [math]::Round($uptime.TotalDays, 2)
        UptimeDisplay  = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        LastBoot       = $os.LastBootUpTime
        Disks          = $disks
        Timestamp      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    if ($Detailed) {
        $processCount = (Get-Process).Count
        $serviceCount = (Get-Service | Where-Object { $_.Status -eq 'Running' }).Count
        $hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5

        $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object {
            [PSCustomObject]@{
                Description = $_.Description
                IPAddress   = ($_.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }) -join ', '
                Gateway     = ($_.DefaultIPGateway) -join ', '
                DNS         = ($_.DNSServerSearchOrder) -join ', '
                DHCP        = $_.DHCPEnabled
            }
        }

        $info | Add-Member -NotePropertyName RunningProcesses -NotePropertyValue $processCount
        $info | Add-Member -NotePropertyName RunningServices -NotePropertyValue $serviceCount
        $info | Add-Member -NotePropertyName RecentHotfixes -NotePropertyValue $hotfixes
        $info | Add-Member -NotePropertyName NetworkAdapters -NotePropertyValue $networkAdapters
    }

    return $info
}
