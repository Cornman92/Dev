function Get-B11RestorePoint{[CmdletBinding()][OutputType([PSCustomObject[]])]param()
try{return @(Get-ComputerRestorePoint -ErrorAction Stop|ForEach-Object{[PSCustomObject]@{SequenceNumber=$_.SequenceNumber;Description=$_.Description;CreationTime="$($_.CreationTime)";RestorePointType="$($_.RestorePointType)"}})}catch{return @()}}
