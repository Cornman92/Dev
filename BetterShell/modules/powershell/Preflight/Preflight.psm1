# Better11.Preflight
using namespace System.Collections.Generic

function Get-Better11PreflightReport {
    [CmdletBinding()]
    param(
        [int]$MinFreeGB = 20,
        [int]$MinMemoryGB = 8
    )
    $report = [ordered]@{ Pass=$true; Checks=@() }

    function Add-Check([string]$Name, [bool]$Ok, [string]$Details) {
        $report.Checks += [ordered]@{ Name=$Name; Pass=$Ok; Details=$Details }
        if (-not $Ok) { $report.Pass = $false }
    }

    # PowerShell 7 check
    $isPs7 = $PSVersionTable.PSVersion.Major -ge 7
    Add-Check "PowerShell7" $isPs7 ("Detected {0}" -f $PSVersionTable.PSVersion.ToString())

    # winget presence
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    Add-Check "winget" ([bool]$winget) ("Path: {0}" -f ($winget.Path))

    # DISM presence
    $dism = Get-Command dism.exe -ErrorAction SilentlyContinue
    Add-Check "DISM" ([bool]$dism) ("Path: {0}" -f ($dism.Path))

    # oscdimg presence
    $oscdimg = Get-Command oscdimg.exe -ErrorAction SilentlyContinue
    if (-not $oscdimg) {
        $adkPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (Test-Path $adkPath) { $oscdimg = Get-Item $adkPath }
    }
    Add-Check "Oscdimg" ([bool]$oscdimg) ("Path: {0}" -f ($oscdimg.FullName))

    # Free disk
    $sysDrive = Get-PSDrive -Name (Get-Location).Path.Substring(0,1)
    $freeGB = [math]::Round($sysDrive.Free/1GB,2)
    Add-Check "DiskFreeGB>=$MinFreeGB" ($freeGB -ge $MinFreeGB) ("FreeGB={0}" -f $freeGB)

    # Memory
    try {
        $memGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2)
    } catch { $memGB = 0 }
    Add-Check "MemoryGB>=$MinMemoryGB" ($memGB -ge $MinMemoryGB) ("RAMGB={0}" -f $memGB)

    [pscustomobject]$report
}

function Test-Better11Preflight {
    [CmdletBinding()]
    param([switch]$Quiet)

    $r = Get-Better11PreflightReport
    if (-not $Quiet) {
        $r.Checks | ForEach-Object {
            $s = if ($_.Pass) { "PASS" } else { "FAIL" }
            Write-Host ("[{0}] {1} -> {2}" -f $s, $_.Name, $_.Details)
        }
        Write-Host ("Overall: {0}" -f ($(if($r.Pass){"PASS"}else{"FAIL"})))
    }
    return $r.Pass
}

Export-ModuleMember -Function Get-Better11PreflightReport, Test-Better11Preflight
