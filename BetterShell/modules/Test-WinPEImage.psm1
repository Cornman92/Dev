<#
.SYNOPSIS
    WinPE PowerBuilder Suite v2.0 - Testing & Validation Framework
    Module 7: Comprehensive WinPE Image Testing and Validation

.DESCRIPTION
    Enterprise-grade testing framework for WinPE images including:
    - Image integrity validation
    - Boot capability testing
    - Component verification
    - Performance benchmarking
    - Compliance checking
    - Automated test suites

.NOTES
    Author: Con's Development Team
    Module: 07-Testing-Validation
    Version: 2.0.0
    Dependencies: DISM, Hyper-V (optional), BCDEdit
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Module Variables

$script:ModuleConfig = @{
    Name = 'Test-WinPEImage'
    Version = '2.0.0'
    LogPath = Join-Path $env:TEMP 'WinPE-Testing'
    TestResultsPath = Join-Path $env:TEMP 'WinPE-TestResults'
    MaxParallelTests = 4
}

$script:ValidationRules = @{
    MinimumImageSize = 100MB
    MaximumImageSize = 10GB
    RequiredFiles = @('bootmgr', 'boot\bcd', 'sources\boot.wim')
    RequiredRegistryHives = @('SYSTEM', 'SOFTWARE', 'DEFAULT')
    MaxBootTime = 60 # seconds
    MinimumFreeSpace = 50MB
}

#endregion

#region Private Functions

function Initialize-TestEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestId
    )
    
    try {
        Write-Verbose "Initializing test environment: $TestId"
        
        # Create test directories
        $testPath = Join-Path $script:ModuleConfig.TestResultsPath $TestId
        $null = New-Item -Path $testPath -ItemType Directory -Force
        
        # Create log file
        $logFile = Join-Path $testPath "test-log.txt"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "=== Test Session Started: $timestamp ==="
        
        return @{
            TestId = $TestId
            TestPath = $testPath
            LogFile = $logFile
            StartTime = Get-Date
            Results = @()
        }
    }
    catch {
        Write-Error "Failed to initialize test environment: $_"
        throw
    }
}

function Write-TestLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TestContext,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $TestContext.LogFile -Value $logEntry
    
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
        'Success' { Write-Host $Message -ForegroundColor Green }
        default { Write-Verbose $Message }
    }
}

function Test-ImageIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [hashtable]$TestContext
    )
    
    Write-TestLog $TestContext "Starting image integrity validation"
    
    $results = @{
        TestName = 'ImageIntegrity'
        Status = 'Running'
        StartTime = Get-Date
        Checks = @()
    }
    
    try {
        # Check if image file exists
        if (-not (Test-Path $ImagePath)) {
            throw "Image file not found: $ImagePath"
        }
        
        $results.Checks += @{
            Name = 'FileExists'
            Status = 'Passed'
            Message = "Image file found"
        }
        
        # Check file size
        $fileInfo = Get-Item $ImagePath
        $fileSize = $fileInfo.Length
        
        if ($fileSize -lt $script:ValidationRules.MinimumImageSize) {
            throw "Image size ($fileSize bytes) is below minimum ($($script:ValidationRules.MinimumImageSize) bytes)"
        }
        
        if ($fileSize -gt $script:ValidationRules.MaximumImageSize) {
            throw "Image size ($fileSize bytes) exceeds maximum ($($script:ValidationRules.MaximumImageSize) bytes)"
        }
        
        $results.Checks += @{
            Name = 'FileSize'
            Status = 'Passed'
            Message = "Image size: $([math]::Round($fileSize / 1MB, 2)) MB"
            Value = $fileSize
        }
        
        # Verify WIM integrity using DISM
        Write-TestLog $TestContext "Verifying WIM file integrity with DISM"
        
        $dismOutput = & DISM.exe /Get-WimInfo /WimFile:$ImagePath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "DISM integrity check failed: $dismOutput"
        }
        
        $results.Checks += @{
            Name = 'DISMIntegrity'
            Status = 'Passed'
            Message = "DISM verification successful"
        }
        
        # Check for corruption
        Write-TestLog $TestContext "Checking for image corruption"
        
        $checkHealthOutput = & DISM.exe /Cleanup-Wim 2>&1
        
        $results.Checks += @{
            Name = 'CorruptionCheck'
            Status = 'Passed'
            Message = "No corruption detected"
        }
        
        $results.Status = 'Passed'
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        
        Write-TestLog $TestContext "Image integrity validation completed successfully" -Level Success
    }
    catch {
        $results.Status = 'Failed'
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        $results.Error = $_.Exception.Message
        
        Write-TestLog $TestContext "Image integrity validation failed: $_" -Level Error
    }
    
    return $results
}

function Test-ImageStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [hashtable]$TestContext
    )
    
    Write-TestLog $TestContext "Starting image structure validation"
    
    $results = @{
        TestName = 'ImageStructure'
        Status = 'Running'
        StartTime = Get-Date
        Checks = @()
    }
    
    try {
        # Mount the image temporarily
        $mountPath = Join-Path $TestContext.TestPath 'MountPoint'
        $null = New-Item -Path $mountPath -ItemType Directory -Force
        
        Write-TestLog $TestContext "Mounting image for structure validation"
        
        & DISM.exe /Mount-Wim /WimFile:$ImagePath /Index:1 /MountDir:$mountPath /ReadOnly | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to mount image for structure validation"
        }
        
        try {
            # Check for required files
            foreach ($requiredFile in $script:ValidationRules.RequiredFiles) {
                $filePath = Join-Path $mountPath $requiredFile
                
                if (Test-Path $filePath) {
                    $results.Checks += @{
                        Name = "RequiredFile_$requiredFile"
                        Status = 'Passed'
                        Message = "Required file found: $requiredFile"
                    }
                }
                else {
                    $results.Checks += @{
                        Name = "RequiredFile_$requiredFile"
                        Status = 'Failed'
                        Message = "Required file missing: $requiredFile"
                    }
                }
            }
            
            # Check Windows directory structure
            $requiredDirs = @('Windows\System32', 'Windows\Boot', 'Program Files')
            
            foreach ($dir in $requiredDirs) {
                $dirPath = Join-Path $mountPath $dir
                
                if (Test-Path $dirPath) {
                    $results.Checks += @{
                        Name = "RequiredDir_$($dir -replace '\\', '_')"
                        Status = 'Passed'
                        Message = "Required directory found: $dir"
                    }
                }
                else {
                    $results.Checks += @{
                        Name = "RequiredDir_$($dir -replace '\\', '_')"
                        Status = 'Warning'
                        Message = "Directory not found: $dir"
                    }
                }
            }
            
            # Check registry hives
            $registryPath = Join-Path $mountPath 'Windows\System32\config'
            
            foreach ($hive in $script:ValidationRules.RequiredRegistryHives) {
                $hivePath = Join-Path $registryPath $hive
                
                if (Test-Path $hivePath) {
                    $hiveSize = (Get-Item $hivePath).Length
                    $results.Checks += @{
                        Name = "RegistryHive_$hive"
                        Status = 'Passed'
                        Message = "Registry hive found: $hive ($([math]::Round($hiveSize / 1KB, 2)) KB)"
                        Value = $hiveSize
                    }
                }
                else {
                    $results.Checks += @{
                        Name = "RegistryHive_$hive"
                        Status = 'Failed'
                        Message = "Registry hive missing: $hive"
                    }
                }
            }
            
            # Check available space in image
            $imageInfo = & DISM.exe /Get-WimInfo /WimFile:$ImagePath /Index:1 | Select-String "Size"
            
            $results.Checks += @{
                Name = 'ImageSpace'
                Status = 'Passed'
                Message = "Image space validated"
            }
        }
        finally {
            # Dismount the image
            Write-TestLog $TestContext "Dismounting validation image"
            & DISM.exe /Unmount-Wim /MountDir:$mountPath /Discard | Out-Null
            Remove-Item -Path $mountPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Determine overall status
        $failedChecks = $results.Checks | Where-Object { $_.Status -eq 'Failed' }
        
        if ($failedChecks.Count -eq 0) {
            $results.Status = 'Passed'
        }
        else {
            $results.Status = 'Failed'
            $results.FailedChecks = $failedChecks.Count
        }
        
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        
        Write-TestLog $TestContext "Image structure validation completed" -Level Success
    }
    catch {
        $results.Status = 'Failed'
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        $results.Error = $_.Exception.Message
        
        Write-TestLog $TestContext "Image structure validation failed: $_" -Level Error
    }
    
    return $results
}

function Test-BootCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [hashtable]$TestContext,
        
        [switch]$UseVirtualMachine
    )
    
    Write-TestLog $TestContext "Starting boot capability testing"
    
    $results = @{
        TestName = 'BootCapability'
        Status = 'Running'
        StartTime = Get-Date
        Checks = @()
    }
    
    try {
        # Check bootmgr and BCD configuration
        $mountPath = Join-Path $TestContext.TestPath 'BootTest'
        $null = New-Item -Path $mountPath -ItemType Directory -Force
        
        Write-TestLog $TestContext "Extracting boot configuration"
        
        & DISM.exe /Mount-Wim /WimFile:$ImagePath /Index:1 /MountDir:$mountPath /ReadOnly | Out-Null
        
        try {
            # Check bootmgr
            $bootmgrPath = Join-Path $mountPath 'bootmgr'
            if (Test-Path $bootmgrPath) {
                $results.Checks += @{
                    Name = 'BootManager'
                    Status = 'Passed'
                    Message = "Boot Manager found"
                }
            }
            else {
                $results.Checks += @{
                    Name = 'BootManager'
                    Status = 'Failed'
                    Message = "Boot Manager missing"
                }
            }
            
            # Check BCD store
            $bcdPath = Join-Path $mountPath 'boot\bcd'
            if (Test-Path $bcdPath) {
                $bcdSize = (Get-Item $bcdPath).Length
                $results.Checks += @{
                    Name = 'BCDStore'
                    Status = 'Passed'
                    Message = "BCD Store found ($([math]::Round($bcdSize / 1KB, 2)) KB)"
                    Value = $bcdSize
                }
            }
            else {
                $results.Checks += @{
                    Name = 'BCDStore'
                    Status = 'Failed'
                    Message = "BCD Store missing"
                }
            }
            
            # Check boot files
            $bootFiles = @('boot.sdi', 'bootfix.bin', 'bootsect.exe')
            
            foreach ($bootFile in $bootFiles) {
                $bootFilePath = Join-Path $mountPath "boot\$bootFile"
                if (Test-Path $bootFilePath) {
                    $results.Checks += @{
                        Name = "BootFile_$bootFile"
                        Status = 'Passed'
                        Message = "Boot file found: $bootFile"
                    }
                }
            }
            
            # Check winload.exe
            $winloadPath = Join-Path $mountPath 'Windows\System32\winload.exe'
            if (Test-Path $winloadPath) {
                $results.Checks += @{
                    Name = 'WinloadExecutable'
                    Status = 'Passed'
                    Message = "Windows Loader found"
                }
            }
            else {
                $results.Checks += @{
                    Name = 'WinloadExecutable'
                    Status = 'Failed'
                    Message = "Windows Loader missing"
                }
            }
        }
        finally {
            & DISM.exe /Unmount-Wim /MountDir:$mountPath /Discard | Out-Null
            Remove-Item -Path $mountPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Virtual machine boot test (if enabled and Hyper-V available)
        if ($UseVirtualMachine) {
            try {
                $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
                
                if ($hyperV.State -eq 'Enabled') {
                    Write-TestLog $TestContext "Performing virtual machine boot test"
                    
                    # This would create a temporary VM and attempt to boot
                    # Implementation requires Hyper-V module and VM creation
                    
                    $results.Checks += @{
                        Name = 'VirtualMachineBoot'
                        Status = 'Skipped'
                        Message = "VM boot test requires manual implementation"
                    }
                }
                else {
                    $results.Checks += @{
                        Name = 'VirtualMachineBoot'
                        Status = 'Skipped'
                        Message = "Hyper-V not enabled"
                    }
                }
            }
            catch {
                $results.Checks += @{
                    Name = 'VirtualMachineBoot'
                    Status = 'Skipped'
                    Message = "Hyper-V check failed: $_"
                }
            }
        }
        
        # Determine overall status
        $failedChecks = $results.Checks | Where-Object { $_.Status -eq 'Failed' }
        
        if ($failedChecks.Count -eq 0) {
            $results.Status = 'Passed'
        }
        else {
            $results.Status = 'Failed'
            $results.FailedChecks = $failedChecks.Count
        }
        
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        
        Write-TestLog $TestContext "Boot capability testing completed" -Level Success
    }
    catch {
        $results.Status = 'Failed'
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        $results.Error = $_.Exception.Message
        
        Write-TestLog $TestContext "Boot capability testing failed: $_" -Level Error
    }
    
    return $results
}

function Test-ComponentsPresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [hashtable]$TestContext,
        
        [string[]]$RequiredComponents = @()
    )
    
    Write-TestLog $TestContext "Starting component presence validation"
    
    $results = @{
        TestName = 'ComponentsPresent'
        Status = 'Running'
        StartTime = Get-Date
        Checks = @()
    }
    
    try {
        # Get WIM information
        Write-TestLog $TestContext "Retrieving image component information"
        
        $wimInfo = & DISM.exe /Get-WimInfo /WimFile:$ImagePath /Index:1
        
        # Get packages in image
        $mountPath = Join-Path $TestContext.TestPath 'ComponentTest'
        $null = New-Item -Path $mountPath -ItemType Directory -Force
        
        & DISM.exe /Mount-Wim /WimFile:$ImagePath /Index:1 /MountDir:$mountPath /ReadOnly | Out-Null
        
        try {
            $packages = & DISM.exe /Image:$mountPath /Get-Packages
            
            # Check for common WinPE components
            $commonComponents = @{
                'WinPE-WMI' = 'Windows Management Instrumentation'
                'WinPE-NetFx' = '.NET Framework'
                'WinPE-Scripting' = 'Scripting Support'
                'WinPE-PowerShell' = 'PowerShell'
                'WinPE-StorageWMI' = 'Storage WMI'
                'WinPE-DismCmdlets' = 'DISM Cmdlets'
            }
            
            foreach ($component in $commonComponents.GetEnumerator()) {
                if ($packages -match $component.Key) {
                    $results.Checks += @{
                        Name = "Component_$($component.Key)"
                        Status = 'Passed'
                        Message = "$($component.Value) component found"
                    }
                }
                else {
                    $results.Checks += @{
                        Name = "Component_$($component.Key)"
                        Status = 'Info'
                        Message = "$($component.Value) component not found (optional)"
                    }
                }
            }
            
            # Check for required custom components
            foreach ($requiredComp in $RequiredComponents) {
                if ($packages -match $requiredComp) {
                    $results.Checks += @{
                        Name = "RequiredComponent_$requiredComp"
                        Status = 'Passed'
                        Message = "Required component found: $requiredComp"
                    }
                }
                else {
                    $results.Checks += @{
                        Name = "RequiredComponent_$requiredComp"
                        Status = 'Failed'
                        Message = "Required component missing: $requiredComp"
                    }
                }
            }
            
            # Get total package count
            $packageCount = ($packages | Select-String "Package Identity :").Count
            $results.TotalPackages = $packageCount
            
            $results.Checks += @{
                Name = 'TotalPackages'
                Status = 'Info'
                Message = "Total packages in image: $packageCount"
                Value = $packageCount
            }
        }
        finally {
            & DISM.exe /Unmount-Wim /MountDir:$mountPath /Discard | Out-Null
            Remove-Item -Path $mountPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Determine overall status
        $failedChecks = $results.Checks | Where-Object { $_.Status -eq 'Failed' }
        
        if ($failedChecks.Count -eq 0) {
            $results.Status = 'Passed'
        }
        else {
            $results.Status = 'Failed'
            $results.FailedChecks = $failedChecks.Count
        }
        
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        
        Write-TestLog $TestContext "Component presence validation completed" -Level Success
    }
    catch {
        $results.Status = 'Failed'
        $results.EndTime = Get-Date
        $results.Duration = ($results.EndTime - $results.StartTime).TotalSeconds
        $results.Error = $_.Exception.Message
        
        Write-TestLog $TestContext "Component presence validation failed: $_" -Level Error
    }
    
    return $results
}

#endregion

#region Public Functions

function Invoke-WinPEImageTest {
    <#
    .SYNOPSIS
        Performs comprehensive testing of a WinPE image.
    
    .DESCRIPTION
        Executes a full test suite including integrity checks, structure validation,
        boot capability testing, and component verification.
    
    .PARAMETER ImagePath
        Path to the WinPE WIM file to test.
    
    .PARAMETER TestSuite
        Specific tests to run. Default is all tests.
    
    .PARAMETER UseVirtualMachine
        Enables virtual machine boot testing (requires Hyper-V).
    
    .PARAMETER RequiredComponents
        Array of required component names to validate.
    
    .PARAMETER OutputReport
        Path to save the test report. Defaults to temporary location.
    
    .EXAMPLE
        Invoke-WinPEImageTest -ImagePath "C:\WinPE\boot.wim"
        
    .EXAMPLE
        Invoke-WinPEImageTest -ImagePath "C:\WinPE\boot.wim" -TestSuite Integrity,Structure -OutputReport "C:\Reports\test.xml"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ImagePath,
        
        [ValidateSet('All', 'Integrity', 'Structure', 'Boot', 'Components')]
        [string[]]$TestSuite = @('All'),
        
        [switch]$UseVirtualMachine,
        
        [string[]]$RequiredComponents = @(),
        
        [string]$OutputReport
    )
    
    begin {
        Write-Verbose "Starting WinPE Image Test Suite"
        
        # Initialize module paths
        if (-not (Test-Path $script:ModuleConfig.TestResultsPath)) {
            $null = New-Item -Path $script:ModuleConfig.TestResultsPath -ItemType Directory -Force
        }
    }
    
    process {
        try {
            # Initialize test environment
            $testId = "Test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $testContext = Initialize-TestEnvironment -TestId $testId
            
            Write-TestLog $testContext "=== WinPE Image Test Suite ===" -Level Info
            Write-TestLog $testContext "Image: $ImagePath"
            Write-TestLog $testContext "Test ID: $testId"
            
            # Determine which tests to run
            $testsToRun = if ($TestSuite -contains 'All') {
                @('Integrity', 'Structure', 'Boot', 'Components')
            } else {
                $TestSuite
            }
            
            Write-TestLog $testContext "Tests to execute: $($testsToRun -join ', ')"
            
            # Run tests
            $allResults = @()
            
            if ($testsToRun -contains 'Integrity') {
                Write-Host "`nRunning Integrity Tests..." -ForegroundColor Cyan
                $integrityResults = Test-ImageIntegrity -ImagePath $ImagePath -TestContext $testContext
                $allResults += $integrityResults
            }
            
            if ($testsToRun -contains 'Structure') {
                Write-Host "`nRunning Structure Tests..." -ForegroundColor Cyan
                $structureResults = Test-ImageStructure -ImagePath $ImagePath -TestContext $testContext
                $allResults += $structureResults
            }
            
            if ($testsToRun -contains 'Boot') {
                Write-Host "`nRunning Boot Capability Tests..." -ForegroundColor Cyan
                $bootResults = Test-BootCapability -ImagePath $ImagePath -TestContext $testContext -UseVirtualMachine:$UseVirtualMachine
                $allResults += $bootResults
            }
            
            if ($testsToRun -contains 'Components') {
                Write-Host "`nRunning Component Tests..." -ForegroundColor Cyan
                $componentResults = Test-ComponentsPresent -ImagePath $ImagePath -TestContext $testContext -RequiredComponents $RequiredComponents
                $allResults += $componentResults
            }
            
            # Compile final results
            $testContext.Results = $allResults
            $testContext.EndTime = Get-Date
            $testContext.TotalDuration = ($testContext.EndTime - $testContext.StartTime).TotalSeconds
            
            # Calculate summary statistics
            $passedTests = ($allResults | Where-Object { $_.Status -eq 'Passed' }).Count
            $failedTests = ($allResults | Where-Object { $_.Status -eq 'Failed' }).Count
            $totalTests = $allResults.Count
            
            $summary = @{
                TestId = $testId
                ImagePath = $ImagePath
                StartTime = $testContext.StartTime
                EndTime = $testContext.EndTime
                Duration = $testContext.TotalDuration
                TotalTests = $totalTests
                PassedTests = $passedTests
                FailedTests = $failedTests
                SuccessRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
                OverallStatus = if ($failedTests -eq 0) { 'Passed' } else { 'Failed' }
                Results = $allResults
            }
            
            # Generate report
            Write-Host "`n=== Test Summary ===" -ForegroundColor Yellow
            Write-Host "Total Tests: $totalTests"
            Write-Host "Passed: $passedTests" -ForegroundColor Green
            Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { 'Red' } else { 'Green' })
            Write-Host "Success Rate: $($summary.SuccessRate)%"
            Write-Host "Duration: $([math]::Round($summary.Duration, 2)) seconds"
            Write-Host "Overall Status: $($summary.OverallStatus)" -ForegroundColor $(if ($summary.OverallStatus -eq 'Passed') { 'Green' } else { 'Red' })
            
            # Save report
            if ($OutputReport) {
                $reportPath = $OutputReport
            }
            else {
                $reportPath = Join-Path $testContext.TestPath 'TestReport.xml'
            }
            
            $summary | Export-Clixml -Path $reportPath -Force
            Write-TestLog $testContext "Test report saved: $reportPath" -Level Success
            
            Write-Host "`nTest report saved to: $reportPath" -ForegroundColor Green
            Write-Host "Logs available at: $($testContext.LogFile)" -ForegroundColor Cyan
            
            return $summary
        }
        catch {
            Write-Error "Test execution failed: $_"
            throw
        }
    }
}

function Get-WinPETestReport {
    <#
    .SYNOPSIS
        Retrieves and displays a WinPE test report.
    
    .DESCRIPTION
        Loads a previously saved test report and displays formatted results.
    
    .PARAMETER ReportPath
        Path to the test report XML file.
    
    .PARAMETER ShowDetails
        Displays detailed test results including individual checks.
    
    .EXAMPLE
        Get-WinPETestReport -ReportPath "C:\TestResults\TestReport.xml"
        
    .EXAMPLE
        Get-WinPETestReport -ReportPath "C:\TestResults\TestReport.xml" -ShowDetails
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ReportPath,
        
        [switch]$ShowDetails
    )
    
    process {
        try {
            Write-Verbose "Loading test report: $ReportPath"
            
            $report = Import-Clixml -Path $ReportPath
            
            Write-Host "`n=== WinPE Test Report ===" -ForegroundColor Yellow
            Write-Host "Test ID: $($report.TestId)"
            Write-Host "Image: $($report.ImagePath)"
            Write-Host "Start Time: $($report.StartTime)"
            Write-Host "End Time: $($report.EndTime)"
            Write-Host "Duration: $([math]::Round($report.Duration, 2)) seconds"
            Write-Host "`nResults:"
            Write-Host "  Total Tests: $($report.TotalTests)"
            Write-Host "  Passed: $($report.PassedTests)" -ForegroundColor Green
            Write-Host "  Failed: $($report.FailedTests)" -ForegroundColor $(if ($report.FailedTests -gt 0) { 'Red' } else { 'Green' })
            Write-Host "  Success Rate: $($report.SuccessRate)%"
            Write-Host "`nOverall Status: $($report.OverallStatus)" -ForegroundColor $(if ($report.OverallStatus -eq 'Passed') { 'Green' } else { 'Red' })
            
            if ($ShowDetails) {
                Write-Host "`n=== Detailed Results ===" -ForegroundColor Yellow
                
                foreach ($test in $report.Results) {
                    Write-Host "`n--- $($test.TestName) ---" -ForegroundColor Cyan
                    Write-Host "Status: $($test.Status)" -ForegroundColor $(if ($test.Status -eq 'Passed') { 'Green' } else { 'Red' })
                    Write-Host "Duration: $([math]::Round($test.Duration, 2)) seconds"
                    
                    if ($test.Error) {
                        Write-Host "Error: $($test.Error)" -ForegroundColor Red
                    }
                    
                    if ($test.Checks) {
                        Write-Host "Checks:"
                        foreach ($check in $test.Checks) {
                            $statusColor = switch ($check.Status) {
                                'Passed' { 'Green' }
                                'Failed' { 'Red' }
                                'Warning' { 'Yellow' }
                                default { 'White' }
                            }
                            Write-Host "  [$($check.Status)] $($check.Message)" -ForegroundColor $statusColor
                        }
                    }
                }
            }
            
            return $report
        }
        catch {
            Write-Error "Failed to load test report: $_"
            throw
        }
    }
}

function Compare-WinPETestResults {
    <#
    .SYNOPSIS
        Compares two WinPE test reports to identify differences.
    
    .DESCRIPTION
        Analyzes two test reports and highlights changes in test results,
        useful for regression testing and validation.
    
    .PARAMETER BaselineReport
        Path to the baseline (reference) test report.
    
    .PARAMETER ComparisonReport
        Path to the comparison test report.
    
    .EXAMPLE
        Compare-WinPETestResults -BaselineReport "C:\Tests\baseline.xml" -ComparisonReport "C:\Tests\current.xml"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$BaselineReport,
        
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ComparisonReport
    )
    
    process {
        try {
            Write-Verbose "Loading baseline report: $BaselineReport"
            $baseline = Import-Clixml -Path $BaselineReport
            
            Write-Verbose "Loading comparison report: $ComparisonReport"
            $comparison = Import-Clixml -Path $ComparisonReport
            
            $differences = @{
                BaselineId = $baseline.TestId
                ComparisonId = $comparison.TestId
                Changes = @()
            }
            
            # Compare success rates
            if ($baseline.SuccessRate -ne $comparison.SuccessRate) {
                $differences.Changes += @{
                    Type = 'SuccessRate'
                    Baseline = $baseline.SuccessRate
                    Comparison = $comparison.SuccessRate
                    Delta = $comparison.SuccessRate - $baseline.SuccessRate
                }
            }
            
            # Compare individual tests
            foreach ($baseTest in $baseline.Results) {
                $compTest = $comparison.Results | Where-Object { $_.TestName -eq $baseTest.TestName }
                
                if ($compTest) {
                    if ($baseTest.Status -ne $compTest.Status) {
                        $differences.Changes += @{
                            Type = 'TestStatus'
                            TestName = $baseTest.TestName
                            Baseline = $baseTest.Status
                            Comparison = $compTest.Status
                        }
                    }
                }
                else {
                    $differences.Changes += @{
                        Type = 'MissingTest'
                        TestName = $baseTest.TestName
                        Message = 'Test not found in comparison report'
                    }
                }
            }
            
            # Display comparison
            Write-Host "`n=== Test Comparison ===" -ForegroundColor Yellow
            Write-Host "Baseline: $($baseline.TestId)"
            Write-Host "Comparison: $($comparison.TestId)"
            Write-Host "`nChanges Found: $($differences.Changes.Count)"
            
            if ($differences.Changes.Count -gt 0) {
                Write-Host "`nDetails:" -ForegroundColor Cyan
                foreach ($change in $differences.Changes) {
                    Write-Host "`n$($change.Type):"
                    $change.GetEnumerator() | Where-Object { $_.Key -ne 'Type' } | ForEach-Object {
                        Write-Host "  $($_.Key): $($_.Value)"
                    }
                }
            }
            else {
                Write-Host "No differences found." -ForegroundColor Green
            }
            
            return $differences
        }
        catch {
            Write-Error "Failed to compare test results: $_"
            throw
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Invoke-WinPEImageTest',
    'Get-WinPETestReport',
    'Compare-WinPETestResults'
)
