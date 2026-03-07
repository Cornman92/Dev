function Get-ProcessByPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if (-not $connection) {
        Write-Host "No process found using port $Port" -ForegroundColor Yellow
        return
    }
    
    $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
    if ($process) {
        $process | Select-Object Id, ProcessName, Path
    } else {
        Write-Host "Process with ID $($connection.OwningProcess) not found" -ForegroundColor Red
    }
}
