<#
.SYNOPSIS
    AI-powered command suggestions based on context and history.

.DESCRIPTION
    Provides intelligent command suggestions using context-aware analysis of:
    - Current directory and project type
    - Recent command history
    - Common command patterns
    - Module availability

.PARAMETER Context
    Additional context string to help with suggestions.

.PARAMETER Count
    Number of suggestions to return (default: 5).

.EXAMPLE
    Get-AICommandSuggestion
    Returns AI-powered command suggestions based on current context.

.EXAMPLE
    Get-AICommandSuggestion -Context "working with git" -Count 3
    Returns 3 git-related command suggestions.
#>
function Get-AICommandSuggestion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Context = '',
        
        [Parameter(Mandatory = $false)]
        [int]$Count = 5
    )

    $suggestions = @()
    $currentPath = Get-Location
    $currentDir = Split-Path -Leaf $currentPath
    
    # Analyze current context
    $isGitRepo = Test-Path (Join-Path $currentPath '.git')
    $hasPackageJson = Test-Path (Join-Path $currentPath 'package.json')
    $hasDockerfile = Test-Path (Join-Path $currentPath 'Dockerfile')
    $hasPomXml = Test-Path (Join-Path $currentPath 'pom.xml')
    $hasRequirements = Test-Path (Join-Path $currentPath 'requirements.txt')
    
    # Get recent history for pattern analysis
    $history = Get-History -Count 20 | Select-Object -ExpandProperty CommandLine
    
    # Context-based suggestions
    if ($isGitRepo) {
        $suggestions += @(
            @{ Command = 'git status'; Description = 'Check repository status'; Score = 90 },
            @{ Command = 'git log --oneline -10'; Description = 'View recent commits'; Score = 75 },
            @{ Command = 'git branch'; Description = 'List branches'; Score = 70 },
            @{ Command = 'git diff'; Description = 'View changes'; Score = 65 }
        )
    }
    
    if ($hasPackageJson) {
        $suggestions += @(
            @{ Command = 'npm install'; Description = 'Install dependencies'; Score = 85 },
            @{ Command = 'npm run'; Description = 'Run npm scripts'; Score = 80 },
            @{ Command = 'npm test'; Description = 'Run tests'; Score = 70 }
        )
    }
    
    if ($hasDockerfile) {
        $suggestions += @(
            @{ Command = 'docker build -t ' + $currentDir.ToLower(); Description = 'Build Docker image'; Score = 85 },
            @{ Command = 'docker-compose up'; Description = 'Start containers'; Score = 80 }
        )
    }
    
    if ($hasPomXml) {
        $suggestions += @(
            @{ Command = 'mvn clean install'; Description = 'Build Maven project'; Score = 85 },
            @{ Command = 'mvn test'; Description = 'Run tests'; Score = 75 }
        )
    }
    
    if ($hasRequirements) {
        $suggestions += @(
            @{ Command = 'pip install -r requirements.txt'; Description = 'Install Python dependencies'; Score = 85 },
            @{ Command = 'python -m pytest'; Description = 'Run tests'; Score = 70 }
        )
    }
    
    # Pattern-based suggestions from history
    $commonPatterns = @{
        'git' = @('git pull', 'git push', 'git commit -m', 'git checkout')
        'docker' = @('docker ps', 'docker images', 'docker-compose down')
        'npm' = @('npm start', 'npm run build', 'npm audit')
        'python' = @('python -m venv venv', 'source venv/bin/activate', 'pip list')
        'pwsh' = @('Get-Process', 'Get-Service', 'Get-ChildItem')
    }
    
    foreach ($pattern in $history) {
        foreach ($key in $commonPatterns.Keys) {
            if ($pattern -like "*$key*") {
                foreach ($cmd in $commonPatterns[$key]) {
                    if ($cmd -notin ($suggestions | Select-Object -ExpandProperty Command)) {
                        $suggestions += @{
                            Command = $cmd
                            Description = "Common $key command"
                            Score = 60
                        }
                    }
                }
            }
        }
    }
    
    # Context string matching
    if ($Context) {
        $contextLower = $Context.ToLower()
        if ($contextLower -match 'git|version|commit') {
            $suggestions += @(
                @{ Command = 'git status'; Description = 'Check git status'; Score = 95 },
                @{ Command = 'git log'; Description = 'View commit history'; Score = 85 }
            )
        }
        if ($contextLower -match 'docker|container') {
            $suggestions += @(
                @{ Command = 'docker ps -a'; Description = 'List all containers'; Score = 95 },
                @{ Command = 'docker images'; Description = 'List images'; Score = 85 }
            )
        }
        if ($contextLower -match 'file|directory|folder') {
            $suggestions += @(
                @{ Command = 'Get-ChildItem -Recurse'; Description = 'List all files recursively'; Score = 90 },
                @{ Command = 'Get-ChildItem | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-7)}'; Description = 'Recent files'; Score = 80 }
            )
        }
    }
    
    # General productivity suggestions
    $suggestions += @(
        @{ Command = 'Get-Process | Sort-Object CPU -Descending | Select-Object -First 10'; Description = 'Top CPU processes'; Score = 50 },
        @{ Command = 'Get-ChildItem | Measure-Object -Property Length -Sum'; Description = 'Directory size'; Score = 50 },
        @{ Command = 'Get-History | Select-Object -Last 10'; Description = 'Recent commands'; Score = 45 }
    )
    
    # Sort by score and return top N
    $suggestions | 
        Sort-Object -Property Score -Descending | 
        Select-Object -First $Count -Unique Command, Description, Score |
        Format-Table -AutoSize
    
    return $suggestions | Sort-Object -Property Score -Descending | Select-Object -First $Count -Unique
}

# Alias for quick access
Set-Alias -Name 'suggest' -Value 'Get-AICommandSuggestion' -Scope Global -Force
Set-Alias -Name 'ai-cmd' -Value 'Get-AICommandSuggestion' -Scope Global -Force

