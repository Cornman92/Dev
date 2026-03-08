// ============================================================================
// File: src/Better11.ViewModels/ScheduledTask/ScheduledTaskViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.ScheduledTask;

/// <summary>
/// ViewModel for the Scheduled Tasks page. Provides task enumeration,
/// enable/disable/run actions, search filtering by name and state, and summary counts.
/// </summary>
public sealed partial class ScheduledTaskViewModel : BaseViewModel
{
    private readonly IScheduledTaskService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="ScheduledTaskViewModel"/> class.
    /// </summary>
    public ScheduledTaskViewModel(IScheduledTaskService service, ILogger<ScheduledTaskViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "Scheduled Tasks";
    }

    // ================================================================ Collections

    /// <summary>Gets the scheduled tasks collection.</summary>
    public ObservableCollection<ScheduledTaskDto> ScheduledTasks { get; } = new();

    /// <summary>Gets the distinct task states for filter options.</summary>
    public ObservableCollection<string> AvailableStates { get; } = new();

    // ============================================================= Properties

    /// <summary>Gets or sets the currently selected task.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(SelectedCount))]
    private ScheduledTaskDto? _selectedTask;

    /// <summary>Gets or sets the search query used to filter tasks.</summary>
    [ObservableProperty]
    private string _searchQuery = string.Empty;

    /// <summary>Gets or sets the state filter (e.g., "Ready", "Disabled", or empty for all).</summary>
    [ObservableProperty]
    private string _stateFilter = string.Empty;

    /// <summary>Gets or sets the total number of scheduled tasks.</summary>
    [ObservableProperty]
    private int _totalCount;

    /// <summary>Gets or sets the number of enabled (Ready) tasks.</summary>
    [ObservableProperty]
    private int _enabledCount;

    /// <summary>Gets or sets the number of disabled tasks.</summary>
    [ObservableProperty]
    private int _disabledCount;

    /// <summary>Gets or sets the task count summary text.</summary>
    [ObservableProperty]
    private string _taskCountSummary = string.Empty;

    /// <summary>Gets the number of tasks matching the current filters.</summary>
    public int FilteredCount => ScheduledTasks.Count(MatchesFilter);

    /// <summary>Filtered list for list view (alias).</summary>
    public ObservableCollection<ScheduledTaskDto> FilteredTasks => ScheduledTasks;

    /// <summary>Selected filter (alias for StateFilter).</summary>
    [ObservableProperty]
    private string _selectedFilter = string.Empty;

    /// <summary>Filter dropdown options (alias).</summary>
    public ObservableCollection<string> FilterOptions => AvailableStates;

    /// <summary>Select all (for XAML).</summary>
    [ObservableProperty]
    private bool _isAllSelected;

    /// <summary>Selected task count (0 or 1).</summary>
    public int SelectedCount => SelectedTask is null ? 0 : 1;

    // ================================================================ Lifecycle

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken);
    }

    // ================================================================ Commands

    [RelayCommand]
    private async Task RefreshAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken);
    }

    [RelayCommand]
    private async Task EnableSelectedAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedTask is null) { SetSuccess("Select a task first."); return; }
        await EnableTaskAsync(cancellationToken);
    }

    [RelayCommand]
    private async Task DisableSelectedAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedTask is null) { SetSuccess("Select a task first."); return; }
        await DisableTaskAsync(cancellationToken);
    }

    [RelayCommand]
    private void DeleteSelected()
    {
        SetSuccess("Delete task not implemented.");
    }

    /// <summary>Loads all scheduled tasks from the service.</summary>
    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetScheduledTasksAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        ScheduledTasks.Clear();
                        AvailableStates.Clear();
                        foreach (var item in result.Value) { ScheduledTasks.Add(item); }
                        foreach (var state in result.Value.Select(t => t.State).Distinct().OrderBy(s => s))
                        {
                            AvailableStates.Add(state);
                        }

                        RecalculateCounts();
                    });
                }
                else { SetErrorFromResult(result); }
            },
            "Loading scheduled tasks...",
            cancellationToken);
    }

    /// <summary>Enables the currently selected task.</summary>
    [RelayCommand]
    private async Task EnableTaskAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedTask is null) { return; }
        var taskPath = SelectedTask.TaskPath;
        var name = SelectedTask.TaskName;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.EnableTaskAsync(taskPath, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Enabled task: {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Enabling {name}...",
            cancellationToken);
    }

    /// <summary>Disables the currently selected task.</summary>
    [RelayCommand]
    private async Task DisableTaskAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedTask is null) { return; }
        var taskPath = SelectedTask.TaskPath;
        var name = SelectedTask.TaskName;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.DisableTaskAsync(taskPath, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Disabled task: {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Disabling {name}...",
            cancellationToken);
    }

    /// <summary>Immediately runs the currently selected task.</summary>
    [RelayCommand]
    private async Task RunNowAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedTask is null) { return; }
        var taskPath = SelectedTask.TaskPath;
        var name = SelectedTask.TaskName;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.RunTaskAsync(taskPath, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"Started task: {name}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            $"Running {name}...",
            cancellationToken);
    }

    // ================================================================ Helpers

    private bool MatchesFilter(ScheduledTaskDto task)
    {
        var matchesSearch = string.IsNullOrWhiteSpace(SearchQuery)
            || task.TaskName.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
            || task.Author.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
            || task.Description.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase);

        var matchesState = string.IsNullOrWhiteSpace(StateFilter)
            || task.State.Equals(StateFilter, StringComparison.OrdinalIgnoreCase);

        return matchesSearch && matchesState;
    }

    private void RecalculateCounts()
    {
        TotalCount = ScheduledTasks.Count;
        EnabledCount = ScheduledTasks.Count(t =>
            t.State.Equals("Ready", StringComparison.OrdinalIgnoreCase));
        DisabledCount = ScheduledTasks.Count(t =>
            t.State.Equals("Disabled", StringComparison.OrdinalIgnoreCase));
        TaskCountSummary = $"{TotalCount} tasks ({EnabledCount} enabled, {DisabledCount} disabled)";
        OnPropertyChanged(nameof(FilteredCount));
    }
}
