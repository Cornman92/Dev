function Invoke-SystemCleanup {
    [CmdletBinding()]
    param()

    Write-Host "Cleaning temp files..." -ForegroundColor Yellow
    Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Emptying recycle bin..." -ForegroundColor Yellow
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup complete!" -ForegroundColor Green
}
