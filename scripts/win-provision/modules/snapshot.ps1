function New-Snapshot($path){
  $snap=[pscustomobject]@{
    Time=(Get-Date)
    Apps=(winget list)
    Features=Get-WindowsOptionalFeature -Online|Select FeatureName,State
    Capabilities=Get-WindowsCapability -Online|Select Name,State
  }
  $snap|ConvertTo-Json -Depth 50|Set-Content $path
}
