#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }
#Requires -Modules @{ ModuleName='FileSystem'; ModuleVersion='2.1.0' }
#Requires -Modules @{ ModuleName='Core'; ModuleVersion='1.0.0' }

<#
.SYNOPSIS
    Pester tests for the FileSystem module.
.DESCRIPTION
    This file contains Pester tests for the FileSystem module, including tests for
    the Backup-Folder and Find-DuplicateFiles functions.
#>

# Stop on first error
$ErrorActionPreference = 'Stop'

# Test setup
$testRoot = Join-Path -Path $TestDrive -ChildPath 'FileSystemTests'
$sourceDir = Join-Path -Path $testRoot -ChildPath 'Source'
$backupDir = Join-Path -Path $testRoot -ChildPath 'Backup'
$testFiles = @(
    'file1.txt',
    'subdir1/file2.txt',
    'subdir2/file3.txt',
    'file4.log'
)

# Helper function to create test files
function Initialize-TestEnvironment {
    [CmdletBinding()]
    param()
    
    # Create test directories
    $null = New-Item -Path $sourceDir -ItemType Directory -Force
    $null = New-Item -Path $backupDir -ItemType Directory -Force
    
    # Create test files with unique content
    foreach ($file in $testFiles) {
        $filePath = Join-Path -Path $sourceDir -ChildPath $file
        $dirPath = Split-Path -Path $filePath -Parent
        
        if (-not (Test-Path -Path $dirPath -PathType Container)) {
            $null = New-Item -Path $dirPath -ItemType Directory -Force
        }
        
        $content = "Test content for $([System.IO.Path]::GetFileName($file)) - $(Get-Random -Minimum 1000 -Maximum 9999)"
        $content | Out-File -FilePath $filePath -Force -Encoding utf8
    }
}

# Helper function to clean up test environment
function Cleanup-TestEnvironment {
    [CmdletBinding()]
    param()
    
    if (Test-Path -Path $testRoot) {
        Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FileSystem Module Tests' -Tag 'FileSystem' {
    BeforeAll {
        # Import required modules
        Import-Module -Name Core -Force -ErrorAction Stop
        Import-Module -Name FileSystem -Force -ErrorAction Stop
        
        # Initialize test environment
        Initialize-TestEnvironment
    }
    
    AfterAll {
        # Clean up test environment
        Cleanup-TestEnvironment
        
        # Remove modules
        Remove-Module -Name FileSystem -Force -ErrorAction SilentlyContinue
        Remove-Module -Name Core -Force -ErrorAction SilentlyContinue
    }
    
    Context 'Module Validation' {
        It 'Should import the FileSystem module successfully' {
            $module = Get-Module -Name FileSystem
            $module | Should -Not -Be $null
            $module.Version | Should -Be '2.1.0'
        }
        
        It 'Should have the expected commands' {
            $commands = Get-Command -Module FileSystem
            $commands.Name | Should -Contain 'Backup-Folder'
            $commands.Name | Should -Contain 'Find-DuplicateFiles'
        }
    }
    
    Context 'Backup-Folder Tests' {
        BeforeEach {
            # Ensure backup directory is empty
            if (Test-Path -Path $backupDir) {
                Remove-Item -Path "$backupDir\*" -Recurse -Force
            }
        }
        
        It 'Should create a backup of the source directory' {
            # Act
            $backupResult = Backup-Folder -SourcePath $sourceDir -DestinationPath $backupDir -CompressionLevel Fastest -Force
            
            # Assert
            $backupResult | Should -Not -Be $null
            $backupResult.FullName | Should -Exist
            
            # Verify backup contents
            $backupFiles = Get-ChildItem -Path $backupDir -File -Recurse
            $backupFiles.Count | Should -BeGreaterThan 0
            
            # Verify manifest file exists
            $manifest = Get-ChildItem -Path $backupDir -Filter 'backup_manifest_*.json' -File
            $manifest | Should -Not -Be $null
            
            # Verify manifest content
            $manifestContent = Get-Content -Path $manifest.FullName -Raw | ConvertFrom-Json
            $manifestContent.SourcePath | Should -Be $sourceDir
            $manifestContent.FileCount | Should -Be $testFiles.Count
            $manifestContent.Status | Should -Be 'Completed'
        }
        
        It 'Should handle non-existent source directory' {
            $invalidPath = Join-Path -Path $testRoot -ChildPath 'NonExistentDir'
            { Backup-Folder -SourcePath $invalidPath -DestinationPath $backupDir -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage "Source path '*' does not exist or is not a directory."
        }
        
        It 'Should validate compression level' {
            { Backup-Folder -SourcePath $sourceDir -DestinationPath $backupDir -CompressionLevel 'InvalidLevel' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'CompressionLevel'"
        }
    }
    
    Context 'Find-DuplicateFiles Tests' {
        BeforeAll {
            # Create some duplicate files for testing
            $dupeContent = "This is a test file with duplicate content - $(Get-Random -Minimum 1000 -Maximum 9999)"
            
            # Create two files with identical content
            $dupe1 = Join-Path -Path $sourceDir -ChildPath 'dupe1.txt'
            $dupe2 = Join-Path -Path $sourceDir -ChildPath 'dupe2.txt'
            $dupeContent | Out-File -Path $dupe1 -Force -Encoding utf8
            $dupeContent | Out-File -Path $dupe2 -Force -Encoding utf8
            
            # Create a large file for testing size filter
            $largeFile = Join-Path -Path $sourceDir -ChildPath 'largefile.bin'
            1..1MB | ForEach-Object { [byte](Get-Random -Minimum 0 -Maximum 255) } | 
                Set-Content -Path $largeFile -Encoding Byte -Force
        }
        
        It 'Should find duplicate files' {
            # Act
            $duplicates = Find-DuplicateFiles -Path $sourceDir -Recurse
            
            # Assert
            $duplicates | Should -Not -Be $null
            $duplicates.Count | Should -BeGreaterThan 0
            
            # Verify we found our test duplicates
            $foundDuplicates = $duplicates | Where-Object { 
                $_.Group | Where-Object { $_.Name -in @('dupe1.txt', 'dupe2.txt') }
            }
            $foundDuplicates | Should -Not -Be $null
            $foundDuplicates.Group.Count | Should -Be 2
        }
        
        It 'Should respect file size filter' {
            # Act - Find files larger than 500KB
            $largeFiles = Find-DuplicateFiles -Path $sourceDir -MinSize 500KB
            
            # Assert
            $largeFiles | Should -Not -Be $null
            $largeFiles.Group | Where-Object { $_.Name -eq 'largefile.bin' } | Should -Not -Be $null
            
            # Verify small files are excluded
            $smallFiles = $largeFiles.Group | Where-Object { $_.Length -lt 500KB }
            $smallFiles | Should -Be $null
        }
        
        It 'Should respect file extension filter' {
            # Act - Only look for .log files
            $logFiles = Find-DuplicateFiles -Path $sourceDir -Extensions @('.log')
            
            # Assert
            $logFiles | Should -Not -Be $null
            $logFiles.Group | Where-Object { $_.Extension -eq '.log' } | Should -Not -Be $null
            
            # Verify non-log files are excluded
            $nonLogFiles = $logFiles.Group | Where-Object { $_.Extension -ne '.log' }
            $nonLogFiles | Should -Be $null
        }
        
        It 'Should handle non-existent path' {
            $invalidPath = Join-Path -Path $testRoot -ChildPath 'NonExistentDir'
            { Find-DuplicateFiles -Path $invalidPath -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage "Path '*' does not exist or is not a directory."
        }
        
        It 'Should validate hash algorithm' {
            { Find-DuplicateFiles -Path $sourceDir -HashAlgorithm 'InvalidAlgo' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'HashAlgorithm'"
        }
    }
    
    Context 'Error Handling' {
        It 'Should handle access denied gracefully' {
            # Try to access a protected system directory without admin rights
            $protectedDir = 'C:\Windows\System32\config'
            
            if (-not (Test-IsAdmin)) {
                $result = Find-DuplicateFiles -Path $protectedDir -ErrorAction SilentlyContinue -ErrorVariable err
                $result | Should -Be $null
                $err | Should -Not -Be $null
                $err.Exception.Message | Should -Match 'access is denied'
            }
            else {
                Set-ItResult -Skipped -Because 'Test requires non-admin privileges'
            }
        }
    }
    
    Context 'Performance' -Tag 'Performance' {
        It 'Should complete within a reasonable time for large directories' -Skip:(-not $env:CI) {
            # Create a large number of test files for performance testing
            $largeTestDir = Join-Path -Path $testRoot -ChildPath 'LargeTestDir'
            $null = New-Item -Path $largeTestDir -ItemType Directory -Force
            
            # Create 1000 small files
            1..1000 | ForEach-Object {
                $filePath = Join-Path -Path $largeTestDir -ChildPath "testfile$_.txt"
                "Test content for file $_" | Out-File -Path $filePath -Force
            }
            
            # Measure execution time
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Find-DuplicateFiles -Path $largeTestDir -ErrorAction Stop
            $sw.Stop()
            
            # Assert completion within 10 seconds (adjust based on system performance)
            $sw.Elapsed.TotalSeconds | Should -BeLessThan 10
            $result | Should -Not -Be $null
        }
    }
}

# FileSystem.Tests.ps1
# Pester tests for the FileSystem module

# Get the module path
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = Split-Path -Leaf $modulePath

# Import the module
$moduleManifest = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

# Test files and directories
$testDrive = Join-Path -Path $TestDrive -ChildPath 'FileSystemTests'
$testFile1 = Join-Path -Path $testDrive -ChildPath 'test1.txt'
$testFile2 = Join-Path -Path $testDrive -ChildPath 'test2.txt'
$testDir1 = Join-Path -Path $testDrive -ChildPath 'Dir1'
$testDir2 = Join-Path -Path $testDrive -ChildPath 'Dir2'

describe 'FileSystem Module Tests' {
    # Setup test environment
    BeforeAll {
        # Import the module
        Import-Module $moduleManifest -Force -ErrorAction Stop
        
        # Create test directory structure
        $null = New-Item -ItemType Directory -Path $testDrive -Force
        $null = New-Item -ItemType Directory -Path $testDir1 -Force
        $null = New-Item -ItemType File -Path $testFile1 -Value 'Test content 1' -Force
        $null = New-Item -ItemType File -Path $testFile2 -Value 'Test content 2' -Force
    }
    
    # Cleanup test environment
    AfterAll {
        # Remove test directories if they exist
        if (Test-Path -Path $testDrive) {
            Remove-Item -Path $testDrive -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Remove the module
        Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    }
    
    # Module tests
    context 'Module Tests' {
        it 'should import without errors' {
            { Import-Module $moduleManifest -Force -ErrorAction Stop } | Should -Not -Throw
        }
        
        it 'should have the expected module name' {
            (Get-Module -Name $moduleName).Name | Should -Be $moduleName
        }
        
        it 'should export expected functions' {
            $exportedFunctions = (Get-Module -Name $moduleName).ExportedFunctions.Keys
            $exportedFunctions | Should -Not -Be $null
            $exportedFunctions.Count | Should -BeGreaterThan 0
        }
    }
    
    # File operation tests
    context 'File Operation Tests' {
        it 'should copy a file' {
            $destFile = Join-Path -Path $testDrive -ChildPath 'copied.txt'
            Copy-Item -Path $testFile1 -Destination $destFile -Force
            Test-Path -Path $destFile | Should -Be $true
            (Get-Content -Path $destFile -Raw).Trim() | Should -Be 'Test content 1'
        }
        
        it 'should move a file' {
            $destFile = Join-Path -Path $testDrive -ChildPath 'moved.txt'
            Move-Item -Path $testFile2 -Destination $destFile -Force
            Test-Path -Path $destFile | Should -Be $true
            Test-Path -Path $testFile2 | Should -Be $false
        }
    }
    
    # Directory operation tests
    context 'Directory Operation Tests' {
        it 'should create a directory' {
            $newDir = Join-Path -Path $testDrive -ChildPath 'NewDir'
            New-Item -ItemType Directory -Path $newDir -Force
            Test-Path -Path $newDir | Should -Be $true
            (Get-Item -Path $newDir).PSIsContainer | Should -Be $true
        }
    }
    
    # Cleanup tests
    context 'Cleanup Tests' {
        it 'should remove test files' {
            $testFiles = Get-ChildItem -Path $testDrive -File -Recurse
            foreach ($file in $testFiles) {
                Remove-Item -Path $file.FullName -Force
                Test-Path -Path $file.FullName | Should -Be $false
            }
        }
        
        it 'should remove test directories' {
            $testDirs = Get-ChildItem -Path $testDrive -Directory -Recurse | 
                        Sort-Object -Property FullName -Descending
            foreach ($dir in $testDirs) {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
                Test-Path -Path $dir.FullName | Should -Be $false
            }
        }
    }
}

# Run the tests
Invoke-Pester -Script @{
    Path = $PSScriptRoot
    OutputFile = Join-Path -Path $PSScriptRoot -ChildPath 'TestResults.xml'
    OutputFormat = 'NUnitXML'
    PassThru = $true
}
