# Interactive Help System

function Get-DeploymentHelp {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Topic
    )

    $helpTopics = @{
        'getting-started' = @{
            Title = 'Getting Started'
            Content = @'
Welcome to Better11 Deployment Toolkit!

Quick Start:
1. Run the configuration wizard: .\scripts\Start-ConfigurationWizard.ps1
2. Set up your deployment share: .\scripts\Initialize-DeploymentShare.ps1
3. Launch the control center: Start-DeployCenter

For more information, use: Get-DeploymentHelp -Topic <topic-name>
'@
        }
        'task-sequences' = @{
            Title = 'Task Sequences'
            Content = @'
Task sequences define the steps for deploying Windows.

Available task sequences:
- baremetal-basic: Basic bare-metal deployment
- baremetal-with-drivers: Deployment with driver injection
- postsetup-optimize-dev: Post-setup optimization
- refresh-deployment: Refresh existing installation
- upgrade-deployment: In-place upgrade

To run a task sequence:
Invoke-TaskSequence -TaskSequenceId <id>
'@
        }
        'modules' = @{
            Title = 'Modules'
            Content = @'
The toolkit consists of the following modules:

- Deployment.Core: Core utilities and logging
- Deployment.Imaging: Disk and image management
- Deployment.Drivers: Hardware detection and driver injection
- Deployment.Packages: Application installation
- Deployment.Optimization: System optimization
- Deployment.Health: Health monitoring
- Deployment.TaskSequence: Task orchestration
- Deployment.UI: User interface
- Deployment.Validation: Pre-flight validation
- Deployment.Network: Network deployment (PXE/WDS)
- Deployment.Integration: MDT/SCCM integration
- Deployment.Cloud: Cloud deployment (Azure/AWS)
- Deployment.DSC: DSC integration

Import modules with: Import-Module <ModuleName>
'@
        }
        'configuration' = @{
            Title = 'Configuration'
            Content = @'
Configuration files are stored in the configs directory:

- configs/task_sequences/: Task sequence definitions
- configs/drivers/catalog.json: Driver catalog
- configs/apps/apps.json: Application catalog
- configs/optimize/: Optimization profiles

Environment Variables:
- DEPLOY_SHARE: Deployment share root path
- WIM_PATH: Windows installation WIM file path
'@
        }
    }

    if ($Topic) {
        if ($helpTopics.ContainsKey($Topic)) {
            $topicData = $helpTopics[$Topic]
            Write-Host ''
            Write-Host "=== $($topicData.Title) ===" -ForegroundColor Cyan
            Write-Host ''
            Write-Host $topicData.Content
            Write-Host ''
        }
        else {
            Write-Host "Topic not found: $Topic" -ForegroundColor Yellow
            Write-Host "Available topics: $($helpTopics.Keys -join ', ')" -ForegroundColor Gray
        }
    }
    else {
        Write-Host ''
        Write-Host '=== Better11 Deployment Toolkit Help ===' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'Available help topics:' -ForegroundColor Yellow
        foreach ($key in $helpTopics.Keys) {
            Write-Host "  - $key" -ForegroundColor White
        }
        Write-Host ''
        Write-Host 'Usage: Get-DeploymentHelp -Topic <topic-name>' -ForegroundColor Gray
        Write-Host ''
    }
}

# Export function
Export-ModuleMember -Function Get-DeploymentHelp

