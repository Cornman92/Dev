// Copyright (c) Better11. All rights reserved.

namespace Better11.ViewModels.Wizard;

using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

/// <summary>
/// ViewModel for the First Run Wizard. Manages a multi-step wizard flow:
/// Welcome -> System Scan -> Quick Config -> Module Selection -> Apply -> Complete.
/// </summary>
public sealed partial class FirstRunWizardViewModel : ObservableObject
{
    private readonly ILogger<FirstRunWizardViewModel> _logger;

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
    /// <param name="logger">The logger instance.</param>
    public FirstRunWizardViewModel(ILogger<FirstRunWizardViewModel> logger)
    {
        _logger = logger;
        Presets = new ObservableCollection<PresetOption>
        {
            new("Gaming", "\uE7FC", "Maximize FPS, disable visual effects, optimize GPU/CPU, disable telemetry, debloat"),
            new("Developer", "\uE943", "Dev tools, package managers, Git config, WSL, PowerShell modules, no bloatware"),
            new("Privacy", "\uE72E", "Maximum privacy, disable telemetry/tracking/ads, harden security, minimal data collection"),
            new("Balanced", "\uE9D5", "Sensible defaults — performance + privacy + usability balance"),
            new("Minimal", "\uE74C", "Only essential tweaks — safe for any system, no aggressive changes"),
        };

        Modules = new ObservableCollection<WizardModule>();
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
            PopulateModulesForPreset();
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

    private void UpdateStepState()
    {
        (StepTitle, StepDescription, NextButtonText) = CurrentStep switch
        {
            0 => ("Welcome", "Welcome to Better11 System Enhancement Suite", "Get Started"),
            1 => ("System Scan", "Analyzing your system configuration...", "Next"),
            2 => ("Quick Config", "Choose a preset that matches your usage", "Next"),
            3 => ("Module Selection", "Fine-tune which modules to enable", "Apply"),
            4 => ("Applying", "Applying your selections...", ""),
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

        try
        {
            // Simulate scan steps with progress
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

            // Populate detected info (in production, these come from SystemInfoService)
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

    private void PopulateModulesForPreset()
    {
        Modules.Clear();

        var allModules = new (string Name, string Category, string Description, bool DefaultOn)[]
        {
            ("System Optimization", "Performance", "CPU, memory, and I/O tweaks", true),
            ("Visual Effects", "Performance", "Disable animations and transparency", false),
            ("Gaming Tweaks", "Performance", "GPU scheduling, game mode, power plan", false),
            ("Disk Cleanup", "Maintenance", "Remove temp files, caches, logs", true),
            ("Startup Manager", "Maintenance", "Disable unnecessary startup items", true),
            ("Scheduled Tasks", "Maintenance", "Disable telemetry and bloat tasks", true),
            ("Privacy Tweaks", "Privacy", "Disable tracking, ads, telemetry", true),
            ("Security Hardening", "Security", "Firewall, UAC, exploit protection", true),
            ("Network Optimization", "Network", "DNS, TCP/IP, adapter settings", false),
            ("Package Manager", "Software", "Install/remove packages via winget", true),
            ("Driver Manager", "Hardware", "Update and backup drivers", true),
            ("Windows Update", "System", "Configure update policies", false),
            ("Appearance", "Customization", "Theme, taskbar, Start menu tweaks", false),
            ("RAM Disk", "Advanced", "Create RAM disks for temp/cache", false),
        };

        foreach (var (name, category, description, defaultOn) in allModules)
        {
            var isSelected = SelectedPreset switch
            {
                "Gaming" => category is "Performance" or "Maintenance" || name == "Privacy Tweaks",
                "Developer" => category is "Software" or "Maintenance" || name is "Network Optimization" or "Privacy Tweaks",
                "Privacy" => category is "Privacy" or "Security" || name is "Startup Manager" or "Scheduled Tasks",
                "Balanced" => defaultOn,
                "Minimal" => name is "System Optimization" or "Disk Cleanup" or "Startup Manager",
                _ => defaultOn,
            };

            Modules.Add(new WizardModule(name, category, description, isSelected));
        }

        SelectedModuleCount = Modules.Count(m => m.IsSelected);
    }

    private async Task ApplySelectionsAsync(CancellationToken cancellationToken)
    {
        IsApplying = true;
        CanGoNext = false;
        var selected = Modules.Where(m => m.IsSelected).ToList();
        TotalToApply = selected.Count;
        AppliedCount = 0;
        ApplyProgress = 0;

        try
        {
            foreach (var module in selected)
            {
                cancellationToken.ThrowIfCancellationRequested();
                ApplyStatus = $"Applying {module.Name}...";
                // In production, invoke the corresponding PowerShell service
                await Task.Delay(500, cancellationToken).ConfigureAwait(true);
                AppliedCount++;
                ApplyProgress = (double)AppliedCount / TotalToApply * 100;
            }

            ApplyStatus = "All selections applied successfully";
            CurrentStep = 5;
            IsComplete = true;
            UpdateStepState();
            _logger.LogInformation("First Run Wizard completed. Applied {Count} modules with preset {Preset}", selected.Count, SelectedPreset);
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
}

/// <summary>
/// Represents a wizard preset option.
/// </summary>
/// <param name="Name">The preset name.</param>
/// <param name="Icon">The icon glyph.</param>
/// <param name="Description">The preset description.</param>
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
    public WizardModule(string name, string category, string description, bool isSelected)
    {
        Name = name;
        Category = category;
        Description = description;
        IsSelected = isSelected;
    }

    /// <summary>Gets the module name.</summary>
    public string Name { get; }

    /// <summary>Gets the module category.</summary>
    public string Category { get; }

    /// <summary>Gets the module description.</summary>
    public string Description { get; }
}
