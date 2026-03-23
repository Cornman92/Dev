<#
.SYNOPSIS
    WinPE PowerBuilder - Testing Framework Module
    Comprehensive testing and validation for WinPE builds and deployments

.DESCRIPTION
    This module provides testing capabilities including:
    - Image validation
    - Deployment testing
    - Hardware compatibility testing
    - Network connectivity testing
    - Driver verification
    - Automated test suites
    - Test reporting

.NOTES
    Module: Testing-Framework
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK, Pester 5.0+
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Module Variables

$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-TestingFramework.log"
$script:TestResultsPath = Join-Path $ModuleRoot "TestResults"
$script:TestReportsPath = Join-Path $ModuleRoot "TestReports"

# Ensure required paths exist
@($TestResultsPath, $TestReportsPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Test results storage
$script:TestResults = @{
    Passed = @()
    Failed = @()
    Warnings = @()
    TotalTests = 0
    StartTime = $null
    EndTime = $null
}

#endregion

#region Logging Functions

function Write-TestLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Test')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
        'Test'    { 'Cyan' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

#endregion

#region Test Result Management

function Add-TestResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestName,
        
        [Parameter(Mandatory)]
        [ValidateSet('Passed', 'Failed', 'Warning')]
        [string]$Status,
        
        [Parameter()]
        [string]$Message,
        
        [Parameter()]
        [timespan]$Duration,
        
        [Parameter()]
        [hashtable]$Details
    )
    
    $result = [PSCustomObject]@{
        TestName = $TestName
        Status = $Status
        Message = $Message
        Duration = $Duration
        Timestamp = Get-Date
        Details = $Details
    }
    
    switch ($Status) {
        'Passed'  { $script:TestResults.Passed += $result }
        'Failed'  { $script:TestResults.Failed += $result }
        'Warning' { $script:TestResults.Warnings += $result }
    }
    
    $script:TestResults.TotalTests++
    
    $color = switch ($Status) {
        'Passed'  { 'Green' }
        'Failed'  { 'Red' }
        'Warning' { 'Yellow' }
    }
    
    Write-Host "  [$Status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
}

function Get-TestSummary {
    [CmdletBinding()]
    param()
    
    $passedCount = $script:TestResults.Passed.Count
    $failedCount = $script:TestResults.Failed.Count
    $warningCount = $script:TestResults.Warnings.Count
    $totalCount = $script:TestResults.TotalTests
    
    $duration = if ($script:TestResults.EndTime) {
        $script:TestResults.EndTime - $script:TestResults.StartTime
    } else {
        [TimeSpan]::Zero
    }
    
    [PSCustomObject]@{
        TotalTests = $totalCount
        Passed = $passedCount
        Failed = $failedCount
        Warnings = $warningCount
        PassRate = if ($totalCount -gt 0) { [Math]::Round(($passedCount / $totalCount) * 100, 2) } else { 0 }
        Duration = $duration
        StartTime = $script:TestResults.StartTime
        EndTime = $script:TestResults.EndTime
    }
}

function Reset-TestResults {
    [CmdletBinding()]
    param()
    
    $script:TestResults = @{
        Passed = @()
        Failed = @()
        Warnings = @()
        TotalTests = 0
        StartTime = Get-Date
        EndTime = $null
    }
}

#endregion

#region Image Validation Tests

function Test-WinPEImageIntegrity {
    <#
    .SYNOPSIS
        Validates WinPE image file integrity
    
    .DESCRIPTION
        Checks image file existence, format, and DISM validation
    
    .EXAMPLE
        Test-WinPEImageIntegrity -ImagePath "C:\WinPE\boot.wim"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    try {
        Write-TestLog "Testing WinPE image integrity: $ImagePath" -Level Test
        $testStart = Get-Date
        
        # Check file exists
        if (-not (Test-Path $ImagePath)) {
            Add-TestResult -TestName "Image Exists" -Status Failed -Message "Image file not found: $ImagePath"
            return $false
        }
        Add-TestResult -TestName "Image Exists" -Status Passed -Message "Image file found"
        
        # Check file extension
        $extension = [System.IO.Path]::GetExtension($ImagePath)
        if ($extension -notin '.wim', '.vhd', '.vhdx') {
            Add-TestResult -TestName "Image Format" -Status Failed -Message "Invalid image format: $extension"
            return $false
        }
        Add-TestResult -TestName "Image Format" -Status Passed -Message "Valid format: $extension"
        
        # Check file size
        $fileInfo = Get-Item $ImagePath
        if ($fileInfo.Length -lt 100MB) {
            Add-TestResult -TestName "Image Size" -Status Warning -Message "Image seems small: $([Math]::Round($fileInfo.Length / 1MB, 2)) MB"
        } else {
            Add-TestResult -TestName "Image Size" -Status Passed -Message "Size: $([Math]::Round($fileInfo.Length / 1MB, 2)) MB"
        }
        
        # DISM validation for WIM files
        if ($extension -eq '.wim') {
            try {
                $imageInfo = Get-WindowsImage -ImagePath $ImagePath -ErrorAction Stop
                Add-TestResult -TestName "DISM Validation" -Status Passed -Message "Image contains $($imageInfo.Count) index(es)"
                
                if ($Detailed) {
                    foreach ($image in $imageInfo) {
                        $details = @{
                            ImageIndex = $image.ImageIndex
                            ImageName = $image.ImageName
                            ImageSize = $image.ImageSize
                        }
                        Add-TestResult -TestName "Image Index $($image.ImageIndex)" -Status Passed -Details $details
                    }
                }
            }
            catch {
                Add-TestResult -TestName "DISM Validation" -Status Failed -Message "DISM validation failed: $_"
                return $false
            }
        }
        
        $duration = (Get-Date) - $testStart
        Write-TestLog "Image integrity test completed in $($duration.TotalSeconds) seconds" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Image integrity test failed: $_" -Level Error
        Add-TestResult -TestName "Image Integrity" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

function Test-WinPEImageComponents {
    <#
    .SYNOPSIS
        Tests WinPE image for required components
    
    .DESCRIPTION
        Validates presence of critical WinPE components and packages
    
    .EXAMPLE
        Test-WinPEImageComponents -MountPath "C:\Mount\WinPE"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [string[]]$RequiredPackages = @('WinPE-WMI', 'WinPE-NetFx', 'WinPE-Scripting', 'WinPE-PowerShell')
    )
    
    try {
        Write-TestLog "Testing WinPE components in: $MountPath" -Level Test
        
        if (-not (Test-Path $MountPath)) {
            Add-TestResult -TestName "Mount Path Exists" -Status Failed -Message "Mount path not found"
            return $false
        }
        Add-TestResult -TestName "Mount Path Exists" -Status Passed
        
        # Get installed packages
        try {
            $packages = Get-WindowsPackage -Path $MountPath -ErrorAction Stop
            Add-TestResult -TestName "Package Enumeration" -Status Passed -Message "$($packages.Count) packages found"
        }
        catch {
            Add-TestResult -TestName "Package Enumeration" -Status Failed -Message "Failed to enumerate packages: $_"
            return $false
        }
        
        # Check required packages
        foreach ($requiredPackage in $RequiredPackages) {
            $found = $packages | Where-Object { $_.PackageName -like "*$requiredPackage*" }
            if ($found) {
                Add-TestResult -TestName "Package: $requiredPackage" -Status Passed -Message "Package installed"
            } else {
                Add-TestResult -TestName "Package: $requiredPackage" -Status Warning -Message "Package not found"
            }
        }
        
        # Check critical system files
        $criticalFiles = @(
            'Windows\System32\winpe.jpg',
            'Windows\System32\startnet.cmd',
            'Windows\System32\wpeinit.exe'
        )
        
        foreach ($file in $criticalFiles) {
            $fullPath = Join-Path $MountPath $file
            if (Test-Path $fullPath) {
                Add-TestResult -TestName "File: $file" -Status Passed
            } else {
                Add-TestResult -TestName "File: $file" -Status Failed -Message "Critical file missing"
            }
        }
        
        Write-TestLog "Component test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Component test failed: $_" -Level Error
        Add-TestResult -TestName "Component Test" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

#endregion

#region Deployment Tests

function Test-WinPEBootability {
    <#
    .SYNOPSIS
        Tests if WinPE image is bootable
    
    .DESCRIPTION
        Validates boot configuration and bootable partitions
    
    .EXAMPLE
        Test-WinPEBootability -ImagePath "C:\WinPE\boot.wim"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath
    )
    
    try {
        Write-TestLog "Testing WinPE bootability" -Level Test
        
        # Check for boot files in WIM
        try {
            $imageInfo = Get-WindowsImage -ImagePath $ImagePath -Index 1 -ErrorAction Stop
            Add-TestResult -TestName "Boot Image Info" -Status Passed -Message "Image index accessible"
        }
        catch {
            Add-TestResult -TestName "Boot Image Info" -Status Failed -Message "Cannot access image index"
            return $false
        }
        
        # Check image size is reasonable for booting
        $fileSize = (Get-Item $ImagePath).Length
        if ($fileSize -gt 4GB) {
            Add-TestResult -TestName "Boot Image Size" -Status Warning -Message "Image larger than 4GB may have boot issues"
        } else {
            Add-TestResult -TestName "Boot Image Size" -Status Passed -Message "Size acceptable for booting"
        }
        
        # Check for UEFI boot support (GPT)
        if ($imageInfo.Architecture -eq 9) { # x64
            Add-TestResult -TestName "UEFI Support" -Status Passed -Message "64-bit image supports UEFI"
        } else {
            Add-TestResult -TestName "UEFI Support" -Status Warning -Message "32-bit image, limited UEFI support"
        }
        
        Write-TestLog "Bootability test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Bootability test failed: $_" -Level Error
        Add-TestResult -TestName "Bootability Test" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

function Test-WinPEDeploymentWorkflow {
    <#
    .SYNOPSIS
        Tests complete deployment workflow
    
    .DESCRIPTION
        Simulates and validates deployment process steps
    
    .EXAMPLE
        Test-WinPEDeploymentWorkflow -ImagePath "C:\WinPE\boot.wim" -TestDiskNumber 1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter()]
        [int]$TestDiskNumber = -1
    )
    
    try {
        Write-TestLog "Testing deployment workflow" -Level Test
        
        # Step 1: Image access
        if (-not (Test-Path $ImagePath)) {
            Add-TestResult -TestName "Deployment: Image Access" -Status Failed -Message "Image not accessible"
            return $false
        }
        Add-TestResult -TestName "Deployment: Image Access" -Status Passed
        
        # Step 2: DISM functionality
        try {
            $null = Get-WindowsImage -ImagePath $ImagePath -ErrorAction Stop
            Add-TestResult -TestName "Deployment: DISM Functions" -Status Passed
        }
        catch {
            Add-TestResult -TestName "Deployment: DISM Functions" -Status Failed -Message "DISM errors: $_"
            return $false
        }
        
        # Step 3: Disk operations (if test disk specified)
        if ($TestDiskNumber -ge 0) {
            try {
                $disk = Get-Disk -Number $TestDiskNumber -ErrorAction Stop
                Add-TestResult -TestName "Deployment: Disk Access" -Status Passed -Message "Test disk accessible"
                
                # Check disk can be initialized
                if ($disk.PartitionStyle -eq 'RAW') {
                    Add-TestResult -TestName "Deployment: Disk Ready" -Status Passed -Message "Disk ready for partitioning"
                } else {
                    Add-TestResult -TestName "Deployment: Disk Status" -Status Warning -Message "Disk already initialized"
                }
            }
            catch {
                Add-TestResult -TestName "Deployment: Disk Access" -Status Failed -Message "Cannot access test disk"
            }
        }
        
        # Step 4: Network capability (if in WinPE)
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        if ($adapters) {
            $activeAdapter = $adapters | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
            if ($activeAdapter) {
                Add-TestResult -TestName "Deployment: Network Ready" -Status Passed -Message "Network adapter available"
            } else {
                Add-TestResult -TestName "Deployment: Network Ready" -Status Warning -Message "No active network adapter"
            }
        }
        
        Write-TestLog "Deployment workflow test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Deployment workflow test failed: $_" -Level Error
        Add-TestResult -TestName "Deployment Workflow" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

#endregion

#region Hardware Compatibility Tests

function Test-WinPEDriverSupport {
    <#
    .SYNOPSIS
        Tests driver support in WinPE image
    
    .DESCRIPTION
        Validates that required drivers are present for hardware
    
    .EXAMPLE
        Test-WinPEDriverSupport -MountPath "C:\Mount\WinPE"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [string[]]$RequiredDriverClasses = @('Net', 'SCSIAdapter', 'HDC')
    )
    
    try {
        Write-TestLog "Testing driver support" -Level Test
        
        # Get installed drivers
        try {
            $drivers = Get-WindowsDriver -Path $MountPath -ErrorAction Stop
            Add-TestResult -TestName "Driver Enumeration" -Status Passed -Message "$($drivers.Count) drivers found"
        }
        catch {
            Add-TestResult -TestName "Driver Enumeration" -Status Failed -Message "Failed to enumerate drivers"
            return $false
        }
        
        # Check for required driver classes
        foreach ($class in $RequiredDriverClasses) {
            $found = $drivers | Where-Object { $_.ClassName -eq $class }
            if ($found) {
                Add-TestResult -TestName "Driver Class: $class" -Status Passed -Message "$($found.Count) driver(s) found"
            } else {
                Add-TestResult -TestName "Driver Class: $class" -Status Warning -Message "No drivers for this class"
            }
        }
        
        # Check current hardware compatibility
        $currentHardware = Get-PnpDevice | Where-Object { $_.Status -ne 'OK' }
        if ($currentHardware) {
            Add-TestResult -TestName "Hardware Compatibility" -Status Warning -Message "$($currentHardware.Count) devices need drivers"
        } else {
            Add-TestResult -TestName "Hardware Compatibility" -Status Passed -Message "All current devices supported"
        }
        
        Write-TestLog "Driver support test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Driver support test failed: $_" -Level Error
        Add-TestResult -TestName "Driver Support" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

function Test-WinPEHardwareDetection {
    <#
    .SYNOPSIS
        Tests hardware detection in WinPE
    
    .DESCRIPTION
        Validates that hardware is properly detected and enumerated
    
    .EXAMPLE
        Test-WinPEHardwareDetection
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-TestLog "Testing hardware detection" -Level Test
        
        # Test CPU detection
        try {
            $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
            Add-TestResult -TestName "CPU Detection" -Status Passed -Message "$($cpu.Name)"
        }
        catch {
            Add-TestResult -TestName "CPU Detection" -Status Failed
        }
        
        # Test memory detection
        try {
            $memory = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
            $totalGB = [Math]::Round(($memory | Measure-Object Capacity -Sum).Sum / 1GB, 2)
            Add-TestResult -TestName "Memory Detection" -Status Passed -Message "${totalGB} GB"
        }
        catch {
            Add-TestResult -TestName "Memory Detection" -Status Failed
        }
        
        # Test disk detection
        try {
            $disks = Get-Disk -ErrorAction Stop
            Add-TestResult -TestName "Disk Detection" -Status Passed -Message "$($disks.Count) disk(s) detected"
        }
        catch {
            Add-TestResult -TestName "Disk Detection" -Status Failed
        }
        
        # Test network adapter detection
        try {
            $adapters = Get-NetAdapter -ErrorAction Stop
            Add-TestResult -TestName "Network Detection" -Status Passed -Message "$($adapters.Count) adapter(s) detected"
        }
        catch {
            Add-TestResult -TestName "Network Detection" -Status Failed
        }
        
        Write-TestLog "Hardware detection test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Hardware detection test failed: $_" -Level Error
        Add-TestResult -TestName "Hardware Detection" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

#endregion

#region Network Tests

function Test-WinPENetworkConfiguration {
    <#
    .SYNOPSIS
        Tests network configuration capabilities
    
    .DESCRIPTION
        Validates network adapter configuration and connectivity
    
    .EXAMPLE
        Test-WinPENetworkConfiguration
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-TestLog "Testing network configuration" -Level Test
        
        # Test adapter enumeration
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        if ($adapters) {
            Add-TestResult -TestName "Network Adapters" -Status Passed -Message "$($adapters.Count) adapter(s) found"
        } else {
            Add-TestResult -TestName "Network Adapters" -Status Failed -Message "No network adapters found"
            return $false
        }
        
        # Test active adapter
        $activeAdapter = $adapters | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
        if ($activeAdapter) {
            Add-TestResult -TestName "Active Adapter" -Status Passed -Message "$($activeAdapter.Name) is up"
            
            # Test IP configuration
            $ipConfig = Get-NetIPConfiguration -InterfaceIndex $activeAdapter.ifIndex -ErrorAction SilentlyContinue
            if ($ipConfig.IPv4Address) {
                Add-TestResult -TestName "IP Configuration" -Status Passed -Message "IP: $($ipConfig.IPv4Address.IPAddress)"
            } else {
                Add-TestResult -TestName "IP Configuration" -Status Warning -Message "No IP address assigned"
            }
            
            # Test DNS configuration
            if ($ipConfig.DNSServer) {
                Add-TestResult -TestName "DNS Configuration" -Status Passed -Message "DNS servers configured"
            } else {
                Add-TestResult -TestName "DNS Configuration" -Status Warning -Message "No DNS servers"
            }
        } else {
            Add-TestResult -TestName "Active Adapter" -Status Warning -Message "No active network adapter"
        }
        
        Write-TestLog "Network configuration test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Network configuration test failed: $_" -Level Error
        Add-TestResult -TestName "Network Configuration" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

function Test-WinPENetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity
    
    .DESCRIPTION
        Validates internet and network connectivity
    
    .EXAMPLE
        Test-WinPENetworkConnectivity -TestHosts @("8.8.8.8", "google.com")
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$TestHosts = @("8.8.8.8", "1.1.1.1")
    )
    
    try {
        Write-TestLog "Testing network connectivity" -Level Test
        
        foreach ($host in $TestHosts) {
            try {
                $pingResult = Test-Connection -ComputerName $host -Count 2 -ErrorAction Stop
                if ($pingResult) {
                    $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
                    Add-TestResult -TestName "Ping: $host" -Status Passed -Message "Latency: $([Math]::Round($avgLatency, 2))ms"
                }
            }
            catch {
                Add-TestResult -TestName "Ping: $host" -Status Failed -Message "No response"
            }
        }
        
        # Test DNS resolution
        try {
            $dnsTest = Resolve-DnsName -Name "www.microsoft.com" -ErrorAction Stop
            Add-TestResult -TestName "DNS Resolution" -Status Passed -Message "DNS working"
        }
        catch {
            Add-TestResult -TestName "DNS Resolution" -Status Failed -Message "DNS resolution failed"
        }
        
        Write-TestLog "Network connectivity test completed" -Level Success
        return $true
    }
    catch {
        Write-TestLog "Network connectivity test failed: $_" -Level Error
        Add-TestResult -TestName "Network Connectivity" -Status Failed -Message $_.Exception.Message
        return $false
    }
}

#endregion

#region Test Suites

function Invoke-WinPETestSuite {
    <#
    .SYNOPSIS
        Runs a comprehensive test suite
    
    .DESCRIPTION
        Executes all tests and generates a report
    
    .EXAMPLE
        Invoke-WinPETestSuite -ImagePath "C:\WinPE\boot.wim" -MountPath "C:\Mount\WinPE"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ImagePath,
        
        [Parameter()]
        [string]$MountPath,
        
        [Parameter()]
        [ValidateSet('Quick', 'Full', 'Custom')]
        [string]$TestLevel = 'Quick',
        
        [Parameter()]
        [string[]]$IncludeTests,
        
        [Parameter()]
        [switch]$GenerateReport
    )
    
    try {
        Write-TestLog "Starting WinPE test suite - Level: $TestLevel" -Level Info
        Reset-TestResults
        
        $allTests = @(
            @{ Name = 'Image Integrity'; Function = { Test-WinPEImageIntegrity -ImagePath $ImagePath } },
            @{ Name = 'Image Components'; Function = { Test-WinPEImageComponents -MountPath $MountPath } },
            @{ Name = 'Bootability'; Function = { Test-WinPEBootability -ImagePath $ImagePath } },
            @{ Name = 'Driver Support'; Function = { Test-WinPEDriverSupport -MountPath $MountPath } },
            @{ Name = 'Hardware Detection'; Function = { Test-WinPEHardwareDetection } },
            @{ Name = 'Network Configuration'; Function = { Test-WinPENetworkConfiguration } },
            @{ Name = 'Network Connectivity'; Function = { Test-WinPENetworkConnectivity } }
        )
        
        # Filter tests based on level
        $testsToRun = switch ($TestLevel) {
            'Quick' {
                $allTests | Where-Object { $_.Name -in @('Image Integrity', 'Hardware Detection', 'Network Configuration') }
            }
            'Full' {
                $allTests
            }
            'Custom' {
                if ($IncludeTests) {
                    $allTests | Where-Object { $_.Name -in $IncludeTests }
                } else {
                    Write-TestLog "Custom test level requires -IncludeTests parameter" -Level Warning
                    return
                }
            }
        }
        
        # Run tests
        foreach ($test in $testsToRun) {
            Write-Host "`n=== Running: $($test.Name) ===" -ForegroundColor Cyan
            try {
                & $test.Function
            }
            catch {
                Write-TestLog "Test '$($test.Name)' encountered an error: $_" -Level Error
                Add-TestResult -TestName $test.Name -Status Failed -Message $_.Exception.Message
            }
        }
        
        $script:TestResults.EndTime = Get-Date
        
        # Display summary
        Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
        $summary = Get-TestSummary
        Write-Host "Total Tests: $($summary.TotalTests)" -ForegroundColor White
        Write-Host "Passed: $($summary.Passed)" -ForegroundColor Green
        Write-Host "Failed: $($summary.Failed)" -ForegroundColor Red
        Write-Host "Warnings: $($summary.Warnings)" -ForegroundColor Yellow
        Write-Host "Pass Rate: $($summary.PassRate)%" -ForegroundColor $(if ($summary.PassRate -ge 80) { 'Green' } else { 'Yellow' })
        Write-Host "Duration: $($summary.Duration.TotalSeconds) seconds" -ForegroundColor White
        
        # Generate report if requested
        if ($GenerateReport) {
            $reportPath = Export-WinPETestReport -Format HTML
            Write-TestLog "Test report generated: $reportPath" -Level Success
        }
        
        return $summary
    }
    catch {
        Write-TestLog "Test suite failed: $_" -Level Error
        throw
    }
}

#endregion

#region Reporting

function Export-WinPETestReport {
    <#
    .SYNOPSIS
        Exports test results to a report
    
    .DESCRIPTION
        Generates test report in specified format
    
    .EXAMPLE
        Export-WinPETestReport -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath
    )
    
    try {
        $summary = Get-TestSummary
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        if (-not $OutputPath) {
            $OutputPath = Join-Path $script:TestReportsPath "WinPE_TestReport_$timestamp.$($Format.ToLower())"
        }
        
        switch ($Format) {
            'HTML' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>WinPE Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D4; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .passed { color: green; font-weight: bold; }
        .failed { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #0078D4; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>WinPE Test Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Generated: $(Get-Date)</p>
        <p>Total Tests: $($summary.TotalTests)</p>
        <p>Passed: <span class="passed">$($summary.Passed)</span></p>
        <p>Failed: <span class="failed">$($summary.Failed)</span></p>
        <p>Warnings: <span class="warning">$($summary.Warnings)</span></p>
        <p>Pass Rate: $($summary.PassRate)%</p>
        <p>Duration: $($summary.Duration.TotalSeconds) seconds</p>
    </div>
    
    <h2>Test Results</h2>
    <table>
        <tr>
            <th>Test Name</th>
            <th>Status</th>
            <th>Message</th>
            <th>Duration</th>
        </tr>
"@
                
                foreach ($result in ($script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Warnings)) {
                    $statusClass = $result.Status.ToLower()
                    $html += @"
        <tr>
            <td>$($result.TestName)</td>
            <td class="$statusClass">$($result.Status)</td>
            <td>$($result.Message)</td>
            <td>$($result.Duration.TotalSeconds) s</td>
        </tr>
"@
                }
                
                $html += @"
    </table>
</body>
</html>
"@
                
                $html | Set-Content -Path $OutputPath -Force
            }
            
            'JSON' {
                $report = @{
                    Summary = $summary
                    Results = @{
                        Passed = $script:TestResults.Passed
                        Failed = $script:TestResults.Failed
                        Warnings = $script:TestResults.Warnings
                    }
                }
                $report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Force
            }
            
            'CSV' {
                ($script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Warnings) | 
                    Export-Csv -Path $OutputPath -NoTypeInformation -Force
            }
            
            'XML' {
                ($script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Warnings) | 
                    Export-Clixml -Path $OutputPath -Force
            }
        }
        
        Write-TestLog "Report exported to: $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-TestLog "Failed to export report: $_" -Level Error
        throw
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'Test-WinPEImageIntegrity',
    'Test-WinPEImageComponents',
    'Test-WinPEBootability',
    'Test-WinPEDeploymentWorkflow',
    'Test-WinPEDriverSupport',
    'Test-WinPEHardwareDetection',
    'Test-WinPENetworkConfiguration',
    'Test-WinPENetworkConnectivity',
    'Invoke-WinPETestSuite',
    'Export-WinPETestReport',
    'Get-TestSummary',
    'Reset-TestResults'
)

#endregion
