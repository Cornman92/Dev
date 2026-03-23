// ============================================================================
// Better11 System Enhancement Suite — SecurityServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Security;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="SecurityService"/>.
/// </summary>
public sealed class SecurityServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<SecurityService>> _mockLogger;
    private readonly SecurityService _service;

    public SecurityServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<SecurityService>>();
        _service = new SecurityService(_mockPs.Object, _mockLogger.Object);
    }

    // ========================================================================
    // Constructor
    // ========================================================================

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new SecurityService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetSecurityStatusAsync
    // ========================================================================

    [Fact]
    public async Task GetSecurityStatusAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new SecurityStatusDto
        {
            Score = 90,
            FirewallStatus = "Enabled",
            AntivirusStatus = "Active",
            UacLevel = "High",
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<SecurityStatusDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(expected));

        var result = await _service.GetSecurityStatusAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.Score.Should().Be(90);
        result.Value.FirewallStatus.Should().Be("Enabled");
    }

    [Fact]
    public async Task GetSecurityStatusAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<SecurityStatusDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetSecurityStatusAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetSecurityStatusAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<SecurityStatusDto>(
            AppConstants.Modules.Security, "Get-B11SecurityStatus",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(new SecurityStatusDto()));

        await _service.GetSecurityStatusAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<SecurityStatusDto>(
            AppConstants.Modules.Security, "Get-B11SecurityStatus",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // RunSecurityScanAsync
    // ========================================================================

    [Fact]
    public async Task RunSecurityScanAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new SecurityScanDto
        {
            Issues = new List<SecurityIssueDto>
            {
                new() { Id = "issue-1", Title = "Firewall disabled", Severity = "High" },
            },
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<SecurityScanDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(expected));

        var result = await _service.RunSecurityScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.Issues.Should().HaveCount(1);
        result.Value.TotalIssues.Should().Be(1);
    }

    [Fact]
    public async Task RunSecurityScanAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<SecurityScanDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.RunSecurityScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task RunSecurityScanAsync_ReturnsEmptyIssues_WhenSystemClean()
    {
        var clean = new SecurityScanDto { Issues = Array.Empty<SecurityIssueDto>() };
        _mockPs.Setup(x => x.InvokeCommandAsync<SecurityScanDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(clean));

        var result = await _service.RunSecurityScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.TotalIssues.Should().Be(0);
    }

    // ========================================================================
    // ApplyHardeningAsync
    // ========================================================================

    [Fact]
    public async Task ApplyHardeningAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.ApplyHardeningAsync("action-1", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ApplyHardeningAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.ApplyHardeningAsync("action-1", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task ApplyHardeningAsync_PassesActionIdToCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Security, "Set-B11SecurityHardening",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("ActionId") && (string)d["ActionId"] == "enable-firewall"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.ApplyHardeningAsync("enable-firewall", CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Security, "Set-B11SecurityHardening",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("ActionId") && (string)d["ActionId"] == "enable-firewall"),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ApplyHardeningAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var act = () => _service.ApplyHardeningAsync("action-1", cts.Token);
        await act.Should().ThrowAsync<OperationCanceledException>();
    }
}
