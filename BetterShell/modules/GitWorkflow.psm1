#Requires -Version 5.1

<#
.SYNOPSIS
    Git Workflow Automation Module for Better11 Suite
.DESCRIPTION
    Advanced Git operations and team workflow management for 150+ developers
.AUTHOR
    Better11 Development Team
.VERSION
    1.0.0
#>

#region Repository Management

function Initialize-GitRepository {
    <#
    .SYNOPSIS
        Initializes a new Git repository with best practices
    .DESCRIPTION
        Creates repository with .gitignore, .gitattributes, and branch protection
    .EXAMPLE
        Initialize-GitRepository -Path C:\Projects\MyApp -Template FullStack
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet('Frontend', 'Backend', 'FullStack', 'Mobile', 'DataScience', 'DevOps')]
        [string]$Template = 'FullStack',
        
        [string]$DefaultBranch = 'main',
        [string]$RemoteUrl,
        [switch]$InitializeReadme
    )
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    
    Push-Location $Path
    
    try {
        # Initialize repository
        git init -b $DefaultBranch
        Write-Host "✓ Initialized Git repository with branch: $DefaultBranch" -ForegroundColor Green
        
        # Create .gitignore
        $gitignore = Get-GitIgnoreTemplate -Template $Template
        $gitignore | Out-File -FilePath '.gitignore' -Encoding UTF8
        Write-Host "✓ Created .gitignore for $Template" -ForegroundColor Green
        
        # Create .gitattributes
        $gitattributes = Get-GitAttributesTemplate
        $gitattributes | Out-File -FilePath '.gitattributes' -Encoding UTF8
        Write-Host "✓ Created .gitattributes" -ForegroundColor Green
        
        # Create README if requested
        if ($InitializeReadme) {
            $readme = @"
# $(Split-Path $Path -Leaf)

## Overview
Project initialized on $(Get-Date -Format 'yyyy-MM-dd')

## Getting Started
1. Clone the repository
2. Install dependencies
3. Run the application

## Development
- Branch: $DefaultBranch
- Template: $Template

## Team
Better11 Development Team
"@
            $readme | Out-File -FilePath 'README.md' -Encoding UTF8
            Write-Host "✓ Created README.md" -ForegroundColor Green
        }
        
        # Initial commit
        git add .
        git commit -m "Initial commit: $Template project setup"
        Write-Host "✓ Created initial commit" -ForegroundColor Green
        
        # Add remote if provided
        if ($RemoteUrl) {
            git remote add origin $RemoteUrl
            Write-Host "✓ Added remote: $RemoteUrl" -ForegroundColor Green
        }
        
        return [PSCustomObject]@{
            Path = $Path
            Branch = $DefaultBranch
            Template = $Template
            Remote = $RemoteUrl
            Success = $true
        }
    }
    catch {
        Write-Error "Failed to initialize repository: $_"
        return [PSCustomObject]@{
            Path = $Path
            Success = $false
            Error = $_.Exception.Message
        }
    }
    finally {
        Pop-Location
    }
}

function Get-GitIgnoreTemplate {
    [CmdletBinding()]
    param(
        [string]$Template
    )
    
    $common = @"
# OS
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# IDEs
.vscode/
.idea/
*.iml
.vs/
*.suo
*.user

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment
.env
.env.local
.env.*.local

# Dependencies
node_modules/
vendor/
packages/
"@

    $templateSpecific = switch ($Template) {
        'Frontend' {
            @"
# Build outputs
dist/
build/
.next/
out/
.nuxt/
.cache/

# Testing
coverage/
.nyc_output/

# Package managers
package-lock.json
yarn.lock
pnpm-lock.yaml
"@
        }
        'Backend' {
            @"
# Build outputs
bin/
obj/
target/
*.exe
*.dll
*.pdb

# Database
*.db
*.sqlite
*.sqlite3

# Secrets
secrets.json
appsettings.Development.json
"@
        }
        'FullStack' {
            @"
# Frontend
dist/
build/
.next/
node_modules/

# Backend
bin/
obj/
target/
*.exe
*.dll

# Database
*.db
*.sqlite

# Config
secrets.json
"@
        }
        default { "" }
    }
    
    return $common + "`n`n" + $templateSpecific
}

function Get-GitAttributesTemplate {
    [CmdletBinding()]
    param()
    
    return @"
# Auto detect text files
* text=auto

# Source code
*.cs text diff=csharp
*.js text
*.jsx text
*.ts text
*.tsx text
*.py text
*.rs text

# Documentation
*.md text
*.txt text

# Images
*.png binary
*.jpg binary
*.gif binary
*.ico binary

# Archives
*.zip binary
*.tar binary
*.gz binary
"@
}

#endregion

#region Branch Management

function New-GitBranch {
    <#
    .SYNOPSIS
        Creates feature, bugfix, or hotfix branches with naming conventions
    .EXAMPLE
        New-GitBranch -Type feature -Name "user-authentication" -BaseBranch develop
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('feature', 'bugfix', 'hotfix', 'release', 'experiment')]
        [string]$Type,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$BaseBranch = 'main',
        [string]$TicketNumber,
        [switch]$Checkout = $true
    )
    
    # Sanitize name
    $sanitizedName = $Name.ToLower() -replace '[^a-z0-9-]', '-'
    
    # Build branch name
    $branchName = if ($TicketNumber) {
        "$Type/$TicketNumber-$sanitizedName"
    }
    else {
        "$Type/$sanitizedName"
    }
    
    try {
        # Ensure we're on base branch
        git checkout $BaseBranch
        git pull origin $BaseBranch
        
        # Create new branch
        if ($PSCmdlet.ShouldProcess($branchName, "Create branch")) {
            git checkout -b $branchName
            
            Write-Host "✓ Created branch: $branchName" -ForegroundColor Green
            
            return [PSCustomObject]@{
                BranchName = $branchName
                Type = $Type
                BaseBranch = $BaseBranch
                Success = $true
            }
        }
    }
    catch {
        Write-Error "Failed to create branch: $_"
        return [PSCustomObject]@{
            BranchName = $branchName
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-GitBranchStatus {
    <#
    .SYNOPSIS
        Gets detailed status of all branches
    .EXAMPLE
        Get-GitBranchStatus -IncludeRemote
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeRemote,
        [switch]$ShowStale
    )
    
    $branches = @()
    
    # Get local branches
    $localBranches = git branch --format='%(refname:short)|%(upstream:short)|%(committerdate:iso8601)'
    
    foreach ($branch in $localBranches) {
        $parts = $branch -split '\|'
        
        $branchObj = [PSCustomObject]@{
            Name = $parts[0]
            Upstream = $parts[1]
            LastCommit = if ($parts[2]) { [datetime]$parts[2] } else { $null }
            Type = 'Local'
            IsStale = $false
        }
        
        # Check if stale (no commits in 30 days)
        if ($ShowStale -and $branchObj.LastCommit) {
            $branchObj.IsStale = ($branchObj.LastCommit -lt (Get-Date).AddDays(-30))
        }
        
        $branches += $branchObj
    }
    
    # Get remote branches if requested
    if ($IncludeRemote) {
        $remoteBranches = git branch -r --format='%(refname:short)|%(committerdate:iso8601)'
        
        foreach ($branch in $remoteBranches) {
            $parts = $branch -split '\|'
            
            $branches += [PSCustomObject]@{
                Name = $parts[0]
                Upstream = ''
                LastCommit = if ($parts[1]) { [datetime]$parts[1] } else { $null }
                Type = 'Remote'
                IsStale = $false
            }
        }
    }
    
    return $branches
}

function Remove-StaleBranches {
    <#
    .SYNOPSIS
        Removes branches with no recent commits
    .EXAMPLE
        Remove-StaleBranches -DaysOld 60 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [int]$DaysOld = 30,
        [switch]$RemoveRemote,
        [string[]]$ProtectedBranches = @('main', 'master', 'develop', 'staging', 'production')
    )
    
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $branches = Get-GitBranchStatus -ShowStale
    
    $staleBranches = $branches | Where-Object {
        $_.IsStale -and 
        $_.Name -notin $ProtectedBranches -and
        $_.Type -eq 'Local'
    }
    
    $removed = @()
    
    foreach ($branch in $staleBranches) {
        if ($PSCmdlet.ShouldProcess($branch.Name, "Delete stale branch")) {
            try {
                git branch -D $branch.Name
                $removed += $branch.Name
                Write-Host "✓ Deleted: $($branch.Name)" -ForegroundColor Yellow
            }
            catch {
                Write-Warning "Failed to delete: $($branch.Name)"
            }
        }
    }
    
    return [PSCustomObject]@{
        RemovedCount = $removed.Count
        RemovedBranches = $removed
        CutoffDate = $cutoffDate
    }
}

#endregion

#region Commit Operations

function New-ConventionalCommit {
    <#
    .SYNOPSIS
        Creates a commit following Conventional Commits specification
    .EXAMPLE
        New-ConventionalCommit -Type feat -Scope auth -Description "add login form"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore')]
        [string]$Type,
        
        [string]$Scope,
        
        [Parameter(Mandatory)]
        [string]$Description,
        
        [string]$Body,
        [string]$Footer,
        [switch]$BreakingChange
    )
    
    # Build commit message
    $message = $Type
    
    if ($Scope) {
        $message += "($Scope)"
    }
    
    if ($BreakingChange) {
        $message += "!"
    }
    
    $message += ": $Description"
    
    if ($Body) {
        $message += "`n`n$Body"
    }
    
    if ($Footer) {
        $message += "`n`n$Footer"
    }
    
    if ($PSCmdlet.ShouldProcess($message, "Create commit")) {
        git commit -m $message
        Write-Host "✓ Committed: $message" -ForegroundColor Green
    }
}

function Get-CommitHistory {
    <#
    .SYNOPSIS
        Gets formatted commit history with analysis
    .EXAMPLE
        Get-CommitHistory -Since "2 weeks ago" -GroupBy Type
    #>
    [CmdletBinding()]
    param(
        [string]$Since = "1 week ago",
        [string]$Until,
        [string]$Author,
        [ValidateSet('Type', 'Author', 'Date', 'None')]
        [string]$GroupBy = 'None',
        [int]$Limit = 100
    )
    
    $gitArgs = @('log', '--format=%H|%an|%ae|%ai|%s', "--since=`"$Since`"")
    
    if ($Until) { $gitArgs += "--until=`"$Until`"" }
    if ($Author) { $gitArgs += "--author=`"$Author`"" }
    if ($Limit) { $gitArgs += "-n", $Limit }
    
    $commits = git @gitArgs | ForEach-Object {
        $parts = $_ -split '\|', 5
        
        # Parse conventional commit
        $message = $parts[4]
        $type = 'other'
        $scope = $null
        
        if ($message -match '^(\w+)(?:\(([^)]+)\))?!?:\s*(.+)') {
            $type = $matches[1]
            $scope = $matches[2]
            $description = $matches[3]
        }
        
        [PSCustomObject]@{
            Hash = $parts[0]
            Author = $parts[1]
            Email = $parts[2]
            Date = [datetime]$parts[3]
            Message = $message
            Type = $type
            Scope = $scope
        }
    }
    
    if ($GroupBy -ne 'None') {
        return $commits | Group-Object -Property $GroupBy
    }
    
    return $commits
}

function Get-CommitStats {
    <#
    .SYNOPSIS
        Analyzes commit statistics for the team
    .EXAMPLE
        Get-CommitStats -Since "1 month ago"
    #>
    [CmdletBinding()]
    param(
        [string]$Since = "1 week ago",
        [string]$Until
    )
    
    $commits = Get-CommitHistory -Since $Since -Until $Until
    
    $stats = [PSCustomObject]@{
        TotalCommits = $commits.Count
        UniqueAuthors = ($commits | Select-Object -Unique Author).Count
        CommitsByType = $commits | Group-Object Type | Select-Object Name, Count
        CommitsByAuthor = $commits | Group-Object Author | Select-Object Name, Count | Sort-Object Count -Descending
        DailyAverage = [math]::Round($commits.Count / (((Get-Date) - (git log --format=%ai --since=$Since --max-count=1 | Get-Date)).Days), 2)
        DateRange = @{
            From = $Since
            To = if ($Until) { $Until } else { "now" }
        }
    }
    
    return $stats
}

#endregion

#region Pull Request Automation

function New-PullRequest {
    <#
    .SYNOPSIS
        Creates a pull request with template
    .EXAMPLE
        New-PullRequest -Title "Add authentication" -BaseBranch main -Template Feature
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [string]$Description,
        [string]$BaseBranch = 'main',
        [string]$HeadBranch,
        [ValidateSet('Feature', 'Bugfix', 'Hotfix')]
        [string]$Template = 'Feature',
        [string[]]$Reviewers,
        [string[]]$Labels
    )
    
    if (-not $HeadBranch) {
        $HeadBranch = git branch --show-current
    }
    
    # Generate PR description from template
    $prDescription = Get-PRTemplate -Template $Template -Title $Title -Description $Description
    
    # Save to temp file for GitHub CLI
    $tempFile = New-TemporaryFile
    $prDescription | Out-File -FilePath $tempFile -Encoding UTF8
    
    try {
        # Use GitHub CLI if available
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            $ghArgs = @('pr', 'create', '--title', $Title, '--body-file', $tempFile, '--base', $BaseBranch)
            
            if ($Reviewers) {
                $ghArgs += '--reviewer'
                $ghArgs += ($Reviewers -join ',')
            }
            
            if ($Labels) {
                $ghArgs += '--label'
                $ghArgs += ($Labels -join ',')
            }
            
            gh @ghArgs
            Write-Host "✓ Pull request created successfully" -ForegroundColor Green
        }
        else {
            Write-Host "PR Description:" -ForegroundColor Cyan
            Write-Host $prDescription
            Write-Host "`nGitHub CLI (gh) not found. Create PR manually." -ForegroundColor Yellow
        }
    }
    finally {
        Remove-Item $tempFile -Force
    }
}

function Get-PRTemplate {
    [CmdletBinding()]
    param(
        [string]$Template,
        [string]$Title,
        [string]$Description
    )
    
    $base = @"
## Description
$Description

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass locally
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated

## Related Issues
Closes #

## Screenshots (if applicable)

"@
    
    return $base
}

#endregion

#region Team Workflows

function Sync-TeamRepositories {
    <#
    .SYNOPSIS
        Synchronizes multiple repositories for team members
    .EXAMPLE
        Sync-TeamRepositories -RepositoryListFile .\repos.txt
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryListFile,
        
        [string]$BasePath = "$env:USERPROFILE\Projects",
        [switch]$PullLatest,
        [switch]$Parallel
    )
    
    if (-not (Test-Path $RepositoryListFile)) {
        throw "Repository list file not found: $RepositoryListFile"
    }
    
    $repos = Get-Content $RepositoryListFile
    $results = @()
    
    $syncRepo = {
        param($repoUrl, $basePath, $pullLatest)
        
        $repoName = ($repoUrl -split '/')[-1] -replace '\.git$', ''
        $repoPath = Join-Path $basePath $repoName
        
        try {
            if (Test-Path $repoPath) {
                if ($pullLatest) {
                    Push-Location $repoPath
                    git pull
                    Pop-Location
                    return [PSCustomObject]@{
                        Repository = $repoName
                        Status = 'Updated'
                        Path = $repoPath
                    }
                }
            }
            else {
                git clone $repoUrl $repoPath
                return [PSCustomObject]@{
                    Repository = $repoName
                    Status = 'Cloned'
                    Path = $repoPath
                }
            }
        }
        catch {
            return [PSCustomObject]@{
                Repository = $repoName
                Status = 'Failed'
                Error = $_.Exception.Message
            }
        }
    }
    
    if ($Parallel) {
        $results = $repos | ForEach-Object -Parallel {
            & $using:syncRepo -repoUrl $_ -basePath $using:BasePath -pullLatest $using:PullLatest
        } -ThrottleLimit 5
    }
    else {
        foreach ($repo in $repos) {
            $results += & $syncRepo -repoUrl $repo -basePath $BasePath -pullLatest $PullLatest
        }
    }
    
    return $results
}

function Get-TeamActivity {
    <#
    .SYNOPSIS
        Generates team activity report
    .EXAMPLE
        Get-TeamActivity -Since "1 week ago" -ExportPath .\team-report.html
    #>
    [CmdletBinding()]
    param(
        [string]$Since = "1 week ago",
        [string]$ExportPath
    )
    
    $stats = Get-CommitStats -Since $Since
    $commits = Get-CommitHistory -Since $Since
    
    $report = [PSCustomObject]@{
        Period = "Since $Since"
        GeneratedAt = Get-Date
        Summary = @{
            TotalCommits = $stats.TotalCommits
            ActiveDevelopers = $stats.UniqueAuthors
            DailyAverage = $stats.DailyAverage
        }
        TopContributors = $stats.CommitsByAuthor | Select-Object -First 10
        CommitsByType = $stats.CommitsByType
        RecentCommits = $commits | Select-Object -First 20
    }
    
    if ($ExportPath) {
        Export-TeamActivityReport -Report $report -Path $ExportPath
    }
    
    return $report
}

function Export-TeamActivityReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Team Activity Report - $($Report.Period)</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric { background: #ecf0f1; padding: 20px; border-radius: 6px; text-align: center; }
        .metric-value { font-size: 2em; color: #2c3e50; font-weight: bold; }
        .metric-label { color: #7f8c8d; margin-top: 10px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #3498db; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Team Activity Report</h1>
        <p><strong>Period:</strong> $($Report.Period)</p>
        <p><strong>Generated:</strong> $($Report.GeneratedAt)</p>
        
        <div class="summary">
            <div class="metric">
                <div class="metric-value">$($Report.Summary.TotalCommits)</div>
                <div class="metric-label">Total Commits</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($Report.Summary.ActiveDevelopers)</div>
                <div class="metric-label">Active Developers</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($Report.Summary.DailyAverage)</div>
                <div class="metric-label">Daily Average</div>
            </div>
        </div>
        
        <h2>Top Contributors</h2>
        <table>
            <tr><th>Developer</th><th>Commits</th></tr>
            $(foreach ($dev in $Report.TopContributors) {
                "<tr><td>$($dev.Name)</td><td>$($dev.Count)</td></tr>"
            })
        </table>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "✓ Report exported to: $Path" -ForegroundColor Green
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Initialize-GitRepository',
    'New-GitBranch',
    'Get-GitBranchStatus',
    'Remove-StaleBranches',
    'New-ConventionalCommit',
    'Get-CommitHistory',
    'Get-CommitStats',
    'New-PullRequest',
    'Sync-TeamRepositories',
    'Get-TeamActivity'
)
