function Export-B11RegistryKey{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$KeyPath,[Parameter()][string]$Name='backup')
if(-not $PSCmdlet.ShouldProcess($KeyPath,'Export')){return $false}
$dir=Join-Path $script:B11BackupDir 'Registry';if(-not(Test-Path $dir)){New-Item $dir -ItemType Directory -Force|Out-Null}
$file=Join-Path $dir "$Name.reg";try{$null=reg export $KeyPath $file /y 2>&1;return $true}catch{Write-Error "Failed: $_";return $false}}
