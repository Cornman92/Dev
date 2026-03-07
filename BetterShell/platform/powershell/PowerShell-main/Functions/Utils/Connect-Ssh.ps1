function Connect-Ssh {
    [CmdletBinding()]
    param([string]$Host)

    ssh $Host
}
