// ============================================================================
// Better11 System Enhancement Suite — PrivacyServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Privacy;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="PrivacyService"/>.
/// </summary>
public sealed class PrivacyServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<PrivacyService>> _mockLogger;
    private readonly PrivacyService _service;

    public PrivacyServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<PrivacyService>>();
        _service = new PrivacyService(_mockPs.Object, _mockLogger.Object);
    }

    // ========================================================================
    // Constructor
    // ========================================================================

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new PrivacyService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetPrivacyAuditAsync
    // ========================================================================

    [Fact]
    public async Task GetPrivacyAuditAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new PrivacyAuditDto { Score = 85, CurrentProfile = "Balanced" };
        _mockPs.Setup(x => x.InvokeCommandAsync<PrivacyAuditDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(expected));

        var result = await _service.GetPrivacyAuditAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.Score.Should().Be(85);
        result.Value.CurrentProfile.Should().Be("Balanced");
    }

    [Fact]
    public async Task GetPrivacyAuditAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<PrivacyAuditDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetPrivacyAuditAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.PowerShell);
    }

    [Fact]
    public async Task GetPrivacyAuditAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<PrivacyAuditDto>(
            AppConstants.Modules.Privacy, "Get-B11PrivacyAudit",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(new PrivacyAuditDto()));

        await _service.GetPrivacyAuditAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<PrivacyAuditDto>(
            AppConstants.Modules.Privacy, "Get-B11PrivacyAudit",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task GetPrivacyAuditAsync_ReturnsSettingsInAudit()
    {
        var audit = new PrivacyAuditDto
        {
            Score = 60,
            Settings = new List<PrivacySettingDto>
            {
                new() { Id = "telemetry", Name = "Telemetry", IsEnabled = true, RecommendedState = false },
                new() { Id = "ads", Name = "Ad Tracking", IsEnabled = false, RecommendedState = false },
            },
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<PrivacyAuditDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        var result = await _service.GetPrivacyAuditAsync(CancellationToken.None);

        result.Value!.Settings.Should().HaveCount(2);
        result.Value.Settings[0].IsEnabled.Should().BeTrue();
        result.Value.Settings[1].IsEnabled.Should().BeFalse();
    }

    // ========================================================================
    // ApplyPrivacyProfileAsync
    // ========================================================================

    [Fact]
    public async Task ApplyPrivacyProfileAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.ApplyPrivacyProfileAsync("Strict", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ApplyPrivacyProfileAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.ApplyPrivacyProfileAsync("Strict", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task ApplyPrivacyProfileAsync_PassesProfileName()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Privacy, "Set-B11PrivacyProfile",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("ProfileName") && (string)d["ProfileName"] == "Maximum"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.ApplyPrivacyProfileAsync("Maximum", CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Privacy, "Set-B11PrivacyProfile",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("ProfileName") && (string)d["ProfileName"] == "Maximum"),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // SetPrivacySettingAsync
    // ========================================================================

    [Fact]
    public async Task SetPrivacySettingAsync_ReturnsSuccess_WhenEnabled()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.SetPrivacySettingAsync("telemetry", true, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task SetPrivacySettingAsync_ReturnsSuccess_WhenDisabled()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.SetPrivacySettingAsync("telemetry", false, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task SetPrivacySettingAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("B11_ACCESS_DENIED", "Access denied"));

        var result = await _service.SetPrivacySettingAsync("telemetry", false, CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be("B11_ACCESS_DENIED");
    }

    [Fact]
    public async Task SetPrivacySettingAsync_PassesSettingIdAndEnabled()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Privacy, "Set-B11PrivacySetting",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("SettingId") && (string)d["SettingId"] == "ads" &&
                d.ContainsKey("Enabled") && (bool)d["Enabled"] == false),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.SetPrivacySettingAsync("ads", false, CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Privacy, "Set-B11PrivacySetting",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("SettingId") && (string)d["SettingId"] == "ads"),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
