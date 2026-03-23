<#
.SYNOPSIS
    WinPE PowerBuilder - Reporting Module
    Comprehensive reporting and documentation generation for WinPE deployments

.DESCRIPTION
    This module provides reporting capabilities including:
    - Deployment reports
    - System inventory reports
    - Driver compliance reports
    - Network configuration reports
    - Test result aggregation
    - Custom report templates
    - Multi-format export (HTML, PDF, JSON, CSV, XML)

.NOTES
    Module: Reporting-Module
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Module Variables

$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-Reporting.log"
$script:ReportPath = Join-Path $ModuleRoot "Reports"
$script:TemplatePath = Join-Path $ModuleRoot "Templates"

# Ensure required paths exist
@($ReportPath, $TemplatePath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Report metadata storage
$script:ReportMetadata = @{
    GeneratedBy = $env:USERNAME
    GeneratedOn = $env:COMPUTERNAME
    ReportVersion = '1.0.0'
}

#endregion

#region Logging Functions

function Write-ReportLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

#endregion

#region System Inventory Reports

function New-WinPESystemInventoryReport {
    <#
    .SYNOPSIS
        Generates comprehensive system inventory report
    
    .DESCRIPTION
        Creates detailed report of hardware, software, and system configuration
    
    .EXAMPLE
        New-WinPESystemInventoryReport -Format HTML -OutputPath "C:\Reports\Inventory.html"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$IncludeDrivers,
        
        [Parameter()]
        [switch]$IncludeNetworkConfig
    )
    
    try {
        Write-ReportLog "Generating system inventory report" -Level Info
        
        # Collect system information
        $computerSystem = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS
        $os = Get-CimInstance Win32_OperatingSystem
        $processor = Get-CimInstance Win32_Processor
        $memory = Get-CimInstance Win32_PhysicalMemory
        $disks = Get-Disk
        
        $inventory = [PSCustomObject]@{
            ComputerName = $computerSystem.Name
            Manufacturer = $computerSystem.Manufacturer
            Model = $computerSystem.Model
            SerialNumber = $bios.SerialNumber
            BIOSVersion = $bios.SMBIOSBIOSVersion
            OSVersion = $os.Version
            OSArchitecture = $os.OSArchitecture
            ProcessorName = $processor.Name
            ProcessorCores = $processor.NumberOfCores
            ProcessorThreads = $processor.NumberOfLogicalProcessors
            TotalMemoryGB = [Math]::Round(($memory | Measure-Object Capacity -Sum).Sum / 1GB, 2)
            TotalDisks = $disks.Count
            TotalDiskCapacityGB = [Math]::Round(($disks | Measure-Object Size -Sum).Sum / 1GB, 2)
            ReportDate = Get-Date
        }
        
        # Add drivers if requested
        if ($IncludeDrivers) {
            $drivers = Get-WindowsDriver -Online | Select-Object -First 50
            $inventory | Add-Member -MemberType NoteProperty -Name Drivers -Value $drivers
        }
        
        # Add network config if requested
        if ($IncludeNetworkConfig) {
            $adapters = Get-NetAdapter | Select-Object Name, Status, MacAddress, LinkSpeed
            $inventory | Add-Member -MemberType NoteProperty -Name NetworkAdapters -Value $adapters
        }
        
        # Generate report
        $reportPath = Export-WinPEReport -Data $inventory -Format $Format -OutputPath $OutputPath -Title "System Inventory Report"
        
        Write-ReportLog "System inventory report generated: $reportPath" -Level Success
        return $reportPath
    }
    catch {
        Write-ReportLog "Failed to generate system inventory report: $_" -Level Error
        throw
    }
}

#endregion

#region Deployment Reports

function New-WinPEDeploymentReport {
    <#
    .SYNOPSIS
        Generates deployment operation report
    
    .DESCRIPTION
        Creates report documenting deployment operations and results
    
    .EXAMPLE
        New-WinPEDeploymentReport -DeploymentData $deploymentLog -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$DeploymentData,
        
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath
    )
    
    try {
        Write-ReportLog "Generating deployment report" -Level Info
        
        # Structure deployment data
        $deploymentReport = [PSCustomObject]@{
            DeploymentID = $DeploymentData.DeploymentID ?? (New-Guid).ToString()
            StartTime = $DeploymentData.StartTime ?? (Get-Date)
            EndTime = $DeploymentData.EndTime ?? (Get-Date)
            Duration = if ($DeploymentData.Duration) { $DeploymentData.Duration } else { 
                (Get-Date) - $DeploymentData.StartTime 
            }
            Status = $DeploymentData.Status ?? 'Unknown'
            TargetSystem = $DeploymentData.TargetSystem ?? $env:COMPUTERNAME
            ImageApplied = $DeploymentData.ImageApplied ?? 'N/A'
            DriversInstalled = $DeploymentData.DriversInstalled ?? 0
            ErrorsEncountered = $DeploymentData.Errors ?? @()
            WarningsEncountered = $DeploymentData.Warnings ?? @()
            StepsCompleted = $DeploymentData.StepsCompleted ?? @()
            TotalSteps = $DeploymentData.TotalSteps ?? 0
            SuccessRate = if ($DeploymentData.TotalSteps -gt 0) {
                [Math]::Round(($DeploymentData.StepsCompleted.Count / $DeploymentData.TotalSteps) * 100, 2)
            } else { 0 }
        }
        
        # Generate report
        $reportPath = Export-WinPEReport -Data $deploymentReport -Format $Format -OutputPath $OutputPath -Title "Deployment Report"
        
        Write-ReportLog "Deployment report generated: $reportPath" -Level Success
        return $reportPath
    }
    catch {
        Write-ReportLog "Failed to generate deployment report: $_" -Level Error
        throw
    }
}

#endregion

#region Driver Compliance Reports

function New-WinPEDriverComplianceReport {
    <#
    .SYNOPSIS
        Generates driver compliance report
    
    .DESCRIPTION
        Creates report showing driver installation status and compliance
    
    .EXAMPLE
        New-WinPEDriverComplianceReport -ImagePath "C:\WinPE\boot.wim" -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ImagePath,
        
        [Parameter()]
        [string]$MountPath,
        
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath
    )
    
    try {
        Write-ReportLog "Generating driver compliance report" -Level Info
        
        # Get installed drivers
        $installedDrivers = if ($MountPath -and (Test-Path $MountPath)) {
            Get-WindowsDriver -Path $MountPath
        } else {
            Get-WindowsDriver -Online
        }
        
        # Get hardware devices
        $devices = Get-PnpDevice
        
        # Analyze driver coverage
        $driversByClass = $installedDrivers | Group-Object -Property ClassName
        $devicesByClass = $devices | Group-Object -Property Class
        
        $compliance = @()
        
        foreach ($deviceClass in $devicesByClass) {
            $className = $deviceClass.Name
            $deviceCount = $deviceClass.Count
            $driverGroup = $driversByClass | Where-Object { $_.Name -eq $className }
            $driverCount = if ($driverGroup) { $driverGroup.Count } else { 0 }
            
            $status = if ($driverCount -gt 0) { 'Covered' } else { 'Missing' }
            
            $compliance += [PSCustomObject]@{
                DeviceClass = $className
                DeviceCount = $deviceCount
                DriversAvailable = $driverCount
                Status = $status
                CompliancePercentage = if ($deviceCount -gt 0) {
                    [Math]::Round(($driverCount / $deviceCount) * 100, 2)
                } else { 0 }
            }
        }
        
        $complianceReport = [PSCustomObject]@{
            TotalDevices = $devices.Count
            TotalDrivers = $installedDrivers.Count
            DevicesCovered = ($compliance | Where-Object { $_.Status -eq 'Covered' } | Measure-Object DeviceCount -Sum).Sum
            DevicesMissing = ($compliance | Where-Object { $_.Status -eq 'Missing' } | Measure-Object DeviceCount -Sum).Sum
            OverallCompliance = [Math]::Round((($compliance | Where-Object { $_.Status -eq 'Covered' } | Measure-Object DeviceCount -Sum).Sum / $devices.Count) * 100, 2)
            ComplianceByClass = $compliance
            ReportDate = Get-Date
        }
        
        # Generate report
        $reportPath = Export-WinPEReport -Data $complianceReport -Format $Format -OutputPath $OutputPath -Title "Driver Compliance Report"
        
        Write-ReportLog "Driver compliance report generated: $reportPath" -Level Success
        return $reportPath
    }
    catch {
        Write-ReportLog "Failed to generate driver compliance report: $_" -Level Error
        throw
    }
}

#endregion

#region Network Configuration Reports

function New-WinPENetworkConfigReport {
    <#
    .SYNOPSIS
        Generates network configuration report
    
    .DESCRIPTION
        Creates report documenting network adapter configuration and status
    
    .EXAMPLE
        New-WinPENetworkConfigReport -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$IncludeConnectivityTest
    )
    
    try {
        Write-ReportLog "Generating network configuration report" -Level Info
        
        # Get network adapters
        $adapters = Get-NetAdapter
        
        $networkConfig = @()
        
        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
            
            $config = [PSCustomObject]@{
                AdapterName = $adapter.Name
                Status = $adapter.Status
                MacAddress = $adapter.MacAddress
                LinkSpeed = $adapter.LinkSpeed
                IPAddress = if ($ipConfig.IPv4Address) { $ipConfig.IPv4Address.IPAddress } else { 'N/A' }
                SubnetMask = if ($ipConfig.IPv4Address) { $ipConfig.IPv4Address.PrefixLength } else { 'N/A' }
                Gateway = if ($ipConfig.IPv4DefaultGateway) { $ipConfig.IPv4DefaultGateway.NextHop } else { 'N/A' }
                DNSServers = if ($ipConfig.DNSServer) { $ipConfig.DNSServer.ServerAddresses -join ', ' } else { 'N/A' }
                DHCPEnabled = $adapter.DhcpEnabled
            }
            
            # Add connectivity test if requested
            if ($IncludeConnectivityTest -and $adapter.Status -eq 'Up') {
                $pingTest = Test-Connection -ComputerName '8.8.8.8' -Count 2 -ErrorAction SilentlyContinue
                $config | Add-Member -MemberType NoteProperty -Name ConnectivityTest -Value $(
                    if ($pingTest) { 'Passed' } else { 'Failed' }
                )
            }
            
            $networkConfig += $config
        }
        
        $networkReport = [PSCustomObject]@{
            TotalAdapters = $adapters.Count
            ActiveAdapters = ($adapters | Where-Object { $_.Status -eq 'Up' }).Count
            AdapterConfigurations = $networkConfig
            ReportDate = Get-Date
        }
        
        # Generate report
        $reportPath = Export-WinPEReport -Data $networkReport -Format $Format -OutputPath $OutputPath -Title "Network Configuration Report"
        
        Write-ReportLog "Network configuration report generated: $reportPath" -Level Success
        return $reportPath
    }
    catch {
        Write-ReportLog "Failed to generate network configuration report: $_" -Level Error
        throw
    }
}

#endregion

#region Test Result Aggregation

function New-WinPETestAggregationReport {
    <#
    .SYNOPSIS
        Aggregates and reports on test results
    
    .DESCRIPTION
        Creates consolidated report from multiple test runs
    
    .EXAMPLE
        New-WinPETestAggregationReport -TestResults $allTestResults -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$TestResults,
        
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath
    )
    
    try {
        Write-ReportLog "Generating test aggregation report" -Level Info
        
        $totalTests = $TestResults.Count
        $passedTests = ($TestResults | Where-Object { $_.Status -eq 'Passed' }).Count
        $failedTests = ($TestResults | Where-Object { $_.Status -eq 'Failed' }).Count
        $warningTests = ($TestResults | Where-Object { $_.Status -eq 'Warning' }).Count
        
        $testsByCategory = $TestResults | Group-Object -Property Category
        
        $aggregation = [PSCustomObject]@{
            TotalTests = $totalTests
            PassedTests = $passedTests
            FailedTests = $failedTests
            WarningTests = $warningTests
            PassRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
            TestsByCategory = $testsByCategory | ForEach-Object {
                [PSCustomObject]@{
                    Category = $_.Name
                    TotalTests = $_.Count
                    Passed = ($_.Group | Where-Object { $_.Status -eq 'Passed' }).Count
                    Failed = ($_.Group | Where-Object { $_.Status -eq 'Failed' }).Count
                    Warnings = ($_.Group | Where-Object { $_.Status -eq 'Warning' }).Count
                }
            }
            DetailedResults = $TestResults
            ReportDate = Get-Date
        }
        
        # Generate report
        $reportPath = Export-WinPEReport -Data $aggregation -Format $Format -OutputPath $OutputPath -Title "Test Aggregation Report"
        
        Write-ReportLog "Test aggregation report generated: $reportPath" -Level Success
        return $reportPath
    }
    catch {
        Write-ReportLog "Failed to generate test aggregation report: $_" -Level Error
        throw
    }
}

#endregion

#region Custom Reports

function New-WinPECustomReport {
    <#
    .SYNOPSIS
        Creates custom report from provided data
    
    .DESCRIPTION
        Generates custom report using provided data and optional template
    
    .EXAMPLE
        New-WinPECustomReport -Data $customData -Title "Custom Report" -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Data,
        
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter()]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format = 'HTML',
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [string]$TemplatePath,
        
        [Parameter()]
        [hashtable]$CustomSections
    )
    
    try {
        Write-ReportLog "Generating custom report: $Title" -Level Info
        
        $customReport = [PSCustomObject]@{
            ReportTitle = $Title
            ReportData = $Data
            GeneratedBy = $script:ReportMetadata.GeneratedBy
            GeneratedOn = $script:ReportMetadata.GeneratedOn
            GeneratedDate = Get-Date
        }
        
        # Add custom sections if provided
        if ($CustomSections) {
            foreach ($section in $CustomSections.GetEnumerator()) {
                $customReport | Add-Member -MemberType NoteProperty -Name $section.Key -Value $section.Value
            }
        }
        
        # Generate report
        $reportPath = Export-WinPEReport -Data $customReport -Format $Format -OutputPath $OutputPath -Title $Title -TemplatePath $TemplatePath
        
        Write-ReportLog "Custom report generated: $reportPath" -Level Success
        return $reportPath
    }
    catch {
        Write-ReportLog "Failed to generate custom report: $_" -Level Error
        throw
    }
}

#endregion

#region Report Export Functions

function Export-WinPEReport {
    <#
    .SYNOPSIS
        Exports report data to specified format
    
    .DESCRIPTION
        Converts report data to various formats (HTML, JSON, CSV, XML, PDF)
    
    .EXAMPLE
        Export-WinPEReport -Data $reportData -Format HTML -Title "My Report"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Data,
        
        [Parameter(Mandatory)]
        [ValidateSet('HTML', 'JSON', 'CSV', 'XML', 'PDF')]
        [string]$Format,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [string]$Title = "WinPE Report",
        
        [Parameter()]
        [string]$TemplatePath
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        if (-not $OutputPath) {
            $OutputPath = Join-Path $script:ReportPath "${Title}_${timestamp}.$($Format.ToLower())"
        }
        
        switch ($Format) {
            'HTML' {
                $html = Get-HTMLReportTemplate -Title $Title -Data $Data -TemplatePath $TemplatePath
                $html | Set-Content -Path $OutputPath -Force
            }
            
            'JSON' {
                $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Force
            }
            
            'CSV' {
                if ($Data -is [Array]) {
                    $Data | Export-Csv -Path $OutputPath -NoTypeInformation -Force
                } else {
                    $Data | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $OutputPath -Force
                }
            }
            
            'XML' {
                $Data | Export-Clixml -Path $OutputPath -Force
            }
            
            'PDF' {
                # Generate HTML first, then convert to PDF
                $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, '.html')
                $html = Get-HTMLReportTemplate -Title $Title -Data $Data
                $html | Set-Content -Path $htmlPath -Force
                
                # Note: PDF conversion would require additional tools like wkhtmltopdf
                Write-ReportLog "HTML generated at: $htmlPath (PDF conversion requires external tool)" -Level Warning
                $OutputPath = $htmlPath
            }
        }
        
        Write-ReportLog "Report exported to: $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-ReportLog "Failed to export report: $_" -Level Error
        throw
    }
}

function Get-HTMLReportTemplate {
    <#
    .SYNOPSIS
        Generates HTML report from data
    
    .DESCRIPTION
        Creates styled HTML report with optional custom template
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter(Mandatory)]
        [object]$Data,
        
        [Parameter()]
        [string]$TemplatePath
    )
    
    # If custom template provided, use it
    if ($TemplatePath -and (Test-Path $TemplatePath)) {
        $template = Get-Content -Path $TemplatePath -Raw
        # Simple template variable replacement
        $template = $template -replace '\{\{Title\}\}', $Title
        $template = $template -replace '\{\{Date\}\}', (Get-Date).ToString()
        $template = $template -replace '\{\{Data\}\}', ($Data | ConvertTo-Html -Fragment)
        return $template
    }
    
    # Default HTML template
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>$Title</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0078D4;
            border-bottom: 3px solid #0078D4;
            padding-bottom: 10px;
        }
        h2 {
            color: #333;
            margin-top: 25px;
        }
        .metadata {
            background-color: #f0f0f0;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .metadata p {
            margin: 5px 0;
            color: #666;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #0078D4;
            color: white;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .status-passed {
            color: green;
            font-weight: bold;
        }
        .status-failed {
            color: red;
            font-weight: bold;
        }
        .status-warning {
            color: orange;
            font-weight: bold;
        }
        .summary-box {
            display: inline-block;
            padding: 15px 25px;
            margin: 10px;
            border-radius: 5px;
            background-color: #e8f4f8;
            border-left: 4px solid #0078D4;
        }
        .summary-box h3 {
            margin: 0 0 5px 0;
            color: #0078D4;
        }
        .summary-box p {
            margin: 0;
            font-size: 24px;
            font-weight: bold;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #999;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        
        <div class="metadata">
            <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
            <p><strong>Generated By:</strong> $($script:ReportMetadata.GeneratedBy)</p>
            <p><strong>Computer:</strong> $($script:ReportMetadata.GeneratedOn)</p>
            <p><strong>Report Version:</strong> $($script:ReportMetadata.ReportVersion)</p>
        </div>
        
        <h2>Report Data</h2>
"@
    
    # Add data content
    if ($Data -is [Array]) {
        $html += $Data | ConvertTo-Html -Fragment
    } else {
        # Convert object properties to HTML
        $html += "<table>"
        $Data.PSObject.Properties | ForEach-Object {
            $propertyName = $_.Name
            $propertyValue = $_.Value
            
            if ($propertyValue -is [Array] -or $propertyValue -is [System.Collections.IEnumerable]) {
                $html += "<tr><th colspan='2'>$propertyName</th></tr>"
                $html += "<tr><td colspan='2'>"
                $html += $propertyValue | ConvertTo-Html -Fragment
                $html += "</td></tr>"
            } else {
                $html += "<tr><th>$propertyName</th><td>$propertyValue</td></tr>"
            }
        }
        $html += "</table>"
    }
    
    # Close HTML
    $html += @"
        
        <div class="footer">
            <p>WinPE PowerBuilder Suite - Reporting Module v$($script:ReportMetadata.ReportVersion)</p>
            <p>Copyright © 2026 Better11 Development Team</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

#endregion

#region Report Scheduling

function Register-WinPEScheduledReport {
    <#
    .SYNOPSIS
        Schedules automatic report generation
    
    .DESCRIPTION
        Creates scheduled task to generate reports automatically
    
    .EXAMPLE
        Register-WinPEScheduledReport -ReportType SystemInventory -Schedule Daily -Time "08:00"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('SystemInventory', 'NetworkConfig', 'DriverCompliance')]
        [string]$ReportType,
        
        [Parameter(Mandatory)]
        [ValidateSet('Daily', 'Weekly', 'Monthly')]
        [string]$Schedule,
        
        [Parameter()]
        [string]$Time = "08:00",
        
        [Parameter()]
        [string]$OutputDirectory = $script:ReportPath
    )
    
    try {
        Write-ReportLog "Registering scheduled report: $ReportType" -Level Info
        
        $taskName = "WinPE_${ReportType}_Report"
        
        # Create scheduled task action
        $action = switch ($ReportType) {
            'SystemInventory' {
                New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command New-WinPESystemInventoryReport -Format HTML -OutputPath '$OutputDirectory'"
            }
            'NetworkConfig' {
                New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command New-WinPENetworkConfigReport -Format HTML -OutputPath '$OutputDirectory'"
            }
            'DriverCompliance' {
                New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command New-WinPEDriverComplianceReport -Format HTML -OutputPath '$OutputDirectory'"
            }
        }
        
        # Create trigger based on schedule
        $trigger = switch ($Schedule) {
            'Daily' {
                New-ScheduledTaskTrigger -Daily -At $Time
            }
            'Weekly' {
                New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $Time
            }
            'Monthly' {
                New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At $Time
            }
        }
        
        # Register scheduled task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Automatic $ReportType report generation" -ErrorAction Stop
        
        Write-ReportLog "Scheduled report registered: $taskName" -Level Success
    }
    catch {
        Write-ReportLog "Failed to register scheduled report: $_" -Level Error
        throw
    }
}

function Unregister-WinPEScheduledReport {
    <#
    .SYNOPSIS
        Removes scheduled report task
    
    .DESCRIPTION
        Unregisters scheduled task for report generation
    
    .EXAMPLE
        Unregister-WinPEScheduledReport -ReportType SystemInventory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('SystemInventory', 'NetworkConfig', 'DriverCompliance')]
        [string]$ReportType
    )
    
    try {
        $taskName = "WinPE_${ReportType}_Report"
        
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        
        Write-ReportLog "Scheduled report unregistered: $taskName" -Level Success
    }
    catch {
        Write-ReportLog "Failed to unregister scheduled report: $_" -Level Error
        throw
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'New-WinPESystemInventoryReport',
    'New-WinPEDeploymentReport',
    'New-WinPEDriverComplianceReport',
    'New-WinPENetworkConfigReport',
    'New-WinPETestAggregationReport',
    'New-WinPECustomReport',
    'Export-WinPEReport',
    'Register-WinPEScheduledReport',
    'Unregister-WinPEScheduledReport'
)

#endregion
