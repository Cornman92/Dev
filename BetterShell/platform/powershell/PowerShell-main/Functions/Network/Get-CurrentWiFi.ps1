function Get-CurrentWiFi {
    [CmdletBinding()]
    param()

    netsh wlan show interfaces | Select-String 'SSID'
}
