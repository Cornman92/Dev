function Start-Timer {
    [CmdletBinding()]
    param()

    $global:TimerStart = Get-Date
    Write-Host "Timer started at $($global:TimerStart)" -ForegroundColor Green
}

function Stop-Timer {
    [CmdletBinding()]
    param()

    if ($global:TimerStart) {
        $elapsed = (Get-Date) - $global:TimerStart
        Write-Host "Elapsed time: $($elapsed.ToString('g'))" -ForegroundColor Yellow
        Remove-Variable TimerStart -Scope Global
    } else {
        Write-Host "No timer running." -ForegroundColor Red
    }
}
