function Get-PSInfo {
    [CmdletBinding()]
    param()

    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "Installed Modules:" -ForegroundColor Green
    Get-Module -ListAvailable | Select-Object Name, Version
}
