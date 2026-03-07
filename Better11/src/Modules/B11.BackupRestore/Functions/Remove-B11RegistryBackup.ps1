function Remove-B11RegistryBackup {
    <#
    .SYNOPSIS
        Deletes a registry backup.
    .PARAMETER BackupId
        The backup identifier.
    .EXAMPLE
        Remove-B11RegistryBackup -BackupId 'abc123'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$BackupId
    )

    $config = Read-JsonConfig -FileName 'registry-backups.json'
    if ($null -eq $config -or $null -eq $config.Backups) { Write-Error 'No backups found.'; return $false }

    $backup = $config.Backups | Where-Object { $_.Id -eq $BackupId } | Select-Object -First 1
    if ($null -eq $backup) { Write-Error "Backup not found: $BackupId"; return $false }

    if (-not $PSCmdlet.ShouldProcess($BackupId, 'Delete registry backup')) { return $false }

    if (Test-Path $backup.FilePath) { Remove-Item $backup.FilePath -Force -ErrorAction SilentlyContinue }
    $config.Backups = @($config.Backups | Where-Object { $_.Id -ne $BackupId })
    Write-JsonConfig -FileName 'registry-backups.json' -Data $config
    Write-B11BackupLog -Operation 'Delete' -BackupType 'Registry' -Target $backup.KeyPath -Status 'Success' -Message 'Backup deleted.'
    return $true
}
