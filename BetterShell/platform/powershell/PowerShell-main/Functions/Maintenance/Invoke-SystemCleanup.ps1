function Invoke-SystemCleanup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param()

    Write-Host "Starting system cleanup..." -ForegroundColor Yellow

    $cleanupPaths = @(
        [System.IO.Path]::GetTempPath(),
        "$env:SystemRoot\Temp"
    )

    $totalSize = 0

    foreach ($path in $cleanupPaths) {
        if (Test-Path $path) {
            Write-Host "`nProcessing path: $path" -ForegroundColor Cyan
            $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            $pathSize = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $totalSize += $pathSize

            if ($PSCmdlet.ShouldProcess($path, "Clean items ($($items.Count) files/folders, $([math]::Round($pathSize / 1MB, 2)) MB)")) {
                foreach ($item in $items) {
                    try {
                        Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                        Write-Verbose "Removed: $($item.FullName)"
                    } catch {
                        Write-Warning "Could not remove: $($item.FullName). It may be in use."
                    }
                }
            }
        }
    }

    Write-Host "`nSystem cleanup complete." -ForegroundColor Green
    Write-Host "Total space recovered: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Green
}
