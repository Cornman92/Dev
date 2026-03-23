// Copyright (c) Better11. All rights reserved.

using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.ApplicationModel.DataTransfer;

namespace Better11.App.Controls;

/// <summary>
/// A console-style output panel with monospace text, auto-scroll, copy, and clear functionality.
/// Used throughout Better11 to display PowerShell command output.
/// </summary>
public sealed partial class ConsoleOutputPanel : UserControl
{
    /// <summary>
    /// Dependency property for the console title.
    /// </summary>
    public static readonly DependencyProperty TitleProperty =
        DependencyProperty.Register(nameof(Title), typeof(string), typeof(ConsoleOutputPanel),
            new PropertyMetadata("Output", OnTitleChanged));

    /// <summary>
    /// Dependency property for the output text content.
    /// </summary>
    public static readonly DependencyProperty OutputProperty =
        DependencyProperty.Register(nameof(Output), typeof(string), typeof(ConsoleOutputPanel),
            new PropertyMetadata(string.Empty, OnOutputChanged));

    /// <summary>
    /// Dependency property for the status text.
    /// </summary>
    public static readonly DependencyProperty StatusProperty =
        DependencyProperty.Register(nameof(Status), typeof(string), typeof(ConsoleOutputPanel),
            new PropertyMetadata("Ready", OnStatusChanged));

    private int _lineCount;

    /// <summary>
    /// Initializes a new instance of the <see cref="ConsoleOutputPanel"/> class.
    /// </summary>
    public ConsoleOutputPanel()
    {
        this.InitializeComponent();
    }

    /// <summary>
    /// Gets or sets the console panel title.
    /// </summary>
    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    /// <summary>
    /// Gets or sets the output text content.
    /// </summary>
    public string Output
    {
        get => (string)GetValue(OutputProperty);
        set => SetValue(OutputProperty, value);
    }

    /// <summary>
    /// Gets or sets the status bar text.
    /// </summary>
    public string Status
    {
        get => (string)GetValue(StatusProperty);
        set => SetValue(StatusProperty, value);
    }

    /// <summary>
    /// Appends a line to the output and auto-scrolls to the bottom.
    /// </summary>
    /// <param name="line">The line to append.</param>
    public void AppendLine(string line)
    {
        _lineCount++;
        OutputText.Text += line + Environment.NewLine;
        LineCountText.Text = $"Lines: {_lineCount}";
        OutputScroller.ChangeView(null, OutputScroller.ScrollableHeight, null);
    }

    /// <summary>
    /// Clears all output text.
    /// </summary>
    public void ClearOutput()
    {
        _lineCount = 0;
        OutputText.Text = string.Empty;
        LineCountText.Text = string.Empty;
        StatusText.Text = "Ready";
    }

    private static void OnTitleChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is ConsoleOutputPanel panel)
        {
            panel.TitleText.Text = e.NewValue as string ?? "Output";
        }
    }

    private static void OnOutputChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is ConsoleOutputPanel panel)
        {
            var text = e.NewValue as string ?? string.Empty;
            panel.OutputText.Text = text;
            panel._lineCount = text.Split('\n').Length;
            panel.LineCountText.Text = panel._lineCount > 0 ? $"Lines: {panel._lineCount}" : string.Empty;
            panel.OutputScroller.ChangeView(null, panel.OutputScroller.ScrollableHeight, null);
        }
    }

    private static void OnStatusChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is ConsoleOutputPanel panel)
        {
            panel.StatusText.Text = e.NewValue as string ?? "Ready";
        }
    }

    private void Copy_Click(object sender, RoutedEventArgs e)
    {
        var dataPackage = new DataPackage();
        dataPackage.SetText(OutputText.Text);
        Clipboard.SetContent(dataPackage);
        StatusText.Text = "Copied to clipboard";
    }

    private void Clear_Click(object sender, RoutedEventArgs e)
    {
        ClearOutput();
    }
}
