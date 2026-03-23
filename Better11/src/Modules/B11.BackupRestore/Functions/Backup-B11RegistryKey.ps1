function Backup-B11RegistryKey {
    <#
    .SYNOPSIS
        Exports a registry key to a backup file.
    .PARAMETER Name
        The backup name.
    .PARAMETER KeyPath
        The registry key path (e.g., HKLM:\SOFTWARE\Microsoft).
    .PARAMETER Compress
        Whether to compress the export.
    .EXAMPLE
        Backup-B11RegistryKey -Name 'Before Tweak' -KeyPath 'HKLM:\SOFTWARE\Microsoft' -Compress $true
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$KeyPath,

        [Parameter()]
        [bool]$Compress = $true
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $id = [Guid]::NewGuid().ToString('N')
    $regFile = Join-Path $script:RegistryDir "$id.reg"

    try {
        # Convert PS drive path to reg.exe format
        $regPath = $KeyPath -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' `
                            -replace '^HKCU:\\', 'HKEY_CURRENT_USER\' `
                            -replace '^HKCR:\\', 'HKEY_CLASSES_ROOT\'

        $null = & reg.exe export $regPath $regFile /y 2>&1
        if ($LASTEXITCODE -ne 0) { throw "reg.exe export failed with code $LASTEXITCODE" }

        $size = (Get-Item $regFile).Length
        $finalPath = $regFile

        if ($Compress) {
            $zipFile = "$regFile.zip"
            Compress-Archive -Path $regFile -DestinationPath $zipFile -Force
            Remove-Item $regFile -Force
            $finalPath = $zipFile
            $size = (Get-Item $zipFile).Length
        }

        $backup = [PSCustomObject]@{
            Id           = $id
            Name         = $Name
            KeyPath      = $KeyPath
            FilePath     = $finalPath
            SizeBytes    = $size
            CreatedDate  = [DateTime]::UtcNow.ToString('o')
            Status       = 'Success'
            IsCompressed = $Compress
        }

        $config = Read-JsonConfig -FileName 'registry-backups.json'
        if ($null -eq $config) { $config = [PSCustomObject]@{ Backups = @() } }
        $list = [System.Collections.Generic.List[object]]::new()
        if ($config.Backups) { foreach ($b in $config.Backups) { $list.Add($b) } }
        $list.Add($backup)
        $config.Backups = $list.ToArray()
        Write-JsonConfig -FileName 'registry-backups.json' -Data $config

        $sw.Stop()
        Write-B11BackupLog -Operation 'Backup' -BackupType 'Registry' -Target $KeyPath -Status 'Success' -Message "Exported $KeyPath" -DurationMs $sw.ElapsedMilliseconds
        return $backup
    } catch {
        $sw.Stop()
        Write-B11BackupLog -Operation 'Backup' -BackupType 'Registry' -Target $KeyPath -Status 'Failed' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
        Write-Error "Registry backup failed: $_"
        return $null
    }
}
