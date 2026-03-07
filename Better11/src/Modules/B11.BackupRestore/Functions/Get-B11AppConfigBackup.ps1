function Get-B11AppConfigBackup {
    [CmdletBinding()] [OutputType([PSCustomObject[]])] param()
    $config = Read-JsonConfig -FileName 'appconfig-backups.json'
    if ($null -eq $config -or $null -eq $config.Backups) { return @() }
    return $config.Backups
}
