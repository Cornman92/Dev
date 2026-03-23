Add-Type -AssemblyName PresentationFramework

function MenuWindow {
    $Window = New-Object System.Windows.Window
    $Window.Title = "PE/RE Hybrid Shell"
    $Window.Height = 480
    $Window.Width = 600
    $Window.WindowStartupLocation = "CenterScreen"
    $Window.Background = "Black"

    $Grid = New-Object System.Windows.Controls.Grid
    $Window.Content = $Grid

    $Buttons = @(
        "Deployment Console",
        "Advanced Recovery Tools",
        "File Explorer++",
        "Hardware Diagnostics",
        "Network Tools",
        "Exit"
    )

    $i=0
    foreach ($b in $Buttons) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $b
        $btn.Margin = "20,20,20,0"
        $btn.Height = 50
        $btn.FontSize = 18
        $btn.VerticalAlignment = "Top"
        $btn.HorizontalAlignment = "Stretch"
        $btn.Tag = $b
        $btn.Add_Click({
            param($sender,$args)
            switch ($sender.Tag) {
                "Deployment Console" { & X:\Scripts\DeployConsole.ps1 }
                "Advanced Recovery Tools" { & X:\Scripts\RecoverySuite.ps1 }
                "File Explorer++" { Start-Process X:\Tools\Explorer++.exe }
                "Hardware Diagnostics" { Start-Process X:\Tools\HWiNFO.exe }
                "Network Tools" { Start-Process X:\Tools\PENetwork.exe }
                "Exit" { $Window.Close() }
            }
        })

        $Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $Grid.Children.Add($btn)
        [System.Windows.Controls.Grid]::SetRow($btn,$i)
        $i++
    }

    $Window.ShowDialog()
}

MenuWindow