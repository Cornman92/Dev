function Show-ASCIIWelcome {
    [CmdletBinding()]
    param()

    $art = @'
   _____                 _ _           _ 
  / ____|               | (_)         | |
 | (___   ___  _ __   __| |_  ___ __ _| |
  \___ \ / _ \| '_ \ / _` | |/ __/ _` | |
  ____) | (_) | | | | (_| | | (_| (_| | |
 |_____/ \___/|_| |_|\__,_|_|\__\__,_ |_|
'@
    Write-Host $art -ForegroundColor Cyan
}
