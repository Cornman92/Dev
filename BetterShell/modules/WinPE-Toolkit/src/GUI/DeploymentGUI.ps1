# Deployment GUI - WPF-based graphical interface

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

function Show-DeploymentGUI {
    [CmdletBinding()]
    param()

    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $env:PSModulePath = "$modulePath;$env:PSModulePath"

    Import-Module Deployment.Core -Force
    Import-Module Deployment.UI -Force

    # Create main window
    $window = New-Object System.Windows.Window
    $window.Title = "Better11 Deployment Toolkit"
    $window.Width = 900
    $window.Height = 600
    $window.WindowStartupLocation = "CenterScreen"

    # Create main grid
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = New-Object System.Windows.Thickness(10)

    # Define rows
    $row1 = New-Object System.Windows.Controls.RowDefinition
    $row1.Height = New-Object System.Windows.GridLength(1, "Auto")
    $row2 = New-Object System.Windows.Controls.RowDefinition
    $row2.Height = New-Object System.Windows.GridLength(1, "*")
    $grid.RowDefinitions.Add($row1)
    $grid.RowDefinitions.Add($row2)

    # Header
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = "Better11 Deployment Toolkit"
    $header.FontSize = 24
    $header.FontWeight = "Bold"
    $header.Margin = New-Object System.Windows.Thickness(0, 0, 0, 20)
    $grid.Children.Add($header)
    [System.Windows.Controls.Grid]::SetRow($header, 0)

    # Main content area
    $tabControl = New-Object System.Windows.Controls.TabControl
    $grid.Children.Add($tabControl)
    [System.Windows.Controls.Grid]::SetRow($tabControl, 1)

    # Task Sequences Tab
    $tsTab = New-Object System.Windows.Controls.TabItem
    $tsTab.Header = "Task Sequences"
    $tsTabContent = New-Object System.Windows.Controls.StackPanel
    $tsTabContent.Margin = New-Object System.Windows.Thickness(10)

    $tsListBox = New-Object System.Windows.Controls.ListBox
    $tsListBox.Height = 300
    $tsListBox.Margin = New-Object System.Windows.Thickness(0, 0, 0, 10)

    try {
        Import-Module Deployment.TaskSequence -Force
        $catalog = Get-TaskSequenceCatalog
        foreach ($ts in $catalog) {
            $tsListBox.Items.Add($ts.name) | Out-Null
        }
    }
    catch {
        $tsListBox.Items.Add("Error loading task sequences: $($_.Exception.Message)") | Out-Null
    }

    $runButton = New-Object System.Windows.Controls.Button
    $runButton.Content = "Run Selected Task Sequence"
    $runButton.Height = 30
    $runButton.Add_Click({
        if ($tsListBox.SelectedItem) {
            [System.Windows.MessageBox]::Show("Running: $($tsListBox.SelectedItem)", "Deployment", "OK", "Information")
        }
    })

    $tsTabContent.Children.Add($tsListBox) | Out-Null
    $tsTabContent.Children.Add($runButton) | Out-Null
    $tsTab.Content = $tsTabContent
    $tabControl.Items.Add($tsTab) | Out-Null

    # Hardware Tab
    $hwTab = New-Object System.Windows.Controls.TabItem
    $hwTab.Header = "Hardware"
    $hwTabContent = New-Object System.Windows.Controls.TextBlock
    $hwTabContent.Margin = New-Object System.Windows.Thickness(10)
    $hwTabContent.TextWrapping = "Wrap"

    try {
        Import-Module Deployment.Drivers -Force
        $hw = Get-HardwareProfile
        $hwTabContent.Text = "Manufacturer: $($hw.Manufacturer)`nModel: $($hw.Model)`nCPU: $($hw.CPUName)`nMemory: $([math]::Round($hw.TotalMemory / 1GB, 1)) GB"
    }
    catch {
        $hwTabContent.Text = "Error loading hardware information: $($_.Exception.Message)"
    }

    $hwTab.Content = $hwTabContent
    $tabControl.Items.Add($hwTab) | Out-Null

    # Logs Tab
    $logsTab = New-Object System.Windows.Controls.TabItem
    $logsTab.Header = "Logs"
    $logsTabContent = New-Object System.Windows.Controls.TextBox
    $logsTabContent.IsReadOnly = $true
    $logsTabContent.VerticalScrollBarVisibility = "Auto"
    $logsTabContent.Text = "Deployment logs will appear here..."
    $logsTab.Content = $logsTabContent
    $tabControl.Items.Add($logsTab) | Out-Null

    $window.Content = $grid
    $window.ShowDialog() | Out-Null
}

# Run GUI if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Show-DeploymentGUI
}

