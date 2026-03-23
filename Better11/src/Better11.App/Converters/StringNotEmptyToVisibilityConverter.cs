// Copyright (c) Better11. All rights reserved.

using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Data;

namespace Better11.App.Converters;

/// <summary>
/// Converts a string to <see cref="Visibility"/>. Visible when non-empty, Collapsed when null or empty.
/// </summary>
public sealed class StringNotEmptyToVisibilityConverter : IValueConverter
{
    /// <inheritdoc/>
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return string.IsNullOrWhiteSpace(value as string) ? Visibility.Collapsed : Visibility.Visible;
    }

    /// <inheritdoc/>
    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotSupportedException();
    }
}
