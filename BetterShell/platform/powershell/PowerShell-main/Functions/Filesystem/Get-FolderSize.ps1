function Get-FolderSize {
    [CmdletBinding()]
    param([string]$Path = $PWD)

    $size = (Get-ChildItem -Path $Path -Recurse -File | Measure-Object -Property Length -Sum).Sum
    Write-Host "Total size of files in $($Path): $([math]::Round($size/1MB,2)) MB" -ForegroundColor Yellow
}
