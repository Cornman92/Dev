Add-Type -AssemblyName PresentationFramework

function Start-GUI {
    # Create Window
    $Window = New-Object System.Windows.Window
    $Window.Title = "Ultimate PE/RE/Hybrid Build Console"
    $Window.Height = 530
    $Window.Width = 700
    $Window.WindowStartupLocation = "CenterScreen"
    $Window.ResizeMode = "NoResize"
    $Window.Background = "#1e1e1e"

    # Grid Container
    $Grid = New-Object System.Windows.Controls.Grid
    $Grid.Margin = 20
    $Window.Content = $Grid

    # Title
    $Title = New-Object System.Windows.Controls.TextBlock
    $Title.Text = "Ultimate Build System"
    $Title.FontSize = 26
    $Title.Foreground = "White"
    $Title.HorizontalAlignment = "Center"
    $Title.Margin = "0,10,0,20"
    $Grid.Children.Add($Title)

    # Create Buttons
    $buttonLabels = @(
        "Build WinPE",
        "Build WinRE",
        "Build Hybrid",
        "Build Combined WIM",
        "Make Multi-Boot ISO",
        "Run Full Build Process",
        "Open Output Folder",
        "Exit"
    )

    $row = 1

    foreach ($label in $buttonLabels) {

        # Row allocation
        $Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $label
        $btn.Margin = "0,5,0,5"
        $btn.FontSize = 18
        $btn.Height = 45
        $btn.Foreground = "White"
        $btn.Background = "#444"
        $btn.Tag = $label

        $btn.Add_Click({
            param($sender,$args)
            $task = $sender.Tag

            switch ($task) {
                "Build WinPE"          { Build-WinPE }
                "Build WinRE"          { Build-WinRE }
                "Build Hybrid"         { Build-Hybrid }
                "Build Combined WIM"   { Build-Combined }
                "Make Multi-Boot ISO"  { Build-ISO }
                "Run Full Build Process" { Build-All }
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

Start-GUI