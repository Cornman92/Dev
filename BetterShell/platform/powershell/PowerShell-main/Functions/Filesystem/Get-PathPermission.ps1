function Get-PathPermission {
    [CmdletBinding()]
    param([string]$Path = $PWD)

    Get-Acl -Path $Path | Format-List
}
