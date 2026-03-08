// ============================================================================
// File: src/Better11.ViewModels/SystemInfo/SystemInfoViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Text;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.SystemInfo;

/// <summary>
/// ViewModel for the System Information page. Provides hardware/OS details,
/// live performance metrics with optional auto-refresh, and a text export.
/// </summary>
public sealed partial class SystemInfoViewModel : BaseViewModel
{
    private readonly ISystemInfoService _service;
    private CancellationTokenSource? _autoRefreshCts;

    /// <summary>
    /// Initializes a new instance of the <see cref="SystemInfoViewModel"/> class.
    /// </summary>
    public SystemInfoViewModel(ISystemInfoService service, ILogger<SystemInfoViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "System Information";
    }

    // ============================================================= Properties

    /// <summary>Gets or sets the system information snapshot.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(OsDisplayText))]
    [NotifyPropertyChangedFor(nameof(CpuDisplayText))]
    [NotifyPropertyChangedFor(nameof(RamDisplayText))]
    [NotifyPropertyChangedFor(nameof(UptimeDisplayText))]
    private SystemInfoDto? _systemInfo;

    /// <summary>Gets or sets the latest performance metrics.</summary>
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CpuUsageText))]
    [NotifyPropertyChangedFor(nameof(MemoryUsageText))]
    [NotifyPropertyChangedFor(nameof(DiskActivityText))]
    [NotifyPropertyChangedFor(nameof(NetworkActivityText))]
    private PerformanceMetricsDto? _performanceMetrics;

    /// <summary>Gets or sets a value indicating whether auto-refresh is active.</summary>
    [ObservableProperty]
    private bool _isAutoRefreshEnabled;

    /// <summary>Gets or sets the auto-refresh interval in seconds.</summary>
    [ObservableProperty]
    private int _autoRefreshIntervalSeconds = 5;

    /// <summary>Gets or sets the exported report text.</summary>
    [ObservableProperty]
    private string _exportedReport = string.Empty;

    // ======================================================= Display Strings

    /// <summary>Gets the formatted OS display text.</summary>
    public string OsDisplayText => SystemInfo is not null
        ? $"{SystemInfo.OsName} {SystemInfo.OsVersion} (Build {SystemInfo.OsBuild})"
        : "--";

    /// <summary>Gets the formatted CPU display text.</summary>
    public string CpuDisplayText => SystemInfo is not null
        ? $"{SystemInfo.CpuName} ({SystemInfo.CpuCores} cores)"
        : "--";

    /// <summary>Gets the formatted RAM display text.</summary>
    public string RamDisplayText => SystemInfo is not null
        ? $"{SystemInfo.TotalRamGb:F1} GB" : "--";

    /// <summary>Gets the formatted uptime display text.</summary>
    public string UptimeDisplayText => SystemInfo is not null
        ? FormatUptime(SystemInfo.Uptime) : "--";

    /// <summary>Gets the formatted CPU usage text.</summary>
    public string CpuUsageText => PerformanceMetrics is not null
        ? $"{PerformanceMetrics.CpuUsagePercent:F1}%" : "--";

    /// <summary>Gets the formatted memory usage text.</summary>
    public string MemoryUsageText => PerformanceMetrics is not null
        ? $"{PerformanceMetrics.MemoryUsagePercent:F1}% ({PerformanceMetrics.AvailableMemoryGb:F1} GB free)"
        : "--";

    /// <summary>Gets the formatted disk activity text.</summary>
    public string DiskActivityText => PerformanceMetrics is not null
        ? $"R: {PerformanceMetrics.DiskReadMbps:F1} MB/s | W: {PerformanceMetrics.DiskWriteMbps:F1} MB/s"
        : "--";

    /// <summary>Gets the formatted network activity text.</summary>
    public string NetworkActivityText => PerformanceMetrics is not null
        ? $"Send: {PerformanceMetrics.NetworkSendKbps:F0} KB/s | Recv: {PerformanceMetrics.NetworkReceiveKbps:F0} KB/s"
        : "--";

    // ================================================================ Lifecycle

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await LoadDataAsync(cancellationToken);
        await RefreshMetricsAsync(cancellationToken);
    }

    /// <inheritdoc/>
    public override void Cleanup()
    {
        StopAutoRefresh();
        base.Cleanup();
    }

    // ================================================================ Commands

    /// <summary>Loads the static system information.</summary>
    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetSystemInfoAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess) { SystemInfo = result.Value; }
                else { SetErrorFromResult(result); }
            },
            "Loading system information...",
            cancellationToken);
    }

    /// <summary>Refreshes the live performance metrics.</summary>
    [RelayCommand]
    private async Task RefreshMetricsAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetPerformanceMetricsAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess) { PerformanceMetrics = result.Value; }
                else { SetErrorFromResult(result); }
            },
            "Refreshing metrics...",
            cancellationToken);
    }

    /// <summary>Toggles auto-refresh of performance metrics on or off.</summary>
    [RelayCommand]
    private void ToggleAutoRefresh()
    {
        if (IsAutoRefreshEnabled) { StopAutoRefresh(); }
        else { StartAutoRefresh(); }
    }

    /// <summary>Generates a text report of the current system information and metrics.</summary>
    [RelayCommand]
    private void ExportSystemInfo()
    {
        if (SystemInfo is null)
        {
            ErrorMessage = "System information has not been loaded yet.";
            return;
        }

        var sb = new StringBuilder();
        sb.AppendLine("=== Better11 System Report ===");
        sb.AppendLine($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        sb.AppendLine();
        sb.AppendLine("--- Hardware ---");
        sb.AppendLine($"Computer Name : {SystemInfo.ComputerName}");
        sb.AppendLine($"Motherboard   : {SystemInfo.Motherboard}");
        sb.AppendLine($"BIOS          : {SystemInfo.BiosVersion}");
        sb.AppendLine($"CPU           : {CpuDisplayText}");
        sb.AppendLine($"RAM           : {RamDisplayText}");
        sb.AppendLine($"GPU           : {SystemInfo.GpuName}");
        sb.AppendLine();
        sb.AppendLine("--- Operating System ---");
        sb.AppendLine($"OS            : {OsDisplayText}");
        sb.AppendLine($"Activation    : {SystemInfo.ActivationStatus}");
        sb.AppendLine($"Uptime        : {UptimeDisplayText}");

        if (PerformanceMetrics is not null)
        {
            sb.AppendLine();
            sb.AppendLine("--- Performance ---");
            sb.AppendLine($"CPU Usage     : {CpuUsageText}");
            sb.AppendLine($"Memory Usage  : {MemoryUsageText}");
            sb.AppendLine($"Disk I/O      : {DiskActivityText}");
            sb.AppendLine($"Network I/O   : {NetworkActivityText}");
            sb.AppendLine($"GPU Usage     : {PerformanceMetrics.GpuUsagePercent:F1}%");
            sb.AppendLine($"Processes     : {PerformanceMetrics.ProcessCount}");
        }

        ExportedReport = sb.ToString();
        SetSuccess("System report generated.");
    }

    // ========================================================== Auto-Refresh

    private void StartAutoRefresh()
    {
        StopAutoRefresh();
        IsAutoRefreshEnabled = true;
        _autoRefreshCts = new CancellationTokenSource();
        _ = AutoRefreshLoopAsync(_autoRefreshCts.Token);
    }

    private void StopAutoRefresh()
    {
        IsAutoRefreshEnabled = false;
        _autoRefreshCts?.Cancel();
        _autoRefreshCts?.Dispose();
        _autoRefreshCts = null;
    }

    private async Task AutoRefreshLoopAsync(CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(
                    TimeSpan.FromSeconds(AutoRefreshIntervalSeconds), cancellationToken);
                await RefreshMetricsAsync(cancellationToken);
            }
            catch (OperationCanceledException) { break; }
        }
    }

    private static string FormatUptime(TimeSpan uptime)
    {
        if (uptime.TotalDays >= 1)
            return $"{(int)uptime.TotalDays}d {uptime.Hours}h {uptime.Minutes}m";
        return uptime.TotalHours >= 1
            ? $"{(int)uptime.TotalHours}h {uptime.Minutes}m"
            : $"{uptime.Minutes}m {uptime.Seconds}s";
    }
}
