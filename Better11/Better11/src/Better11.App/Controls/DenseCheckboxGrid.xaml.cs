// Copyright (c) Better11. All rights reserved.

using System.Collections;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Better11.App.Controls;

/// <summary>
/// A dense checkbox grid control for displaying toggleable items in a compact grid layout.
/// Inspired by WinUtil's checkbox-heavy interface for system tweaks.
/// </summary>
public sealed partial class DenseCheckboxGrid : UserControl
{
    /// <summary>
    /// Dependency property for the section header text.
    /// </summary>
    public static readonly DependencyProperty HeaderProperty =
        DependencyProperty.Register(nameof(Header), typeof(string), typeof(DenseCheckboxGrid),
            new PropertyMetadata(string.Empty, OnHeaderChanged));

    /// <summary>
    /// Dependency property for the items source.
    /// </summary>
    public static readonly DependencyProperty ItemsSourceProperty =
        DependencyProperty.Register(nameof(ItemsSource), typeof(IEnumerable), typeof(DenseCheckboxGrid),
            new PropertyMetadata(null, OnItemsSourceChanged));

    /// <summary>
    /// Initializes a new instance of the <see cref="DenseCheckboxGrid"/> class.
    /// </summary>
    public DenseCheckboxGrid()
    {
        this.InitializeComponent();
    }

    /// <summary>
    /// Gets or sets the section header text.
    /// </summary>
    public string Header
    {
        get => (string)GetValue(HeaderProperty);
        set => SetValue(HeaderProperty, value);
    }

    /// <summary>
    /// Gets or sets the items source.
    /// </summary>
    public IEnumerable ItemsSource
    {
        get => (IEnumerable)GetValue(ItemsSourceProperty);
        set => SetValue(ItemsSourceProperty, value);
    }

    private static void OnHeaderChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is DenseCheckboxGrid grid)
        {
            grid.HeaderText.Text = e.NewValue as string ?? string.Empty;
        }
    }

    private static void OnItemsSourceChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is DenseCheckboxGrid grid)
        {
            grid.CheckboxRepeater.ItemsSource = e.NewValue as IEnumerable;
            grid.UpdateCount();
        }
    }

    private void SelectAll_Click(object sender, RoutedEventArgs e)
    {
        SetAllChecked(true);
    }

    private void SelectNone_Click(object sender, RoutedEventArgs e)
    {
        SetAllChecked(false);
    }

    private void SetAllChecked(bool isChecked)
    {
        if (ItemsSource is null)
        {
            return;
        }

        foreach (var item in ItemsSource)
        {
            var prop = item.GetType().GetProperty("IsSelected");
            prop?.SetValue(item, isChecked);
        }
    }

    private void UpdateCount()
    {
        var count = 0;
        if (ItemsSource is not null)
        {
            foreach (var unused in ItemsSource)
            {
                count++;
            }
        }

        CountText.Text = $"({count} items)";
    }
}
