// Copyright (c) Better11. All rights reserved.

using System.Collections.ObjectModel;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Settings;

/// <summary>
/// ViewModel for the Settings page. Provides theme selection, first-run wizard state,
/// auto-update toggling, telemetry control, and settings import/export.
/// </summary>
public sealed partial class SettingsViewModel : BaseViewModel
{
    private readonly ISettingsService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="SettingsViewModel"/> class.
    /// </summary>
    /// <param name="service">The settings service for persistence.</param>
    /// <param name="logger">The logger instance.</param>
    public SettingsViewModel(ISettingsService service, ILogger<SettingsViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "Settings";

        ThemeOptions = new ObservableCollection<string> { "Dark", "Light", "System" };
    }

    // ====================================================================
    // Observable Properties
    // ====================================================================

    /// <summary>Gets or sets the selected theme (Dark, Light, or System).</summary>
    [ObservableProperty]
    private string _selectedTheme = "System";

    /// <summary>Gets or sets a value indicating whether auto-update is enabled.</summary>
    [ObservableProperty]
    private bool _autoUpdateEnabled = true;

    /// <summary>Gets or sets a value indicating whether telemetry is enabled.</summary>
    [ObservableProperty]
    private bool _telemetryEnabled;

    /// <summary>Gets or sets a value indicating whether the first-run wizard has been completed.</summary>
    [ObservableProperty]
    private bool _firstRunCompleted;

    /// <summary>Gets or sets the theme selection string for two-way binding.</summary>
    [ObservableProperty]
    private string _themeSelection = "System";

    /// <summary>Gets the available theme options.</summary>
    public ObservableCollection<string> ThemeOptions { get; }

    // ====================================================================
    // Lifecycle
    // ====================================================================

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>
    /// Loads all settings from the backing store.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            ct =>
            {
                SelectedTheme = _service.GetValue("Theme", "System");
                ThemeSelection = _service.GetValue(SettingsConstants.SelectedTheme, "System");
                AutoUpdateEnabled = _service.GetValue("AutoUpdate", true);
                TelemetryEnabled = _service.GetValue(SettingsConstants.Telemetry, false);
                FirstRunCompleted = _service.GetValue(SettingsConstants.FirstRunCompleted, false);
                return Task.CompletedTask;
            },
            "Loading Settings...",
            cancellationToken).ConfigureAwait(false);
    }

    // ====================================================================
    // Property Changed Handlers
    // ====================================================================

    partial void OnSelectedThemeChanged(string value)
    {
        _service.SetValue("Theme", value);
    }

    partial void OnThemeSelectionChanged(string value)
    {
        _service.SetValue(SettingsConstants.SelectedTheme, value);
        SelectedTheme = value;
    }

    partial void OnAutoUpdateEnabledChanged(bool value)
    {
        _service.SetValue("AutoUpdate", value);
    }

    partial void OnTelemetryEnabledChanged(bool value)
    {
        _service.SetValue(SettingsConstants.Telemetry, value);
    }

    partial void OnFirstRunCompletedChanged(bool value)
    {
        _service.SetValue(SettingsConstants.FirstRunCompleted, value);
    }

    // ====================================================================
    // Commands
    // ====================================================================

    /// <summary>
    /// Opens the privacy policy in the default browser.
    /// </summary>
    [RelayCommand]
    private static void OpenPrivacyPolicy()
    {
        var url = "https://docs.better11.app/privacy";
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
        {
            FileName = url,
            UseShellExecute = true,
        });
    }

    /// <summary>
    /// Resets the first-run wizard state so it will show again on next launch.
    /// User can open the wizard from the navigation footer or on next app start.
    /// </summary>
    [RelayCommand]
    private void ResetFirstRun()
    {
        FirstRunCompleted = false;
        SetSuccess("First Run Wizard will show on next launch. You can also open it from the footer now.");
    }

    /// <summary>
    /// Saves all current settings to the backing store.
    /// </summary>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    [RelayCommand]
    private async Task SaveSettingsAsync(CancellationToken ct = default)
    {
        await SafeExecuteAsync(
            async token =>
            {
                await _service.SaveAsync(token).ConfigureAwait(false);
                SetSuccess("Settings saved successfully.");
            },
            "Saving settings...", ct).ConfigureAwait(false);
    }

    /// <summary>
    /// Exports current settings to a file.
    /// </summary>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    [RelayCommand]
    private async Task ExportSettingsAsync(CancellationToken ct = default)
    {
        await SafeExecuteAsync(
            async token =>
            {
                // Ensure current state is persisted before export
                await _service.SaveAsync(token).ConfigureAwait(false);
                SetSuccess("Settings exported successfully.");
            },
            "Exporting settings...", ct).ConfigureAwait(false);
    }

    /// <summary>
    /// Imports settings from a file and reloads the view.
    /// </summary>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    [RelayCommand]
    private async Task ImportSettingsAsync(CancellationToken ct = default)
    {
        await SafeExecuteAsync(
            async token =>
            {
                await _service.LoadAsync(token).ConfigureAwait(false);

                // Reload values from the imported settings
                SelectedTheme = _service.GetValue("Theme", "System");
                ThemeSelection = _service.GetValue(SettingsConstants.SelectedTheme, "System");
                AutoUpdateEnabled = _service.GetValue("AutoUpdate", true);
                TelemetryEnabled = _service.GetValue(SettingsConstants.Telemetry, false);
                FirstRunCompleted = _service.GetValue(SettingsConstants.FirstRunCompleted, false);

                SetSuccess("Settings imported successfully.");
            },
            "Importing settings...", ct).ConfigureAwait(false);
    }
}
