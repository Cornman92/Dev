function Assert-Admin {
  $p = New-Object Security.Principal.WindowsPrincipal `
       ([Security.Principal.WindowsIdentity]::GetCurrent())
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run PowerShell as Administrator."
  }
}
function Read-Json($p){ Get-Content $p -Raw | ConvertFrom-Json }
function Write-Json($p,$o){ ($o|ConvertTo-Json -Depth 80)|Set-Content $p -Encoding UTF8 }
function Ensure-Prop($o,$n,$d){
  if(-not($o.PSObject.Properties.Name -contains $n)){
    $o|Add-Member -NotePropertyName $n -NotePropertyValue $d -Force
  }
}
function Module-Enabled($t,$n){
  try{ [bool]$t.modules.$n.Enabled }catch{ $false }
}
