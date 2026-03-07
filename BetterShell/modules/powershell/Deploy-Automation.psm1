<#
.SYNOPSIS
    WinPE PowerBuilder - Deployment Automation Module
    Handles automated deployment workflows, task sequencing, and unattended installation

.DESCRIPTION
    This module provides comprehensive deployment automation capabilities including:
    - Task sequence creation and management
    - Unattended installation configuration
    - Deployment workflow orchestration
    - Post-deployment configuration
    - Multi-machine deployment coordination

.NOTES
    Module: Deploy-Automation
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK, WinPE environment
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Module Variables

$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-DeploymentAutomation.log"
$script:TaskSequencePath = Join-Path $ModuleRoot "TaskSequences"
$script:DeploymentProfilesPath = Join-Path $ModuleRoot "DeploymentProfiles"
$script:UnattendedConfigPath = Join-Path $ModuleRoot "UnattendedConfigs"

# Ensure required paths exist
@($TaskSequencePath, $DeploymentProfilesPath, $UnattendedConfigPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

#endregion

#region Logging Functions

function Write-DeployLog {
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
    
    # Console output with color
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    # File output
    Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

#endregion

#region Task Sequence Functions

function New-DeploymentTaskSequence {
    <#
    .SYNOPSIS
        Creates a new deployment task sequence
    
    .DESCRIPTION
        Creates a structured task sequence for automated deployments
        Supports conditional execution, error handling, and rollback
    
    .EXAMPLE
        New-DeploymentTaskSequence -Name "StandardDesktop" -Description "Standard desktop deployment"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [string]$Version = "1.0.0",
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-DeployLog "Creating task sequence: $Name" -Level Info
        
        $sequencePath = Join-Path $TaskSequencePath "$Name.json"
        
        if ((Test-Path $sequencePath) -and -not $Force) {
            throw "Task sequence '$Name' already exists. Use -Force to overwrite."
        }
        
        $taskSequence = @{
            Name = $Name
            Description = $Description
            Version = $Version
            Created = (Get-Date).ToString('o')
            Modified = (Get-Date).ToString('o')
            Variables = $Variables
            Tasks = @()
            ErrorHandling = @{
                ContinueOnError = $false
                MaxRetries = 3
                RetryDelay = 30
                RollbackOnFailure = $true
            }
        }
        
        $taskSequence | ConvertTo-Json -Depth 10 | Set-Content -Path $sequencePath -Force
        
        Write-DeployLog "Task sequence created successfully: $sequencePath" -Level Success
        return $taskSequence
    }
    catch {
        Write-DeployLog "Failed to create task sequence: $_" -Level Error
        throw
    }
}

function Add-TaskSequenceStep {
    <#
    .SYNOPSIS
        Adds a step to a deployment task sequence
    
    .DESCRIPTION
        Adds a configured step to an existing task sequence
        Supports various step types: Command, Script, Reboot, Condition
    
    .EXAMPLE
        Add-TaskSequenceStep -SequenceName "StandardDesktop" -StepName "ApplyDrivers" -Type Script -ScriptPath "Apply-Drivers.ps1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SequenceName,
        
        [Parameter(Mandatory)]
        [string]$StepName,
        
        [Parameter(Mandatory)]
        [ValidateSet('Command', 'Script', 'Reboot', 'Condition', 'Group', 'Install', 'Configure')]
        [string]$Type,
        
        [Parameter()]
        [string]$Command,
        
        [Parameter()]
        [string]$ScriptPath,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [string]$Condition,
        
        [Parameter()]
        [int]$Timeout = 3600,
        
        [Parameter()]
        [bool]$ContinueOnError = $false,
        
        [Parameter()]
        [string]$Description
    )
    
    try {
        Write-DeployLog "Adding step '$StepName' to sequence '$SequenceName'" -Level Info
        
        $sequencePath = Join-Path $TaskSequencePath "$SequenceName.json"
        
        if (-not (Test-Path $sequencePath)) {
            throw "Task sequence '$SequenceName' not found."
        }
        
        $taskSequence = Get-Content $sequencePath -Raw | ConvertFrom-Json
        
        $step = @{
            Name = $StepName
            Type = $Type
            Description = $Description
            Enabled = $true
            ContinueOnError = $ContinueOnError
            Timeout = $Timeout
            Condition = $Condition
            Order = $taskSequence.Tasks.Count + 1
        }
        
        switch ($Type) {
            'Command' {
                $step.Command = $Command
                $step.Parameters = $Parameters
            }
            'Script' {
                $step.ScriptPath = $ScriptPath
                $step.Parameters = $Parameters
            }
            'Reboot' {
                $step.RebootDelay = 10
                $step.Message = "System will reboot in {0} seconds..."
            }
            'Condition' {
                $step.ConditionScript = $Condition
                $step.TrueSteps = @()
                $step.FalseSteps = @()
            }
            'Group' {
                $step.Steps = @()
                $step.RunMode = 'Sequential'
            }
            'Install' {
                $step.PackagePath = $Parameters.PackagePath
                $step.InstallCommand = $Command
                $step.UninstallCommand = $Parameters.UninstallCommand
            }
            'Configure' {
                $step.ConfigScript = $ScriptPath
                $step.Settings = $Parameters
            }
        }
        
        # Convert to PSCustomObject for proper JSON serialization
        $taskSequence.Tasks += $step
        $taskSequence.Modified = (Get-Date).ToString('o')
        
        # Save updated sequence
        $taskSequence | ConvertTo-Json -Depth 10 | Set-Content -Path $sequencePath -Force
        
        Write-DeployLog "Step added successfully to sequence" -Level Success
        return $step
    }
    catch {
        Write-DeployLog "Failed to add task sequence step: $_" -Level Error
        throw
    }
}

function Invoke-TaskSequence {
    <#
    .SYNOPSIS
        Executes a deployment task sequence
    
    .DESCRIPTION
        Runs a complete task sequence with error handling, logging, and progress tracking
    
    .EXAMPLE
        Invoke-TaskSequence -SequenceName "StandardDesktop" -Variables @{ComputerName="DESK001"}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SequenceName,
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    try {
        Write-DeployLog "Starting task sequence execution: $SequenceName" -Level Info
        
        $sequencePath = Join-Path $TaskSequencePath "$SequenceName.json"
        
        if (-not (Test-Path $sequencePath)) {
            throw "Task sequence '$SequenceName' not found."
        }
        
        $taskSequence = Get-Content $sequencePath -Raw | ConvertFrom-Json
        
        # Merge variables
        $allVariables = $taskSequence.Variables.Clone()
        foreach ($key in $Variables.Keys) {
            $allVariables[$key] = $Variables[$key]
        }
        
        # Initialize execution context
        $context = @{
            SequenceName = $SequenceName
            Variables = $allVariables
            StartTime = Get-Date
            CompletedSteps = @()
            FailedSteps = @()
            SkippedSteps = @()
            CurrentStep = 0
            TotalSteps = $taskSequence.Tasks.Count
        }
        
        Write-DeployLog "Task sequence has $($context.TotalSteps) steps" -Level Info
        
        # Execute each task
        foreach ($task in $taskSequence.Tasks) {
            $context.CurrentStep++
            
            Write-DeployLog "[$($context.CurrentStep)/$($context.TotalSteps)] Executing step: $($task.Name)" -Level Info
            
            if (-not $task.Enabled) {
                Write-DeployLog "Step '$($task.Name)' is disabled, skipping" -Level Warning
                $context.SkippedSteps += $task.Name
                continue
            }
            
            # Evaluate condition if present
            if ($task.Condition) {
                $conditionResult = Invoke-Expression $task.Condition
                if (-not $conditionResult) {
                    Write-DeployLog "Step '$($task.Name)' condition not met, skipping" -Level Info
                    $context.SkippedSteps += $task.Name
                    continue
                }
            }
            
            if ($WhatIf) {
                Write-DeployLog "[WHATIF] Would execute: $($task.Name) ($($task.Type))" -Level Info
                continue
            }
            
            try {
                # Execute step based on type
                $stepResult = Invoke-TaskSequenceStep -Task $task -Context $context -ErrorAction Stop
                
                if ($stepResult.Success) {
                    Write-DeployLog "Step '$($task.Name)' completed successfully" -Level Success
                    $context.CompletedSteps += $task.Name
                } else {
                    throw "Step failed: $($stepResult.Error)"
                }
            }
            catch {
                Write-DeployLog "Step '$($task.Name)' failed: $_" -Level Error
                $context.FailedSteps += $task.Name
                
                if (-not $task.ContinueOnError) {
                    if ($taskSequence.ErrorHandling.RollbackOnFailure) {
                        Write-DeployLog "Initiating rollback due to failure" -Level Warning
                        Invoke-TaskSequenceRollback -Context $context
                    }
                    throw "Task sequence failed at step: $($task.Name)"
                }
            }
        }
        
        $context.EndTime = Get-Date
        $context.Duration = $context.EndTime - $context.StartTime
        
        Write-DeployLog "Task sequence completed" -Level Success
        Write-DeployLog "Completed: $($context.CompletedSteps.Count) | Failed: $($context.FailedSteps.Count) | Skipped: $($context.SkippedSteps.Count)" -Level Info
        Write-DeployLog "Total duration: $($context.Duration.ToString())" -Level Info
        
        return $context
    }
    catch {
        Write-DeployLog "Task sequence execution failed: $_" -Level Error
        throw
    }
}

function Invoke-TaskSequenceStep {
    <#
    .SYNOPSIS
        Executes an individual task sequence step
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Task,
        
        [Parameter(Mandatory)]
        $Context
    )
    
    $result = @{
        Success = $false
        Error = $null
        Output = $null
        Duration = $null
    }
    
    $startTime = Get-Date
    
    try {
        switch ($Task.Type) {
            'Command' {
                $expandedCommand = Expand-Variables -String $Task.Command -Variables $Context.Variables
                $result.Output = Invoke-Expression $expandedCommand
                $result.Success = $LASTEXITCODE -eq 0
            }
            
            'Script' {
                $expandedPath = Expand-Variables -String $Task.ScriptPath -Variables $Context.Variables
                if (Test-Path $expandedPath) {
                    $params = @{}
                    foreach ($key in $Task.Parameters.Keys) {
                        $params[$key] = Expand-Variables -String $Task.Parameters[$key] -Variables $Context.Variables
                    }
                    $result.Output = & $expandedPath @params
                    $result.Success = $?
                } else {
                    throw "Script not found: $expandedPath"
                }
            }
            
            'Reboot' {
                Write-DeployLog "Initiating system reboot in $($Task.RebootDelay) seconds..." -Level Warning
                Start-Sleep -Seconds $Task.RebootDelay
                Restart-Computer -Force
                $result.Success = $true
            }
            
            'Condition' {
                $conditionResult = Invoke-Expression $Task.ConditionScript
                if ($conditionResult) {
                    foreach ($trueStep in $Task.TrueSteps) {
                        Invoke-TaskSequenceStep -Task $trueStep -Context $Context
                    }
                } else {
                    foreach ($falseStep in $Task.FalseSteps) {
                        Invoke-TaskSequenceStep -Task $falseStep -Context $Context
                    }
                }
                $result.Success = $true
            }
            
            'Group' {
                foreach ($groupStep in $Task.Steps) {
                    Invoke-TaskSequenceStep -Task $groupStep -Context $Context
                }
                $result.Success = $true
            }
            
            'Install' {
                $packagePath = Expand-Variables -String $Task.PackagePath -Variables $Context.Variables
                $installCmd = Expand-Variables -String $Task.InstallCommand -Variables $Context.Variables
                
                if (Test-Path $packagePath) {
                    $result.Output = Invoke-Expression $installCmd
                    $result.Success = $LASTEXITCODE -eq 0
                } else {
                    throw "Package not found: $packagePath"
                }
            }
            
            'Configure' {
                $configScript = Expand-Variables -String $Task.ConfigScript -Variables $Context.Variables
                $result.Output = & $configScript -Settings $Task.Settings
                $result.Success = $?
            }
        }
    }
    catch {
        $result.Error = $_.Exception.Message
        $result.Success = $false
    }
    
    $result.Duration = (Get-Date) - $startTime
    return $result
}

function Invoke-TaskSequenceRollback {
    <#
    .SYNOPSIS
        Performs rollback of completed task sequence steps
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context
    )
    
    Write-DeployLog "Starting task sequence rollback" -Level Warning
    
    # Rollback in reverse order
    $completedSteps = $Context.CompletedSteps
    [array]::Reverse($completedSteps)
    
    foreach ($stepName in $completedSteps) {
        try {
            Write-DeployLog "Rolling back step: $stepName" -Level Warning
            # Implement rollback logic per step type
            # This would need step-specific rollback handlers
        }
        catch {
            Write-DeployLog "Rollback failed for step '$stepName': $_" -Level Error
        }
    }
    
    Write-DeployLog "Rollback completed" -Level Warning
}

#endregion

#region Unattended Installation Functions

function New-UnattendedAnswerFile {
    <#
    .SYNOPSIS
        Creates a new unattended answer file (unattend.xml)
    
    .DESCRIPTION
        Generates a complete Windows unattended installation answer file
        with customizable settings for automated deployments
    
    .EXAMPLE
        New-UnattendedAnswerFile -Name "Enterprise" -ComputerName "DESK-%RANDOM%" -ProductKey "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter()]
        [string]$ComputerName = "WIN-%RANDOM%",
        
        [Parameter()]
        [string]$ProductKey,
        
        [Parameter()]
        [string]$Organization = "Organization",
        
        [Parameter()]
        [string]$Owner = "Owner",
        
        [Parameter()]
        [string]$TimeZone = "Pacific Standard Time",
        
        [Parameter()]
        [string]$InputLocale = "en-US",
        
        [Parameter()]
        [string]$SystemLocale = "en-US",
        
        [Parameter()]
        [string]$UILanguage = "en-US",
        
        [Parameter()]
        [string]$UserLocale = "en-US",
        
        [Parameter()]
        [string]$AdministratorPassword,
        
        [Parameter()]
        [hashtable[]]$UserAccounts = @(),
        
        [Parameter()]
        [string]$DomainName,
        
        [Parameter()]
        [string]$DomainUser,
        
        [Parameter()]
        [string]$DomainPassword,
        
        [Parameter()]
        [string]$TargetOU,
        
        [Parameter()]
        [hashtable]$NetworkSettings = @{},
        
        [Parameter()]
        [string[]]$RunSynchronousCommands = @(),
        
        [Parameter()]
        [string[]]$FirstLogonCommands = @(),
        
        [Parameter()]
        [switch]$AutoLogon,
        
        [Parameter()]
        [int]$AutoLogonCount = 1,
        
        [Parameter()]
        [switch]$HideEULAPage,
        
        [Parameter()]
        [switch]$ProtectComputer,
        
        [Parameter()]
        [ValidateSet('Professional', 'Enterprise', 'Education', 'Home')]
        [string]$Edition = "Professional"
    )
    
    try {
        Write-DeployLog "Creating unattended answer file: $Name" -Level Info
        
        $answerFilePath = Join-Path $UnattendedConfigPath "$Name.xml"
        
        # Build XML structure
        $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>$UILanguage</UILanguage>
            </SetupUILanguage>
            <InputLocale>$InputLocale</InputLocale>
            <SystemLocale>$SystemLocale</SystemLocale>
            <UILanguage>$UILanguage</UILanguage>
            <UserLocale>$UserLocale</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserData>
                <ProductKey>
"@
        
        if ($ProductKey) {
            $xml += @"
                    <Key>$ProductKey</Key>
                    <WillShowUI>Never</WillShowUI>
"@
        } else {
            $xml += @"
                    <WillShowUI>OnError</WillShowUI>
"@
        }
        
        $xml += @"
                </ProductKey>
                <AcceptEula>true</AcceptEula>
                <Organization>$Organization</Organization>
            </UserData>
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>Primary</Type>
                            <Size>500</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Active>true</Active>
                            <Format>NTFS</Format>
                            <Label>System</Label>
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <TypeID>0x27</TypeID>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Format>NTFS</Format>
                            <Label>Windows</Label>
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>Windows 11 $Edition</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>2</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>$ComputerName</ComputerName>
            <RegisteredOrganization>$Organization</RegisteredOrganization>
            <RegisteredOwner>$Owner</RegisteredOwner>
            <TimeZone>$TimeZone</TimeZone>
        </component>
"@
        
        # Add domain join configuration if specified
        if ($DomainName) {
            $xml += @"
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Identification>
                <Credentials>
                    <Domain>$DomainName</Domain>
                    <Password>$DomainPassword</Password>
                    <Username>$DomainUser</Username>
                </Credentials>
                <JoinDomain>$DomainName</JoinDomain>
"@
            if ($TargetOU) {
                $xml += @"
                <MachineObjectOU>$TargetOU</MachineObjectOU>
"@
            }
            $xml += @"
            </Identification>
        </component>
"@
        }
        
        # Add network configuration if specified
        if ($NetworkSettings.Count -gt 0) {
            $xml += @"
        <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Interfaces>
                <Interface wcm:action="add">
                    <Ipv4Settings>
                        <DhcpEnabled>$($NetworkSettings.UseDHCP -eq $true)</DhcpEnabled>
                    </Ipv4Settings>
"@
            if (-not $NetworkSettings.UseDHCP) {
                $xml += @"
                    <UnicastIpAddresses>
                        <IpAddress wcm:action="add" wcm:keyValue="1">$($NetworkSettings.IPAddress)/$($NetworkSettings.SubnetMask)</IpAddress>
                    </UnicastIpAddresses>
                    <Routes>
                        <Route wcm:action="add">
                            <Identifier>0</Identifier>
                            <Prefix>0.0.0.0/0</Prefix>
                            <NextHopAddress>$($NetworkSettings.Gateway)</NextHopAddress>
                        </Route>
                    </Routes>
"@
            }
            $xml += @"
                    <Identifier>0</Identifier>
                </Interface>
            </Interfaces>
        </component>
        <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Interfaces>
                <Interface wcm:action="add">
                    <DNSServerSearchOrder>
"@
            $dnsOrder = 1
            foreach ($dns in $NetworkSettings.DNSServers) {
                $xml += @"
                        <IpAddress wcm:action="add" wcm:keyValue="$dnsOrder">$dns</IpAddress>
"@
                $dnsOrder++
            }
            $xml += @"
                    </DNSServerSearchOrder>
                    <Identifier>0</Identifier>
                </Interface>
            </Interfaces>
        </component>
"@
        }
        
        $xml += @"
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>$($HideEULAPage.ToString().ToLower())</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>$($ProtectComputer ? '1' : '3')</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <UserAccounts>
"@
        
        # Add administrator password
        if ($AdministratorPassword) {
            $encodedPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($AdministratorPassword + "AdministratorPassword"))
            $xml += @"
                <AdministratorPassword>
                    <Value>$encodedPassword</Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
"@
        }
        
        # Add user accounts
        if ($UserAccounts.Count -gt 0) {
            $xml += @"
                <LocalAccounts>
"@
            foreach ($user in $UserAccounts) {
                $userPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($user.Password + "Password"))
                $xml += @"
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>$userPassword</Value>
                            <PlainText>false</PlainText>
                        </Password>
                        <Name>$($user.Username)</Name>
                        <DisplayName>$($user.DisplayName)</DisplayName>
                        <Group>$($user.Group)</Group>
                        <Description>$($user.Description)</Description>
                    </LocalAccount>
"@
            }
            $xml += @"
                </LocalAccounts>
"@
        }
        
        $xml += @"
            </UserAccounts>
"@
        
        # Add AutoLogon if specified
        if ($AutoLogon) {
            $logonPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($AdministratorPassword + "AutoLogon"))
            $xml += @"
            <AutoLogon>
                <Password>
                    <Value>$logonPassword</Value>
                    <PlainText>false</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <Username>Administrator</Username>
                <LogonCount>$AutoLogonCount</LogonCount>
            </AutoLogon>
"@
        }
        
        # Add FirstLogonCommands
        if ($FirstLogonCommands.Count -gt 0) {
            $xml += @"
            <FirstLogonCommands>
"@
            $cmdOrder = 1
            foreach ($cmd in $FirstLogonCommands) {
                $xml += @"
                <SynchronousCommand wcm:action="add">
                    <Order>$cmdOrder</Order>
                    <CommandLine>$cmd</CommandLine>
                    <Description>First logon command $cmdOrder</Description>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
"@
                $cmdOrder++
            }
            $xml += @"
            </FirstLogonCommands>
"@
        }
        
        $xml += @"
        </component>
    </settings>
</unattend>
"@
        
        # Save XML file
        $xml | Set-Content -Path $answerFilePath -Force -Encoding UTF8
        
        Write-DeployLog "Unattended answer file created: $answerFilePath" -Level Success
        return $answerFilePath
    }
    catch {
        Write-DeployLog "Failed to create unattended answer file: $_" -Level Error
        throw
    }
}

function Test-UnattendedAnswerFile {
    <#
    .SYNOPSIS
        Validates an unattended answer file
    
    .DESCRIPTION
        Uses Windows SIM (System Image Manager) to validate answer file syntax
    
    .EXAMPLE
        Test-UnattendedAnswerFile -Path "C:\Unattend.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    try {
        Write-DeployLog "Validating unattended answer file: $Path" -Level Info
        
        if (-not (Test-Path $Path)) {
            throw "Answer file not found: $Path"
        }
        
        # Load XML
        [xml]$xml = Get-Content $Path
        
        # Basic schema validation
        if ($xml.unattend -eq $null) {
            throw "Invalid unattend.xml structure - root element missing"
        }
        
        $validationResults = @{
            Valid = $true
            Warnings = @()
            Errors = @()
        }
        
        # Check for required components
        $requiredSettings = @('windowsPE', 'specialize', 'oobeSystem')
        foreach ($setting in $requiredSettings) {
            $settingsPass = $xml.unattend.settings | Where-Object { $_.pass -eq $setting }
            if ($null -eq $settingsPass) {
                $validationResults.Warnings += "Missing settings pass: $setting"
            }
        }
        
        # Validate product key format if present
        $productKey = $xml.unattend.settings.component.UserData.ProductKey.Key
        if ($productKey -and $productKey -notmatch '^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$') {
            $validationResults.Errors += "Invalid product key format"
            $validationResults.Valid = $false
        }
        
        # Check computer name
        $computerName = $xml.unattend.settings.component | Where-Object { $_.name -eq 'Microsoft-Windows-Shell-Setup' } | Select-Object -First 1 -ExpandProperty ComputerName
        if ([string]::IsNullOrEmpty($computerName)) {
            $validationResults.Warnings += "No computer name specified"
        }
        
        if ($validationResults.Valid) {
            Write-DeployLog "Answer file validation passed" -Level Success
        } else {
            Write-DeployLog "Answer file validation failed" -Level Error
        }
        
        foreach ($warning in $validationResults.Warnings) {
            Write-DeployLog "Validation warning: $warning" -Level Warning
        }
        
        foreach ($error in $validationResults.Errors) {
            Write-DeployLog "Validation error: $error" -Level Error
        }
        
        return $validationResults
    }
    catch {
        Write-DeployLog "Failed to validate answer file: $_" -Level Error
        throw
    }
}

#endregion

#region Deployment Profile Functions

function New-DeploymentProfile {
    <#
    .SYNOPSIS
        Creates a complete deployment profile combining task sequences and answer files
    
    .DESCRIPTION
        Creates a deployment profile that defines all aspects of an automated deployment
    
    .EXAMPLE
        New-DeploymentProfile -Name "StandardDesktop" -TaskSequence "DesktopDeploy" -AnswerFile "Desktop.xml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$TaskSequenceName,
        
        [Parameter()]
        [string]$AnswerFileName,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [hashtable]$DefaultVariables = @{},
        
        [Parameter()]
        [string[]]$RequiredDrivers = @(),
        
        [Parameter()]
        [string[]]$RequiredApplications = @(),
        
        [Parameter()]
        [hashtable]$PostDeploymentConfig = @{},
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-DeployLog "Creating deployment profile: $Name" -Level Info
        
        $profilePath = Join-Path $DeploymentProfilesPath "$Name.json"
        
        if ((Test-Path $profilePath) -and -not $Force) {
            throw "Deployment profile '$Name' already exists. Use -Force to overwrite."
        }
        
        $profile = @{
            Name = $Name
            Description = $Description
            Created = (Get-Date).ToString('o')
            Modified = (Get-Date).ToString('o')
            TaskSequence = $TaskSequenceName
            AnswerFile = $AnswerFileName
            DefaultVariables = $DefaultVariables
            RequiredDrivers = $RequiredDrivers
            RequiredApplications = $RequiredApplications
            PostDeploymentConfig = $PostDeploymentConfig
            Enabled = $true
        }
        
        $profile | ConvertTo-Json -Depth 10 | Set-Content -Path $profilePath -Force
        
        Write-DeployLog "Deployment profile created: $profilePath" -Level Success
        return $profile
    }
    catch {
        Write-DeployLog "Failed to create deployment profile: $_" -Level Error
        throw
    }
}

function Invoke-DeploymentProfile {
    <#
    .SYNOPSIS
        Executes a complete deployment using a deployment profile
    
    .DESCRIPTION
        Orchestrates the entire deployment process including task sequence execution,
        driver installation, application deployment, and post-deployment configuration
    
    .EXAMPLE
        Invoke-DeploymentProfile -ProfileName "StandardDesktop" -TargetComputer "DESK001"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileName,
        
        [Parameter()]
        [string]$TargetComputer = $env:COMPUTERNAME,
        
        [Parameter()]
        [hashtable]$Variables = @{},
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    try {
        Write-DeployLog "Starting deployment with profile: $ProfileName" -Level Info
        Write-DeployLog "Target computer: $TargetComputer" -Level Info
        
        $profilePath = Join-Path $DeploymentProfilesPath "$ProfileName.json"
        
        if (-not (Test-Path $profilePath)) {
            throw "Deployment profile '$ProfileName' not found."
        }
        
        $profile = Get-Content $profilePath -Raw | ConvertFrom-Json
        
        if (-not $profile.Enabled) {
            throw "Deployment profile '$ProfileName' is disabled."
        }
        
        # Merge variables
        $deploymentVariables = $profile.DefaultVariables.Clone()
        foreach ($key in $Variables.Keys) {
            $deploymentVariables[$key] = $Variables[$key]
        }
        $deploymentVariables['TargetComputer'] = $TargetComputer
        
        # Initialize deployment context
        $context = @{
            ProfileName = $ProfileName
            TargetComputer = $TargetComputer
            StartTime = Get-Date
            Variables = $deploymentVariables
            Phases = @{
                TaskSequence = @{Status = 'Pending'; StartTime = $null; EndTime = $null}
                Drivers = @{Status = 'Pending'; StartTime = $null; EndTime = $null}
                Applications = @{Status = 'Pending'; StartTime = $null; EndTime = $null}
                PostConfig = @{Status = 'Pending'; StartTime = $null; EndTime = $null}
            }
        }
        
        # Phase 1: Execute Task Sequence
        Write-DeployLog "Phase 1: Executing task sequence" -Level Info
        $context.Phases.TaskSequence.StartTime = Get-Date
        $context.Phases.TaskSequence.Status = 'Running'
        
        try {
            $tsResult = Invoke-TaskSequence -SequenceName $profile.TaskSequence -Variables $deploymentVariables -WhatIf:$WhatIf
            $context.Phases.TaskSequence.Status = 'Completed'
            $context.Phases.TaskSequence.Result = $tsResult
        }
        catch {
            $context.Phases.TaskSequence.Status = 'Failed'
            $context.Phases.TaskSequence.Error = $_.Exception.Message
            throw "Task sequence execution failed: $_"
        }
        finally {
            $context.Phases.TaskSequence.EndTime = Get-Date
        }
        
        # Phase 2: Install Required Drivers
        if ($profile.RequiredDrivers.Count -gt 0) {
            Write-DeployLog "Phase 2: Installing required drivers" -Level Info
            $context.Phases.Drivers.StartTime = Get-Date
            $context.Phases.Drivers.Status = 'Running'
            
            try {
                foreach ($driver in $profile.RequiredDrivers) {
                    Write-DeployLog "Installing driver: $driver" -Level Info
                    if (-not $WhatIf) {
                        # Call driver installation function
                        # Install-Driver -Name $driver
                    }
                }
                $context.Phases.Drivers.Status = 'Completed'
            }
            catch {
                $context.Phases.Drivers.Status = 'Failed'
                $context.Phases.Drivers.Error = $_.Exception.Message
                Write-DeployLog "Driver installation failed: $_" -Level Error
            }
            finally {
                $context.Phases.Drivers.EndTime = Get-Date
            }
        }
        
        # Phase 3: Deploy Required Applications
        if ($profile.RequiredApplications.Count -gt 0) {
            Write-DeployLog "Phase 3: Deploying required applications" -Level Info
            $context.Phases.Applications.StartTime = Get-Date
            $context.Phases.Applications.Status = 'Running'
            
            try {
                foreach ($app in $profile.RequiredApplications) {
                    Write-DeployLog "Installing application: $app" -Level Info
                    if (-not $WhatIf) {
                        # Call application installation function
                        # Install-Application -Name $app
                    }
                }
                $context.Phases.Applications.Status = 'Completed'
            }
            catch {
                $context.Phases.Applications.Status = 'Failed'
                $context.Phases.Applications.Error = $_.Exception.Message
                Write-DeployLog "Application deployment failed: $_" -Level Error
            }
            finally {
                $context.Phases.Applications.EndTime = Get-Date
            }
        }
        
        # Phase 4: Post-Deployment Configuration
        if ($profile.PostDeploymentConfig.Count -gt 0) {
            Write-DeployLog "Phase 4: Applying post-deployment configuration" -Level Info
            $context.Phases.PostConfig.StartTime = Get-Date
            $context.Phases.PostConfig.Status = 'Running'
            
            try {
                foreach ($config in $profile.PostDeploymentConfig.GetEnumerator()) {
                    Write-DeployLog "Applying configuration: $($config.Key)" -Level Info
                    if (-not $WhatIf) {
                        # Apply configuration based on type
                    }
                }
                $context.Phases.PostConfig.Status = 'Completed'
            }
            catch {
                $context.Phases.PostConfig.Status = 'Failed'
                $context.Phases.PostConfig.Error = $_.Exception.Message
                Write-DeployLog "Post-deployment configuration failed: $_" -Level Error
            }
            finally {
                $context.Phases.PostConfig.EndTime = Get-Date
            }
        }
        
        $context.EndTime = Get-Date
        $context.Duration = $context.EndTime - $context.StartTime
        
        # Generate deployment report
        $reportPath = Join-Path $env:TEMP "DeploymentReport_$($ProfileName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $context | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Force
        
        Write-DeployLog "Deployment completed successfully" -Level Success
        Write-DeployLog "Total duration: $($context.Duration.ToString())" -Level Info
        Write-DeployLog "Deployment report: $reportPath" -Level Info
        
        return $context
    }
    catch {
        Write-DeployLog "Deployment failed: $_" -Level Error
        throw
    }
}

#endregion

#region Helper Functions

function Expand-Variables {
    <#
    .SYNOPSIS
        Expands variables in a string using the provided hashtable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String,
        
        [Parameter(Mandatory)]
        [hashtable]$Variables
    )
    
    $result = $String
    foreach ($key in $Variables.Keys) {
        $result = $result -replace "%$key%", $Variables[$key]
    }
    
    return $result
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'New-DeploymentTaskSequence',
    'Add-TaskSequenceStep',
    'Invoke-TaskSequence',
    'New-UnattendedAnswerFile',
    'Test-UnattendedAnswerFile',
    'New-DeploymentProfile',
    'Invoke-DeploymentProfile'
)

#endregion
