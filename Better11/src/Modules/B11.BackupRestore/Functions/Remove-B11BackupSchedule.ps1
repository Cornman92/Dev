function Remove-B11BackupSchedule{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$Name)
if(-not $PSCmdlet.ShouldProcess($Name,'Delete schedule')){return $false}
$file=Join-Path $script:B11BackupDir 'schedules.json'
try{if(-not(Test-Path $file)){return $false}
$list=@(Get-Content $file -Raw|ConvertFrom-Json|Where-Object{$_.Name -ne $Name})
$list|ConvertTo-Json -Depth 5|Set-Content $file -Force;return $true}catch{Write-Error "Failed: $_";return $false}}
