# Backup.Tests.ps1
# Pester tests for Backup functions in the FileSystem module

# Get the module path
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = Split-Path -Leaf $modulePath

# Import the module
$moduleManifest = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

# Test files and directories
$testDrive = Join-Path -Path $TestDrive -ChildPath 'BackupTests'
$sourceDir = Join-Path -Path $testDrive -ChildPath 'Source'
$backupDir = Join-Path -Path $testDrive -ChildPath 'Backup'
$testFile1 = Join-Path -Path $sourceDir -ChildPath 'test1.txt'
$testFile2 = Join-Path -Path $sourceDir -ChildPath 'test2.txt'

# Mock data for testing
$testContent1 = 'This is a test file 1'
$testContent2 = 'This is a test file 2'

describe 'Backup Functionality Tests' {
    # Setup test environment
    BeforeAll {
        # Import the module
        Import-Module $moduleManifest -Force -ErrorAction Stop
        
        # Create test directory structure
        $null = New-Item -ItemType Directory -Path $sourceDir -Force
        $null = New-Item -ItemType Directory -Path $backupDir -Force
        
        # Create test files
        $null = New-Item -ItemType File -Path $testFile1 -Value $testContent1 -Force
        $null = New-Item -ItemType File -Path $testFile2 -Value $testContent2 -Force
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
    
    # Test Register-FileSystemBackupSchedule function
    context 'Register-FileSystemBackupSchedule Tests' {
        it 'should register a new backup schedule' {
            $scheduleName = 'TestBackupSchedule'
            
            # Mock the scheduled task functions
            Mock Register-ScheduledTask -MockWith { 
                return [PSCustomObject]@{ 
                    TaskName = $scheduleName 
                    TaskPath = '\FileSystem\Backup\'
                }
            }
            
            # Test the function
            $result = Register-FileSystemBackupSchedule -Name $scheduleName -Source $sourceDir -Destination $backupDir -ScheduleType Daily -At '12:00'
            
            # Assertions
            $result | Should -Not -Be $null
            $result.TaskName | Should -Be $scheduleName
            Assert-MockCalled Register-ScheduledTask -Exactly 1
        }
        
        it 'should throw an error for invalid schedule type' {
            { 
                Register-FileSystemBackupSchedule -Name 'InvalidSchedule' -Source $sourceDir -Destination $backupDir -ScheduleType 'Invalid' -At '12:00' 
            } | Should -Throw
        }
    }
    
    # Test Get-FileSystemBackupSchedule function
    context 'Get-FileSystemBackupSchedule Tests' {
        it 'should retrieve backup schedules' {
            # Mock the scheduled task functions
            Mock Get-ScheduledTask -MockWith {
                return @(
                    [PSCustomObject]@{
                        TaskName = 'TestBackup1'
                        TaskPath = '\FileSystem\Backup\'
                    },
                    [PSCustomObject]@{
                        TaskName = 'TestBackup2'
                        TaskPath = '\FileSystem\Backup\'
                    }
                )
            }
            
            # Test the function
            $result = Get-FileSystemBackupSchedule
            
            # Assertions
            $result | Should -Not -Be $null
            $result.Count | Should -Be 2
            Assert-MockCalled Get-ScheduledTask -Exactly 1
        }
        
        it 'should filter schedules by name' {
            # Mock the scheduled task functions
            Mock Get-ScheduledTask -MockWith {
                return [PSCustomObject]@{
                    TaskName = 'TestBackup1'
                    TaskPath = '\FileSystem\Backup\'
                }
            }
            
            # Test the function
            $result = Get-FileSystemBackupSchedule -Name 'TestBackup1'
            
            # Assertions
            $result | Should -Not -Be $null
            $result.TaskName | Should -Be 'TestBackup1'
            Assert-MockCalled Get-ScheduledTask -Exactly 1
        }
    }
    
    # Test Unregister-FileSystemBackupSchedule function
    context 'Unregister-FileSystemBackupSchedule Tests' {
        it 'should unregister a backup schedule' {
            $scheduleName = 'TestBackupToRemove'
            
            # Mock the scheduled task functions
            Mock Unregister-ScheduledTask -MockWith { return $true }
            
            # Test the function
            $result = Unregister-FileSystemBackupSchedule -Name $scheduleName -Force
            
            # Assertions
            $result | Should -Be $true
            Assert-MockCalled Unregister-ScheduledTask -Exactly 1
        }
    }
    
    # Test backup file operations
    context 'Backup File Operations' {
        it 'should create a backup of files' {
            $backupName = 'TestBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')'
            $backupPath = Join-Path -Path $backupDir -ChildPath $backupName
            
            # Create backup
            $result = Backup-Folder -Source $sourceDir -Destination $backupPath
            
            # Assertions
            $result | Should -Not -Be $null
            $result.Success | Should -Be $true
            Test-Path -Path $backupPath | Should -Be $true
            
            # Verify files were backed up
            $backedUpFile1 = Join-Path -Path $backupPath -ChildPath (Split-Path -Leaf $testFile1)
            $backedUpFile2 = Join-Path -Path $backupPath -ChildPath (Split-Path -Leaf $testFile2)
            
            Test-Path -Path $backedUpFile1 | Should -Be $true
            Test-Path -Path $backedUpFile2 | Should -Be $true
            
            # Verify file contents
            (Get-Content -Path $backedUpFile1 -Raw).Trim() | Should -Be $testContent1
            (Get-Content -Path $backedUpFile2 -Raw).Trim() | Should -Be $testContent2
        }
    }
}
