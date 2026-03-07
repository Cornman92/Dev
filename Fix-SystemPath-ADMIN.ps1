#Requires -RunAsAdministrator
# Fix-SystemPath-ADMIN.ps1
# Fixes two corruptions in the System (Machine) PATH:
#   1. Merged entry: "C:\Program Files\nodejs \user C\Users\C-Man\..." 
#      -> Split back into just "C:\Program Files\nodejs"
#   2. Truncated entry at end: "%ProgramW6432%\NVIDIA" -> removed (already present in full form)
# Run this script as Administrator (right-click -> Run as Administrator)

Write-Host "Reading current System PATH..." -ForegroundColor Cyan
$currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')

Write-Host "`nCurrent System PATH entries:" -ForegroundColor Yellow
$entries = $currentPath -split ';'
for ($i = 0; $i -lt $entries.Count; $i++) {
    Write-Host "  [$i] $($entries[$i])"
}

# --- Fix 1: Replace the corrupted merged nodejs+Python entry ---
$corruptedEntry = 'C:\Program Files\nodejs \user C\Users\C-Man\AppData\Local\Programs\Python\Python313\Scripts\'
$nodejsEntry    = 'C:\Program Files\nodejs'

if ($currentPath -like "*$corruptedEntry*") {
    Write-Host "`n[FIX 1] Found corrupted entry. Replacing with clean nodejs entry..." -ForegroundColor Green
    $currentPath = $currentPath.Replace($corruptedEntry, $nodejsEntry)
} else {
    Write-Host "`n[FIX 1] Corrupted nodejs entry not found (may already be fixed)." -ForegroundColor Yellow
}

# --- Fix 2: Remove truncated %ProgramW6432%\NVIDIA entry at end ---
$truncated = '%ProgramW6432%\NVIDIA'
if ($currentPath.TrimEnd(';').EndsWith($truncated)) {
    Write-Host "[FIX 2] Found truncated NVIDIA entry at end. Removing..." -ForegroundColor Green
    # Remove trailing truncated entry
    $currentPath = ($currentPath -split ';' | Where-Object { $_ -ne $truncated -and $_ -ne '' }) -join ';'
} elseif ($currentPath -like "*$truncated;*" -or $currentPath -like "*$truncated") {
    Write-Host "[FIX 2] Found truncated NVIDIA entry. Removing..." -ForegroundColor Green
    $currentPath = ($currentPath -split ';' | Where-Object { $_ -ne $truncated -and $_ -ne '' }) -join ';'
} else {
    Write-Host "[FIX 2] Truncated NVIDIA entry not found (may already be fixed)." -ForegroundColor Yellow
}

# --- Remove duplicate empty entries ---
$cleanEntries = $currentPath -split ';' | Where-Object { $_.Trim() -ne '' } | Select-Object -Unique
$cleanPath = $cleanEntries -join ';'

Write-Host "`nNew System PATH entries:" -ForegroundColor Yellow
for ($i = 0; $i -lt $cleanEntries.Count; $i++) {
    Write-Host "  [$i] $($cleanEntries[$i])"
}

$confirm = Read-Host "`nApply these changes to System PATH? (yes/no)"
if ($confirm -eq 'yes') {
    [System.Environment]::SetEnvironmentVariable('PATH', $cleanPath, 'Machine')
    Write-Host "`n[DONE] System PATH updated. Restart your terminal for changes to take effect." -ForegroundColor Green
} else {
    Write-Host "`n[CANCELLED] No changes made." -ForegroundColor Red
}
