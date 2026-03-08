// ============================================================================
// File: src/Better11.ViewModels/Privacy/PrivacyViewModel.cs
// Better11 System Enhancement Suite — Privacy ViewModel
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Privacy;

/// <summary>
/// ViewModel for the privacy management page.
/// </summary>
public sealed partial class PrivacyViewModel : BaseViewModel
{
    private readonly IPrivacyService _privacyService;
    private readonly ILogger<PrivacyViewModel> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="PrivacyViewModel"/> class.
    /// </summary>
    /// <param name="privacyService">The privacy service.</param>
    /// <exception cref="ArgumentNullException">Thrown when privacyService is null.</exception>
    public PrivacyViewModel(IPrivacyService privacyService, ILogger<PrivacyViewModel> logger)
        : base(logger)
    {
        _privacyService = privacyService
            ?? throw new ArgumentNullException(nameof(privacyService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        PageTitle = "Privacy Controls";
    }

    /// <summary>Gets the privacy settings.</summary>
    public ObservableCollection<PrivacySettingDto> Settings { get; } = new();

    /// <summary>Gets or sets the privacy score.</summary>
    [ObservableProperty]
    private int _privacyScore;

    /// <summary>Gets or sets the current profile.</summary>
    [ObservableProperty]
    private string _currentProfile = string.Empty;

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken)
    {
        await LoadAuditAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Loads the privacy audit.</summary>
    [RelayCommand]
    private async Task LoadAuditAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _privacyService.GetPrivacyAuditAsync(ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    var audit = result.Value!;
                    RunOnUIThread(() =>
                    {
                        PrivacyScore = audit.Score;
                        CurrentProfile = audit.CurrentProfile;
                        Settings.Clear();
                        foreach (var setting in audit.Settings)
                        {
                            Settings.Add(setting);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading privacy audit...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Applies a privacy profile.</summary>
    [RelayCommand]
    private async Task ApplyProfileAsync(string profileName, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(profileName))
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _privacyService.ApplyPrivacyProfileAsync(profileName, ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    SuccessMessage = $"Privacy profile '{profileName}' applied successfully.";
                    await LoadAuditAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            $"Applying '{profileName}' profile...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Toggles a privacy setting.</summary>
    [RelayCommand]
    private async Task ToggleSettingAsync(PrivacySettingDto? setting, CancellationToken cancellationToken = default)
    {
        if (setting is null)
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _privacyService.SetPrivacySettingAsync(
                    setting.Id,
                    !setting.IsEnabled,
                    ct).ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    setting.IsEnabled = !setting.IsEnabled;
                    await LoadAuditAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Updating privacy setting...",
            cancellationToken).ConfigureAwait(false);
    }
}
