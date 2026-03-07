// Copyright (c) Better11. All rights reserved.

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Dashboard;

/// <summary>
/// ViewModel for the application dashboard — the main home screen.
/// Displays system info, live performance metrics, disk space,
/// a computed health score, and provides quick-action commands.
/// </summary>
public sealed partial class DashboardViewModel : BaseViewModel
{
    private readonly ISystemInfoService _systemInfoService;
    private readonly IOptimizationService _optimizationService;
    private readonly IDiskCleanupService _diskCleanupService;

    /// <summary>
    /// Initializes a new instance of the <see cref="DashboardViewModel"/> class.
    /// </summary>
    /// <param name="systemInfoService">The system information service.</param>
    /// <param name="optimizationService">The optimization service.</param>
    /// <param name="diskCleanupService">The disk cleanup service.</param>
    /// <param name="logger">The logger instance.</param>
    public DashboardViewModel(
        ISystemInfoService systemInfoService,
        IOptimizationService optimizationService,
        IDiskCleanupService diskCleanupService,
        ILogger<DashboardViewModel> logger)
        : base(logger)
    {
        _systemInfoService = systemInfoService ?? throw new ArgumentNullException(nameof(systemInfoService));
        _optimizationService = optimizationService ?? throw new ArgumentNullException(nameof(optimizationService));
        _diskCleanupService = diskCleanupService ?? throw new ArgumentNullException(nameof(diskCleanupService));
        PageTitle = "Dashboard";
    }

    // ====================================================================
    // Observable Properties
    // ====================================================================

    /// <summary>Gets or sets the system information (OS, CPU, RAM, GPU).</summary>
    [ObservableProperty]
    private SystemInfoDto? _systemInfo;

    /// <summary>Gets or sets the current performance metrics.</summary>
    [ObservableProperty]
    private PerformanceMetricsDto? _performanceMetrics;

    /// <summary>Gets or sets the computed system health score (0-100).</summary>
    [ObservableProperty]
    private int _healthScore;

    /// <summary>Gets or sets the date/time of the last data refresh.</summary>
    [ObservableProperty]
    private DateTime? _lastScanDate;

    /// <summary>Gets or sets the number of optimization tweaks currently applied.</summary>
    [ObservableProperty]
    private int _appliedTweakCount;

    /// <summary>Gets or sets a value indicating whether auto-refresh is enabled.</summary>
    [ObservableProperty]
    private bool _isAutoRefreshEnabled;

    /// <summary>Gets the disk space information for all drives.</summary>
    public ObservableCollection<DiskSpaceDto> DiskSpaces { get; } = new();

    // ====================================================================
    // Lifecycle
    // ====================================================================

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await RefreshAsync(cancellationToken).ConfigureAwait(false);
    }

    // ====================================================================
    // Commands
    // ====================================================================

    /// <summary>Reloads all dashboard data (system info, metrics, disk space, tweak count).</summary>
    [RelayCommand]
    private async Task RefreshAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(async ct =>
        {
            var infoResult = await _systemInfoService.GetSystemInfoAsync(ct).ConfigureAwait(false);
            if (infoResult.IsSuccess) { SystemInfo = infoResult.Value; }
            else { SetErrorFromResult(infoResult); }

            var metricsResult = await _systemInfoService.GetPerformanceMetricsAsync(ct).ConfigureAwait(false);
            if (metricsResult.IsSuccess)
            {
                PerformanceMetrics = metricsResult.Value;
                HealthScore = CalculateHealthScore(metricsResult.Value);
            }
            else { SetErrorFromResult(metricsResult); }

            var diskResult = await _diskCleanupService.GetDiskSpaceAsync(ct).ConfigureAwait(false);
            if (diskResult.IsSuccess)
            {
                RunOnUIThread(() =>
                {
                    DiskSpaces.Clear();
                    foreach (var d in diskResult.Value) { DiskSpaces.Add(d); }
                });
            }

            var catResult = await _optimizationService.GetCategoriesAsync(ct).ConfigureAwait(false);
            if (catResult.IsSuccess)
            {
                AppliedTweakCount = catResult.Value.SelectMany(c => c.Tweaks).Count(t => t.IsApplied);
            }

            LastScanDate = DateTime.Now;
        }, "Loading dashboard...", cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Runs a quick system optimization (low-risk tweaks only).</summary>
    [RelayCommand]
    private async Task RunOptimizationAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(async ct =>
        {
            var cats = await _optimizationService.GetCategoriesAsync(ct).ConfigureAwait(false);
            if (!cats.IsSuccess) { SetErrorFromResult(cats); return; }

            var ids = cats.Value.SelectMany(c => c.Tweaks)
                .Where(t => !t.IsApplied && t.RiskLevel == "Low")
                .Select(t => t.Id).ToList();

            if (ids.Count == 0) { SetSuccess("System is already optimized."); return; }

            var result = await _optimizationService.ApplyOptimizationsAsync(ids, ct).ConfigureAwait(false);
            if (result.IsSuccess)
            {
                AppliedTweakCount += result.Value.TweaksApplied;
                SetSuccess($"Applied {result.Value.TweaksApplied} optimization(s).");
            }
            else { SetErrorFromResult(result); }
        }, "Running optimization...", cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Runs a quick disk cleanup using default categories.</summary>
    [RelayCommand]
    private async Task RunDiskCleanupAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(async ct =>
        {
            var scan = await _diskCleanupService.ScanAsync(ct).ConfigureAwait(false);
            if (!scan.IsSuccess) { SetErrorFromResult(scan); return; }

            var names = scan.Value.Categories.Where(c => c.IsSelectedByDefault)
                .Select(c => c.Name).ToList();
            if (names.Count == 0) { SetSuccess("No cleanable items found."); return; }

            var clean = await _diskCleanupService.CleanAsync(names, ct).ConfigureAwait(false);
            if (clean.IsSuccess)
            {
                var mb = clean.Value.BytesFreed / (1024.0 * 1024.0);
                SetSuccess($"Freed {mb:F1} MB across {clean.Value.FilesRemoved} file(s).");
            }
            else { SetErrorFromResult(clean); }
        }, "Running disk cleanup...", cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Initiates a privacy scan (signals navigation to Privacy page).</summary>
    [RelayCommand]
    private async Task RunPrivacyScanAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(_ =>
        {
            SetSuccess("Navigate to Privacy Controls for a full privacy audit.");
            return Task.CompletedTask;
        }, "Preparing privacy scan...", cancellationToken).ConfigureAwait(false);
    }

    // ====================================================================
    // Private Helpers
    // ====================================================================

    /// <summary>
    /// Computes a health score from 0 to 100 based on current metrics.
    /// High CPU, memory, or GPU usage and excessive process counts reduce the score.
    /// </summary>
    private static int CalculateHealthScore(PerformanceMetricsDto m)
    {
        var score = 100;
        if (m.CpuUsagePercent > 90) { score -= 25; }
        else if (m.CpuUsagePercent > 70) { score -= 15; }
        if (m.MemoryUsagePercent > 90) { score -= 25; }
        else if (m.MemoryUsagePercent > 75) { score -= 15; }
        if (m.GpuUsagePercent > 95) { score -= 10; }
        if (m.ProcessCount > 300) { score -= 10; }
        return Math.Max(0, Math.Min(100, score));
    }
}
