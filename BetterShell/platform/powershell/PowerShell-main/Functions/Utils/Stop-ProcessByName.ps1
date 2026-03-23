function Stop-ProcessByName {
    [CmdletBinding()]
    param([string]$Name)

    Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "Process '$Name' killed (if running)." -ForegroundColor Magenta
}
