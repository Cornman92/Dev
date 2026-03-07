BeforeAll {
    # Import the module and create test directories
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FileSystem.psm1' -Resolve
    Import-Module $modulePath -Force
    
    # Create test directories
    $testRoot = Join-Path -Path $TestDrive -ChildPath 'BackupTest'
    $sourceDir = Join-Path -Path $testRoot -ChildPath 'Source'
    $destDir = Join-Path -Path $testRoot -ChildPath 'Backup'
    
    # Create test files
    $null = New-Item -Path $sourceDir -ItemType Directory -Force
    $null = New-Item -Path $destDir -ItemType Directory -Force
    
    # Create some test files
    1..3 | ForEach-Object {
        $filePath = Join-Path -Path $sourceDir -ChildPath "File$_.txt"
        "Test content for file $_" | Out-File -FilePath $filePath -Force
    }
    
    # Test task name
    $testTaskName = "FS_Test_Backup_$([guid]::NewGuid().ToString().Substring(0,8))"
}

afterAll {
    # Clean up test task if it exists
    $task = Get-ScheduledTask -TaskName $testTaskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $testTaskName -Confirm:$false -ErrorAction SilentlyContinue
    }
    
    # Remove test directories
    if (Test-Path $testRoot) {
        Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

describe 'Register-FileSystemBackupSchedule Tests' {
    it 'Creates a scheduled backup task' {
        # Arrange
        $params = @{
            TaskName = $testTaskName
            SourcePath = $sourceDir
            DestinationPath = $destDir
            Interval = '1h'
            CompressionLevel = 'None'
            WhatIf = $true
        }
        
        # Act
        $result = Register-FileSystemBackupSchedule @params
        
        # Assert
        $result | Should -Not -Be $null
        $result.TaskName | Should -Be $testTaskName
        $result.SourcePath | Should -Be $sourceDir
        $result.DestinationPath | Should -Be $destDir
    }
    
    it 'Validates source path exists' {
        # Arrange
        $invalidPath = Join-Path -Path $testRoot -ChildPath 'NonexistentSource'
        
        # Act/Assert
        { Register-FileSystemBackupSchedule -TaskName $testTaskName -SourcePath $invalidPath -DestinationPath $destDir -Interval '1h' -ErrorAction Stop } | 
            Should -Throw -ExpectedMessage "does not exist or is not a directory"
    }
    
    it 'Validates interval format' {
        # Arrange
        $invalidInterval = 'invalid'
        
        # Act/Assert
        { Register-FileSystemBackupSchedule -TaskName $testTaskName -SourcePath $sourceDir -DestinationPath $destDir -Interval $invalidInterval -ErrorAction Stop } | 
            Should -Throw -ExpectedMessage "Interval must match pattern"
    }
    
    it 'Can overwrite existing task with Force' {
        # Arrange - Create initial task
        $params = @{
            TaskName = $testTaskName
            SourcePath = $sourceDir
            DestinationPath = $destDir
            Interval = '1h'
            WhatIf = $true
        }
        $null = Register-FileSystemBackupSchedule @params
        
        # Act/Assert - Should throw without Force
        { Register-FileSystemBackupSchedule @params -ErrorAction Stop } | 
            Should -Throw -ExpectedMessage "already exists"
            
        # Act/Assert - Should not throw with Force
        { Register-FileSystemBackupSchedule @params -Force } | Should -Not -Throw
    }
}

describe 'Get-FileSystemBackupSchedule Tests' {
    it 'Retrieves information about scheduled backup tasks' {
        # Arrange - Create a test task
        $null = Register-FileSystemBackupSchedule -TaskName $testTaskName `
            -SourcePath $sourceDir `
            -DestinationPath $destDir `
            -Interval '1h' `
            -WhatIf
        
        # Act
        $result = Get-FileSystemBackupSchedule -TaskName $testTaskName
        
        # Assert
        $result | Should -Not -Be $null
        $result.TaskName | Should -Be $testTaskName
        $result.State | Should -Not -Be $null
    }
    
    it 'Returns all backup tasks when no TaskName is specified' {
        # Act
        $result = Get-FileSystemBackupSchedule
        
        # Assert
        $result | Should -Not -Be $null
        $result.Count | Should -BeGreaterOrEqual 1
        ($result | Where-Object { $_.TaskName -eq $testTaskName }) | Should -Not -Be $null
    }
    
    it 'Returns empty when no matching tasks found' {
        # Act
        $result = Get-FileSystemBackupSchedule -TaskName 'NonexistentTaskName_12345'
        
        # Assert
        $result | Should -Be $null
    }
}

describe 'Backup Task Execution Tests' -Tag 'Integration' {
    it 'Successfully executes a backup when triggered' -Skip:($env:CI -ne $null) {
        # Arrange - Create a task with RunNow
        $params = @{
            TaskName = $testTaskName
            SourcePath = $sourceDir
            DestinationPath = $destDir
            Interval = '1d'
            RunNow = $true
            Force = $true
        }
        
        # Act
        $result = Register-FileSystemBackupSchedule @params
        
        # Give the task some time to complete
        Start-Sleep -Seconds 10
        
        # Assert - Check if backup was created
        $backupDirs = Get-ChildItem -Path $destDir -Directory -Filter 'Backup_*'
        $backupDirs.Count | Should -BeGreaterOrEqual 1
        
        # Verify files were copied
        $sourceFiles = Get-ChildItem -Path $sourceDir -File -Recurse
        $backupFiles = Get-ChildItem -Path $backupDirs[0].FullName -File -Recurse
        
        $backupFiles.Count | Should -Be $sourceFiles.Count
        
        # Clean up
        $null = Unregister-ScheduledTask -TaskName $testTaskName -Confirm:$false -ErrorAction SilentlyContinue
    }
}
