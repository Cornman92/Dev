Set-StrictMode -Version Latest

Import-Module Deployment.Core         -ErrorAction Stop
Import-Module Deployment.TaskSequence -ErrorAction Stop
Import-Module Deployment.Drivers      -ErrorAction Stop
Import-Module Deployment.Autounattend -ErrorAction Stop
Import-Module Deployment.Provisioning -ErrorAction Stop
Import-Module Deployment.Health       -ErrorAction Stop

function Show-HardwareSummary {
    [CmdletBinding()]
    param()

    try {
        $hw = Get-HardwareProfile

        Write-Host 'Hardware Summary:' -ForegroundColor Cyan
        Write-Host "  Manufacturer: $($hw.Manufacturer)"
        Write-Host "  Model        : $($hw.Model)"
        Write-Host "  CPU          : $($hw.CPUName) ($($hw.CPUCores) cores, $($hw.CPUThreads) threads)"
        Write-Host "  Memory       : $($hw.TotalMemoryGB) GB"
        Write-Host "  BIOS         : $($hw.BIOSVersion) ($($hw.BIOSVendor))"
        Write-Host ''
    }
    catch {
        Write-Host "  Unable to detect hardware: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ''
    }
}

function Show-TaskSequenceSummaryInline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]] $TaskSequences
    )

    Write-Host 'Available Task Sequences:' -ForegroundColor Cyan
    $index = 1

    foreach ($ts in $TaskSequences) {
        Write-Host "  [$index] $($ts.name) (id: $($ts.id))" -ForegroundColor White
        if ($ts.description) {
            Write-Host "      $($ts.description)" -ForegroundColor Gray
        }
        $index++
    }

    Write-Host ''
}

function Show-TaskSequencePicker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]] $TaskSequences
    )

    Show-TaskSequenceSummaryInline -TaskSequences $TaskSequences

    while ($true) {
        $choice = Read-Host "Select a task sequence (1-$($TaskSequences.Count)) or 'q' to cancel"

        if ($choice -eq 'q' -or $choice -eq 'Q') {
            return $null
        }

        if ([int]::TryParse($choice, [ref]([int]0))) {
            $idx = [int]$choice - 1

            if ($idx -ge 0 -and $idx -lt $TaskSequences.Count) {
                return $TaskSequences[$idx]
            }
        }

        Write-Host "Invalid selection. Please enter a number between 1 and $($TaskSequences.Count), or 'q' to cancel." -ForegroundColor Red
    }
}

function Invoke-TaskSequenceFromUi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $TaskSequence
    )

    Clear-Host
    Write-Host '=============================================' -ForegroundColor Cyan
    Write-Host "   Task Sequence: $($TaskSequence.name)" -ForegroundColor Cyan
    Write-Host '=============================================' -ForegroundColor Cyan
    Write-Host ''

    $ctx = New-DeployRunContext

    Write-Host "Run ID: $($ctx.RunId)"
    Write-Host "Logs: $($ctx.RunLogPath)"
    Write-Host ''

    # Disk selection if needed
    $needsDisk = $TaskSequence.steps | Where-Object { $_.type -eq 'PartitionDisk' }

    if ($needsDisk) {
        Write-Host 'Available disks:' -ForegroundColor Cyan
        $disks = Get-Disk | Where-Object { $_.PartitionStyle -ne 'RAW' -or $_.Size -gt 0 }

        foreach ($d in $disks) {
            $sizeGB = [math]::Round($d.Size / 1GB, 1)
            Write-Host "  Disk $($d.Number): $sizeGB GB ($($d.PartitionStyle), $($d.FriendlyName))" -ForegroundColor White
        }

        Write-Host ''

        while ($true) {
            $diskChoice = Read-Host "Select target disk number (or 'q' to cancel)"

            if ($diskChoice -eq 'q' -or $diskChoice -eq 'Q') {
                Write-Host 'Operation cancelled.' -ForegroundColor Yellow
                return
            }

            if ([int]::TryParse($diskChoice, [ref]([int]0))) {
                $diskNum = [int]$diskChoice
                $selected = $disks | Where-Object Number -eq $diskNum

                if ($selected) {
                    $vars = @{ DiskNumber = $diskNum }
                    break
                }
            }

            Write-Host "Invalid disk number. Please select a valid disk." -ForegroundColor Red
        }
    }
    else {
        $vars = @{}
    }

    Write-Host ''
    Write-Host "Starting task sequence '$($TaskSequence.name)'..." -ForegroundColor Green
    Write-Host ''

    try {
        Invoke-TaskSequence -RunContext $ctx -TaskSequence $TaskSequence -Variables $vars

        Write-Host ''
        Write-Host "Task sequence completed successfully!" -ForegroundColor Green
        Write-Host "Logs available at: $($ctx.RunLogPath)" -ForegroundColor Cyan
    }
    catch {
        Write-Host ''
        Write-Host "Task sequence failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Logs available at: $($ctx.RunLogPath)" -ForegroundColor Cyan
        throw
    }
}

function Start-DeployCenter {
    [CmdletBinding()]
    param()

    if (-not (Test-DeployAdmin)) {
        Write-Host 'ERROR: Deployment Center must be run as Administrator.' -ForegroundColor Red
        return
    }

    while ($true) {
        Clear-Host
        Write-Host '=============================================' -ForegroundColor Cyan
        Write-Host '   Better11 Deployment Control Center       ' -ForegroundColor Cyan
        Write-Host '=============================================' -ForegroundColor Cyan
        Write-Host ''

        Show-HardwareSummary

        Write-Host 'Main Menu:' -ForegroundColor Cyan
        Write-Host '  [1] Run a task sequence'
        Write-Host '  [2] Generate autounattend.xml'
        Write-Host '  [3] Capture app provisioning package'
        Write-Host '  [4] Install provisioning package'
        Write-Host '  [5] Export diagnostics'
        Write-Host '  [q] Quit'
        Write-Host ''

        $choice = Read-Host 'Select an option'

        switch ($choice) {
            '1' {
                try {
                    $catalog = Get-TaskSequenceCatalog

                    if (-not $catalog -or $catalog.Count -eq 0) {
                        Write-Host 'No task sequences found.' -ForegroundColor Yellow
                        Read-Host 'Press Enter to continue'
                        continue
                    }

                    $ts = Show-TaskSequencePicker -TaskSequences $catalog

                    if ($ts) {
                        Invoke-TaskSequenceFromUi -TaskSequence $ts
                        Read-Host 'Press Enter to continue'
                    }
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                    Read-Host 'Press Enter to continue'
                }
            }

            '2' {
                try {
                    Start-AutounattendWizard
                    Read-Host 'Press Enter to continue'
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                    Read-Host 'Press Enter to continue'
                }
            }

            '3' {
                try {
                    $ctx = New-DeployRunContext

                    $outPath = Read-Host "Output path for PPKG (e.g., C:\Deploy\apps.ppkg)"

                    if ([string]::IsNullOrWhiteSpace($outPath)) {
                        Write-Host 'Operation cancelled.' -ForegroundColor Yellow
                        Read-Host 'Press Enter to continue'
                        continue
                    }

                    New-AppCaptureProvisioningPackage -RunContext $ctx -OutputPath $outPath -OverwriteExisting

                    Write-Host ''
                    Write-Host "Provisioning package created at: $outPath" -ForegroundColor Green
                    Read-Host 'Press Enter to continue'
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                    Read-Host 'Press Enter to continue'
                }
            }

            '4' {
                try {
                    $ctx = New-DeployRunContext

                    $pkgPath = Read-Host "Path to provisioning package (.ppkg)"

                    if (-not (Test-Path $pkgPath)) {
                        Write-Host "File not found: $pkgPath" -ForegroundColor Red
                        Read-Host 'Press Enter to continue'
                        continue
                    }

                    Install-ProvisioningPackageLocal -RunContext $ctx -PackagePath $pkgPath

                    Write-Host ''
                    Write-Host "Provisioning package installed successfully." -ForegroundColor Green
                    Read-Host 'Press Enter to continue'
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                    Read-Host 'Press Enter to continue'
                }
            }

            '5' {
                try {
                    $ctx = New-DeployRunContext
                    $zipPath = Export-DeployDiagnostics -RunContext $ctx

                    Write-Host ''
                    Write-Host "Diagnostics exported to: $zipPath" -ForegroundColor Green
                    Read-Host 'Press Enter to continue'
                }
                catch {
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                    Read-Host 'Press Enter to continue'
                }
            }

            'q' {
                Write-Host 'Exiting Deployment Center.' -ForegroundColor Cyan
                return
            }

            default {
                Write-Host 'Invalid option. Please try again.' -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Start-DeployConsole {
    [CmdletBinding()]
    param()

    # Backwards-compatible wrapper
    Start-DeployCenter
}

