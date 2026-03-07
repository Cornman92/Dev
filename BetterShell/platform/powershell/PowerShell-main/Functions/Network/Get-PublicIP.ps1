function Get-PublicIP {
    [CmdletBinding()]
    param()
    
    try {
        (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip
    } catch {
        Write-Warning "Failed to get public IP: $_"
    }
}
