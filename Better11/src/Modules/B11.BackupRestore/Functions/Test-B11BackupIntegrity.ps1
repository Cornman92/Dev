function Test-B11BackupIntegrity {
    <#
    .SYNOPSIS
        Verifies integrity of all backup files. Returns list of issues found.
    #>
    [CmdletBinding()] [OutputType([string[]])]
    param()

    $issues = @()
    foreach ($b in (Get-B11RegistryBackup)) {
        if (-not (Test-Path $b.FilePath)) { $issues += "MISSING: Registry '$($b.Name)' - $($b.FilePath)" }
        elseif ((Get-Item $b.FilePath).Length -eq 0) { $issues += "EMPTY: Registry '$($b.Name)' - $($b.FilePath)" }
    }
    foreach ($b in (Get-B11AppConfigBackup)) {
        if (-not (Test-Path $b.ArchivePath)) { $issues += "MISSING: AppConfig '$($b.Name)' - $($b.ArchivePath)" }
        elseif ((Get-Item $b.ArchivePath).Length -eq 0) { $issues += "EMPTY: AppConfig '$($b.Name)' - $($b.ArchivePath)" }
        else {
            try { $null = [System.IO.Compression.ZipFile]::OpenRead($b.ArchivePath).Dispose() }
            catch { $issues += "CORRUPTED: AppConfig '$($b.Name)' - invalid archive" }
        }
    }
    Write-B11BackupLog -Operation 'Verify' -BackupType 'All' -Target 'Integrity Check' -Status 'Success' -Message "$($issues.Count) issues found."
    return @($issues)
}
