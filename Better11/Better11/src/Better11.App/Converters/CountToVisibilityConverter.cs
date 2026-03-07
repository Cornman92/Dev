// Copyright (c) Better11. All rights reserved.

using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Data;

namespace Better11.App.Converters;

/// <summary>
/// Converts a numeric count to <see cref="Visibility"/>. Visible when count > 0, Collapsed when 0.
/// </summary>
public sealed class CountToVisibilityConverter : IValueConverter
{
    /// <summary>
    /// Gets or sets a value indicating whether the conversion is inverted.
    /// When true, 0 maps to Visible and non-zero maps to Collapsed.
    /// </summary>
    public bool IsInverted { get; set; }

    /// <inheritdoc/>
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        var count = value switch
        {
            int i => i,
            long l => (int)l,
            double d => (int)d,
            _ => 0,
        };

        var hasItems = count > 0;
        return (hasItems ^ IsInverted) ? Visibility.Visible : Visibility.Collapsed;
    }

    /// <inheritdoc/>
    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotSupportedException();
    }
}
