function Restore-B11RegistryKey {
    <#
    .SYNOPSIS
        Restores a registry backup by importing the .reg file.
    .PARAMETER BackupId
        The backup identifier.
    .EXAMPLE
        Restore-B11RegistryKey -BackupId 'abc123'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$BackupId
    )

    $backups = Get-B11RegistryBackup
    $backup = $backups | Where-Object { $_.Id -eq $BackupId } | Select-Object -First 1
    if ($null -eq $backup) { Write-Error "Backup not found: $BackupId"; return $false }

    if (-not $PSCmdlet.ShouldProcess($backup.KeyPath, 'Restore registry key')) { return $false }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $regFile = $backup.FilePath
        if ($backup.IsCompressed) {
            $tempDir = Join-Path $env:TEMP "B11RegRestore_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
            Expand-Archive -Path $regFile -DestinationPath $tempDir -Force
            $regFile = Get-ChildItem -Path $tempDir -Filter '*.reg' | Select-Object -First 1 -ExpandProperty FullName
        }

        $null = & reg.exe import $regFile 2>&1
        if ($LASTEXITCODE -ne 0) { throw "reg.exe import failed with code $LASTEXITCODE" }

        if ($backup.IsCompressed -and (Test-Path $tempDir)) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        $sw.Stop()
        Write-B11BackupLog -Operation 'Restore' -BackupType 'Registry' -Target $backup.KeyPath -Status 'Success' -Message 'Registry restored.' -DurationMs $sw.ElapsedMilliseconds
        return $true
    } catch {
        $sw.Stop()
        Write-B11BackupLog -Operation 'Restore' -BackupType 'Registry' -Target $backup.KeyPath -Status 'Failed' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
        Write-Error "Registry restore failed: $_"
        return $false
    }
}
