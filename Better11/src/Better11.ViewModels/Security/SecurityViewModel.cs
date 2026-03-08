// ============================================================================
// File: src/Better11.ViewModels/Security/SecurityViewModel.cs
// Better11 System Enhancement Suite — Security ViewModel
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Security;

/// <summary>
/// ViewModel for the security management page.
/// </summary>
public sealed partial class SecurityViewModel : BaseViewModel
{
    private readonly ISecurityService _securityService;
    private readonly ILogger<SecurityViewModel> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="SecurityViewModel"/> class.
    /// </summary>
    /// <param name="securityService">The security service.</param>
    /// <exception cref="ArgumentNullException">Thrown when securityService is null.</exception>
    public SecurityViewModel(ISecurityService securityService, ILogger<SecurityViewModel> logger)
        : base(logger)
    {
        _securityService = securityService
            ?? throw new ArgumentNullException(nameof(securityService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        PageTitle = "Security Center";
    }

    /// <summary>Gets the security issues.</summary>
    public ObservableCollection<SecurityIssueDto> Issues { get; } = new();

    /// <summary>Gets or sets the security status.</summary>
    [ObservableProperty]
    private SecurityStatusDto? _securityStatus;

    /// <summary>Gets or sets the security score.</summary>
    [ObservableProperty]
    private int _securityScore;

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken)
    {
        await LoadSecurityStatusAsync(cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Loads the security status.</summary>
    [RelayCommand]
    private async Task LoadSecurityStatusAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _securityService.GetSecurityStatusAsync(ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        SecurityStatus = result.Value;
                        SecurityScore = result.Value!.Score;
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading security status...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Runs a security scan.</summary>
    [RelayCommand]
    private async Task RunScanAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _securityService.RunSecurityScanAsync(ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    var scan = result.Value!;
                    RunOnUIThread(() =>
                    {
                        Issues.Clear();
                        foreach (var issue in scan.Issues)
                        {
                            Issues.Add(issue);
                        }

                        SuccessMessage = scan.TotalIssues == 0
                            ? "No security issues found."
                            : $"Found {scan.TotalIssues} security issue(s).";
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Running security scan...",
            cancellationToken).ConfigureAwait(false);
    }

    /// <summary>Applies a hardening action.</summary>
    [RelayCommand]
    private async Task ApplyHardeningAsync(string? actionId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(actionId))
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _securityService.ApplyHardeningAsync(actionId, ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    SuccessMessage = "Security hardening applied successfully.";
                    await LoadSecurityStatusAsync(ct).ConfigureAwait(false);
                    await RunScanAsync(ct).ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Applying security hardening...",
            cancellationToken).ConfigureAwait(false);
    }
}
