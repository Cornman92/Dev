function Get-SystemUptime {
    [CmdletBinding()]
    param()

    $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    Write-Host "System Uptime: $($uptime.ToString('g'))" -ForegroundColor Magenta
}
