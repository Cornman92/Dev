// ============================================================================
// File: src/Better11.ViewModels/Update/UpdateViewModel.cs
// Better11 System Enhancement Suite — Windows Update ViewModel
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Update;

/// <summary>
/// ViewModel for the Windows Update management page.
/// </summary>
public sealed partial class UpdateViewModel : BaseViewModel
{
    private readonly IUpdateService _updateService;
    private readonly ILogger<UpdateViewModel> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="UpdateViewModel"/> class.
    /// </summary>
    /// <param name="updateService">The update service.</param>
    /// <exception cref="ArgumentNullException">Thrown when updateService is null.</exception>
    public UpdateViewModel(IUpdateService updateService, ILogger<UpdateViewModel> logger)
        : base(logger)
    {
        _updateService = updateService
            ?? throw new ArgumentNullException(nameof(updateService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        PageTitle = "Windows Updates";
    }

    /// <summary>Gets available updates.</summary>
    public ObservableCollection<WindowsUpdateDto> AvailableUpdates { get; } = new();

    /// <summary>Gets update history.</summary>
    public ObservableCollection<WindowsUpdateDto> UpdateHistory { get; } = new();

    /// <summary>Gets or sets the total available update count.</summary>
    [ObservableProperty]
    private int _availableUpdateCount;

    /// <summary>Gets or sets the total download size text.</summary>
    [ObservableProperty]
    private string _totalSizeText = string.Empty;

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken)
    {
        await CheckForUpdatesAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Checks for available updates.</summary>
    [RelayCommand]
    private async Task CheckForUpdatesAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _updateService.CheckForUpdatesAsync(ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    var updates = result.Value!;
                    RunOnUIThread(() =>
                    {
                        AvailableUpdates.Clear();
                        foreach (var update in updates)
                        {
                            AvailableUpdates.Add(update);
                        }

                        AvailableUpdateCount = updates.Count;
                        var totalBytes = updates.Sum(u => u.SizeBytes);
                        TotalSizeText = FormatBytes(totalBytes);
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Checking for updates...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Installs all available updates.</summary>
    [RelayCommand]
    private async Task InstallAllUpdatesAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var updateIds = AvailableUpdates.Select(u => u.Id).ToList();
                if (updateIds.Count == 0)
                {
                    ErrorMessage = "No updates available to install.";
                    return;
                }

                var result = await _updateService.InstallUpdatesAsync(updateIds, ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    SuccessMessage = $"Successfully installed {updateIds.Count} update(s).";
                    await CheckForUpdatesAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Installing updates...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Loads update history.</summary>
    [RelayCommand]
    private async Task LoadHistoryAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _updateService.GetUpdateHistoryAsync(ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        UpdateHistory.Clear();
                        foreach (var update in result.Value!)
                        {
                            UpdateHistory.Add(update);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading update history...",
            cancellationToken).ConfigureAwait(false);
    }

    private static string FormatBytes(long bytes)
    {
        string[] suffixes = { "B", "KB", "MB", "GB", "TB" };
        int order = 0;
        double size = bytes;
        while (size >= 1024 && order < suffixes.Length - 1)
        {
            order++;
            size /= 1024;
        }

        return $"{size:0.##} {suffixes[order]}";
    }
}
