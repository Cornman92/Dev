function Restore-B11DisasterRecoveryBundle {
    <#
    .SYNOPSIS
        Restores from a disaster recovery bundle.
    .PARAMETER BundlePath
        Path to the bundle .zip file.
    #>
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [string]$BundlePath)

    if (-not (Test-Path $BundlePath)) { Write-Error "Bundle not found: $BundlePath"; return $false }
    if (-not $PSCmdlet.ShouldProcess($BundlePath, 'Restore DR bundle')) { return $false }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $tempDir = Join-Path $env:TEMP "B11DRRestore_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
        Expand-Archive -Path $BundlePath -DestinationPath $tempDir -Force

        # Restore registry files
        $regDir = Join-Path $tempDir 'Registry'
        if (Test-Path $regDir) {
            Get-ChildItem -Path $regDir -Filter '*.reg' | ForEach-Object {
                $null = & reg.exe import $_.FullName 2>&1
            }
        }

        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        $sw.Stop()
        Write-B11BackupLog -Operation 'Restore' -BackupType 'DisasterRecovery' -Target $BundlePath -Status 'Success' -Message 'Bundle restored.' -DurationMs $sw.ElapsedMilliseconds
        return $true
    } catch {
        $sw.Stop()
        Write-B11BackupLog -Operation 'Restore' -BackupType 'DisasterRecovery' -Target $BundlePath -Status 'Failed' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
        Write-Error "DR bundle restore failed: $_"
        return $false
    }
}
