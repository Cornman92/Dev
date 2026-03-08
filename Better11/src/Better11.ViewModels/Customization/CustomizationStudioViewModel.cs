#pragma warning disable CS1591

using System.Collections.ObjectModel;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Customization;

/// <summary>
/// ViewModel for the shared customization studio.
/// </summary>
public sealed partial class CustomizationStudioViewModel : BaseViewModel
{
    private readonly ICustomizationCatalogService _catalogService;
    private readonly ICustomizationExecutionService _executionService;
    private readonly IRecipeService _recipeService;
    private readonly ISettingsService _settingsService;
    private readonly ILogger<CustomizationStudioViewModel> _logger;
    private readonly List<CatalogCategoryDto> _allCategories = new();

    private ExecutionPlanDto? _currentPlan;

    public CustomizationStudioViewModel(
        ICustomizationCatalogService catalogService,
        ICustomizationExecutionService executionService,
        IRecipeService recipeService,
        ISettingsService settingsService,
        ILogger<CustomizationStudioViewModel> logger)
        : base(logger)
    {
        _catalogService = catalogService ?? throw new ArgumentNullException(nameof(catalogService));
        _executionService = executionService ?? throw new ArgumentNullException(nameof(executionService));
        _recipeService = recipeService ?? throw new ArgumentNullException(nameof(recipeService));
        _settingsService = settingsService ?? throw new ArgumentNullException(nameof(settingsService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        PageTitle = "Customization Studio";

        TargetOptions = new ObservableCollection<CustomizationTargetKind>
        {
            CustomizationTargetKind.LiveSystem,
            CustomizationTargetKind.OfflineImage,
        };

        SafetyTierOptions = new ObservableCollection<SafetyTier>
        {
            SafetyTier.Basic,
            SafetyTier.Advanced,
            SafetyTier.Expert,
            SafetyTier.Lab,
        };
    }

    public ObservableCollection<CustomizationTargetKind> TargetOptions { get; }

    public ObservableCollection<SafetyTier> SafetyTierOptions { get; }

    public ObservableCollection<CatalogCategoryDto> CatalogCategories { get; } = new();

    public ObservableCollection<CatalogItemDto> VisibleItems { get; } = new();

    public ObservableCollection<CatalogItemDto> QueueItems { get; } = new();

    public ObservableCollection<string> PlanWarnings { get; } = new();

    public ObservableCollection<BlockedCustomizationItemDto> BlockedItems { get; } = new();

    public ObservableCollection<RecipeDto> Recipes { get; } = new();

    public ObservableCollection<RollbackEntryDto> RollbackHistory { get; } = new();

    [ObservableProperty]
    private CustomizationTargetKind _selectedTarget = CustomizationTargetKind.LiveSystem;

    [ObservableProperty]
    private SafetyTier _selectedSafetyTier = SafetyTier.Advanced;

    [ObservableProperty]
    private string _searchQuery = string.Empty;

    [ObservableProperty]
    private CatalogCategoryDto? _selectedCategory;

    [ObservableProperty]
    private CatalogItemDto? _selectedCatalogItem;

    [ObservableProperty]
    private RecipeDto? _selectedRecipe;

    [ObservableProperty]
    private RollbackEntryDto? _selectedRollbackEntry;

    [ObservableProperty]
    private string _planSummary = "Queue items and run Analyze to build a plan.";

    [ObservableProperty]
    private string _exportPath = string.Empty;

    public int QueueCount => QueueItems.Count;

    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        SelectedTarget = ParseTarget(
            _settingsService.GetValue(SettingsConstants.CustomizationTarget, nameof(CustomizationTargetKind.LiveSystem)));
        SelectedSafetyTier = ParseSafetyTier(
            _settingsService.GetValue(SettingsConstants.CustomizationSafetyTier, nameof(SafetyTier.Advanced)));

        await LoadStudioAsync(cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadStudioAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                _settingsService.SetValue(SettingsConstants.CustomizationTarget, SelectedTarget.ToString());
                _settingsService.SetValue(SettingsConstants.CustomizationSafetyTier, SelectedSafetyTier.ToString());

                var catalogResult = await _catalogService.GetCatalogAsync(SelectedTarget, SelectedSafetyTier, ct)
                    .ConfigureAwait(false);
                if (catalogResult.IsFailure)
                {
                    SetErrorFromResult(catalogResult);
                    return;
                }

                var categoryKey = SelectedCategory?.Key;
                RunOnUIThread(() =>
                {
                    _allCategories.Clear();
                    _allCategories.AddRange(catalogResult.Value!);

                    CatalogCategories.Clear();
                    foreach (var category in _allCategories)
                    {
                        CatalogCategories.Add(category);
                    }

                    SelectedCategory = CatalogCategories.FirstOrDefault(category =>
                            string.Equals(category.Key, categoryKey, StringComparison.OrdinalIgnoreCase))
                        ?? CatalogCategories.FirstOrDefault();
                });

                await LoadRecipesAsync(ct).ConfigureAwait(false);
                await LoadRollbackHistoryAsync(ct).ConfigureAwait(false);
                RefreshVisibleItems();
                await AnalyzeQueueAsync(ct).ConfigureAwait(false);
            },
            "Loading customization studio...",
            cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private void QueueSelectedItem()
    {
        if (SelectedCatalogItem is null || QueueItems.Any(item => item.Id == SelectedCatalogItem.Id))
        {
            return;
        }

        QueueItems.Add(SelectedCatalogItem);
        OnPropertyChanged(nameof(QueueCount));
    }

    [RelayCommand]
    private void RemoveQueuedItem(CatalogItemDto? item)
    {
        if (item is null)
        {
            return;
        }

        QueueItems.Remove(item);
        OnPropertyChanged(nameof(QueueCount));
    }

    [RelayCommand]
    private async Task AnalyzeQueueAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                if (QueueItems.Count == 0)
                {
                    RunOnUIThread(() =>
                    {
                        PlanWarnings.Clear();
                        BlockedItems.Clear();
                        PlanSummary = "Queue items and run Analyze to build a plan.";
                    });
                    _currentPlan = null;
                    return;
                }

                var planResult = await _executionService.BuildExecutionPlanAsync(
                    QueueItems.Select(item => item.Id).ToList(),
                    SelectedTarget,
                    SelectedSafetyTier,
                    ct).ConfigureAwait(false);

                if (planResult.IsFailure)
                {
                    SetErrorFromResult(planResult);
                    return;
                }

                _currentPlan = planResult.Value;
                RunOnUIThread(() =>
                {
                    PlanWarnings.Clear();
                    foreach (var warning in _currentPlan!.Warnings)
                    {
                        PlanWarnings.Add(warning);
                    }

                    BlockedItems.Clear();
                    foreach (var blockedItem in _currentPlan.BlockedItems)
                    {
                        BlockedItems.Add(blockedItem);
                    }

                    PlanSummary = $"{_currentPlan.ResolvedItems.Count} ready, {BlockedItems.Count} blocked, "
                        + $"{PlanWarnings.Count} warnings.";
                });
            },
            "Analyzing queue...",
            cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task ApplyPlanAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                if (_currentPlan is null || !_currentPlan.CanExecute)
                {
                    await AnalyzeQueueAsync(ct).ConfigureAwait(false);
                }

                if (_currentPlan is null || !_currentPlan.CanExecute)
                {
                    SetError("The current queue cannot be executed.");
                    return;
                }

                var executionResult = await _executionService.ExecutePlanAsync(_currentPlan, ct)
                    .ConfigureAwait(false);
                if (executionResult.IsFailure)
                {
                    SetErrorFromResult(executionResult);
                    return;
                }

                RunOnUIThread(() =>
                {
                    QueueItems.Clear();
                    OnPropertyChanged(nameof(QueueCount));
                    PlanSummary = executionResult.Value!.LogSummary;
                    ExportPath = string.Empty;
                });

                SetSuccess(executionResult.Value!.LogSummary);
                await LoadRollbackHistoryAsync(ct).ConfigureAwait(false);
                await LoadStudioAsync(ct).ConfigureAwait(false);
            },
            "Applying customization plan...",
            cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task QueueSelectedRecipeAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                if (SelectedRecipe is null)
                {
                    return;
                }

                var planResult = await _executionService.BuildExecutionPlanAsync(
                    SelectedRecipe.Items.Where(item => item.Enabled).Select(item => item.ItemId).ToList(),
                    SelectedRecipe.TargetKind,
                    SelectedRecipe.SafetyTier,
                    ct).ConfigureAwait(false);

                if (planResult.IsFailure)
                {
                    SetErrorFromResult(planResult);
                    return;
                }

                RunOnUIThread(() =>
                {
                    QueueItems.Clear();
                    foreach (var item in planResult.Value!.ResolvedItems)
                    {
                        QueueItems.Add(item);
                    }

                    OnPropertyChanged(nameof(QueueCount));
                    SelectedSafetyTier = SelectedRecipe.SafetyTier;
                });

                await AnalyzeQueueAsync(ct).ConfigureAwait(false);
            },
            "Loading recipe into queue...",
            cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task SaveQueueAsRecipeAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                if (QueueItems.Count == 0)
                {
                    SetError("Queue at least one item before saving a recipe.");
                    return;
                }

                var recipe = BuildRecipe("Custom Recipe", "Saved from the current studio queue.");
                var saveResult = await _recipeService.SaveRecipeAsync(recipe, ct).ConfigureAwait(false);
                if (saveResult.IsFailure)
                {
                    SetErrorFromResult(saveResult);
                    return;
                }

                SetSuccess($"Saved recipe '{recipe.Name}'.");
                await LoadRecipesAsync(ct).ConfigureAwait(false);
            },
            "Saving recipe...",
            cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task ExportQueueAsRecipeAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                if (QueueItems.Count == 0)
                {
                    SetError("Queue at least one item before exporting a recipe.");
                    return;
                }

                var recipe = BuildRecipe(
                    $"Customization-{DateTime.Now:yyyyMMdd-HHmmss}",
                    "Exported from the Better11 customization studio.");
                var outputPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
                    "Better11",
                    "Recipes",
                    $"{recipe.Name}.json");

                var exportResult = await _recipeService.ExportRecipeAsync(recipe, outputPath, ct).ConfigureAwait(false);
                if (exportResult.IsFailure)
                {
                    SetErrorFromResult(exportResult);
                    return;
                }

                ExportPath = exportResult.Value!;
                SetSuccess($"Exported recipe to {ExportPath}");
            },
            "Exporting recipe...",
            cancellationToken).ConfigureAwait(false);
    }

    [RelayCommand]
    private async Task LoadRollbackHistoryAsync(CancellationToken cancellationToken = default)
    {
        var historyResult = await _executionService.GetRollbackEntriesAsync(cancellationToken).ConfigureAwait(false);
        if (historyResult.IsFailure)
        {
            SetErrorFromResult(historyResult);
            return;
        }

        RunOnUIThread(() =>
        {
            RollbackHistory.Clear();
            foreach (var entry in historyResult.Value!)
            {
                RollbackHistory.Add(entry);
            }
        });
    }

    [RelayCommand]
    private async Task RollbackSelectedEntryAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                if (SelectedRollbackEntry is null)
                {
                    return;
                }

                var rollbackResult = await _executionService.RollbackAsync(SelectedRollbackEntry.Id, ct)
                    .ConfigureAwait(false);
                if (rollbackResult.IsFailure)
                {
                    SetErrorFromResult(rollbackResult);
                    return;
                }

                SetSuccess($"Rolled back '{SelectedRollbackEntry.Title}'.");
                await LoadRollbackHistoryAsync(ct).ConfigureAwait(false);
            },
            "Running rollback...",
            cancellationToken).ConfigureAwait(false);
    }

    partial void OnSearchQueryChanged(string value)
    {
        RefreshVisibleItems();
    }

    partial void OnSelectedCategoryChanged(CatalogCategoryDto? value)
    {
        RefreshVisibleItems();
    }

    partial void OnSelectedTargetChanged(CustomizationTargetKind value)
    {
        _ = LoadStudioAsync();
    }

    partial void OnSelectedSafetyTierChanged(SafetyTier value)
    {
        _ = LoadStudioAsync();
    }

    private async Task LoadRecipesAsync(CancellationToken cancellationToken)
    {
        var builtInResult = await _recipeService.GetBuiltInRecipesAsync(cancellationToken).ConfigureAwait(false);
        var savedResult = await _recipeService.GetSavedRecipesAsync(cancellationToken).ConfigureAwait(false);

        RunOnUIThread(() =>
        {
            Recipes.Clear();

            if (builtInResult.IsSuccess)
            {
                foreach (var recipe in builtInResult.Value!)
                {
                    Recipes.Add(recipe);
                }
            }

            if (savedResult.IsSuccess)
            {
                foreach (var recipe in savedResult.Value!)
                {
                    Recipes.Add(recipe);
                }
            }

            if (SelectedRecipe is null && Recipes.Count > 0)
            {
                SelectedRecipe = Recipes.FirstOrDefault(recipe => recipe.Name == "Balanced") ?? Recipes[0];
            }
        });
    }

    private void RefreshVisibleItems()
    {
        var items = SelectedCategory is null
            ? _allCategories.SelectMany(category => category.Items)
            : SelectedCategory.Items;

        if (!string.IsNullOrWhiteSpace(SearchQuery))
        {
            items = items.Where(item =>
                item.Title.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
                || item.Description.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)
                || item.Tags.Any(tag => tag.Contains(SearchQuery, StringComparison.OrdinalIgnoreCase)));
        }

        RunOnUIThread(() =>
        {
            VisibleItems.Clear();
            foreach (var item in items.OrderBy(item => item.Title, StringComparer.OrdinalIgnoreCase))
            {
                VisibleItems.Add(item);
            }

            SelectedCatalogItem = VisibleItems.FirstOrDefault();
        });
    }

    private RecipeDto BuildRecipe(string name, string description)
    {
        return new RecipeDto
        {
            Name = name,
            Description = description,
            Source = "User",
            TargetKind = SelectedTarget,
            SafetyTier = SelectedSafetyTier,
            Tags = new[] { "user", "studio" },
            Items = QueueItems
                .Select(item => new RecipeItemDto { ItemId = item.Id, Enabled = true })
                .ToList(),
        };
    }

    private static CustomizationTargetKind ParseTarget(string value)
    {
        return Enum.TryParse<CustomizationTargetKind>(value, true, out var result)
            ? result
            : CustomizationTargetKind.LiveSystem;
    }

    private static SafetyTier ParseSafetyTier(string value)
    {
        return Enum.TryParse<SafetyTier>(value, true, out var result)
            ? result
            : SafetyTier.Advanced;
    }
}

#pragma warning restore CS1591
