function Show-Tree {
    [CmdletBinding()]
    param([string]$Path = '.')

    tree $Path
}
