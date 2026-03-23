function Get-B11RegistryBackup{[CmdletBinding()][OutputType([PSCustomObject[]])]param()
$dir=Join-Path $script:B11BackupDir 'Registry';if(-not(Test-Path $dir)){return @()}
return @(Get-ChildItem $dir -Filter '*.reg'|ForEach-Object{[PSCustomObject]@{Name=$_.BaseName;KeyPath='';FilePath=$_.FullName;Created=$_.CreationTime.ToString('o');SizeKb=[math]::Round($_.Length/1KB)}})}
