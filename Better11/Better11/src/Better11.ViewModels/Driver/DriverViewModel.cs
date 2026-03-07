// ============================================================================
// File: src/Better11.ViewModels/Driver/DriverViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Driver;

/// <summary>
/// ViewModel for the Driver Manager page. Provides driver inventory,
/// update scanning, per-driver update/backup/rollback, and category filtering.
/// </summary>
public sealed partial class DriverViewModel : BaseViewModel
{
    private readonly IDriverService _service;
    private const string DefaultBackupPath = @"%LOCALAPPDATA%\Better11\DriverBackups";

    /// <summary>
    /// Initializes a new instance of the <see cref="DriverViewModel"/> class.
    /// </summary>
    public DriverViewModel(IDriverService service, ILogger<DriverViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "Driver Manager";
    }

    // ================================================================ Collections

    /// <summary>Gets the installed drivers collection.</summary>
    public ObservableCollection<DriverDto> InstalledDrivers { get; } = new();

    /// <summary>Gets the outdated drivers that have pending updates.</summary>
    public ObservableCollection<DriverDto> OutdatedDrivers { get; } = new();

    /// <summary>Gets the distinct category names from installed drivers.</summary>
    public ObservableCollection<string> Categories { get; } = new();

    // ============================================================= Properties

    /// <summary>Gets or sets the currently selected driver.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(SelectedCount))]
    private DriverDto? _selectedDriver;

    /// <summary>Gets or sets the search query used to filter drivers.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(FilteredDriverCount))]
    private string _searchQuery = string.Empty;

    /// <summary>Gets or sets the selected category filter.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(FilteredDriverCount))]
    private string _categoryFilter = string.Empty;

    /// <summary>Gets or sets a value indicating whether an update scan is in progress.</summary>
    [ObservableProperty]
    private bool _isScanning;

    /// <summary>Gets or sets the driver count summary text.</summary>
    [ObservableProperty]
    private string _driverCountSummary = string.Empty;

    /// <summary>Gets the number of drivers matching the current filter.</summary>
    public int FilteredDriverCount => InstalledDrivers.Count(MatchesFilter);

    /// <summary>Total installed drivers (for XAML binding).</summary>
    public int TotalDrivers => InstalledDrivers.Count;

    /// <summary>Count of drivers that are up to date (for XAML binding).</summary>
    public int UpToDateCount => InstalledDrivers.Count - OutdatedDrivers.Count;

    /// <summary>Count of drivers with updates available (for XAML binding).</summary>
    public int UpdatesAvailableCount => OutdatedDrivers.Count;

    /// <summary>Count of drivers with problems (for XAML binding).</summary>
    public int ProblemCount => 0;

    /// <summary>Select all in list (for XAML binding).</summary>
    [ObservableProperty]
    private bool _isAllSelected;

    /// <summary>Drivers list for list view (alias for InstalledDrivers).</summary>
    public ObservableCollection<DriverDto> Drivers => InstalledDrivers;

    /// <summary>Number of selected drivers (single selection: 0 or 1).</summary>
    public int SelectedCount => SelectedDriver is null ? 0 : 1;

    // ================================================================ Lifecycle

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken);
    }

    // ================================================================ Commands

    /// <summary>Refresh / load drivers (alias for LoadData).</summary>
    [RelayCommand]
    private async Task RefreshAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken);
    }

    /// <summary>Scan for driver updates (alias for ScanForUpdates).</summary>
    [RelayCommand]
    private async Task ScanDriversAsync(CancellationToken cancellationToken = default)
    {
        await ScanForUpdatesAsync(cancellationToken);
    }

    /// <summary>Loads all installed drivers from the service.</summary>
    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetInstalledDriversAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        InstalledDrivers.Clear();
                        Categories.Clear();
                        foreach (var item in result.Value) { InstalledDrivers.Add(item); }
                        foreach (var cat in result.Value.Select(d => d.Category).Distinct().OrderBy(c => c))
                        {
                            Categories.Add(cat);
                        }

                        UpdateSummary();
                    });
                }
                else { SetErrorFromResult(result); }
            },
            "Loading drivers...",
            cancellationToken);
    }

    /// <summary>Scans for available driver updates.</summary>
    [RelayCommand]
    private async Task ScanForUpdatesAsync(CancellationToken cancellationToken = default)
    {
        IsScanning = true;
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.ScanForUpdatesAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        OutdatedDrivers.Clear();
                        foreach (var item in result.Value) { OutdatedDrivers.Add(item); }
                        UpdateSummary();
                    });

                    SetSuccess(result.Value.Count == 0
                        ? "All drivers are up to date."
                        : $"Found {result.Value.Count} driver(s) with available updates.");
                }
                else { SetErrorFromResult(result); }
            },
            "Scanning for driver updates...",
            cancellationToken);
        IsScanning = false;
    }

    /// <summary>Updates the currently selected driver (alias for XAML).</summary>
    [RelayCommand]
    private async Task UpdateSelectedAsync(CancellationToken cancellationToken = default)
    {
        await UpdateSelectedDriverAsync(cancellationToken);
    }

    /// <summary>Updates the currently selected driver.</summary>
    [RelayCommand]
    private async Task UpdateSelectedDriverAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedDriver is null) { return; }
        var deviceId = SelectedDriver.DeviceId;
        var name = SelectedDriver.DeviceName;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.UpdateDriverAsync(deviceId, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Successfully updated {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Updating {name}...",
            cancellationToken);
    }

    /// <summary>Creates a backup of the currently selected driver.</summary>
    [RelayCommand]
    private async Task BackupSelectedDriverAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedDriver is null) { return; }
        var deviceId = SelectedDriver.DeviceId;
        var name = SelectedDriver.DeviceName;
        var backupPath = Environment.ExpandEnvironmentVariables(DefaultBackupPath);

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.BackupDriverAsync(deviceId, backupPath, ct)
                    .ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Backed up {name} to {result.Value}."); }
                else { SetErrorFromResult(result); }
            },
            $"Backing up {name}...",
            cancellationToken);
    }

    /// <summary>Backup all drivers (backs up selected or shows message).</summary>
    [RelayCommand]
    private async Task BackupAllAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedDriver is null)
        {
            SetSuccess("Select a driver to back up.");
            return;
        }

        await BackupSelectedDriverAsync(cancellationToken);
    }

    /// <summary>Export driver list (for XAML).</summary>
    [RelayCommand]
    private void Export()
    {
        SetSuccess("Export not implemented.");
    }

    /// <summary>Rolls back the currently selected driver to its previous version.</summary>
    [RelayCommand]
    private async Task RollbackSelectedDriverAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedDriver is null) { return; }
        var deviceId = SelectedDriver.DeviceId;
        var name = SelectedDriver.DeviceName;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.RollbackDriverAsync(deviceId, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Rolled back {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Rolling back {name}...",
            cancellationToken);
    }

    // ================================================================ Helpers

    private bool MatchesFilter(DriverDto driver)
    {
        var matchesSearch = string.IsNullOrWhiteSpace(SearchQuery)
            || driver.DeviceName.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
            || driver.Manufacturer.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase);

        var matchesCategory = string.IsNullOrWhiteSpace(CategoryFilter)
            || driver.Category.Equals(CategoryFilter, StringComparison.OrdinalIgnoreCase);

        return matchesSearch && matchesCategory;
    }

    private void UpdateSummary()
    {
        var total = InstalledDrivers.Count;
        var outdated = OutdatedDrivers.Count;
        DriverCountSummary = outdated > 0
            ? $"{total} drivers installed, {outdated} update(s) available"
            : $"{total} drivers installed";
        OnPropertyChanged(nameof(FilteredDriverCount));
        OnPropertyChanged(nameof(TotalDrivers));
        OnPropertyChanged(nameof(UpToDateCount));
        OnPropertyChanged(nameof(UpdatesAvailableCount));
    }
}
