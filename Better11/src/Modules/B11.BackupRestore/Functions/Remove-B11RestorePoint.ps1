function Remove-B11RestorePoint{[CmdletBinding(SupportsShouldProcess)][OutputType([bool])]param([Parameter(Mandatory)][int]$SequenceNumber)
if(-not $PSCmdlet.ShouldProcess("RP $SequenceNumber",'Delete')){return $false}
try{$null=vssadmin delete shadows /shadow=$SequenceNumber /quiet 2>&1;return $true}catch{Write-Error "Failed: $_";return $false}}
