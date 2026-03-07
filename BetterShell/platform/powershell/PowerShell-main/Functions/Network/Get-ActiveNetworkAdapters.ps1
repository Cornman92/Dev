function Get-ActiveNetworkAdapters {
    [CmdletBinding()]
    param()

    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name, Status, MacAddress, LinkSpeed
}
