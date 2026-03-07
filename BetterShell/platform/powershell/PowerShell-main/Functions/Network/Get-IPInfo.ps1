function Get-IPInfo {
    [CmdletBinding()]
    param()

    Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4"}
}
