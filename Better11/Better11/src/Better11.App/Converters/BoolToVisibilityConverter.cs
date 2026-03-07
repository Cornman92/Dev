// Copyright (c) Better11. All rights reserved.

using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Data;

namespace Better11.App.Converters;

/// <summary>
/// Converts a boolean value to a <see cref="Visibility"/> value.
/// </summary>
public sealed class BoolToVisibilityConverter : IValueConverter
{
    /// <summary>
    /// Gets or sets a value indicating whether the conversion is inverted.
    /// When true, false maps to Visible and true maps to Collapsed.
    /// </summary>
    public bool IsInverted { get; set; }

    /// <inheritdoc/>
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        if (value is bool boolValue)
        {
            return (boolValue ^ IsInverted) ? Visibility.Visible : Visibility.Collapsed;
        }

        return Visibility.Collapsed;
    }

    /// <inheritdoc/>
    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        if (value is Visibility visibility)
        {
            return (visibility == Visibility.Visible) ^ IsInverted;
        }

        return false;
    }
}
