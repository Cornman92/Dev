function New-B11FileBackup{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination,[Parameter()][bool]$Compress=$true,[Parameter()][bool]$Encrypt=$false)
if(-not $PSCmdlet.ShouldProcess($Source,'Backup')){return $false}
if(-not(Test-Path $Source)){Write-Error "Source not found";return $false}
try{$name="backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')";$dst=if($Destination){$Destination}else{Join-Path $script:B11BackupDir "Files"}
if(-not(Test-Path $dst)){New-Item $dst -ItemType Directory -Force|Out-Null}
if($Compress){$zipPath=Join-Path $dst "$name.zip";Compress-Archive -Path "$Source\*" -DestinationPath $zipPath -Force}
else{$copyDst=Join-Path $dst $name;Copy-Item -Path $Source -Destination $copyDst -Recurse -Force}
return $true}catch{Write-Error "Failed: $_";return $false}}
