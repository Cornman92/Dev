function Install-ToolWithWinget {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,

        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    # 1. Check if the command already exists
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Host -ForegroundColor Green "Tool '$CommandName' is already installed."
        return $true
    }

    # 2. Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget is not available. Please install it from the Microsoft Store."
        return $false
    }

    # 3. Install the package
    Write-Host -ForegroundColor Yellow "Attempting to install '$PackageId' with winget..."
    if ($PSCmdlet.ShouldProcess($PackageId, "Install with winget")) {
        try {
            winget install --id $PackageId --source winget --accept-package-agreements --silent
            Write-Host -ForegroundColor Green "Successfully installed '$PackageId'. Please restart your shell to use it."
            return $true
        } catch {
            Write-Error "Failed to install '$PackageId' with winget. Error: $_"
            return $false
        }
    }
    return $false
}
