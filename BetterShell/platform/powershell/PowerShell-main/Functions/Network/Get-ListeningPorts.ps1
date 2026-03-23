function Get-ListeningPorts {
    [CmdletBinding()]
    param()

    Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' } | Select-Object LocalAddress, LocalPort, OwningProcess
}
