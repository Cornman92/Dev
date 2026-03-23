function Get-TopProcesses {
    [CmdletBinding()]
    param()

    Write-Host "--- Top 5 CPU Processes ---" -ForegroundColor Cyan
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, PM
    Write-Host "--- Top 5 Memory Processes ---" -ForegroundColor Cyan
    Get-Process | Sort-Object PM -Descending | Select-Object -First 5 Name, CPU, PM
}
