# ================================
# Start.ps1 — Universal Bootstrap
# ================================

Write-Host "Initializing environment..."

$Global:ENV = @{
    PathRoot = "X:\"
    Tools    = "X:\Tools"
    Scripts  = "X:\Scripts"
    Modules  = "X:\Modules"
    Menu     = "X:\Menu"
}

# Load modules
if (Test-Path $ENV.Modules) {
    Get-ChildItem $ENV.Modules -Filter *.psm1 | ForEach-Object {
        Import-Module $_.FullName -Force
    }
}

# Detect environment
if (Test-Path "$($ENV.PathRoot)Recovery") {
    $Global:ENV.Type = "WinRE"
} elseif (Test-Path "$($ENV.PathRoot)Hybrid.flag") {
    $Global:ENV.Type = "Hybrid"
} else {
    $Global:ENV.Type = "WinPE"
}

Write-Host "Environment Detected: $($ENV.Type)"

# Initialize network
Start-Process wpeinit -Wait

# Launch main console
& "$($ENV.Scripts)\DeployConsole.ps1"