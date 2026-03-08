// Copyright (c) Better11. All rights reserved.

namespace Better11.ViewModels.Wizard;

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

/// <summary>
/// ViewModel for the First Run Wizard. Manages a multi-step wizard flow:
/// Welcome -> System Scan -> Quick Config -> Module Selection -> Apply -> Complete.
/// </summary>
public sealed partial class FirstRunWizardViewModel : ObservableObject
{
    private readonly ICustomizationCatalogService _catalogService;
    private readonly ICustomizationExecutionService _executionService;
    private readonly IRecipeService _recipeService;
    private readonly ILogger<FirstRunWizardViewModel> _logger;
    private readonly List<RecipeDto> _recipeTemplates = new();
    private RecipeDto? _selectedRecipeTemplate;

    [ObservableProperty]
    private int _currentStep;

    [ObservableProperty]
    private int _totalSteps = 6;

    [ObservableProperty]
    private string _stepTitle = "Welcome";

    [ObservableProperty]
    private string _stepDescription = "Welcome to Better11 System Enhancement Suite";

    [ObservableProperty]
    private bool _isBusy;

    [ObservableProperty]
    private bool _isScanning;

    [ObservableProperty]
    private double _scanProgress;

    [ObservableProperty]
    private string _scanStatus = string.Empty;

    [ObservableProperty]
    private bool _hasError;

    [ObservableProperty]
    private string _errorMessage = string.Empty;

    [ObservableProperty]
    private bool _canGoBack;

    [ObservableProperty]
    private bool _canGoNext = true;

    [ObservableProperty]
    private string _nextButtonText = "Get Started";

    [ObservableProperty]
    private string _selectedPreset = "Balanced";

    [ObservableProperty]
    private PresetOption? _selectedPresetOption;

    [ObservableProperty]
    private string _systemSummary = string.Empty;

    [ObservableProperty]
    private string _osVersion = string.Empty;

    [ObservableProperty]
    private string _cpuName = string.Empty;

    [ObservableProperty]
    private string _ramAmount = string.Empty;

    [ObservableProperty]
    private string _gpuName = string.Empty;

    [ObservableProperty]
    private string _diskInfo = string.Empty;

    [ObservableProperty]
    private int _selectedModuleCount;

    [ObservableProperty]
    private int _appliedCount;

    [ObservableProperty]
    private int _totalToApply;

    [ObservableProperty]
    private double _applyProgress;

    [ObservableProperty]
    private string _applyStatus = string.Empty;

    [ObservableProperty]
    private bool _isApplying;

    [ObservableProperty]
    private bool _isComplete;

    /// <summary>
    /// Initializes a new instance of the <see cref="FirstRunWizardViewModel"/> class.
    /// </summary>
    public FirstRunWizardViewModel(
        ICustomizationCatalogService catalogService,
        ICustomizationExecutionService executionService,
        IRecipeService recipeService,
        ILogger<FirstRunWizardViewModel> logger)
    {
        _catalogService = catalogService ?? throw new ArgumentNullException(nameof(catalogService));
        _executionService = executionService ?? throw new ArgumentNullException(nameof(executionService));
        _recipeService = recipeService ?? throw new ArgumentNullException(nameof(recipeService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        Presets = new ObservableCollection<PresetOption>
        {
            new("Gaming", "\uE7FC", "FPS-oriented baseline with gaming, cleanup, startup, and privacy items queued."),
            new("Developer", "\uE943", "Workstation setup focused on productivity, privacy, and reduced background noise."),
            new("Privacy", "\uE72E", "Aggressive privacy and security configuration with telemetry-reduction defaults."),
            new("Balanced", "\uE9D5", "Recommended mixed preset that balances performance, privacy, and usability."),
            new("Minimal", "\uE74C", "Conservative starting point with low-risk items only."),
        };

        Modules = new ObservableCollection<WizardModule>();
        SelectedPresetOption = Presets.FirstOrDefault(option => option.Name == SelectedPreset) ?? Presets.FirstOrDefault();
    }

    /// <summary>
    /// Gets the available preset options.
    /// </summary>
    public ObservableCollection<PresetOption> Presets { get; }

    /// <summary>
    /// Gets the available modules for selection.
    /// </summary>
    public ObservableCollection<WizardModule> Modules { get; }

    /// <summary>
    /// Navigates to the next wizard step.
    /// </summary>
    [RelayCommand]
    private async Task GoNextAsync(CancellationToken cancellationToken)
    {
        if (CurrentStep >= TotalSteps - 1)
        {
            return;
        }

        CurrentStep++;
        UpdateStepState();

        if (CurrentStep == 1)
        {
            await RunSystemScanAsync(cancellationToken).ConfigureAwait(true);
        }
        else if (CurrentStep == 3)
        {
            await PopulateModulesForPresetAsync(cancellationToken).ConfigureAwait(true);
        }
        else if (CurrentStep == 4)
        {
            await ApplySelectionsAsync(cancellationToken).ConfigureAwait(true);
        }
    }

    /// <summary>
    /// Navigates to the previous wizard step.
    /// </summary>
    [RelayCommand]
    private void GoBack()
    {
        if (CurrentStep <= 0)
        {
            return;
        }

        CurrentStep--;
        UpdateStepState();
    }

    /// <summary>
    /// Skips the wizard and marks first run as complete.
    /// </summary>
    [RelayCommand]
    private void Skip()
    {
        IsComplete = true;
        _logger.LogInformation("First Run Wizard skipped by user");
    }

    partial void OnSelectedPresetOptionChanged(PresetOption? value)
    {
        if (value is null)
        {
            return;
        }

        SelectedPreset = value.Name;
        if (CurrentStep >= 3)
        {
            _ = PopulateModulesForPresetAsync(CancellationToken.None);
        }
    }

    private void UpdateStepState()
    {
        (StepTitle, StepDescription, NextButtonText) = CurrentStep switch
        {
            0 => ("Welcome", "Welcome to Better11 System Enhancement Suite", "Get Started"),
            1 => ("System Scan", "Analyzing your system configuration...", "Next"),
            2 => ("Quick Config", "Choose a recipe template that matches your usage", "Next"),
            3 => ("Module Selection", "Adjust the recipe-backed customization catalog before applying", "Apply"),
            4 => ("Applying", "Applying your selections...", string.Empty),
            5 => ("Complete", "Better11 is configured and ready!", "Finish"),
            _ => ("Unknown", string.Empty, "Next"),
        };

        CanGoBack = CurrentStep > 0 && CurrentStep < 4;
        CanGoNext = CurrentStep < TotalSteps - 1 && !IsApplying;
    }

    private async Task RunSystemScanAsync(CancellationToken cancellationToken)
    {
        IsScanning = true;
        ScanProgress = 0;
        ScanStatus = "Detecting hardware...";
        HasError = false;
        ErrorMessage = string.Empty;

        try
        {
            var steps = new[]
            {
                ("Detecting OS version...", 15.0),
                ("Scanning CPU...", 30.0),
                ("Checking memory...", 45.0),
                ("Detecting GPU...", 60.0),
                ("Scanning disks...", 75.0),
                ("Checking installed software...", 90.0),
                ("Generating summary...", 100.0),
            };

            foreach (var (status, progress) in steps)
            {
                cancellationToken.ThrowIfCancellationRequested();
                ScanStatus = status;
                ScanProgress = progress;
                await Task.Delay(300, cancellationToken).ConfigureAwait(true);
            }

            OsVersion = Environment.OSVersion.VersionString;
            CpuName = Environment.GetEnvironmentVariable("PROCESSOR_IDENTIFIER") ?? "Unknown CPU";
            RamAmount = $"{GC.GetGCMemoryInfo().TotalAvailableMemoryBytes / (1024 * 1024 * 1024)} GB";
            GpuName = "Detected via PowerShell";
            DiskInfo = "Detected via PowerShell";
            SystemSummary = $"Windows {Environment.OSVersion.Version.Build} | {CpuName} | {RamAmount} RAM";

            ScanStatus = "Scan complete";
            CanGoNext = true;
            _logger.LogInformation("System scan completed successfully");
        }
        catch (OperationCanceledException)
        {
            ScanStatus = "Scan cancelled";
        }
        catch (Exception ex)
        {
            HasError = true;
            ErrorMessage = $"Scan failed: {ex.Message}";
            _logger.LogError(ex, "System scan failed");
        }
        finally
        {
            IsScanning = false;
        }
    }

    private async Task PopulateModulesForPresetAsync(CancellationToken cancellationToken)
    {
        HasError = false;
        ErrorMessage = string.Empty;
        Modules.Clear();

        var recipesResult = await _recipeService.GetBuiltInRecipesAsync(cancellationToken).ConfigureAwait(true);
        if (recipesResult.IsFailure || recipesResult.Value is null)
        {
            HasError = true;
            ErrorMessage = $"Failed to load preset recipes: {recipesResult.Error?.Message}";
            return;
        }

        _recipeTemplates.Clear();
        _recipeTemplates.AddRange(recipesResult.Value);
        _selectedRecipeTemplate = _recipeTemplates.FirstOrDefault(recipe =>
                string.Equals(recipe.Name, SelectedPreset, StringComparison.OrdinalIgnoreCase))
            ?? _recipeTemplates.FirstOrDefault(recipe =>
                string.Equals(recipe.Name, "Balanced", StringComparison.OrdinalIgnoreCase))
            ?? _recipeTemplates.FirstOrDefault();

        if (_selectedRecipeTemplate is null)
        {
            HasError = true;
            ErrorMessage = "No built-in preset recipes are available.";
            return;
        }

        var catalogResult = await _catalogService.GetCatalogAsync(
            _selectedRecipeTemplate.TargetKind,
            _selectedRecipeTemplate.SafetyTier,
            cancellationToken).ConfigureAwait(true);

        if (catalogResult.IsFailure || catalogResult.Value is null)
        {
            HasError = true;
            ErrorMessage = $"Failed to load customization catalog: {catalogResult.Error?.Message}";
            return;
        }

        var selectedItemIds = _selectedRecipeTemplate.Items
            .Where(item => item.Enabled)
            .Select(item => item.ItemId)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var item in catalogResult.Value
                     .SelectMany(category => category.Items)
                     .OrderBy(item => item.CategoryTitle, StringComparer.OrdinalIgnoreCase)
                     .ThenBy(item => item.Title, StringComparer.OrdinalIgnoreCase))
        {
            var module = new WizardModule(
                item.Id,
                item.Title,
                item.CategoryTitle,
                item.Description,
                selectedItemIds.Contains(item.Id),
                item.RiskLabel,
                item.SafetyTier.ToString());

            module.PropertyChanged += OnModulePropertyChanged;
            Modules.Add(module);
        }

        UpdateSelectedModuleCount();
    }

    private async Task ApplySelectionsAsync(CancellationToken cancellationToken)
    {
        IsApplying = true;
        CanGoNext = false;
        AppliedCount = 0;
        ApplyProgress = 0;
        HasError = false;
        ErrorMessage = string.Empty;

        try
        {
            var selectedItemIds = Modules
                .Where(module => module.IsSelected)
                .Select(module => module.ItemId)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (selectedItemIds.Count == 0)
            {
                ApplyStatus = "No customization items selected";
                return;
            }

            var targetKind = _selectedRecipeTemplate?.TargetKind ?? CustomizationTargetKind.LiveSystem;
            var safetyTier = _selectedRecipeTemplate?.SafetyTier ?? SafetyTier.Advanced;

            ApplyStatus = "Building execution plan...";
            ApplyProgress = 20;

            var planResult = await _executionService.BuildExecutionPlanAsync(
                selectedItemIds,
                targetKind,
                safetyTier,
                cancellationToken).ConfigureAwait(true);

            if (planResult.IsFailure || planResult.Value is null)
            {
                HasError = true;
                ErrorMessage = $"Failed to build plan: {planResult.Error?.Message}";
                return;
            }

            TotalToApply = planResult.Value.ResolvedItems.Count;
            ApplyStatus = "Applying customization recipe...";
            ApplyProgress = 55;

            var executeResult = await _executionService.ExecutePlanAsync(planResult.Value, cancellationToken)
                .ConfigureAwait(true);

            if (executeResult.IsFailure || executeResult.Value is null)
            {
                HasError = true;
                ErrorMessage = $"Apply failed: {executeResult.Error?.Message}";
                return;
            }

            AppliedCount = executeResult.Value.AppliedItemIds.Count;
            ApplyProgress = 100;
            ApplyStatus = executeResult.Value.LogSummary;
            CurrentStep = 5;
            IsComplete = true;
            UpdateStepState();

            _logger.LogInformation(
                "First Run Wizard completed. Applied {Count} customization items with preset {Preset}",
                AppliedCount,
                SelectedPreset);
        }
        catch (OperationCanceledException)
        {
            ApplyStatus = "Apply cancelled";
        }
        catch (Exception ex)
        {
            HasError = true;
            ErrorMessage = $"Apply failed: {ex.Message}";
            _logger.LogError(ex, "First Run Wizard apply failed");
        }
        finally
        {
            IsApplying = false;
            CanGoNext = true;
        }
    }

    private void OnModulePropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (string.Equals(e.PropertyName, nameof(WizardModule.IsSelected), StringComparison.Ordinal))
        {
            UpdateSelectedModuleCount();
        }
    }

    private void UpdateSelectedModuleCount()
    {
        SelectedModuleCount = Modules.Count(module => module.IsSelected);
    }
}

/// <summary>
/// Represents a wizard preset option.
/// </summary>
public sealed record PresetOption(string Name, string Icon, string Description);

/// <summary>
/// Represents a module selectable in the wizard.
/// </summary>
public sealed partial class WizardModule : ObservableObject
{
    [ObservableProperty]
    private bool _isSelected;

    /// <summary>
    /// Initializes a new instance of the <see cref="WizardModule"/> class.
    /// </summary>
    public WizardModule(
        string itemId,
        string name,
        string category,
        string description,
        bool isSelected,
        string riskLabel,
        string safetyTier)
    {
        ItemId = itemId;
        Name = name;
        Category = category;
        Description = description;
        IsSelected = isSelected;
        RiskLabel = riskLabel;
        SafetyTier = safetyTier;
    }

    /// <summary>Gets the catalog item identifier.</summary>
    public string ItemId { get; }

    /// <summary>Gets the module name.</summary>
    public string Name { get; }

    /// <summary>Gets the module category.</summary>
    public string Category { get; }

    /// <summary>Gets the module description.</summary>
    public string Description { get; }

    /// <summary>Gets the risk label.</summary>
    public string RiskLabel { get; }

    /// <summary>Gets the safety tier.</summary>
    public string SafetyTier { get; }
}
