function Get-LargestFiles {
    [CmdletBinding()]
    param([string]$Path = $PWD, [int]$Count = 10)

    Get-ChildItem -Path $Path -File -Recurse | Sort-Object Length -Descending | Select-Object -First $Count FullName, @{Name='SizeMB';Expression={[math]::Round($_.Length/1MB,2)}}
}
