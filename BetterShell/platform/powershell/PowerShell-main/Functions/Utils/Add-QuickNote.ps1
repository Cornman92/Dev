function Add-QuickNote {
    [CmdletBinding()]
    param([string]$Note)

    $notesFile = "$env:USERPROFILE\quick_notes.txt"
    Add-Content -Path $notesFile -Value ("[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Note")
    Write-Host "Note added to $notesFile" -ForegroundColor Green
}
