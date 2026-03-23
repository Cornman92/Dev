function Get-FileTypesSummary {
    [CmdletBinding()]
    param([string]$Path = $PWD)

    Get-ChildItem -Path $Path -File -Recurse | Group-Object Extension | Sort-Object Count -Descending | Select-Object Name, Count
}
