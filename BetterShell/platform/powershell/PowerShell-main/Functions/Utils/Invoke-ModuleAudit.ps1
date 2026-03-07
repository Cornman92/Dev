function Invoke-ModuleAudit {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ModulePath = "$PSScriptRoot\..\Modules"
    )

    $disabledPath = Join-Path -Path $ModulePath -ChildPath '_disabled'
    $archivePath = Join-Path -Path $ModulePath -ChildPath '_archive'

    # Ensure disabled and archive directories exist
    if (-not (Test-Path $disabledPath)) {
        New-Item -Path $disabledPath -ItemType Directory | Out-Null
    }
    if (-not (Test-Path $archivePath)) {
        New-Item -Path $archivePath -ItemType Directory | Out-Null
    }

    $modules = Get-ChildItem -Path $ModulePath -Filter *.psm1

    if (-not $modules) {
        Write-Host -ForegroundColor Green "No modules found to audit in '$ModulePath'."
        return
    }

    foreach ($module in $modules) {
        $title = "Auditing Module: $($module.Name)"
        Write-Host -ForegroundColor Cyan "`n$title"
        Write-Host ("-" * $title.Length)

        $choice = Read-Host -Prompt "Action for '$($module.Name)'? [K]eep, [D]isable, [A]rchive, [S]kip"

        switch ($choice.ToUpper()) {
            'D' {
                $destination = Join-Path -Path $disabledPath -ChildPath $module.Name
                if ($PSCmdlet.ShouldProcess($module.FullName, "Disable (Move to $destination)")) {
                    Move-Item -Path $module.FullName -Destination $destination -Force
                    Write-Host -ForegroundColor Yellow "Module '$($module.Name)' disabled."
                }
            }
            'A' {
                $zipFileName = "$($module.BaseName)_$(Get-Date -Format 'yyyyMMddHHmmss').zip"
                $zipFilePath = Join-Path -Path $archivePath -ChildPath $zipFileName
                if ($PSCmdlet.ShouldProcess($module.FullName, "Archive (Zip to $zipFilePath)")) {
                    Compress-Archive -Path $module.FullName -DestinationPath $zipFilePath
                    Remove-Item -Path $module.FullName -Force
                    Write-Host -ForegroundColor Magenta "Module '$($module.Name)' archived to '$zipFilePath'."
                }
            }
            'K' {
                Write-Host -ForegroundColor Green "Module '$($module.Name)' kept."
            }
            'S' {
                Write-Host "Skipping '$($module.Name)'."
            }
            default {
                Write-Warning "Invalid option. Module '$($module.Name)' will be skipped."
            }
        }
    }

    Write-Host -ForegroundColor Green "`nModule audit complete."
}
