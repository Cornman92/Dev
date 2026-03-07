function Open-UrlInBrowser {
    [CmdletBinding()]
    param([string]$Url)

    Start-Process $Url
    Write-Host "Opened $Url in default browser." -ForegroundColor Cyan
}
