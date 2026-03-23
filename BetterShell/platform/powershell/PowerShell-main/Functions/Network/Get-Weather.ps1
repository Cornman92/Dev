function Get-Weather {
    [CmdletBinding()]
    param(
        [string]$Location = 'New York',
        [int]$Days = 1
    )
    
    try {
        $uri = "https://wttr.in/$($Location)?format=%l+%c+%t+%h+%w+%p+%P&$Days"
        (Invoke-WebRequest -Uri $uri -UseBasicParsing).Content
    } catch {
        Write-Warning "Failed to get weather data: $_"
    }
}
