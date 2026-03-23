function Backup-B11AppConfig {
    <#
    .SYNOPSIS
        Backs up application config folders to a compressed archive.
    .PARAMETER Name
        Backup name.
    .PARAMETER AppName
        Application name.
    .PARAMETER SourcePaths
        Pipe-delimited source folder paths.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter()] [string]$AppName = '',
        [Parameter(Mandatory)] [string]$SourcePaths
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $id = [Guid]::NewGuid().ToString('N')
    $paths = $SourcePaths -split '\|' | Where-Object { $_ -ne '' }
    $archivePath = Join-Path $script:AppConfigDir "$id.zip"

    try {
        $tempStaging = Join-Path $env:TEMP "B11AppCfg_$id"
        New-Item -Path $tempStaging -ItemType Directory -Force | Out-Null
        $fileCount = 0

        foreach ($src in $paths) {
            if (Test-Path $src) {
                $destName = (Split-Path $src -Leaf)
                $dest = Join-Path $tempStaging $destName
                Copy-Item -Path $src -Destination $dest -Recurse -Force
                $fileCount += (Get-ChildItem -Path $dest -Recurse -File).Count
            }
        }

        Compress-Archive -Path "$tempStaging\*" -DestinationPath $archivePath -Force
        Remove-Item $tempStaging -Recurse -Force -ErrorAction SilentlyContinue

        $size = (Get-Item $archivePath).Length
        $backup = [PSCustomObject]@{
            Id          = $id
            Name        = $Name
            AppName     = $AppName
            SourcePaths = @($paths)
            ArchivePath = $archivePath
            SizeBytes   = $size
            CreatedDate = [DateTime]::UtcNow.ToString('o')
            FileCount   = $fileCount
            Status      = 'Success'
        }

        $config = Read-JsonConfig -FileName 'appconfig-backups.json'
        if ($null -eq $config) { $config = [PSCustomObject]@{ Backups = @() } }
        $list = [System.Collections.Generic.List[object]]::new()
        if ($config.Backups) { foreach ($b in $config.Backups) { $list.Add($b) } }
        $list.Add($backup)
        $config.Backups = $list.ToArray()
        Write-JsonConfig -FileName 'appconfig-backups.json' -Data $config

        $sw.Stop()
        Write-B11BackupLog -Operation 'Backup' -BackupType 'AppConfig' -Target $AppName -Status 'Success' -Message "$fileCount files archived." -DurationMs $sw.ElapsedMilliseconds
        return $backup
    } catch {
        $sw.Stop()
        Write-B11BackupLog -Operation 'Backup' -BackupType 'AppConfig' -Target $AppName -Status 'Failed' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
        Write-Error "App config backup failed: $_"
        return $null
    }
}
