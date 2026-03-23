function New-B11BackupSchedule{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$Destination,[Parameter()][string]$Frequency='Daily',[Parameter()][int]$RetentionDays=30)
if(-not $PSCmdlet.ShouldProcess($Name,'Create schedule')){return $false}
$file=Join-Path $script:B11BackupDir 'schedules.json'
try{$list=if(Test-Path $file){@(Get-Content $file -Raw|ConvertFrom-Json)}else{@()}
$list=@($list|Where-Object{$_.Name -ne $Name})
$list+=[PSCustomObject]@{Name=$Name;SourcePath=$Source;DestinationPath=$Destination;Frequency=$Frequency;RetentionDays=$RetentionDays;NextRun=(Get-Date).AddDays(1).ToString('o');Enabled=$true}
$list|ConvertTo-Json -Depth 5|Set-Content $file -Force;return $true}catch{Write-Error "Failed: $_";return $false}}
