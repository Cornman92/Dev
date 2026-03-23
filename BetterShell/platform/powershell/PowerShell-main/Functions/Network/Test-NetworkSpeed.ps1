function Test-NetworkSpeed {
    [CmdletBinding()]
    param()

    if (Get-Command speedtest -ErrorAction SilentlyContinue) {
        speedtest
    } else {
        Write-Host "speedtest-cli not installed. Install via 'pip install speedtest-cli' or download from https://www.speedtest.net/apps/cli" -ForegroundColor Red
    }
}
