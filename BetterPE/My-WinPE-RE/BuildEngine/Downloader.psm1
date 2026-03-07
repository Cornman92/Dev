function Download-IfMissing {
    param(
        [string]$ToolName,
        [string]$Url,
        [string]$Destination
    )

    if (Test-Path $Destination) {
        Write-Log "$ToolName already present."
    }
    else {
        Write-Log "Downloading $ToolName..."
        Invoke-WebRequest -Uri $Url -OutFile $Destination
        Write-Log "$ToolName downloaded."
    }
}