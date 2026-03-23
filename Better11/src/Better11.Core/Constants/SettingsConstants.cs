// Copyright (c) Better11. All rights reserved.

namespace Better11.Core.Constants;

/// <summary>
/// Constants for application settings keys used with <see cref="Better11.Core.Interfaces.ISettingsService"/>.
/// </summary>
public static class SettingsConstants
{
    /// <summary>Key indicating whether the first-run wizard has been completed.</summary>
    public const string FirstRunCompleted = "FirstRunCompleted";

    /// <summary>Key for the user-selected application theme (Dark, Light, or System).</summary>
    public const string SelectedTheme = "SelectedTheme";

    /// <summary>Key indicating whether automatic data refresh is enabled.</summary>
    public const string AutoRefreshEnabled = "AutoRefreshEnabled";

    /// <summary>Key for the automatic refresh interval in seconds.</summary>
    public const string AutoRefreshIntervalSeconds = "AutoRefreshIntervalSeconds";

    /// <summary>Key for the date/time of the last system scan.</summary>
    public const string LastScanDate = "LastScanDate";

    /// <summary>Key for the currently selected optimization preset.</summary>
    public const string SelectedPreset = "SelectedPreset";

    /// <summary>Key for the list of applied optimization modules.</summary>
    public const string AppliedModules = "AppliedModules";

    /// <summary>Key indicating whether anonymous usage telemetry is enabled (opt-in).</summary>
    public const string Telemetry = "Telemetry";
}
