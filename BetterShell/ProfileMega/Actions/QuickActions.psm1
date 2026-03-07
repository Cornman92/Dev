#Requires -Version 7.0

# PROFILE ENHANCEMENTS - Quick actions and productivity boosters

# QUICK PROJECT SCAFFOLDS
function New-GitProject {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [ValidateSet('Public','Private')]
        [string]$Visibility = 'Private'
    )
    
    mkdir $Name
    cd $Name
    git init
    ".DS_Store`n*.log`nnode_modules/`n.env" | Out-File .gitignore
    "# $Name`n`nCreated: $(Get-Date -Format 'yyyy-MM-dd')" | Out-File README.md
    git add .
    git commit -m "Initial commit"
    
    if (Test-CommandExists gh) {
        $visFlag = if ($Visibility -eq 'Private') { '--private' } else { '--public' }
        gh repo create $Name $visFlag --source=. --remote=origin
    }
}

function New-FullStackProject {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [ValidateSet('MERN','PERN','Django','Laravel')]
        [string]$Stack = 'MERN'
    )
    
    mkdir $Name
    cd $Name
    
    switch ($Stack) {
        'MERN' {
            npx create-react-app client
            mkdir server
            cd server
            npm init -y
            npm install express mongoose dotenv cors
            "const express = require('express');" | Out-File index.js
            cd ..
        }
        'PERN' {
            npx create-react-app client
            mkdir server
            cd server
            npm init -y
            npm install express pg dotenv cors
            cd ..
        }
    }
    
    git init
    "node_modules/`n.env`n*.log" | Out-File .gitignore
    git add .
    git commit -m "Project scaffold"
}

# QUICK SERVERS
function Start-PythonServer {
    param([int]$Port = 8000)
    python -m http.server $Port
}

function Start-NodeServer {
    param(
        [int]$Port = 3000,
        [string]$Directory = "."
    )
    
    Push-Location $Directory
    "const express = require('express'); const app = express(); app.use(express.static('.')); app.listen($Port, () => console.log('Server on port $Port'));" | Out-File -Encoding UTF8 server.js
    npm init -y
    npm install express
    node server.js
    Pop-Location
}

function Start-StaticServer {
    param([int]$Port = 8080)
    
    if (Test-CommandExists npx) {
        npx serve -l $Port
    } else {
        Start-PythonServer -Port $Port
    }
}

# QUICK DOCKER
function docker-clean-all {
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
    docker rmi $(docker images -q)
    docker volume prune -f
    docker network prune -f
}

function docker-shell {
    param([Parameter(Mandatory=$true)][string]$Container)
    docker exec -it $Container /bin/bash
}

function docker-logs-follow {
    param([Parameter(Mandatory=$true)][string]$Container)
    docker logs -f --tail 100 $Container
}

function docker-stats-watch {
    docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# QUICK GIT
function git-undo-commit {
    git reset --soft HEAD~1
}

function git-amend {
    git commit --amend --no-edit
}

function git-stash-all {
    git stash save "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

function git-clean-branches {
    git branch --merged | Where-Object { $_ -notmatch 'main|master|develop' } | ForEach-Object { git branch -d $_.Trim() }
}

function git-recent {
    param([int]$Count = 10)
    git log -$Count --pretty=format:"%h - %an, %ar : %s"
}

function git-contributors {
    git log --format='%aN' | Sort-Object | Get-Unique
}

function git-file-history {
    param([Parameter(Mandatory=$true)][string]$File)
    git log --follow --pretty=format:"%h - %an, %ar : %s" -- $File
}

# QUICK SEARCH
function Search-Code {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern,
        [string]$Path = ".",
        [string]$FileType = "*"
    )
    
    if (Test-CommandExists rg) {
        rg $Pattern -g "*.$FileType" $Path
    } else {
        Get-ChildItem -Path $Path -Recurse -Filter "*.$FileType" | 
            Select-String -Pattern $Pattern | 
            Select-Object Path, LineNumber, Line
    }
}

function Search-Files {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern,
        [string]$Path = "."
    )
    
    if (Test-CommandExists fd) {
        fd $Pattern $Path
    } else {
        Get-ChildItem -Path $Path -Recurse -Filter "*$Pattern*"
    }
}

# QUICK ANALYSIS
function Analyze-Project {
    $result = @{
        Language = "Unknown"
        Lines = 0
        Files = 0
        Size = 0
        GitRepo = Test-Path .git
        Dependencies = @{}
    }
    
    if (Test-Path "package.json") {
        $result.Language = "JavaScript/TypeScript"
        $pkg = Get-Content package.json | ConvertFrom-Json
        $result.Dependencies = $pkg.dependencies
    }
    elseif (Test-Path "requirements.txt") {
        $result.Language = "Python"
    }
    elseif (Test-Path "*.csproj") {
        $result.Language = ".NET"
    }
    elseif (Test-Path "Cargo.toml") {
        $result.Language = "Rust"
    }
    elseif (Test-Path "go.mod") {
        $result.Language = "Go"
    }
    
    $files = Get-ChildItem -Recurse -File | Where-Object { $_.Extension -match '\.(js|ts|py|cs|rs|go)$' }
    $result.Files = $files.Count
    $result.Lines = ($files | Get-Content | Measure-Object -Line).Lines
    $result.Size = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    
    $result
}

function Get-CodeStats {
    if (Test-CommandExists tokei) {
        tokei
    } else {
        Write-Host "Install tokei for detailed code statistics: winget install XAMPPRocky.tokei" -ForegroundColor Yellow
        Analyze-Project
    }
}

# QUICK CLEANUP
function Clean-ProjectCache {
    $cleaned = @()
    
    if (Test-Path "node_modules") {
        Remove-Item -Recurse -Force node_modules
        $cleaned += "node_modules"
    }
    if (Test-Path ".next") {
        Remove-Item -Recurse -Force .next
        $cleaned += ".next"
    }
    if (Test-Path "dist") {
        Remove-Item -Recurse -Force dist
        $cleaned += "dist"
    }
    if (Test-Path "build") {
        Remove-Item -Recurse -Force build
        $cleaned += "build"
    }
    if (Test-Path "__pycache__") {
        Remove-Item -Recurse -Force __pycache__
        $cleaned += "__pycache__"
    }
    if (Test-Path "target") {
        Remove-Item -Recurse -Force target
        $cleaned += "target"
    }
    
    Write-Host "Cleaned: $($cleaned -join ', ')" -ForegroundColor Green
}

function Clean-TempFiles {
    $paths = @(
        "$env:TEMP\*",
        "C:\Windows\Temp\*",
        "C:\Windows\Prefetch\*"
    )
    
    $totalSize = 0
    foreach ($path in $paths) {
        try {
            $items = Get-ChildItem $path -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object -Property Length -Sum).Sum
            $totalSize += $size
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    Write-Host "Cleaned $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Green
}

# QUICK BENCHMARKS
function Measure-Function {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [int]$Iterations = 10
    )
    
    $times = @()
    1..$Iterations | ForEach-Object {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock
        $sw.Stop()
        $times += $sw.Elapsed.TotalMilliseconds
    }
    
    @{
        Iterations = $Iterations
        Average = [math]::Round(($times | Measure-Object -Average).Average, 2)
        Min = [math]::Round(($times | Measure-Object -Minimum).Minimum, 2)
        Max = [math]::Round(($times | Measure-Object -Maximum).Maximum, 2)
        Total = [math]::Round(($times | Measure-Object -Sum).Sum, 2)
    }
}

function Compare-Functions {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Functions,
        [int]$Iterations = 10
    )
    
    $results = @{}
    foreach ($name in $Functions.Keys) {
        Write-Host "Benchmarking $name..." -ForegroundColor Cyan
        $results[$name] = Measure-Function -ScriptBlock $Functions[$name] -Iterations $Iterations
    }
    
    $results | Format-Table -AutoSize
}

# QUICK NOTIFICATIONS
function Send-Toast {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Title = "PowerShell",
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Type = 'Info'
    )
    
    if (Get-Module -ListAvailable -Name BurntToast) {
        Import-Module BurntToast
        New-BurntToastNotification -Text $Title, $Message
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Information
        $notification.BalloonTipTitle = $Title
        $notification.BalloonTipText = $Message
        $notification.Visible = $true
        $notification.ShowBalloonTip(5000)
    }
}

function Invoke-WithNotification {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [string]$SuccessMessage = "Task completed",
        [string]$ErrorMessage = "Task failed"
    )
    
    try {
        & $ScriptBlock
        Send-Toast -Message $SuccessMessage -Type Success
    } catch {
        Send-Toast -Message "$ErrorMessage : $_" -Type Error
        throw
    }
}

# QUICK CLIPBOARD
function Copy-FileContent {
    param([Parameter(Mandatory=$true)][string]$Path)
    Get-Content $Path | Set-Clipboard
    Write-Host "Content copied to clipboard" -ForegroundColor Green
}

function Copy-Tree {
    param([string]$Path = ".", [int]$Depth = 3)
    
    if (Test-CommandExists tree) {
        tree /F /A $Path | Set-Clipboard
    } else {
        Get-ChildItem -Path $Path -Recurse -Depth $Depth | ForEach-Object {
            $indent = "  " * ($_.FullName.Split('\').Count - $Path.Split('\').Count)
            "$indent$($_.Name)"
        } | Set-Clipboard
    }
    Write-Host "Directory tree copied to clipboard" -ForegroundColor Green
}

# QUICK CONVERSIONS
function Convert-JsonToYaml {
    param([Parameter(ValueFromPipeline=$true)][string]$Json)
    
    $obj = $Json | ConvertFrom-Json
    # Simplified YAML conversion
    $obj | ConvertTo-Json -Depth 10
}

function Convert-CsvToJson {
    param([Parameter(Mandatory=$true)][string]$Path)
    Import-Csv $Path | ConvertTo-Json
}

function Convert-XmlToJson {
    param([Parameter(Mandatory=$true)][string]$Path)
    ([xml](Get-Content $Path)).OuterXml | ConvertTo-Json
}

# QUICK HELP
function Show-QuickHelp {
    @"
=== QUICK ACTIONS ===

PROJECT CREATION:
  New-GitProject <name>           Create git repo with README
  New-FullStackProject <name>     Scaffold full-stack app
  
SERVERS:
  Start-PythonServer [port]       Quick HTTP server
  Start-StaticServer [port]       Static file server
  
DOCKER:
  docker-clean-all                Remove all containers/images
  docker-shell <container>        Open shell in container
  docker-logs-follow <container>  Follow logs
  
GIT:
  git-undo-commit                 Undo last commit (keep changes)
  git-clean-branches              Remove merged branches
  git-recent [count]              Show recent commits
  
SEARCH:
  Search-Code <pattern>           Search in code files
  Search-Files <pattern>          Find files by name
  
CLEANUP:
  Clean-ProjectCache              Remove build artifacts
  Clean-TempFiles                 Clean Windows temp files
  
BENCHMARKS:
  Measure-Function {script}       Benchmark script execution
  
UTILITIES:
  Analyze-Project                 Get project info
  Get-CodeStats                   Detailed code statistics
  Send-Toast <message>            Desktop notification
"@ | Write-Host -ForegroundColor Cyan
}

Set-Alias qh Show-QuickHelp
Set-Alias qhelp Show-QuickHelp

Export-ModuleMember -Function * -Alias *
