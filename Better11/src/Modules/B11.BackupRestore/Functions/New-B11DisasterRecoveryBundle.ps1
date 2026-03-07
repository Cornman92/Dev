function New-B11DisasterRecoveryBundle {
    <#
    .SYNOPSIS
        Creates a disaster recovery bundle combining restore point + registry + app configs.
    .PARAMETER Name
        Bundle name.
    #>
    [CmdletBinding(SupportsShouldProcess)] [OutputType([string])]
    param([Parameter(Mandatory)] [string]$Name)

    if (-not $PSCmdlet.ShouldProcess('System', "Create DR bundle: $Name")) { return '' }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $bundleId = [Guid]::NewGuid().ToString('N')
    $bundleDir = Join-Path $script:BundleDir $bundleId
    New-Item -Path $bundleDir -ItemType Directory -Force | Out-Null

    try {
        # 1. Create restore point
        New-B11RestorePoint -Description "DR Bundle: $Name" -Confirm:$false -ErrorAction SilentlyContinue

        # 2. Copy all registry backups
        $regDir = Join-Path $bundleDir 'Registry'
        New-Item -Path $regDir -ItemType Directory -Force | Out-Null
        foreach ($b in (Get-B11RegistryBackup)) {
            if (Test-Path $b.FilePath) { Copy-Item -Path $b.FilePath -Destination $regDir -Force }
        }

        # 3. Copy all app config backups
        $appDir = Join-Path $bundleDir 'AppConfig'
        New-Item -Path $appDir -ItemType Directory -Force | Out-Null
        foreach ($b in (Get-B11AppConfigBackup)) {
            if (Test-Path $b.ArchivePath) { Copy-Item -Path $b.ArchivePath -Destination $appDir -Force }
        }

        # 4. Include metadata
        $meta = [PSCustomObject]@{
            Name = $Name; Id = $bundleId; CreatedDate = [DateTime]::UtcNow.ToString('o')
            RegistryBackups = (Get-B11RegistryBackup).Count
            AppConfigBackups = (Get-B11AppConfigBackup).Count
        }
        $meta | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $bundleDir 'bundle-manifest.json') -Force

        # 5. Compress bundle
        $bundleZip = Join-Path $script:BundleDir "$Name-$bundleId.zip"
        Compress-Archive -Path "$bundleDir\*" -DestinationPath $bundleZip -Force
        Remove-Item $bundleDir -Recurse -Force -ErrorAction SilentlyContinue

        $sw.Stop()
        Write-B11BackupLog -Operation 'Create' -BackupType 'DisasterRecovery' -Target $Name -Status 'Success' -Message "Bundle created: $bundleZip" -DurationMs $sw.ElapsedMilliseconds
        return $bundleZip
    } catch {
        $sw.Stop()
        Write-B11BackupLog -Operation 'Create' -BackupType 'DisasterRecovery' -Target $Name -Status 'Failed' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
        Write-Error "DR bundle creation failed: $_"
        return ''
    }
}
