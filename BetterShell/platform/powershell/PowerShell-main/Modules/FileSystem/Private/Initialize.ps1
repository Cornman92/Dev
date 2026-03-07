<#
.SYNOPSIS
    Initialization script for the FileSystem module
.DESCRIPTION
    This script runs when the FileSystem module is imported and performs necessary
    environment setup and validation.
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Initialize module variables
$script:FileSystemWatchers = @{}
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Set the root paths
$script:ModuleRoot = 'D:\\OneDrive\\C-Man\\Documents\\PowerShell\\Modules\\FileSystem'
$script:ModuleDataPath = Join-Path -Path $env:APPDATA -ChildPath 'FileSystem'
$script:PublicFunctionsPath = 'D:\\OneDrive\\C-Man\\Documents\\PowerShell\\Functions\\Public'
$script:PrivateFunctionsPath = 'D:\\OneDrive\\C-Man\\Documents\\PowerShell\\Functions\\Private'

# Create the data directory if it doesn't exist
if (-not (Test-Path -Path $script:ModuleDataPath)) {
    $null = New-Item -Path $script:ModuleDataPath -ItemType Directory -Force
}

# Function to check if a command is available
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
$requiredCommands = @('7z', 'robocopy')
$missingCommands = $requiredCommands | Where-Object { -not (Test-CommandExists -Command $_) }

if ($missingCommands) {
    Write-Warning "The following recommended commands are not available: $($missingCommands -join ', ')"
    Write-Warning "Some functionality may be limited without these tools."
}

# Return the variables to be exported
@{
    IsAdmin = $script:IsAdmin
    ModuleRoot = $script:ModuleRoot
    ModuleDataPath = $script:ModuleDataPath
    PublicFunctionsPath = $script:PublicFunctionsPath
    PrivateFunctionsPath = $script:PrivateFunctionsPath
}
