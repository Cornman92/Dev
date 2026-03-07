function Restore-B11AppConfig {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$BackupId)

    $backups = Get-B11AppConfigBackup
    $backup = $backups | Where-Object { $_.Id -eq $BackupId } | Select-Object -First 1
    if ($null -eq $backup) { Write-Error "Backup not found: $BackupId"; return $false }
    if (-not $PSCmdlet.ShouldProcess($backup.AppName, 'Restore app config')) { return $false }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $tempDir = Join-Path $env:TEMP "B11AppRestore_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
        Expand-Archive -Path $backup.ArchivePath -DestinationPath $tempDir -Force

        foreach ($src in $backup.SourcePaths) {
            $folderName = Split-Path $src -Leaf
            $restored = Join-Path $tempDir $folderName
            if (Test-Path $restored) {
                if (Test-Path $src) { Remove-Item $src -Recurse -Force }
                Copy-Item -Path $restored -Destination $src -Recurse -Force
            }
        }
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        $sw.Stop()
        Write-B11BackupLog -Operation 'Restore' -BackupType 'AppConfig' -Target $backup.AppName -Status 'Success' -Message 'Config restored.' -DurationMs $sw.ElapsedMilliseconds
        return $true
    } catch {
        $sw.Stop()
        Write-B11BackupLog -Operation 'Restore' -BackupType 'AppConfig' -Target $backup.AppName -Status 'Failed' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
        Write-Error "App config restore failed: $_"
        return $false
    }
}
