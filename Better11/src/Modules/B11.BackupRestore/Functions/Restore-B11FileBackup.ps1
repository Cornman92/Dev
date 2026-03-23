function Restore-B11FileBackup{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$BackupPath,[Parameter(Mandatory)][string]$RestorePath)
if(-not $PSCmdlet.ShouldProcess($BackupPath,'Restore')){return $false}
if(-not(Test-Path $BackupPath)){Write-Error "Not found";return $false}
try{if($BackupPath -like '*.zip'){Expand-Archive -Path $BackupPath -DestinationPath $RestorePath -Force}
else{Copy-Item -Path $BackupPath -Destination $RestorePath -Recurse -Force};return $true}catch{Write-Error "Failed: $_";return $false}}
