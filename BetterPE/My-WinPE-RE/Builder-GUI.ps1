Add-Type -AssemblyName PresentationFramework

# Load Build Engine Modules
Import-Module "D:\My-Win[PE][RE]\BuildEngine\Logger.psm1"      -Force
Import-Module "D:\My-Win[PE][RE]\BuildEngine\Progress.psm1"    -Force
Import-Module "D:\My-Win[PE][RE]\BuildEngine\Downloader.psm1"  -Force
Import-Module "D:\My-Win[PE][RE]\BuildEngine\Drivers.psm1"      -Force
Import-Module "D:\My-Win[PE][RE]\BuildEngine\WimBuilder.psm1"   -Force
Import-Module "D:\My-Win[PE][RE]\BuildEngine\ISOBuilder.psm1"   -Force

function LaunchBuilderGUI {

    $Window           = New-Object System.Windows.Window
    $Window.Title     = "Ultimate PE/RE/Hybrid Build System"
    $Window.Height    = 560
    $Window.Width     = 720
    $Window.Background = "#1E1E1E"
    $Window.WindowStartupLocation = "CenterScreen"

    $Grid = New-Object System.Windows.Controls.Grid
    $Window.Content = $Grid
    $Grid.Margin = 20

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = "Ultimate Build Console"
    $title.FontSize = 28
    $title.HorizontalAlignment = "Center"
    $title.Foreground = "White"
    $title.Margin = "0,10,0,20"
    $Grid.Children.Add($title)

    $buttons = @(
        "Build WinPE",
        "Build WinRE",
        "Build Hybrid",
        "Build Combined WIM",
        "Build Multi-Boot ISO",
        "Run Full Build",
        "Open Output Folder",
        "Exit"
    )

    $row = 1
    foreach ($label in $buttons) {

        $Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $label
        $btn.Height = 50
        $btn.FontSize = 18
        $btn.Background = "#353535"
        $btn.Foreground = "White"
        $btn.Margin = "0,5,0,5"
        $btn.Tag = $label

        $btn.Add_Click({
            switch ($this.Tag) {
                "Build WinPE"          { Build-WinPE }
                "Build WinRE"          { Build-WinRE }
                "Build Hybrid"         { Build-Hybrid }
                "Build Combined WIM"   { Build-Combined }
                "Build Multi-Boot ISO" { Build-ISO }
                "Run Full Build"       { Build-All }
                "Open Output Folder"   { Start-Process "D:\My-Win[PE][RE]\Output" }
                "Exit"                 { $Window.Close() }
            }
        })

        $Grid.Children.Add($btn)
        [System.Windows.Controls.Grid]::SetRow($btn,$row)
        $row++
    }

    $Window.ShowDialog()
}

LaunchBuilderGUI