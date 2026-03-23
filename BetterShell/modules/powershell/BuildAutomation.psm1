#Requires -Version 5.1

<#
.SYNOPSIS
    Build & Deployment Automation Module for Better11 Suite
.DESCRIPTION
    Comprehensive CI/CD automation for Windows applications and services
.AUTHOR
    Better11 Development Team
.VERSION
    1.0.0
#>

#region Build Configuration

class BuildConfiguration {
    [string]$ProjectPath
    [string]$BuildType
    [string]$Platform
    [string]$Configuration
    [hashtable]$Environment
    [string[]]$PreBuildSteps
    [string[]]$PostBuildSteps
    
    BuildConfiguration() {
        $this.Environment = @{}
        $this.PreBuildSteps = @()
        $this.PostBuildSteps = @()
    }
}

function New-BuildConfiguration {
    <#
    .SYNOPSIS
        Creates a new build configuration
    .EXAMPLE
        $config = New-BuildConfiguration -ProjectPath C:\Projects\MyApp -BuildType DotNet
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        
        [ValidateSet('DotNet', 'Node', 'Rust', 'Tauri', 'MSBuild', 'Custom')]
        [string]$BuildType,
        
        [ValidateSet('x64', 'x86', 'ARM64', 'AnyCPU')]
        [string]$Platform = 'x64',
        
        [ValidateSet('Debug', 'Release')]
        [string]$Configuration = 'Release',
        
        [hashtable]$Environment = @{}
    )
    
    $config = [BuildConfiguration]::new()
    $config.ProjectPath = $ProjectPath
    $config.BuildType = $BuildType
    $config.Platform = $Platform
    $config.Configuration = $Configuration
    $config.Environment = $Environment
    
    return $config
}

#endregion

#region Build Execution

function Invoke-Build {
    <#
    .SYNOPSIS
        Executes a build based on configuration
    .EXAMPLE
        Invoke-Build -Configuration $config -Verbose
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [BuildConfiguration]$Configuration,
        
        [switch]$Clean,
        [switch]$Parallel,
        [int]$MaxParallel = 4,
        [string]$OutputPath
    )
    
    if (-not (Test-Path $Configuration.ProjectPath)) {
        throw "Project path not found: $($Configuration.ProjectPath)"
    }
    
    $buildResult = [PSCustomObject]@{
        StartTime = Get-Date
        EndTime = $null
        Success = $false
        BuildType = $Configuration.BuildType
        Configuration = $Configuration.Configuration
        Platform = $Configuration.Platform
        Output = @()
        Errors = @()
        Warnings = @()
    }
    
    try {
        Push-Location $Configuration.ProjectPath
        
        Write-Host "=== Building $($Configuration.BuildType) Project ===" -ForegroundColor Cyan
        Write-Host "Path: $($Configuration.ProjectPath)" -ForegroundColor Gray
        Write-Host "Configuration: $($Configuration.Configuration)" -ForegroundColor Gray
        Write-Host "Platform: $($Configuration.Platform)" -ForegroundColor Gray
        
        # Set environment variables
        foreach ($envVar in $Configuration.Environment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($envVar.Key, $envVar.Value, 'Process')
            Write-Verbose "Set environment: $($envVar.Key) = $($envVar.Value)"
        }
        
        # Run pre-build steps
        if ($Configuration.PreBuildSteps.Count -gt 0) {
            Write-Host "`n--- Running Pre-Build Steps ---" -ForegroundColor Yellow
            foreach ($step in $Configuration.PreBuildSteps) {
                Write-Host "Executing: $step" -ForegroundColor Gray
                Invoke-Expression $step
            }
        }
        
        # Clean if requested
        if ($Clean) {
            Write-Host "`n--- Cleaning Build ---" -ForegroundColor Yellow
            Invoke-BuildClean -Configuration $Configuration
        }
        
        # Execute build based on type
        Write-Host "`n--- Building ---" -ForegroundColor Yellow
        
        $buildSuccess = switch ($Configuration.BuildType) {
            'DotNet' { Invoke-DotNetBuild -Configuration $Configuration -OutputPath $OutputPath }
            'Node' { Invoke-NodeBuild -Configuration $Configuration -OutputPath $OutputPath }
            'Rust' { Invoke-RustBuild -Configuration $Configuration -OutputPath $OutputPath }
            'Tauri' { Invoke-TauriBuild -Configuration $Configuration -OutputPath $OutputPath }
            'MSBuild' { Invoke-MSBuildBuild -Configuration $Configuration -OutputPath $OutputPath }
            'Custom' { Invoke-CustomBuild -Configuration $Configuration -OutputPath $OutputPath }
        }
        
        $buildResult.Success = $buildSuccess
        
        # Run post-build steps
        if ($buildSuccess -and $Configuration.PostBuildSteps.Count -gt 0) {
            Write-Host "`n--- Running Post-Build Steps ---" -ForegroundColor Yellow
            foreach ($step in $Configuration.PostBuildSteps) {
                Write-Host "Executing: $step" -ForegroundColor Gray
                Invoke-Expression $step
            }
        }
        
        $buildResult.EndTime = Get-Date
        $duration = $buildResult.EndTime - $buildResult.StartTime
        
        if ($buildSuccess) {
            Write-Host "`n=== Build Succeeded ===" -ForegroundColor Green
            Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
        }
        else {
            Write-Host "`n=== Build Failed ===" -ForegroundColor Red
        }
    }
    catch {
        $buildResult.Errors += $_.Exception.Message
        Write-Error "Build failed: $_"
    }
    finally {
        Pop-Location
    }
    
    return $buildResult
}

function Invoke-BuildClean {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration
    )
    
    $commonCleanPaths = @('bin', 'obj', 'dist', 'build', 'target', 'out', '.next', 'node_modules/.cache')
    
    foreach ($path in $commonCleanPaths) {
        $fullPath = Join-Path $Configuration.ProjectPath $path
        if (Test-Path $fullPath) {
            Write-Host "Removing: $path" -ForegroundColor Gray
            Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-DotNetBuild {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration,
        [string]$OutputPath
    )
    
    $args = @('build')
    $args += '--configuration', $Configuration.Configuration
    
    if ($Configuration.Platform -ne 'AnyCPU') {
        $args += '--arch', $Configuration.Platform.ToLower()
    }
    
    if ($OutputPath) {
        $args += '--output', $OutputPath
    }
    
    Write-Host "Command: dotnet $($args -join ' ')" -ForegroundColor Gray
    
    & dotnet @args
    
    return $LASTEXITCODE -eq 0
}

function Invoke-NodeBuild {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration,
        [string]$OutputPath
    )
    
    # Check for package.json
    $packageJson = Join-Path $Configuration.ProjectPath 'package.json'
    if (-not (Test-Path $packageJson)) {
        throw "package.json not found"
    }
    
    # Install dependencies if node_modules doesn't exist
    if (-not (Test-Path (Join-Path $Configuration.ProjectPath 'node_modules'))) {
        Write-Host "Installing dependencies..." -ForegroundColor Yellow
        npm install
    }
    
    # Determine build command
    $package = Get-Content $packageJson | ConvertFrom-Json
    $buildScript = if ($package.scripts.build) { 'build' } else { $null }
    
    if ($buildScript) {
        npm run $buildScript
        return $LASTEXITCODE -eq 0
    }
    else {
        Write-Warning "No build script found in package.json"
        return $true
    }
}

function Invoke-RustBuild {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration,
        [string]$OutputPath
    )
    
    $args = @('build')
    
    if ($Configuration.Configuration -eq 'Release') {
        $args += '--release'
    }
    
    if ($OutputPath) {
        $args += '--target-dir', $OutputPath
    }
    
    Write-Host "Command: cargo $($args -join ' ')" -ForegroundColor Gray
    
    & cargo @args
    
    return $LASTEXITCODE -eq 0
}

function Invoke-TauriBuild {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration,
        [string]$OutputPath
    )
    
    # Tauri requires both npm and cargo
    Write-Host "Building Tauri application..." -ForegroundColor Yellow
    
    # Build frontend
    if (Test-Path (Join-Path $Configuration.ProjectPath 'package.json')) {
        npm install
        npm run build
    }
    
    # Build backend with Tauri
    $args = @('tauri', 'build')
    
    if ($Configuration.Configuration -eq 'Debug') {
        $args += '--debug'
    }
    
    & npm @args
    
    return $LASTEXITCODE -eq 0
}

function Invoke-MSBuildBuild {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration,
        [string]$OutputPath
    )
    
    # Find solution or project file
    $solutionFile = Get-ChildItem -Path $Configuration.ProjectPath -Filter "*.sln" | Select-Object -First 1
    
    if (-not $solutionFile) {
        $solutionFile = Get-ChildItem -Path $Configuration.ProjectPath -Filter "*.*proj" | Select-Object -First 1
    }
    
    if (-not $solutionFile) {
        throw "No solution or project file found"
    }
    
    $args = @(
        $solutionFile.FullName,
        "/p:Configuration=$($Configuration.Configuration)",
        "/p:Platform=$($Configuration.Platform)",
        "/m",  # Parallel build
        "/v:minimal"
    )
    
    if ($OutputPath) {
        $args += "/p:OutputPath=$OutputPath"
    }
    
    Write-Host "Command: msbuild $($args -join ' ')" -ForegroundColor Gray
    
    & msbuild @args
    
    return $LASTEXITCODE -eq 0
}

function Invoke-CustomBuild {
    [CmdletBinding()]
    param(
        [BuildConfiguration]$Configuration,
        [string]$OutputPath
    )
    
    Write-Warning "Custom build type requires pre-configured build steps"
    return $true
}

#endregion

#region Testing

function Invoke-Tests {
    <#
    .SYNOPSIS
        Runs tests for the project
    .EXAMPLE
        Invoke-Tests -ProjectPath C:\Projects\MyApp -TestType DotNet
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        
        [ValidateSet('DotNet', 'Node', 'Rust', 'Python')]
        [string]$TestType,
        
        [string]$Configuration = 'Release',
        [switch]$GenerateCoverage,
        [string]$CoverageOutput
    )
    
    Push-Location $ProjectPath
    
    try {
        Write-Host "=== Running Tests ===" -ForegroundColor Cyan
        
        $testResult = switch ($TestType) {
            'DotNet' {
                $args = @('test', '--configuration', $Configuration, '--no-build')
                
                if ($GenerateCoverage) {
                    $args += '--collect:"XPlat Code Coverage"'
                }
                
                & dotnet @args
                $LASTEXITCODE -eq 0
            }
            
            'Node' {
                npm test
                $LASTEXITCODE -eq 0
            }
            
            'Rust' {
                cargo test
                $LASTEXITCODE -eq 0
            }
            
            'Python' {
                pytest
                $LASTEXITCODE -eq 0
            }
        }
        
        if ($testResult) {
            Write-Host "✓ All tests passed" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Tests failed" -ForegroundColor Red
        }
        
        return $testResult
    }
    finally {
        Pop-Location
    }
}

#endregion

#region Packaging

function New-Installer {
    <#
    .SYNOPSIS
        Creates an installer package
    .EXAMPLE
        New-Installer -SourcePath .\bin\Release -OutputPath .\installer -Type NSIS
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet('NSIS', 'WiX', 'InnoSetup', 'ZIP', 'MSI')]
        [string]$Type,
        
        [string]$ProductName,
        [string]$Version = '1.0.0',
        [string]$Publisher,
        [hashtable]$Metadata = @{}
    )
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    Write-Host "=== Creating $Type Installer ===" -ForegroundColor Cyan
    
    switch ($Type) {
        'ZIP' {
            $zipPath = Join-Path $OutputPath "$ProductName-$Version.zip"
            Compress-Archive -Path "$SourcePath\*" -DestinationPath $zipPath -Force
            Write-Host "✓ Created: $zipPath" -ForegroundColor Green
            return $zipPath
        }
        
        'NSIS' {
            # NSIS installer creation
            Write-Host "NSIS installer creation requires NSIS to be installed" -ForegroundColor Yellow
            # Implementation would go here
        }
        
        'WiX' {
            # WiX installer creation
            Write-Host "WiX installer creation requires WiX Toolset" -ForegroundColor Yellow
            # Implementation would go here
        }
        
        'InnoSetup' {
            # Inno Setup installer creation
            Write-Host "InnoSetup requires Inno Setup to be installed" -ForegroundColor Yellow
            # Implementation would go here
        }
    }
}

#endregion

#region Deployment

function Publish-Application {
    <#
    .SYNOPSIS
        Publishes application to target environment
    .EXAMPLE
        Publish-Application -SourcePath .\build -Destination "\\server\deploy" -Method FileShare
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,
        
        [Parameter(Mandatory)]
        [string]$Destination,
        
        [ValidateSet('FileShare', 'FTP', 'Azure', 'S3', 'GitHub')]
        [string]$Method,
        
        [hashtable]$Credentials,
        [switch]$CreateBackup,
        [string]$BackupPath
    )
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }
    
    Write-Host "=== Publishing Application ===" -ForegroundColor Cyan
    Write-Host "Method: $Method" -ForegroundColor Gray
    Write-Host "Destination: $Destination" -ForegroundColor Gray
    
    if ($PSCmdlet.ShouldProcess($Destination, "Publish to")) {
        switch ($Method) {
            'FileShare' {
                # Create backup if requested
                if ($CreateBackup -and (Test-Path $Destination)) {
                    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
                    $backupDest = if ($BackupPath) {
                        Join-Path $BackupPath "backup_$timestamp"
                    }
                    else {
                        "$Destination`_backup_$timestamp"
                    }
                    
                    Write-Host "Creating backup: $backupDest" -ForegroundColor Yellow
                    Copy-Item -Path $Destination -Destination $backupDest -Recurse -Force
                }
                
                # Copy files
                Write-Host "Copying files..." -ForegroundColor Yellow
                
                if (-not (Test-Path $Destination)) {
                    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                }
                
                Copy-Item -Path "$SourcePath\*" -Destination $Destination -Recurse -Force
                
                Write-Host "✓ Published successfully" -ForegroundColor Green
                return $true
            }
            
            'FTP' {
                Write-Host "FTP deployment requires additional configuration" -ForegroundColor Yellow
                # FTP implementation would go here
            }
            
            'Azure' {
                Write-Host "Azure deployment requires Azure CLI" -ForegroundColor Yellow
                # Azure implementation would go here
            }
            
            'GitHub' {
                Write-Host "GitHub release requires GitHub CLI" -ForegroundColor Yellow
                # GitHub release implementation would go here
            }
        }
    }
}

#endregion

#region CI/CD Pipeline

function Invoke-CIPipeline {
    <#
    .SYNOPSIS
        Executes a complete CI/CD pipeline
    .EXAMPLE
        $config = New-BuildConfiguration -ProjectPath C:\Projects\MyApp -BuildType DotNet
        Invoke-CIPipeline -Configuration $config -RunTests -CreateInstaller -Deploy
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [BuildConfiguration]$Configuration,
        
        [switch]$RunTests,
        [string]$TestType,
        
        [switch]$CreateInstaller,
        [string]$InstallerType = 'ZIP',
        
        [switch]$Deploy,
        [string]$DeploymentTarget,
        [string]$DeploymentMethod,
        
        [string]$OutputPath
    )
    
    $pipelineResult = [PSCustomObject]@{
        StartTime = Get-Date
        EndTime = $null
        BuildSuccess = $false
        TestSuccess = $null
        InstallerCreated = $null
        DeploymentSuccess = $null
        Stages = @()
    }
    
    try {
        # Stage 1: Build
        Write-Host "`n========== STAGE 1: BUILD ==========" -ForegroundColor Magenta
        $buildResult = Invoke-Build -Configuration $Configuration -OutputPath $OutputPath -Clean
        $pipelineResult.BuildSuccess = $buildResult.Success
        $pipelineResult.Stages += @{Stage = 'Build'; Success = $buildResult.Success}
        
        if (-not $buildResult.Success) {
            throw "Build failed"
        }
        
        # Stage 2: Tests
        if ($RunTests) {
            Write-Host "`n========== STAGE 2: TESTS ==========" -ForegroundColor Magenta
            
            if (-not $TestType) {
                $TestType = $Configuration.BuildType
            }
            
            $testResult = Invoke-Tests -ProjectPath $Configuration.ProjectPath -TestType $TestType -Configuration $Configuration.Configuration
            $pipelineResult.TestSuccess = $testResult
            $pipelineResult.Stages += @{Stage = 'Tests'; Success = $testResult}
            
            if (-not $testResult) {
                throw "Tests failed"
            }
        }
        
        # Stage 3: Create Installer
        if ($CreateInstaller) {
            Write-Host "`n========== STAGE 3: PACKAGING ==========" -ForegroundColor Magenta
            
            $buildOutput = if ($OutputPath) { $OutputPath } else { Join-Path $Configuration.ProjectPath "bin\$($Configuration.Configuration)" }
            $installerOutput = Join-Path $Configuration.ProjectPath "installers"
            
            $installer = New-Installer -SourcePath $buildOutput -OutputPath $installerOutput -Type $InstallerType -ProductName (Split-Path $Configuration.ProjectPath -Leaf) -Version "1.0.0"
            
            $pipelineResult.InstallerCreated = $installer -ne $null
            $pipelineResult.Stages += @{Stage = 'Packaging'; Success = ($installer -ne $null)}
        }
        
        # Stage 4: Deploy
        if ($Deploy -and $DeploymentTarget) {
            Write-Host "`n========== STAGE 4: DEPLOYMENT ==========" -ForegroundColor Magenta
            
            $sourceForDeployment = if ($CreateInstaller) {
                Join-Path $Configuration.ProjectPath "installers"
            }
            else {
                if ($OutputPath) { $OutputPath } else { Join-Path $Configuration.ProjectPath "bin\$($Configuration.Configuration)" }
            }
            
            $deployResult = Publish-Application -SourcePath $sourceForDeployment -Destination $DeploymentTarget -Method $DeploymentMethod -CreateBackup
            $pipelineResult.DeploymentSuccess = $deployResult
            $pipelineResult.Stages += @{Stage = 'Deployment'; Success = $deployResult}
        }
        
        $pipelineResult.EndTime = Get-Date
        $duration = $pipelineResult.EndTime - $pipelineResult.StartTime
        
        Write-Host "`n========================================" -ForegroundColor Magenta
        Write-Host "=== PIPELINE COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
    }
    catch {
        $pipelineResult.EndTime = Get-Date
        Write-Host "`n========================================" -ForegroundColor Magenta
        Write-Host "=== PIPELINE FAILED ===" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Magenta
        Write-Error "Pipeline failed: $_"
    }
    
    return $pipelineResult
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-BuildConfiguration',
    'Invoke-Build',
    'Invoke-Tests',
    'New-Installer',
    'Publish-Application',
    'Invoke-CIPipeline'
)
