function Write-ErrorColor { 
    [CmdletBinding()]
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red 
}

function Write-WarningColor { 
    [CmdletBinding()]
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow 
}
