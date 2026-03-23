function Get-RunningServices {
    [CmdletBinding()]
    param()

    Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name, DisplayName
}
