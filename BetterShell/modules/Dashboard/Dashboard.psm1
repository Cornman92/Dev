function Get-SystemSnapshot {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed
    $mem = Get-CimInstance Win32_ComputerSystem
    $os  = Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,LastBootUpTime
    $gpu = Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,AdapterRAM
    $disks = Get-PhysicalDisk | Select-Object FriendlyName,MediaType,Size,SerialNumber,HealthStatus
    [pscustomobject]@{ CPU=$cpu; MemoryGB=[math]::Round($mem.TotalPhysicalMemory/1GB,2); OS=$os; GPU=$gpu; Disks=$disks }
}
function Show-AuroraTUI {
    Clear-Host
    Write-Host "==== Aurora Dashboard (TUI) ===="
    Write-Host "1) System Snapshot"
    Write-Host "2) Run Benchmarks"
    Write-Host "3) Generate Report"
    Write-Host "4) Exit"
    while($true){
        $c = Read-Host "Select"
        switch($c){
            '1'{ Get-SystemSnapshot | Format-List | Out-Host }
            '2'{ Import-Module (Join-Path $PSScriptRoot '..\Benchmarks\Benchmarks.psd1') -Force; Start-AuroraBenchmarks -Disk -CPU -GPU -Memory | Format-Table | Out-Host }
            '3'{ Import-Module (Join-Path $PSScriptRoot '..\Reports\Reports.psd1') -Force; $snap=Get-SystemSnapshot | ConvertTo-Json -Depth 6 | ConvertFrom-Json; $rep=New-AuroraReport -Data @{Snapshot=$snap;Generated=(Get-Date -Format o)}; $rep | Format-List | Out-Host }
            '4'{ break }
            default{ Write-Host "Invalid" }
        }
    }
}
function Show-AuroraGUI {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $f = New-Object System.Windows.Forms.Form
    $f.Text='Aurora Dashboard'; $f.Width=800; $f.Height=600
    $b1=New-Object System.Windows.Forms.Button; $b1.Text='System Snapshot'; $b1.Left=20; $b1.Top=20; $b1.Width=150
    $b2=New-Object System.Windows.Forms.Button; $b2.Text='Run Benchmarks'; $b2.Left=180; $b2.Top=20; $b2.Width=150
    $b3=New-Object System.Windows.Forms.Button; $b3.Text='Generate Report'; $b3.Left=340; $b3.Top=20; $b3.Width=150
    $txt=New-Object System.Windows.Forms.TextBox; $txt.Multiline=$true; $txt.ScrollBars='Vertical'; $txt.Left=20; $txt.Top=60; $txt.Width=740; $txt.Height=480
    $f.Controls.AddRange(@($b1,$b2,$b3,$txt))
    $b1.Add_Click({ $txt.Text = (Get-SystemSnapshot | ConvertTo-Json -Depth 6) })
    $b2.Add_Click({ Import-Module (Join-Path $PSScriptRoot '..\Benchmarks\Benchmarks.psd1') -Force; $r=Start-AuroraBenchmarks -Disk -CPU -GPU -Memory -WhatIf; $txt.Text = ($r | ConvertTo-Json -Depth 6) })
    $b3.Add_Click({ Import-Module (Join-Path $PSScriptRoot '..\Reports\Reports.psd1') -Force; $snap=Get-SystemSnapshot | ConvertTo-Json -Depth 6 | ConvertFrom-Json; $rep=New-AuroraReport -Data @{Snapshot=$snap;Generated=(Get-Date -Format o)}; $txt.Text = "Report:`r`nJSON: $($rep.Json)`r`nHTML: $($rep.Html)" })
    [void]$f.ShowDialog()
}
function Show-AuroraDashboard { param([ValidateSet('TUI','GUI')]$Mode='TUI'); if($Mode -eq 'TUI'){ Show-AuroraTUI } else { Show-AuroraGUI } }
Export-ModuleMember -Function Show-AuroraDashboard
