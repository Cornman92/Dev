// ============================================================================
// File: src/Better11.ViewModels/Optimization/OptimizationViewModel.cs
// Better11 System Enhancement Suite — Optimization ViewModel
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Optimization;

/// <summary>
/// ViewModel for the system optimization page.
/// </summary>
public sealed partial class OptimizationViewModel : BaseViewModel
{
    private readonly IOptimizationService _optimizationService;
    private readonly ILogger<OptimizationViewModel> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="OptimizationViewModel"/> class.
    /// </summary>
    /// <param name="optimizationService">The optimization service.</param>
    /// <exception cref="ArgumentNullException">Thrown when optimizationService is null.</exception>
    public OptimizationViewModel(IOptimizationService optimizationService, ILogger<OptimizationViewModel> logger)
        : base(logger)
    {
        _optimizationService = optimizationService
            ?? throw new ArgumentNullException(nameof(optimizationService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        PageTitle = "System Optimization";
    }

    /// <summary>Gets the optimization categories.</summary>
    public ObservableCollection<OptimizationCategoryDto> Categories { get; } = new();

    /// <summary>Gets or sets the last optimization result.</summary>
    [ObservableProperty]
    private OptimizationResultDto? _lastResult;

    /// <summary>Gets or sets a value indicating whether a reboot is required.</summary>
    [ObservableProperty]
    private bool _rebootRequired;

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken)
    {
        await LoadCategoriesAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Loads optimization categories.</summary>
    [RelayCommand]
    private async Task LoadCategoriesAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _optimizationService.GetCategoriesAsync(ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    var categories = result.Value!
                        .Select(category => new OptimizationCategoryDto
                        {
                            Name = category.Name,
                            Description = category.Description,
                            Tweaks = category.Tweaks
                                .Select(tweak => new TweakDto
                                {
                                    Id = tweak.Id,
                                    Name = tweak.Name,
                                    Description = tweak.Description,
                                    IsApplied = tweak.IsApplied,
                                    IsSelected = !tweak.IsApplied,
                                    RiskLevel = tweak.RiskLevel,
                                })
                                .ToList(),
                        })
                        .ToList();

                    RunOnUIThread(() =>
                    {
                        Categories.Clear();
                        foreach (var category in categories)
                        {
                            Categories.Add(category);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading optimization categories...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Applies selected optimizations.</summary>
    [RelayCommand]
    private async Task ApplyOptimizationsAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var selectedTweakIds = Categories
                    .SelectMany(c => c.Tweaks)
                    .Where(t => t.IsSelected && !t.IsApplied)
                    .Select(t => t.Id)
                    .ToList();

                if (selectedTweakIds.Count == 0)
                {
                    ErrorMessage = "No optimizations selected to apply.";
                    return;
                }

                var restoreResult = await _optimizationService.CreateRestorePointAsync(
                    "Better11 Optimization",
                    ct).ConfigureAwait(false);

                if (!restoreResult.IsSuccess)
                {
                    ErrorMessage = $"Failed to create restore point: {restoreResult.Error?.Message}";
                    return;
                }

                var result = await _optimizationService.ApplyOptimizationsAsync(
                    selectedTweakIds,
                    ct).ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    LastResult = result.Value;
                    RebootRequired = result.Value!.RebootRequired;
                    SuccessMessage = $"Applied {result.Value.TweaksApplied} optimizations successfully.";
                    await LoadCategoriesAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Applying optimizations...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Creates a system restore point.</summary>
    [RelayCommand]
    private async Task CreateRestorePointAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _optimizationService.CreateRestorePointAsync(
                    "Better11 Manual Restore Point",
                    ct).ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    SuccessMessage = $"Restore point created: {result.Value}";
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Creating restore point...",
            cancellationToken).ConfigureAwait(false);
    }
}
