# CreateModuleStructure.ps1
# This script creates the directory structure for the FileSystem module

$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the directory structure
$structure = @{
    'Private\Backup' = @()
    'Private\FileOperations' = @() 
    'Private\Permissions' = @()
    'Private\Utilities' = @()
    'Public\Backup' = @()
    'Public\FileOperations' = @()
    'Public\DirectoryOperations' = @()
    'Public\SearchAndFilter' = @()
    'Public\ContentOperations' = @()
    'Tests\Unit' = @()
    'Tests\Integration' = @()
    'docs' = @('en-US')
    'en-US' = @('about_FileSystem.help.txt')
}

# Create directories
foreach ($dir in $structure.Keys) {
    $fullPath = Join-Path -Path $moduleRoot -ChildPath $dir
    if (-not (Test-Path -Path $fullPath)) {
        $null = New-Item -ItemType Directory -Path $fullPath -Force
        Write-Host "Created directory: $fullPath" -ForegroundColor Green
    }
    
    # Create any files in the directory
    foreach ($file in $structure[$dir]) {
        $filePath = Join-Path -Path $fullPath -ChildPath $file
        if (-not (Test-Path -Path $filePath)) {
            $null = New-Item -ItemType File -Path $filePath -Force
            Write-Host "Created file: $filePath" -ForegroundColor Cyan
        }
    }
}

# Create a basic about_FileSystem help file
$aboutContent = @'
TOPIC
    about_FileSystem

SHORT DESCRIPTION
    Describes the FileSystem module and its functionality.

LONG DESCRIPTION
    The FileSystem module provides advanced file system operations including:
    - File and directory management
    - Backup and restore operations
    - File searching and filtering
    - Content manipulation
    - Permission management

EXAMPLES
    # Get help for the module
    Get-Help about_FileSystem -Full

    # List all available commands
    Get-Command -Module FileSystem

RELATED LINKS
    Online version: https://github.com/yourusername/FileSystem

KEYWORDS
    FileSystem, Files, Directories, Backup, Restore, Search, Filter
'@

$aboutPath = Join-Path -Path $moduleRoot -ChildPath "en-US\about_FileSystem.help.txt"
$aboutContent | Out-File -FilePath $aboutPath -Force

Write-Host "`nModule structure created successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Add your functions to the appropriate Public and Private directories"
Write-Host "2. Update the module manifest if you add new functions"
Write-Host "3. Run tests using Invoke-Pester"
Write-Host "4. Import the module with: Import-Module $moduleRoot -Force"
