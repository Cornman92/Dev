// ============================================================================
// File: src/Better11.ViewModels/Network/NetworkViewModel.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Network;

/// <summary>
/// ViewModel for the Network Manager page. Provides adapter enumeration,
/// DNS configuration with presets, cache flushing, and connectivity diagnostics.
/// </summary>
public sealed partial class NetworkViewModel : BaseViewModel
{
    private readonly INetworkService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="NetworkViewModel"/> class.
    /// </summary>
    public NetworkViewModel(INetworkService service, ILogger<NetworkViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "Network Manager";
        InitializeDnsPresets();
    }

    // ================================================================ Collections

    /// <summary>Gets the network adapters collection.</summary>
    public ObservableCollection<NetworkAdapterDto> Adapters { get; } = new();

    /// <summary>Gets the available DNS preset options.</summary>
    public ObservableCollection<DnsPreset> DnsPresets { get; } = new();

    // ============================================================= Properties

    /// <summary>Gets or sets the selected network adapter.</summary>
    [ObservableProperty]
    private NetworkAdapterDto? _selectedAdapter;

    /// <summary>Gets or sets the current DNS configuration.</summary>
    [ObservableProperty]
    private DnsConfigDto? _dnsConfig;

    /// <summary>Gets or sets the latest diagnostics result.</summary>
    [ObservableProperty]
    private NetworkDiagnosticsDto? _diagnostics;

    /// <summary>Gets or sets the primary DNS server address for manual entry.</summary>
    [ObservableProperty]
    private string _primaryDns = string.Empty;

    /// <summary>Gets or sets the secondary DNS server address for manual entry.</summary>
    [ObservableProperty]
    private string _secondaryDns = string.Empty;

    /// <summary>Gets or sets the selected DNS preset.</summary>
    [ObservableProperty]
    private DnsPreset? _selectedDnsPreset;

    /// <summary>Gets or sets the connection status display text.</summary>
    [ObservableProperty]
    private string _connectionStatus = "Unknown";

    /// <summary>Gets or sets the latency display text.</summary>
    [ObservableProperty]
    private string _latencyText = "--";

    /// <summary>Gets or sets a value indicating whether the network is connected.</summary>
    [ObservableProperty]
    private bool _isConnected;

    /// <summary>Gets or sets a value indicating whether diagnostics are running.</summary>
    [ObservableProperty]
    private bool _isDiagnosticsRunning;

    // Stub properties for XAML bindings (firewall / advanced options)
    [ObservableProperty]
    private bool _isDnsOverHttpsEnabled;

    [ObservableProperty]
    private bool _isFlushDnsOnChange;

    [ObservableProperty]
    private bool _isSmartMultiHomedDisabled;

    [ObservableProperty]
    private bool _isNetBiosDisabled;

    [ObservableProperty]
    private string _firewallStatusText = "Unknown";

    [ObservableProperty]
    private string _firewallStatusColor = "#777777";

    [ObservableProperty]
    private bool _isDomainFirewallEnabled;

    [ObservableProperty]
    private bool _isPrivateFirewallEnabled;

    [ObservableProperty]
    private bool _isPublicFirewallEnabled;

    [ObservableProperty]
    private bool _isBlockInboundEnabled;

    [ObservableProperty]
    private bool _isLogDroppedEnabled;

    [ObservableProperty]
    private bool _isTeredoDisabled;

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
    private void ResetNetwork()
    {
        SetSuccess("Reset network not implemented.");
    }

    [RelayCommand]
    private void OpenFirewallSettings()
    {
        SetSuccess("Open firewall settings not implemented.");
    }

    [RelayCommand]
    private void ApplyFirewall()
    {
        SetSuccess("Apply firewall not implemented.");
    }

    [RelayCommand]
    private void ResetFirewall()
    {
        SetSuccess("Reset firewall not implemented.");
    }

    /// <summary>Loads adapters and current DNS configuration.</summary>
    [RelayCommand]
    private async Task LoadDataAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var adaptersResult = await _service.GetAdaptersAsync(ct).ConfigureAwait(false);
                if (adaptersResult.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        Adapters.Clear();
                        foreach (var item in adaptersResult.Value) { Adapters.Add(item); }
                    });
                }
                else { SetErrorFromResult(adaptersResult); return; }

                var dnsResult = await _service.GetDnsConfigAsync(ct).ConfigureAwait(false);
                if (dnsResult.IsSuccess)
                {
                    DnsConfig = dnsResult.Value;
                    PrimaryDns = dnsResult.Value.PrimaryDns;
                    SecondaryDns = dnsResult.Value.SecondaryDns;
                }
                else { SetErrorFromResult(dnsResult); }
            },
            "Loading network configuration...",
            cancellationToken);
    }

    /// <summary>Applies the specified DNS servers to the selected adapter.</summary>
    [RelayCommand]
    private async Task SetDnsAsync(CancellationToken cancellationToken = default)
    {
        if (SelectedAdapter is null) { ErrorMessage = "Please select a network adapter first."; return; }
        if (string.IsNullOrWhiteSpace(PrimaryDns)) { ErrorMessage = "Primary DNS address is required."; return; }

        var adapterId = SelectedAdapter.Id;
        var adapterName = SelectedAdapter.Name;

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.SetDnsServersAsync(
                    adapterId, PrimaryDns, SecondaryDns, ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess($"DNS updated on {adapterName}."); await LoadDataAsync(ct); }
                else { SetErrorFromResult(result); }
            },
            "Applying DNS settings...",
            cancellationToken);
    }

    /// <summary>Applies a DNS preset to the input fields.</summary>
    [RelayCommand]
    private void ApplyDnsPreset(DnsPreset? preset)
    {
        if (preset is null) { return; }
        PrimaryDns = preset.Primary;
        SecondaryDns = preset.Secondary;
        SelectedDnsPreset = preset;
    }

    /// <summary>Flushes the system DNS resolver cache.</summary>
    [RelayCommand]
    private async Task FlushDnsCacheAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.FlushDnsCacheAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess) { SetSuccess("DNS cache flushed successfully."); }
                else { SetErrorFromResult(result); }
            },
            "Flushing DNS cache...",
            cancellationToken);
    }

    /// <summary>Runs network connectivity diagnostics.</summary>
    [RelayCommand]
    private async Task RunDiagnosticsAsync(CancellationToken cancellationToken = default)
    {
        IsDiagnosticsRunning = true;
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.RunDiagnosticsAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    Diagnostics = result.Value;
                    IsConnected = result.Value.IsConnected;
                    ConnectionStatus = result.Value.IsConnected ? "Connected" : "Disconnected";
                    LatencyText = result.Value.IsConnected ? $"{result.Value.LatencyMs} ms" : "--";
                    SetSuccess("Diagnostics completed.");
                }
                else { SetErrorFromResult(result); ConnectionStatus = "Error"; }
            },
            "Running network diagnostics...",
            cancellationToken);
        IsDiagnosticsRunning = false;
    }

    // ================================================================ Helpers

    private void InitializeDnsPresets()
    {
        DnsPresets.Add(new DnsPreset("Google", "8.8.8.8", "8.8.4.4"));
        DnsPresets.Add(new DnsPreset("Cloudflare", "1.1.1.1", "1.0.0.1"));
        DnsPresets.Add(new DnsPreset("OpenDNS", "208.67.222.222", "208.67.220.220"));
        DnsPresets.Add(new DnsPreset("Quad9", "9.9.9.9", "149.112.112.112"));
    }
}

/// <summary>
/// Represents a named DNS server preset with primary and secondary addresses.
/// </summary>
/// <param name="Name">The display name of the preset.</param>
/// <param name="Primary">The primary DNS address.</param>
/// <param name="Secondary">The secondary DNS address.</param>
public sealed record DnsPreset(string Name, string Primary, string Secondary);
