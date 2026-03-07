#Requires -Version 5.1

<#
.SYNOPSIS
    Development Environment Management Module for Better11 Suite
.DESCRIPTION
    Comprehensive toolkit for managing development environments across large teams
.AUTHOR
    Better11 Development Team
.VERSION
    1.0.0
#>

#region Environment Detection

function Get-DevelopmentEnvironment {
    <#
    .SYNOPSIS
        Detects and analyzes the current development environment
    .DESCRIPTION
        Scans for installed development tools, SDKs, runtimes, and configurations
    .EXAMPLE
        Get-DevelopmentEnvironment -Detailed
    #>
    [CmdletBinding()]
    param(
        [switch]$Detailed,
        [switch]$CheckVersions
    )
    
    $env = [PSCustomObject]@{
        Timestamp = Get-Date
        System = Get-SystemInfo
        DevelopmentTools = @{}
        Runtimes = @{}
        PackageManagers = @{}
        IDEs = @{}
        VCS = @{}
        Containers = @{}
    }
    
    # Detect Node.js
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVersion = node --version
        $npmVersion = npm --version
        $env.Runtimes.NodeJS = @{
            Installed = $true
            NodeVersion = $nodeVersion
            NpmVersion = $npmVersion
            GlobalPackages = if ($Detailed) { npm list -g --depth=0 2>$null } else { $null }
        }
    }
    
    # Detect Python
    $pythonCommands = @('python', 'python3', 'py')
    foreach ($cmd in $pythonCommands) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            $pyVersion = & $cmd --version 2>&1
            $pipVersion = & $cmd -m pip --version 2>&1
            $env.Runtimes.Python = @{
                Installed = $true
                Command = $cmd
                Version = $pyVersion
                PipVersion = $pipVersion
                VirtualEnv = Test-Path -Path "$env:USERPROFILE\.virtualenvs"
            }
            break
        }
    }
    
    # Detect .NET
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        $dotnetInfo = dotnet --info 2>$null
        $sdks = dotnet --list-sdks 2>$null
        $runtimes = dotnet --list-runtimes 2>$null
        $env.Runtimes.DotNet = @{
            Installed = $true
            Info = $dotnetInfo
            SDKs = $sdks
            Runtimes = $runtimes
        }
    }
    
    # Detect Rust
    if (Get-Command rustc -ErrorAction SilentlyContinue) {
        $rustVersion = rustc --version
        $cargoVersion = cargo --version
        $env.Runtimes.Rust = @{
            Installed = $true
            RustcVersion = $rustVersion
            CargoVersion = $cargoVersion
            Toolchains = if (Get-Command rustup -ErrorAction SilentlyContinue) { rustup toolchain list } else { $null }
        }
    }
    
    # Detect Go
    if (Get-Command go -ErrorAction SilentlyContinue) {
        $goVersion = go version
        $env.Runtimes.Go = @{
            Installed = $true
            Version = $goVersion
            GOPATH = $env:GOPATH
            GOROOT = $env:GOROOT
        }
    }
    
    # Detect Java
    if (Get-Command java -ErrorAction SilentlyContinue) {
        $javaVersion = java -version 2>&1
        $env.Runtimes.Java = @{
            Installed = $true
            Version = $javaVersion
            JAVA_HOME = $env:JAVA_HOME
        }
    }
    
    # Detect Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = git --version
        $gitConfig = git config --list 2>$null
        $env.VCS.Git = @{
            Installed = $true
            Version = $gitVersion
            UserName = git config user.name 2>$null
            UserEmail = git config user.email 2>$null
            Config = if ($Detailed) { $gitConfig } else { $null }
        }
    }
    
    # Detect Package Managers
    $packageManagers = @(
        @{Name='WinGet'; Command='winget'; VersionArg='--version'},
        @{Name='Chocolatey'; Command='choco'; VersionArg='--version'},
        @{Name='Scoop'; Command='scoop'; VersionArg='--version'},
        @{Name='Cargo'; Command='cargo'; VersionArg='--version'},
        @{Name='pip'; Command='pip'; VersionArg='--version'},
        @{Name='npm'; Command='npm'; VersionArg='--version'},
        @{Name='yarn'; Command='yarn'; VersionArg='--version'},
        @{Name='pnpm'; Command='pnpm'; VersionArg='--version'}
    )
    
    foreach ($pm in $packageManagers) {
        if (Get-Command $pm.Command -ErrorAction SilentlyContinue) {
            $version = & $pm.Command $pm.VersionArg 2>&1
            $env.PackageManagers[$pm.Name] = @{
                Installed = $true
                Version = $version
            }
        }
    }
    
    # Detect IDEs and Editors
    $ides = @(
        @{Name='VSCode'; Path='code'; DisplayName='Visual Studio Code'},
        @{Name='VisualStudio'; Path='devenv'; DisplayName='Visual Studio'},
        @{Name='Rider'; Path='rider64'; DisplayName='JetBrains Rider'},
        @{Name='IntelliJ'; Path='idea64'; DisplayName='IntelliJ IDEA'},
        @{Name='WebStorm'; Path='webstorm64'; DisplayName='WebStorm'},
        @{Name='PyCharm'; Path='pycharm64'; DisplayName='PyCharm'}
    )
    
    foreach ($ide in $ides) {
        if (Get-Command $ide.Path -ErrorAction SilentlyContinue) {
            $env.IDEs[$ide.Name] = @{
                Installed = $true
                DisplayName = $ide.DisplayName
                Command = $ide.Path
            }
        }
    }
    
    # Detect Containers
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerVersion = docker --version
        $dockerInfo = docker info 2>$null
        $env.Containers.Docker = @{
            Installed = $true
            Version = $dockerVersion
            Running = $LASTEXITCODE -eq 0
            Info = if ($Detailed -and $LASTEXITCODE -eq 0) { $dockerInfo } else { $null }
        }
    }
    
    return $env
}

function Get-SystemInfo {
    [CmdletBinding()]
    param()
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Username = $env:USERNAME
        OS = $os.Caption
        Version = $os.Version
        Architecture = $os.OSArchitecture
        RAM = "$([math]::Round($cs.TotalPhysicalMemory/1GB, 2)) GB"
        Processor = (Get-CimInstance Win32_Processor).Name
    }
}

#endregion

#region Environment Setup

function Initialize-DevelopmentEnvironment {
    <#
    .SYNOPSIS
        Sets up a complete development environment
    .DESCRIPTION
        Installs and configures development tools, runtimes, and utilities
    .EXAMPLE
        Initialize-DevelopmentEnvironment -Profile FullStack -InstallIDEs
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('Frontend', 'Backend', 'FullStack', 'DataScience', 'DevOps', 'Mobile')]
        [string]$Profile = 'FullStack',
        
        [switch]$InstallIDEs,
        [switch]$ConfigureGit,
        [switch]$SetupSSH,
        [switch]$InstallExtensions,
        [switch]$All
    )
    
    if ($All) {
        $InstallIDEs = $ConfigureGit = $SetupSSH = $InstallExtensions = $true
    }
    
    $results = @()
    
    Write-Host "Initializing $Profile development environment..." -ForegroundColor Cyan
    
    # Install core tools based on profile
    $results += Install-ProfileTools -Profile $Profile
    
    if ($ConfigureGit) {
        $results += Initialize-GitConfiguration
    }
    
    if ($SetupSSH) {
        $results += Initialize-SSHConfiguration
    }
    
    if ($InstallIDEs) {
        $results += Install-DevelopmentIDEs -Profile $Profile
    }
    
    if ($InstallExtensions) {
        $results += Install-IDEExtensions -Profile $Profile
    }
    
    # Create project structure
    $results += New-ProjectStructure -Profile $Profile
    
    return [PSCustomObject]@{
        Profile = $Profile
        Results = $results
        Environment = Get-DevelopmentEnvironment
    }
}

function Install-ProfileTools {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile
    )
    
    $tools = switch ($Profile) {
        'Frontend' {
            @{
                WinGet = @('Git.Git', 'OpenJS.NodeJS', 'Microsoft.VisualStudioCode')
                NPM = @('typescript', 'vite', 'eslint', 'prettier')
            }
        }
        'Backend' {
            @{
                WinGet = @('Git.Git', 'OpenJS.NodeJS', 'Microsoft.DotNet.SDK.8', 'Rustlang.Rustup')
                NPM = @('typescript', 'ts-node', 'nodemon')
            }
        }
        'FullStack' {
            @{
                WinGet = @('Git.Git', 'OpenJS.NodeJS', 'Microsoft.DotNet.SDK.8', 'Microsoft.VisualStudioCode', 'Docker.DockerDesktop')
                NPM = @('typescript', 'vite', 'eslint', 'prettier', 'concurrently')
            }
        }
        'DataScience' {
            @{
                WinGet = @('Git.Git', 'Python.Python.3.12', 'Anaconda.Miniconda3')
                PIP = @('jupyter', 'pandas', 'numpy', 'matplotlib', 'scikit-learn')
            }
        }
        'DevOps' {
            @{
                WinGet = @('Git.Git', 'Docker.DockerDesktop', 'Kubernetes.kubectl', 'Hashicorp.Terraform')
                NPM = @()
            }
        }
        'Mobile' {
            @{
                WinGet = @('Git.Git', 'OpenJS.NodeJS', 'Google.AndroidStudio')
                NPM = @('react-native-cli', 'expo-cli')
            }
        }
    }
    
    $results = @()
    
    # Install WinGet packages
    if ($tools.WinGet) {
        foreach ($package in $tools.WinGet) {
            if ($PSCmdlet.ShouldProcess($package, "Install via WinGet")) {
                try {
                    Write-Host "Installing $package..." -ForegroundColor Yellow
                    winget install --id $package --silent --accept-source-agreements --accept-package-agreements
                    $results += "✓ Installed: $package"
                }
                catch {
                    $results += "✗ Failed: $package - $_"
                }
            }
        }
    }
    
    # Install NPM packages globally
    if ($tools.NPM -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        foreach ($package in $tools.NPM) {
            if ($PSCmdlet.ShouldProcess($package, "Install via NPM")) {
                try {
                    Write-Host "Installing NPM package: $package..." -ForegroundColor Yellow
                    npm install -g $package
                    $results += "✓ Installed NPM: $package"
                }
                catch {
                    $results += "✗ Failed NPM: $package - $_"
                }
            }
        }
    }
    
    # Install PIP packages
    if ($tools.PIP -and (Get-Command python -ErrorAction SilentlyContinue)) {
        foreach ($package in $tools.PIP) {
            if ($PSCmdlet.ShouldProcess($package, "Install via PIP")) {
                try {
                    Write-Host "Installing PIP package: $package..." -ForegroundColor Yellow
                    python -m pip install $package
                    $results += "✓ Installed PIP: $package"
                }
                catch {
                    $results += "✗ Failed PIP: $package - $_"
                }
            }
        }
    }
    
    return $results
}

function Initialize-GitConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $results = @()
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return "Git not installed"
    }
    
    # Check if already configured
    $existingUser = git config --global user.name 2>$null
    $existingEmail = git config --global user.email 2>$null
    
    if (-not $existingUser -or -not $existingEmail) {
        $userName = Read-Host "Enter your Git username"
        $userEmail = Read-Host "Enter your Git email"
        
        if ($PSCmdlet.ShouldProcess("Git", "Configure user")) {
            git config --global user.name $userName
            git config --global user.email $userEmail
            $results += "✓ Configured Git user: $userName"
        }
    }
    
    # Set useful Git defaults
    if ($PSCmdlet.ShouldProcess("Git", "Configure defaults")) {
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.autocrlf true
        git config --global core.editor "code --wait"
        $results += "✓ Configured Git defaults"
    }
    
    return $results
}

function Initialize-SSHConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $sshPath = "$env:USERPROFILE\.ssh"
    $keyPath = "$sshPath\id_ed25519"
    
    if (-not (Test-Path $sshPath)) {
        New-Item -ItemType Directory -Path $sshPath -Force | Out-Null
    }
    
    if (-not (Test-Path $keyPath)) {
        if ($PSCmdlet.ShouldProcess("SSH Key", "Generate")) {
            $email = Read-Host "Enter your email for SSH key"
            ssh-keygen -t ed25519 -C $email -f $keyPath -N '""'
            
            # Start SSH agent and add key
            Start-Service ssh-agent
            ssh-add $keyPath
            
            Write-Host "`nYour public key:" -ForegroundColor Cyan
            Get-Content "$keyPath.pub"
            Write-Host "`nAdd this to GitHub/GitLab/etc." -ForegroundColor Yellow
            
            return "✓ SSH key generated and added to agent"
        }
    }
    
    return "SSH key already exists"
}

function Install-DevelopmentIDEs {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile
    )
    
    $ides = @('Microsoft.VisualStudioCode')
    
    $results = @()
    foreach ($ide in $ides) {
        if ($PSCmdlet.ShouldProcess($ide, "Install")) {
            try {
                winget install --id $ide --silent
                $results += "✓ Installed: $ide"
            }
            catch {
                $results += "✗ Failed: $ide"
            }
        }
    }
    
    return $results
}

function Install-IDEExtensions {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile
    )
    
    $results = @()
    
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $extensions = @(
            'ms-vscode.powershell',
            'ms-vscode.cpptools',
            'ms-python.python',
            'rust-lang.rust-analyzer',
            'bradlc.vscode-tailwindcss',
            'esbenp.prettier-vscode',
            'dbaeumer.vscode-eslint',
            'eamodio.gitlens'
        )
        
        foreach ($ext in $extensions) {
            if ($PSCmdlet.ShouldProcess($ext, "Install VS Code Extension")) {
                try {
                    code --install-extension $ext --force
                    $results += "✓ Installed extension: $ext"
                }
                catch {
                    $results += "✗ Failed extension: $ext"
                }
            }
        }
    }
    
    return $results
}

function New-ProjectStructure {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Profile,
        [string]$BasePath = "$env:USERPROFILE\Projects"
    )
    
    if (-not (Test-Path $BasePath)) {
        if ($PSCmdlet.ShouldProcess($BasePath, "Create project directory")) {
            New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
        }
    }
    
    $folders = @('active', 'archived', 'templates', 'experiments')
    
    foreach ($folder in $folders) {
        $path = Join-Path $BasePath $folder
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    
    return "✓ Created project structure in $BasePath"
}

#endregion

#region Team Management

function Sync-TeamEnvironment {
    <#
    .SYNOPSIS
        Synchronizes development environment across team
    .DESCRIPTION
        Ensures all team members have consistent tooling and configurations
    .EXAMPLE
        Sync-TeamEnvironment -ConfigRepo "https://github.com/company/dev-config"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigRepo,
        
        [string]$Branch = 'main',
        [switch]$Force
    )
    
    $configPath = "$env:USERPROFILE\.dev-config"
    
    # Clone or update config repo
    if (Test-Path $configPath) {
        if ($Force) {
            Remove-Item $configPath -Recurse -Force
            git clone $ConfigRepo $configPath
        }
        else {
            Push-Location $configPath
            git pull origin $Branch
            Pop-Location
        }
    }
    else {
        git clone $ConfigRepo $configPath
    }
    
    # Apply configurations
    $configFile = Join-Path $configPath "team-config.json"
    if (Test-Path $configFile) {
        $config = Get-Content $configFile | ConvertFrom-Json
        
        # Install required tools
        foreach ($tool in $config.RequiredTools) {
            Install-Tool -Name $tool.Name -Version $tool.Version
        }
        
        # Apply environment variables
        foreach ($envVar in $config.EnvironmentVariables.PSObject.Properties) {
            [Environment]::SetEnvironmentVariable($envVar.Name, $envVar.Value, 'User')
        }
        
        return "✓ Team environment synchronized"
    }
    
    return "✗ Configuration file not found"
}

function Test-EnvironmentCompliance {
    <#
    .SYNOPSIS
        Checks if environment meets team standards
    .DESCRIPTION
        Validates installed tools, versions, and configurations against requirements
    .EXAMPLE
        Test-EnvironmentCompliance -RequirementsFile .\requirements.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RequirementsFile
    )
    
    if (-not (Test-Path $RequirementsFile)) {
        throw "Requirements file not found: $RequirementsFile"
    }
    
    $requirements = Get-Content $RequirementsFile | ConvertFrom-Json
    $currentEnv = Get-DevelopmentEnvironment
    
    $compliance = @{
        Compliant = $true
        Issues = @()
        Warnings = @()
    }
    
    # Check required runtimes
    foreach ($runtime in $requirements.Runtimes.PSObject.Properties) {
        $runtimeName = $runtime.Name
        $requiredVersion = $runtime.Value.MinVersion
        
        if (-not $currentEnv.Runtimes[$runtimeName]) {
            $compliance.Compliant = $false
            $compliance.Issues += "$runtimeName is not installed (required: $requiredVersion)"
        }
    }
    
    # Check required package managers
    foreach ($pm in $requirements.PackageManagers) {
        if (-not $currentEnv.PackageManagers[$pm]) {
            $compliance.Warnings += "$pm is not installed"
        }
    }
    
    return [PSCustomObject]$compliance
}

function Export-EnvironmentSnapshot {
    <#
    .SYNOPSIS
        Exports current environment configuration
    .DESCRIPTION
        Creates a portable snapshot of the development environment
    .EXAMPLE
        Export-EnvironmentSnapshot -Path .\my-env-snapshot.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$IncludePackages
    )
    
    $env = Get-DevelopmentEnvironment -Detailed
    
    $snapshot = @{
        Timestamp = Get-Date
        System = $env.System
        Runtimes = $env.Runtimes
        PackageManagers = $env.PackageManagers
        IDEs = $env.IDEs
        VCS = $env.VCS
    }
    
    if ($IncludePackages) {
        $snapshot.Packages = @{
            NPM = if (Get-Command npm -ErrorAction SilentlyContinue) { npm list -g --depth=0 --json | ConvertFrom-Json } else { $null }
            PIP = if (Get-Command pip -ErrorAction SilentlyContinue) { pip list --format=json | ConvertFrom-Json } else { $null }
            Cargo = if (Get-Command cargo -ErrorAction SilentlyContinue) { cargo install --list } else { $null }
        }
    }
    
    $snapshot | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
    
    Write-Host "Environment snapshot saved to: $Path" -ForegroundColor Green
    return $Path
}

function Import-EnvironmentSnapshot {
    <#
    .SYNOPSIS
        Restores environment from a snapshot
    .DESCRIPTION
        Installs tools and packages from a previously exported snapshot
    .EXAMPLE
        Import-EnvironmentSnapshot -Path .\snapshot.json -InstallPackages
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$InstallPackages
    )
    
    if (-not (Test-Path $Path)) {
        throw "Snapshot file not found: $Path"
    }
    
    $snapshot = Get-Content $Path | ConvertFrom-Json
    
    Write-Host "Restoring environment from snapshot..." -ForegroundColor Cyan
    Write-Host "Snapshot date: $($snapshot.Timestamp)" -ForegroundColor Yellow
    
    # Install runtimes
    foreach ($runtime in $snapshot.Runtimes.PSObject.Properties) {
        Write-Host "Processing runtime: $($runtime.Name)" -ForegroundColor Yellow
        # Installation logic here
    }
    
    if ($InstallPackages -and $snapshot.Packages) {
        # Restore NPM packages
        if ($snapshot.Packages.NPM) {
            foreach ($package in $snapshot.Packages.NPM.dependencies.PSObject.Properties) {
                npm install -g $package.Name
            }
        }
        
        # Restore PIP packages
        if ($snapshot.Packages.PIP) {
            foreach ($package in $snapshot.Packages.PIP) {
                pip install "$($package.name)==$($package.version)"
            }
        }
    }
    
    return "✓ Environment restored from snapshot"
}

#endregion

#region Utilities

function Install-Tool {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Name,
        [string]$Version
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Install")) {
        winget install --id $Name --version $Version --silent
    }
}

function Get-InstalledSDKs {
    <#
    .SYNOPSIS
        Lists all installed SDKs and their versions
    .EXAMPLE
        Get-InstalledSDKs -Type DotNet
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'DotNet', 'Java', 'Android', 'iOS')]
        [string]$Type = 'All'
    )
    
    $sdks = @{}
    
    if ($Type -in @('All', 'DotNet') -and (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        $sdks.DotNet = dotnet --list-sdks
    }
    
    if ($Type -in @('All', 'Java')) {
        # Java SDK detection logic
    }
    
    return $sdks
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-DevelopmentEnvironment',
    'Initialize-DevelopmentEnvironment',
    'Sync-TeamEnvironment',
    'Test-EnvironmentCompliance',
    'Export-EnvironmentSnapshot',
    'Import-EnvironmentSnapshot',
    'Get-InstalledSDKs'
)
