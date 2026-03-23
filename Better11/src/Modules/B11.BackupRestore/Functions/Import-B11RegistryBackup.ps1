function Import-B11RegistryBackup{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$FilePath)
if(-not $PSCmdlet.ShouldProcess($FilePath,'Import')){return $false}
if(-not(Test-Path $FilePath)){Write-Error "Not found: $FilePath";return $false}
try{$null=reg import $FilePath 2>&1;return $true}catch{Write-Error "Failed: $_";return $false}}
