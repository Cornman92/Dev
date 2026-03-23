// Copyright (c) Better11. All rights reserved.

using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Better11.App.Controls;

/// <summary>
/// A compact settings card with icon, title, description, and an action content slot.
/// Used for dense settings/configuration rows throughout the Better11 UI.
/// </summary>
public sealed partial class CompactSettingsCard : UserControl
{
    /// <summary>
    /// Dependency property for the card title.
    /// </summary>
    public static readonly DependencyProperty TitleProperty =
        DependencyProperty.Register(nameof(Title), typeof(string), typeof(CompactSettingsCard),
            new PropertyMetadata(string.Empty, OnTitleChanged));

    /// <summary>
    /// Dependency property for the card description.
    /// </summary>
    public static readonly DependencyProperty DescriptionProperty =
        DependencyProperty.Register(nameof(Description), typeof(string), typeof(CompactSettingsCard),
            new PropertyMetadata(string.Empty, OnDescriptionChanged));

    /// <summary>
    /// Dependency property for the icon glyph.
    /// </summary>
    public static readonly DependencyProperty GlyphProperty =
        DependencyProperty.Register(nameof(Glyph), typeof(string), typeof(CompactSettingsCard),
            new PropertyMetadata(string.Empty, OnGlyphChanged));

    /// <summary>
    /// Dependency property for the action content (e.g., ToggleSwitch, Button, ComboBox).
    /// </summary>
    public static readonly DependencyProperty ActionContentProperty =
        DependencyProperty.Register(nameof(ActionContent), typeof(object), typeof(CompactSettingsCard),
            new PropertyMetadata(null));

    /// <summary>
    /// Initializes a new instance of the <see cref="CompactSettingsCard"/> class.
    /// </summary>
    public CompactSettingsCard()
    {
        this.InitializeComponent();
    }

    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    /// <summary>
    /// Gets or sets the card description.
    /// </summary>
    public string Description
    {
        get => (string)GetValue(DescriptionProperty);
        set => SetValue(DescriptionProperty, value);
    }

    /// <summary>
    /// Gets or sets the icon glyph character.
    /// </summary>
    public string Glyph
    {
        get => (string)GetValue(GlyphProperty);
        set => SetValue(GlyphProperty, value);
    }

    /// <summary>
    /// Gets or sets the action content (ToggleSwitch, Button, ComboBox, etc.).
    /// </summary>
    public object ActionContent
    {
        get => GetValue(ActionContentProperty);
        set => SetValue(ActionContentProperty, value);
    }

    private static void OnTitleChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is CompactSettingsCard card)
        {
            card.TitleText.Text = e.NewValue as string ?? string.Empty;
        }
    }

    private static void OnDescriptionChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is CompactSettingsCard card)
        {
            var desc = e.NewValue as string ?? string.Empty;
            card.DescriptionText.Text = desc;
            card.DescriptionText.Visibility = string.IsNullOrEmpty(desc) ? Visibility.Collapsed : Visibility.Visible;
        }
    }

    private static void OnGlyphChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is CompactSettingsCard card)
        {
            var glyph = e.NewValue as string ?? string.Empty;
            card.CardIcon.Glyph = glyph;
            card.CardIcon.Visibility = string.IsNullOrEmpty(glyph) ? Visibility.Collapsed : Visibility.Visible;
        }
    }
}
