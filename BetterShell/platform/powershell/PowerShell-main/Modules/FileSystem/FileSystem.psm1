# FileSystem.psm1 - Main module file for FileSystem module

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import required .NET assemblies
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Security

# Module variables
$script:ModuleName = 'FileSystem'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleDataPath = Join-Path -Path $env:APPDATA -ChildPath $ModuleName
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$script:logFile = Join-Path -Path $script:ModuleDataPath -ChildPath "$($script:ModuleName)_$(Get-Date -Format 'yyyyMMdd').log"

# Create module data directory if it doesn't exist
if (-not (Test-Path -Path $script:ModuleDataPath)) {
    $null = New-Item -ItemType Directory -Path $script:ModuleDataPath -Force
}

# Function to source all .ps1 files in a directory
function Import-DirectoryFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Filter *.ps1 -Recurse | ForEach-Object {
            try {
                $content = Get-Content -Path $_.FullName -Raw
                $sb = [ScriptBlock]::Create($content)
                . $sb
                Write-Verbose "Imported function: $($_.Name)"
            }
            catch {
                Write-Error "Failed to import function $($_.Name): $_"
            }
        }
    }
}

# Function to test if a command exists
function Test-CommandExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command
    )
    
    try {
        $null = Get-Command -Name $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Check for required external commands
$requiredCommands = @('robocopy')
$recommendedCommands = @('7z')

$missingRequired = $requiredCommands | Where-Object { -not (Test-CommandExists -Command $_) }
$missingRecommended = $recommendedCommands | Where-Object { -not (Test-CommandExists -Command $_) }

if ($missingRequired) {
    $errorMessage = "The following required commands are not available: $($missingRequired -join ', ')"
    Write-Error $errorMessage -ErrorAction Stop
    throw $errorMessage
}

if ($missingRecommended) {
    Write-Warning "The following recommended commands are not available: $($missingRecommended -join ', ')"
    Write-Warning "Some functionality may be limited without these tools."
}

# Import all private functions first
$privateFunctions = @{
    'Backup' = @(
        'Initialize-BackupEnvironment.ps1',
        'New-BackupManifest.ps1',
        'Test-BackupIntegrity.ps1',
        'Get-BackupRetentionPolicy.ps1'
    )
    'FileOperations' = @(
        'Test-FileLock.ps1',
        'Get-FileHashExtended.ps1',
        'ConvertTo-FileSize.ps1',
        'Test-ValidPath.ps1'
    )
    'Permissions' = @(
        'Get-FileSystemAccess.ps1',
        'Set-FileSystemAccess.ps1',
        'Copy-FileSystemPermissions.ps1',
        'Reset-FileSystemPermissions.ps1'
    )
    'Utilities' = @(
        'Write-Log.ps1',
        'Get-LogFile.ps1',
        'Test-IsAdministrator.ps1',
        'Get-FileSystemInfo.ps1',
        'Get-FileType.ps1'
    )
}

# Import all private functions
foreach ($category in $privateFunctions.Keys) {
    $categoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Private\$category"
    if (Test-Path -Path $categoryPath) {
        Get-ChildItem -Path $categoryPath -Filter *.ps1 | ForEach-Object {
            try {
                $functionName = $_.BaseName
                Write-Verbose "Importing function from: $($_.FullName)"
                . $_.FullName
                Write-Verbose "Successfully imported function: $functionName"
            }
            catch {
                Write-Error "Failed to import function from $($_.Name): $_"
            }
        }
    }
}

# Define public functions to export
$publicFunctions = @{
    'Compression' = @(
        'Compress-Folder.ps1',
        'Expand-Zip.ps1'
    )
    'FileManagement' = @(
        'Get-ChildItemDetailed.ps1',
        'Get-FileHash.ps1',
        'Copy-FileWithProgress.ps1',
        'Move-FileWithProgress.ps1',
        'Remove-FileSafely.ps1',
        'Get-FileHashExtended.ps1',
        'Test-FileLock.ps1',
        'Wait-FileUnlock.ps1'
    )
    'Search' = @(
        'Find-DuplicateFiles.ps1',
        'Search-FileContent.ps1'
    )
    'DirectoryOperations' = @(
        'Get-DirectorySize.ps1',
        'Get-DirectoryTree.ps1',
        'New-DirectoryStructure.ps1',
        'Remove-EmptyDirectories.ps1',
        'Test-DirectoryEmpty.ps1'
    )
    'Backup' = @(
        'Backup-Folder.ps1',
        'Restore-Folder.ps1',
        'Get-BackupHistory.ps1',
        'Remove-OldBackups.ps1',
        'Register-FileSystemBackupSchedule.ps1',
        'Get-FileSystemBackupSchedule.ps1',
        'Unregister-FileSystemBackupSchedule.ps1'
    )
}

# Import all public functions
$script:functionsToExport = @()
foreach ($category in $publicFunctions.Keys) {
    $categoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Public\$category"
    if (Test-Path -Path $categoryPath) {
        foreach ($functionFile in $publicFunctions[$category]) {
            $functionPath = Join-Path -Path $categoryPath -ChildPath $functionFile
            if (Test-Path -Path $functionPath) {
                try {
                    . $functionPath
                    $functionName = $functionFile -replace '\.ps1$', ''
                    $script:functionsToExport += $functionName
                    Write-Verbose "Imported public function: $functionName"
                }
                catch {
                    Write-Error "Failed to import public function '$functionFile': $_"
                }
            }
        }
    }
}

# Export public functions
if ($script:functionsToExport) {
    Export-ModuleMember -Function $script:functionsToExport
}

# Set up module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Clean up any module-specific resources here
    Write-Verbose "Cleaning up $ModuleName module resources..."
    
    # Example: Stop any running jobs or timers
    Get-Job -Module $ModuleName | Stop-Job -PassThru | Remove-Job -Force
    
    # Clean up module variables
    Remove-Variable -Name ModuleName, ModuleRoot, ModuleDataPath, IsAdmin -Scope Script -ErrorAction SilentlyContinue
    
    Write-Verbose "$ModuleName module cleanup completed."
}

# Initialize module logging
$logFile = Join-Path -Path $script:ModuleDataPath -ChildPath "$($script:ModuleName)_$(Get-Date -Format 'yyyyMMdd').log"

function Write-ModuleLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Verbose', 'Debug')]
        [string]$Level = 'Info',
        [switch]$PassThru
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logMessage = "$timestamp [$($Level.ToUpper())] $Message"
    
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
    
    if ($PassThru) {
        switch ($Level) {
            'Error'   { Write-Error $Message }
            'Warning' { Write-Warning $Message }
            'Verbose' { Write-Verbose $Message }
            'Debug'   { Write-Debug $Message }
            default   { Write-Output $Message }
        }
    }
}

# Export the logging function
Export-ModuleMember -Function Write-ModuleLog

# Module initialization complete
Write-Verbose "Module $ModuleName (v$($MyInvocation.MyCommand.Module.Version)) loaded successfully."
