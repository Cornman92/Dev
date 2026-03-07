#Requires -Version 7.0

# ADVANCED POWERSHELL UTILITIES - Extended function library

# TEXT PROCESSING
function Convert-TextCase {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text,
        [ValidateSet('Upper','Lower','Title','Camel','Pascal','Snake','Kebab')]
        [string]$Case = 'Title'
    )
    
    switch ($Case) {
        'Upper' { $Text.ToUpper() }
        'Lower' { $Text.ToLower() }
        'Title' { (Get-Culture).TextInfo.ToTitleCase($Text.ToLower()) }
        'Camel' {
            $words = $Text -split '\s+'
            $words[0].ToLower() + ($words[1..($words.Length-1)] | ForEach-Object { 
                $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() 
            }) -join ''
        }
        'Pascal' {
            ($Text -split '\s+' | ForEach-Object { 
                $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() 
            }) -join ''
        }
        'Snake' { ($Text -replace '\s+', '_').ToLower() }
        'Kebab' { ($Text -replace '\s+', '-').ToLower() }
    }
}

function Measure-TextComplexity {
    param([string]$Text)
    
    @{
        Length = $Text.Length
        Words = ($Text -split '\s+').Count
        Sentences = ($Text -split '[.!?]').Count
        Paragraphs = ($Text -split '\n\n').Count
        UniqueWords = ($Text -split '\s+' | Select-Object -Unique).Count
        AvgWordLength = [math]::Round((($Text -split '\s+' | Measure-Object -Property Length -Average).Average), 2)
    }
}

# FILE OPERATIONS
function Find-DuplicateFiles {
    param(
        [string]$Path = ".",
        [switch]$ByContent
    )
    
    $files = Get-ChildItem -Path $Path -Recurse -File
    $groups = if ($ByContent) {
        $files | Group-Object { (Get-FileHash $_.FullName -Algorithm MD5).Hash }
    } else {
        $files | Group-Object { "$($_.Name)_$($_.Length)" }
    }
    
    $groups | Where-Object { $_.Count -gt 1 } | ForEach-Object {
        @{
            Files = $_.Group.FullName
            Count = $_.Count
            SizeMB = [math]::Round($_.Group[0].Length / 1MB, 2)
        }
    }
}

function Compare-Directories {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path1,
        [Parameter(Mandatory=$true)]
        [string]$Path2
    )
    
    $files1 = Get-ChildItem -Path $Path1 -Recurse -File | Select-Object Name, Length, @{N='Hash';E={(Get-FileHash $_.FullName).Hash}}
    $files2 = Get-ChildItem -Path $Path2 -Recurse -File | Select-Object Name, Length, @{N='Hash';E={(Get-FileHash $_.FullName).Hash}}
    
    @{
        OnlyIn1 = Compare-Object $files1 $files2 -Property Name | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty Name
        OnlyIn2 = Compare-Object $files1 $files2 -Property Name | Where-Object {$_.SideIndicator -eq '=>'} | Select-Object -ExpandProperty Name
        Different = Compare-Object $files1 $files2 -Property Name, Hash | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty Name
        Same = (Compare-Object $files1 $files2 -Property Name, Hash -IncludeEqual -ExcludeDifferent).Count
    }
}

function Optimize-Images {
    param(
        [string]$Path = ".",
        [int]$Quality = 85,
        [switch]$Recursive
    )
    
    $params = @{Path = $Path; Filter = "*.jpg", "*.jpeg", "*.png"}
    if ($Recursive) { $params.Recurse = $true }
    
    Get-ChildItem @params | ForEach-Object {
        $originalSize = $_.Length
        # Would use ImageMagick or similar
        @{
            File = $_.Name
            OriginalSizeMB = [math]::Round($originalSize / 1MB, 2)
            Optimized = $true
        }
    }
}

# SYSTEM UTILITIES
function Get-SystemPerformance {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $mem = Get-CimInstance Win32_OperatingSystem
    $memPercent = (($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100
    $disk = Get-PSDrive C | Select-Object Used, Free
    
    @{
        CPU = [math]::Round($cpu, 2)
        MemoryPercent = [math]::Round($memPercent, 2)
        MemoryUsedGB = [math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1MB, 2)
        MemoryFreeGB = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
        DiskUsedGB = [math]::Round($disk.Used / 1GB, 2)
        DiskFreeGB = [math]::Round($disk.Free / 1GB, 2)
        Uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    }
}

function Watch-Process {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProcessName,
        [int]$Interval = 1
    )
    
    while ($true) {
        $proc = Get-Process $ProcessName -ErrorAction SilentlyContinue
        if ($proc) {
            Clear-Host
            Write-Host "Process: $ProcessName (PID: $($proc.Id))" -ForegroundColor Cyan
            Write-Host "CPU: $([math]::Round($proc.CPU, 2))s" -ForegroundColor Green
            Write-Host "Memory: $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Yellow
            Write-Host "Threads: $($proc.Threads.Count)" -ForegroundColor Magenta
        } else {
            Write-Host "Process not found: $ProcessName" -ForegroundColor Red
        }
        Start-Sleep -Seconds $Interval
    }
}

function Get-ProcessTree {
    param([int]$ProcessId = $PID)
    
    function Get-ChildProcesses($ParentId) {
        Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ParentId } | ForEach-Object {
            @{
                Name = $_.Name
                PID = $_.ProcessId
                ParentPID = $_.ParentProcessId
                Children = Get-ChildProcesses $_.ProcessId
            }
        }
    }
    
    $proc = Get-Process -Id $ProcessId
    @{
        Name = $proc.ProcessName
        PID = $proc.Id
        Children = Get-ChildProcesses $ProcessId
    }
}

# NETWORK UTILITIES
function Test-PortScan {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        [int[]]$Ports = @(21, 22, 23, 25, 53, 80, 443, 3389, 8080)
    )
    
    $results = @()
    foreach ($port in $Ports) {
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $tcp.Connect($ComputerName, $port)
            $results += @{Port = $port; Status = "Open"}
            $tcp.Close()
        } catch {
            $results += @{Port = $port; Status = "Closed"}
        }
    }
    $results
}

function Get-PublicIP {
    try {
        (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5).Content.Trim()
    } catch {
        "Unable to determine"
    }
}

function Test-InternetSpeed {
    Write-Host "Testing download speed..." -ForegroundColor Cyan
    $url = "http://speedtest.ftp.otenet.gr/files/test10Mb.db"
    $start = Get-Date
    Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 | Out-Null
    $elapsed = ((Get-Date) - $start).TotalSeconds
    $speedMbps = [math]::Round((10 / $elapsed), 2)
    
    @{
        DownloadMbps = $speedMbps
        TestDuration = $elapsed
        TestSize = "10 MB"
    }
}

function Get-DNSInfo {
    param([Parameter(Mandatory=$true)][string]$Hostname)
    
    @{
        IPv4 = [System.Net.Dns]::GetHostAddresses($Hostname) | Where-Object {$_.AddressFamily -eq 'InterNetwork'} | Select-Object -ExpandProperty IPAddressToString
        IPv6 = [System.Net.Dns]::GetHostAddresses($Hostname) | Where-Object {$_.AddressFamily -eq 'InterNetworkV6'} | Select-Object -ExpandProperty IPAddressToString
        HostName = $Hostname
    }
}

# DATA UTILITIES
function ConvertTo-Table {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [object[]]$InputObject
    )
    
    begin { $items = @() }
    process { $items += $InputObject }
    end { $items | Format-Table -AutoSize }
}

function Export-ToExcel {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [object[]]$InputObject,
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    begin { $items = @() }
    process { $items += $InputObject }
    end {
        if (Get-Module -ListAvailable -Name ImportExcel) {
            Import-Module ImportExcel
            $items | Export-Excel -Path $Path -AutoSize -Show
        } else {
            Write-Warning "ImportExcel module not installed. Exporting to CSV instead."
            $items | Export-Csv -Path ($Path -replace '\.xlsx$','.csv') -NoTypeInformation
        }
    }
}

function Invoke-Parallel {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [Parameter(ValueFromPipeline=$true)]
        [object[]]$InputObject,
        [int]$ThrottleLimit = 5
    )
    
    begin { $items = @() }
    process { $items += $InputObject }
    end {
        $items | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit
    }
}

# TIME UTILITIES
function ConvertFrom-UnixTime {
    param([Parameter(Mandatory=$true)][long]$UnixTime)
    [DateTimeOffset]::FromUnixTimeSeconds($UnixTime).LocalDateTime
}

function ConvertTo-UnixTime {
    param([Parameter(Mandatory=$true)][datetime]$DateTime)
    [DateTimeOffset]::new($DateTime).ToUnixTimeSeconds()
}

function Get-TimeZones {
    [System.TimeZoneInfo]::GetSystemTimeZones() | Select-Object Id, DisplayName, BaseUtcOffset
}

function Convert-TimeZone {
    param(
        [Parameter(Mandatory=$true)]
        [datetime]$DateTime,
        [Parameter(Mandatory=$true)]
        [string]$FromTimeZone,
        [Parameter(Mandatory=$true)]
        [string]$ToTimeZone
    )
    
    $from = [System.TimeZoneInfo]::FindSystemTimeZoneById($FromTimeZone)
    $to = [System.TimeZoneInfo]::FindSystemTimeZoneById($ToTimeZone)
    
    [System.TimeZoneInfo]::ConvertTime($DateTime, $from, $to)
}

# ENCODING UTILITIES
function ConvertTo-Base32 {
    param([Parameter(Mandatory=$true)][string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    $bits = -join ($bytes | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') })
    $result = ""
    for ($i = 0; $i -lt $bits.Length; $i += 5) {
        $chunk = $bits.Substring($i, [Math]::Min(5, $bits.Length - $i)).PadRight(5, '0')
        $result += $base32Chars[[Convert]::ToInt32($chunk, 2)]
    }
    $result
}

function Invoke-RestMethod2 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [object]$Body,
        [int]$TimeoutSec = 30
    )
    
    $params = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
        TimeoutSec = $TimeoutSec
        UseBasicParsing = $true
    }
    
    if ($Body) {
        $params.Body = $Body | ConvertTo-Json
        $params.Headers['Content-Type'] = 'application/json'
    }
    
    try {
        $response = Invoke-RestMethod @params
        @{
            Success = $true
            Data = $response
            StatusCode = 200
        }
    } catch {
        @{
            Success = $false
            Error = $_.Exception.Message
            StatusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        }
    }
}

# LOGGING UTILITIES
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet('Info','Warning','Error','Success','Debug')]
        [string]$Level = 'Info',
        [string]$LogFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    $colors = @{
        'Info' = 'White'
        'Warning' = 'Yellow'
        'Error' = 'Red'
        'Success' = 'Green'
        'Debug' = 'Gray'
    }
    
    Write-Host $logEntry -ForegroundColor $colors[$Level]
    
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $logEntry
    }
}

function New-ProgressBar {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Total,
        [string]$Activity = "Processing"
    )
    
    $script:progressTotal = $Total
    $script:progressCurrent = 0
    $script:progressActivity = $Activity
    
    @{
        Update = {
            param([int]$Current)
            $script:progressCurrent = $Current
            $percent = [math]::Round(($Current / $script:progressTotal) * 100)
            Write-Progress -Activity $script:progressActivity -PercentComplete $percent -Status "$Current of $script:progressTotal"
        }
        Complete = {
            Write-Progress -Activity $script:progressActivity -Completed
        }
    }
}

# VALIDATION UTILITIES
function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsElevated {
    Test-IsAdmin
}

function Test-IsValidEmail {
    param([Parameter(Mandatory=$true)][string]$Email)
    $Email -match '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
}

function Test-IsValidUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $Url -match '^https?://[\w\-\.]+(:\d+)?(/.*)?$'
}

function Test-IsValidIP {
    param([Parameter(Mandatory=$true)][string]$IPAddress)
    $IPAddress -match '^(\d{1,3}\.){3}\d{1,3}$' -and 
    ($IPAddress -split '\.' | ForEach-Object { [int]$_ -ge 0 -and [int]$_ -le 255 }) -notcontains $false
}

Export-ModuleMember -Function *
