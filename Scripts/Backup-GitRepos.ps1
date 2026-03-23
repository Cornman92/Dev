<#
.SYNOPSIS
    Backs up git repositories by cloning or pulling latest changes.

.DESCRIPTION
    Takes a list of git repository paths or URLs and creates mirror
    clones in a backup directory. For existing backups, performs a
    fetch to update. Generates a summary report of backup status.

.PARAMETER RepoList
    Array of local repository paths or remote URLs to back up.

.PARAMETER RepoFile
    Path to a text file containing one repository path/URL per line.

.PARAMETER BackupRoot
    Root directory for backups. Defaults to C:\Dev\Artifacts\GitBackups.

.EXAMPLE
    .\Backup-GitRepos.ps1 -RepoList "C:\Dev","C:\Projects\MyApp"
    Backs up two local repositories.

.EXAMPLE
    .\Backup-GitRepos.ps1 -RepoFile "C:\Dev\Assets\repos.txt"
    Backs up repositories listed in a file.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'List')]
    [string[]]$RepoList,

    [Parameter(ParameterSetName = 'File')]
    [string]$RepoFile,

    [Parameter()]
    [string]$BackupRoot = "C:\Dev\Artifacts\GitBackups"
)

$ErrorActionPreference = 'Stop'

# Resolve repo list
if ($RepoFile) {
    if (-not (Test-Path $RepoFile)) {
        Write-Error "Repo file not found: $RepoFile"
    }
    $repos = Get-Content $RepoFile | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^\s*#' }
}
elseif ($RepoList) {
    $repos = $RepoList
}
else {
    Write-Error "Provide either -RepoList or -RepoFile."
}

# Ensure backup root exists
if (-not (Test-Path $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Git Repository Backup" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Backup root: $BackupRoot"
Write-Host "  Repositories: $($repos.Count)"
Write-Host ""

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($repo in $repos) {
    $repo = $repo.Trim()

    # Determine repo name
    if ($repo -match '[\\/]([^\\/]+?)(\.git)?$') {
        $repoName = $Matches[1]
    }
    else {
        $repoName = $repo -replace '[^a-zA-Z0-9_-]', '_'
    }

    $backupPath = Join-Path $BackupRoot "$repoName.git"
    $status = 'Unknown'
    $message = ''

    try {
        if (Test-Path $backupPath) {
            # Update existing mirror
            Write-Host "  Updating: $repoName..." -ForegroundColor Yellow -NoNewline
            Push-Location $backupPath
            git fetch --all --prune 2>&1 | Out-Null
            Pop-Location
            $status = 'Updated'
            $message = 'Fetched latest changes'
            Write-Host " done" -ForegroundColor Green
        }
        else {
            # Create new mirror clone
            Write-Host "  Cloning: $repoName..." -ForegroundColor Yellow -NoNewline
            git clone --mirror $repo $backupPath 2>&1 | Out-Null
            $status = 'Created'
            $message = 'New mirror clone'
            Write-Host " done" -ForegroundColor Green
        }
    }
    catch {
        $status = 'Failed'
        $message = $_.Exception.Message
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "    Error: $message" -ForegroundColor Red
    }

    $results.Add([PSCustomObject]@{
        Repository = $repoName
        Source     = $repo
        BackupPath = $backupPath
        Status     = $status
        Message    = $message
        Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    })
}

# Summary
Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Backup Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
$created = ($results | Where-Object Status -eq 'Created').Count
$updated = ($results | Where-Object Status -eq 'Updated').Count
$failed  = ($results | Where-Object Status -eq 'Failed').Count

Write-Host "  Created: $created | Updated: $updated | Failed: $failed" -ForegroundColor White
Write-Host ""
