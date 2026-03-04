<#
.SYNOPSIS
    Renames multiple files using pattern matching and replacement.

.DESCRIPTION
    Bulk-renames files in a directory using regex or simple string
    replacement. Supports prefixing, suffixing, numbering, and
    case changes. Always previews changes before applying.

.PARAMETER Path
    Directory containing files to rename.

.PARAMETER Pattern
    Regex pattern to match in file names.

.PARAMETER Replacement
    Replacement string (supports regex backreferences like $1).

.PARAMETER Prefix
    String to prepend to all file names.

.PARAMETER Suffix
    String to append before the file extension.

.PARAMETER ToLower
    Convert all file names to lowercase.

.PARAMETER ToUpper
    Convert all file names to uppercase.

.PARAMETER Number
    Add sequential numbers as prefix (e.g., 001_, 002_).

.PARAMETER Filter
    Wildcard filter for which files to include (e.g., "*.jpg").

.PARAMETER Force
    Apply changes without confirmation prompt.

.EXAMPLE
    .\Invoke-BulkRename.ps1 -Path "C:\Photos" -Pattern "\s+" -Replacement "_" -Filter "*.jpg"
    Replaces spaces with underscores in JPG file names.

.EXAMPLE
    .\Invoke-BulkRename.ps1 -Path "C:\Docs" -Prefix "2026_" -Filter "*.pdf"
    Adds "2026_" prefix to all PDF files.

.EXAMPLE
    .\Invoke-BulkRename.ps1 -Path "C:\Music" -ToLower -Filter "*.mp3"
    Converts all MP3 file names to lowercase.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Path,

    [Parameter(ParameterSetName = 'Regex')]
    [string]$Pattern,

    [Parameter(ParameterSetName = 'Regex')]
    [string]$Replacement,

    [Parameter()]
    [string]$Prefix,

    [Parameter()]
    [string]$Suffix,

    [Parameter(ParameterSetName = 'Lower')]
    [switch]$ToLower,

    [Parameter(ParameterSetName = 'Upper')]
    [switch]$ToUpper,

    [Parameter()]
    [switch]$Number,

    [Parameter()]
    [string]$Filter = '*',

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Path -PathType Container)) {
    Write-Error "Directory not found: $Path"
}

$files = Get-ChildItem -Path $Path -File -Filter $Filter | Sort-Object Name
if ($files.Count -eq 0) {
    Write-Host "No files matching '$Filter' found in $Path" -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Bulk File Rename" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Directory: $Path"
Write-Host "  Files: $($files.Count)"
Write-Host ""

$renames = [System.Collections.Generic.List[PSCustomObject]]::new()
$counter = 1
$padWidth = ([string]$files.Count).Length

foreach ($file in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $extension = $file.Extension
    $newBaseName = $baseName

    # Apply regex replacement
    if ($Pattern) {
        $newBaseName = [regex]::Replace($newBaseName, $Pattern, $Replacement)
    }

    # Apply case change
    if ($ToLower) { $newBaseName = $newBaseName.ToLower() }
    if ($ToUpper) { $newBaseName = $newBaseName.ToUpper() }

    # Apply prefix
    if ($Prefix) { $newBaseName = "$Prefix$newBaseName" }

    # Apply suffix
    if ($Suffix) { $newBaseName = "$newBaseName$Suffix" }

    # Apply numbering
    if ($Number) {
        $num = $counter.ToString().PadLeft($padWidth, '0')
        $newBaseName = "${num}_$newBaseName"
    }

    $newName = "$newBaseName$extension"

    if ($newName -ne $file.Name) {
        $renames.Add([PSCustomObject]@{
            OldName = $file.Name
            NewName = $newName
            FullPath = $file.FullName
        })
    }

    $counter++
}

if ($renames.Count -eq 0) {
    Write-Host "No renames needed - all names already match the target pattern." -ForegroundColor Green
    return
}

# Preview
Write-Host "Preview ($($renames.Count) changes):" -ForegroundColor White
Write-Host ""
foreach ($rename in $renames) {
    Write-Host "  $($rename.OldName)" -ForegroundColor Red -NoNewline
    Write-Host " -> " -ForegroundColor Gray -NoNewline
    Write-Host "$($rename.NewName)" -ForegroundColor Green
}
Write-Host ""

# Confirm
if (-not $Force) {
    $confirm = Read-Host "Apply these renames? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }
}

# Apply
$successCount = 0
foreach ($rename in $renames) {
    $newPath = Join-Path (Split-Path $rename.FullPath -Parent) $rename.NewName
    if ($PSCmdlet.ShouldProcess($rename.OldName, "Rename to $($rename.NewName)")) {
        try {
            Rename-Item -Path $rename.FullPath -NewName $rename.NewName -ErrorAction Stop
            $successCount++
        }
        catch {
            Write-Host "  FAILED: $($rename.OldName) - $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Renamed $successCount of $($renames.Count) files." -ForegroundColor Green
Write-Host ""
