function Copy-ItemBackup {
    [CmdletBinding()]
    param([string]$Source, [string]$Destination)

    Copy-Item -Path $Source -Destination $Destination -Recurse -Force
    Write-Host "Backup from $Source to $Destination complete." -ForegroundColor Green
}
