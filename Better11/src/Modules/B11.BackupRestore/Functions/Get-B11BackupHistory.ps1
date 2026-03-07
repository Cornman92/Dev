function Get-B11BackupHistory {
    <#
    .SYNOPSIS
        Gets the backup operation history log.
    .PARAMETER MaxEntries
        Maximum entries to return.
    #>
    [CmdletBinding()] [OutputType([PSCustomObject[]])]
    param([Parameter()] [int]$MaxEntries = 100)

    $config = Read-JsonConfig -FileName 'history.json'
    if ($null -eq $config -or $null -eq $config.Entries) { return @() }
    return @($config.Entries | Select-Object -First $MaxEntries)
}
