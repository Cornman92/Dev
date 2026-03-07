function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $logPath = "D:\My-Win[PE][RE]\Output\build.log"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    Add-Content -Path $logPath -Value "[$timestamp][$Level] $Message"
    Write-Host "[$Level] $Message"
}