function New-B11RestorePoint{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$Description)
if(-not $PSCmdlet.ShouldProcess($Description,'Create restore point')){return $false}
try{Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS -ErrorAction Stop;return $true}catch{Write-Error "Failed: $_";return $false}}
