// Copyright (c) Better11. All rights reserved.

using Microsoft.UI.Xaml.Data;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Better11.App.Converters;

/// <summary>
/// Converts severity level strings to corresponding theme colors.
/// Supports: Success, Warning, Error, Info, Critical.
/// </summary>
public sealed class SeverityToColorConverter : IValueConverter
{
    /// <inheritdoc/>
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        var severity = value?.ToString()?.ToUpperInvariant();

        var color = severity switch
        {
            "SUCCESS" or "OK" or "PASS" => Color.FromArgb(255, 46, 160, 67),    // #2EA043
            "WARNING" or "WARN" => Color.FromArgb(255, 210, 153, 34),            // #D29922
            "ERROR" or "FAIL" or "CRITICAL" => Color.FromArgb(255, 248, 81, 73), // #F85149
            "INFO" or "INFORMATION" => Color.FromArgb(255, 88, 166, 255),        // #58A6FF
            _ => Color.FromArgb(255, 170, 170, 170),                             // #AAAAAA
        };

        return new SolidColorBrush(color);
    }

    /// <inheritdoc/>
    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotSupportedException();
    }
}
