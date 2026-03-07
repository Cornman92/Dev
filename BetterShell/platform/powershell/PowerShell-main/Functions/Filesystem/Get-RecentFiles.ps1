function Get-RecentFiles {
    [CmdletBinding()]
    param([string]$Path = $PWD, [int]$Count = 10)

    Get-ChildItem -Path $Path -File -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First $Count FullName, LastWriteTime
}
