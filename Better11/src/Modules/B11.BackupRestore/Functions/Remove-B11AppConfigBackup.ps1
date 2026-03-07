function Remove-B11AppConfigBackup {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$BackupId)

    $config = Read-JsonConfig -FileName 'appconfig-backups.json'
    if ($null -eq $config -or $null -eq $config.Backups) { Write-Error 'No backups.'; return $false }
    $backup = $config.Backups | Where-Object { $_.Id -eq $BackupId } | Select-Object -First 1
    if ($null -eq $backup) { Write-Error "Not found: $BackupId"; return $false }
    if (-not $PSCmdlet.ShouldProcess($BackupId, 'Delete app config backup')) { return $false }

    if (Test-Path $backup.ArchivePath) { Remove-Item $backup.ArchivePath -Force -ErrorAction SilentlyContinue }
    $config.Backups = @($config.Backups | Where-Object { $_.Id -ne $BackupId })
    Write-JsonConfig -FileName 'appconfig-backups.json' -Data $config
    Write-B11BackupLog -Operation 'Delete' -BackupType 'AppConfig' -Target $backup.AppName -Status 'Success' -Message 'Backup deleted.'
    return $true
}
