# Revert Console::WriteLine back to Write-Host (cleaner) and add SuppressMessageAttribute
$path    = 'D:\Dev\Migrate-OneDriveDevToLocal.ps1'
$content = Get-Content $path -Raw -Encoding UTF8

# Undo the Console replacements -> back to Write-Host with -ForegroundColor
$content = $content -replace '\[Console\]::ForegroundColor = \[System\.ConsoleColor\]::Cyan; \[Console\]::WriteLine\(\$line\); \[Console\]::ResetColor\(\)',
    'Write-Host $line -ForegroundColor Cyan'
$content = $content -replace '\[Console\]::ForegroundColor = \[System\.ConsoleColor\]::Green; \[Console\]::WriteLine\(\$line\); \[Console\]::ResetColor\(\)',
    'Write-Host $line -ForegroundColor Green'
$content = $content -replace '\[Console\]::ForegroundColor = \[System\.ConsoleColor\]::Yellow; \[Console\]::WriteLine\(\$line\); \[Console\]::ResetColor\(\)',
    'Write-Host $line -ForegroundColor Yellow'
$content = $content -replace '\[Console\]::ForegroundColor = \[System\.ConsoleColor\]::Red; \[Console\]::WriteLine\(\$line\); \[Console\]::ResetColor\(\)',
    'Write-Host $line -ForegroundColor Red'
$content = $content -replace '\[Console\]::ForegroundColor = \[System\.ConsoleColor\]::DarkGray; \[Console\]::WriteLine\(\$line\); \[Console\]::ResetColor\(\)',
    'Write-Host $line -ForegroundColor DarkGray'
$content = $content -replace '\[Console\]::WriteLine\(\$line\)',
    'Write-Host $line'

# Add SuppressMessageAttribute before the function Write-MigrationLog
$old = 'function Write-MigrationLog {'
$new = "[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification='Intentional interactive console output with color for migration UX')]`nfunction Write-MigrationLog {"
$content = $content.Replace($old, $new)

# Save with UTF8 BOM
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($path, $content, $utf8Bom)
Write-Host 'Reverted and SuppressMessageAttribute added.' -ForegroundColor Green
