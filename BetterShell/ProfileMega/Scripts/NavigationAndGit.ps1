#Requires -Version 7.0
# Navigation and Git wrappers (dot-sourced by root module)
# Git functions defined only when not already present (e.g. base profile may define gs, ga)

function Set-LocationParent { Set-Location .. }
function Set-LocationGrandParent { Set-Location ..\.. }
function Set-LocationHome { Set-Location $HOME }

if (-not (Get-Command -Name 'git-status' -ErrorAction SilentlyContinue)) {
    function git-status { git status @args }
}
if (-not (Get-Command -Name 'git-add-all' -ErrorAction SilentlyContinue)) {
    function git-add-all { git add . @args }
}
if (-not (Get-Command -Name 'git-commit' -ErrorAction SilentlyContinue)) {
    function git-commit { param([string]$Message) if ($Message) { git commit -m $Message } else { git commit @args } }
}
if (-not (Get-Command -Name 'git-push' -ErrorAction SilentlyContinue)) {
    function git-push { git push @args }
}
if (-not (Get-Command -Name 'git-pull' -ErrorAction SilentlyContinue)) {
    function git-pull { git pull @args }
}
