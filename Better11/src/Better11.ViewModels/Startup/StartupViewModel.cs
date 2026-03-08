// ============================================================================
// File: src/Better11.ViewModels/Startup/StartupViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Startup;

/// <summary>
/// ViewModel for the Startup Manager page. Provides startup item enumeration,
/// enable/disable/remove actions, search filtering, and summary counts.
/// </summary>
public sealed partial class StartupViewModel : BaseViewModel
{
    private readonly IStartupService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="StartupViewModel"/> class.
    /// </summary>
    public StartupViewModel(IStartupService service, ILogger<StartupViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "Startup Manager";
    }

    // ================================================================ Collections

    /// <summary>Gets the startup items collection.</summary>
    public ObservableCollection<StartupItemDto> StartupItems { get; } = new();

    // ============================================================= Properties

    /// <summary>Gets or sets the currently selected startup item.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(SelectedCount))]
    private StartupItemDto? _selectedItem;

    /// <summary>Gets or sets the search query used to filter startup items.</summary>
    [ObservableProperty]
    private string _searchQuery = string.Empty;

    /// <summary>Gets or sets the number of enabled startup items.</summary>
    [ObservableProperty]
    private int _enabledCount;

    /// <summary>Gets or sets the number of disabled startup items.</summary>
    [ObservableProperty]
    private int _disabledCount;

    /// <summary>Gets or sets the total item count.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(TotalItems))]
    private int _totalCount;

    /// <summary>Gets total items (alias for TotalCount for XAML binding).</summary>
    public int TotalItems => TotalCount;

    /// <summary>Gets or sets whether all items are selected (header checkbox).</summary>
    [ObservableProperty]
    private bool _isAllSelected;

    /// <summary>Gets the number of selected items (0 or 1 when using single selection).</summary>
    public int SelectedCount => SelectedItem is null ? 0 : 1;

    /// <summary>Gets or sets the startup impact filter (empty = all).</summary>
    [ObservableProperty]
    private string _impactFilter = string.Empty;

    /// <summary>Gets the number of items matching the current search filter.</summary>
    public int FilteredCount => StartupItems.Count(MatchesFilter);

    // ================================================================ Lifecycle

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken);
    }

    // ================================================================ Commands

    /// <summary>Loads all startup items from the service.</summary>
    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetStartupItemsAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        StartupItems.Clear();
                        foreach (var item in result.Value) { StartupItems.Add(item); }
                        RecalculateCounts();
                    });
                }
                else { SetErrorFromResult(result); }
            },
            "Loading startup items...",
            cancellationToken);
    }

    /// <summary>Enables the currently selected startup item.</summary>
    [RelayCommand]
    private async Task EnableItemAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedItem is null) { return; }
        var itemId = SelectedItem.Id;
        var name = SelectedItem.Name;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.EnableStartupItemAsync(itemId, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Enabled {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Enabling {name}...",
            cancellationToken);
    }

    /// <summary>Disables the currently selected startup item.</summary>
    [RelayCommand]
    private async Task DisableItemAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedItem is null) { return; }
        var itemId = SelectedItem.Id;
        var name = SelectedItem.Name;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.DisableStartupItemAsync(itemId, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Disabled {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Disabling {name}...",
            cancellationToken);
    }

    /// <summary>Toggles the selected startup item between enabled and disabled.</summary>
    [RelayCommand]
    private async Task ToggleSelectedAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedItem is null) { return; }

        if (SelectedItem.IsEnabled) { await DisableItemAsync(cancellationToken); }
        else { await EnableItemAsync(cancellationToken); }
    }

    /// <summary>Permanently removes the currently selected startup item.</summary>
    [RelayCommand]
    private async Task RemoveItemAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedItem is null) { return; }
        var itemId = SelectedItem.Id;
        var name = SelectedItem.Name;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.RemoveStartupItemAsync(itemId, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Removed {name}.");
                    SelectedItem = null;
                    await LoadDataAsync(ct);
                }
                else { SetErrorFromResult(result); }
            },
            $"Removing {name}...",
            cancellationToken);
    }

    // ================================================================ Helpers

    private bool MatchesFilter(StartupItemDto item)
    {
        var matchesSearch = string.IsNullOrWhiteSpace(SearchQuery)
            || item.Name.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
            || item.Publisher.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
            || item.Command.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase);

        var matchesImpact = string.IsNullOrWhiteSpace(ImpactFilter)
            || item.Impact.Equals(ImpactFilter, StringComparison.OrdinalIgnoreCase);

        return matchesSearch && matchesImpact;
    }

    private void RecalculateCounts()
    {
        TotalCount = StartupItems.Count;
        EnabledCount = StartupItems.Count(i => i.IsEnabled);
        DisabledCount = StartupItems.Count(i => !i.IsEnabled);
        OnPropertyChanged(nameof(FilteredCount));
        OnPropertyChanged(nameof(TotalItems));
    }

    /// <summary>Refresh command (alias for LoadData).</summary>
    [RelayCommand]
    private async Task RefreshAsync(CancellationToken cancellationToken = default)
        => await LoadDataAsync(cancellationToken).ConfigureAwait(false);

    /// <summary>Enables the selected item(s). Bound as EnableSelectedCommand.</summary>
    [RelayCommand]
    private async Task EnableSelectedAsync(CancellationToken cancellationToken = default)
        => await EnableItemAsync(cancellationToken).ConfigureAwait(false);

    /// <summary>Disables the selected item(s). Bound as DisableSelectedCommand.</summary>
    [RelayCommand]
    private async Task DisableSelectedAsync(CancellationToken cancellationToken = default)
        => await DisableItemAsync(cancellationToken).ConfigureAwait(false);
}
