// Copyright (c) Better11. All rights reserved.

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.Privacy;
using Better11.ViewModels.Security;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for the privacy and security workflows, verifying end-to-end
/// ViewModel orchestration through IPrivacyService and ISecurityService.
/// </summary>
public sealed class PrivacySecurityWorkflowTests
{
    private readonly Mock<IPrivacyService> _mockPrivacyService;
    private readonly Mock<ISecurityService> _mockSecurityService;
    private readonly Mock<ILogger<PrivacyViewModel>> _mockPrivacyLogger;
    private readonly Mock<ILogger<SecurityViewModel>> _mockSecurityLogger;
    private readonly PrivacyViewModel _privacyVm;
    private readonly SecurityViewModel _securityVm;

    public PrivacySecurityWorkflowTests()
    {
        _mockPrivacyService = new Mock<IPrivacyService>();
        _mockSecurityService = new Mock<ISecurityService>();
        _mockPrivacyLogger = new Mock<ILogger<PrivacyViewModel>>();
        _mockSecurityLogger = new Mock<ILogger<SecurityViewModel>>();
        _privacyVm = new PrivacyViewModel(_mockPrivacyService.Object, _mockPrivacyLogger.Object);
        _securityVm = new SecurityViewModel(_mockSecurityService.Object, _mockSecurityLogger.Object);
    }

    // ====================================================================
    // Privacy: LoadAudit
    // ====================================================================

    [Fact]
    public async Task LoadPrivacyAudit_Success_PopulatesSettingsAndScore()
    {
        // Arrange
        var audit = new PrivacyAuditDto
        {
            Score = 72,
            CurrentProfile = "Balanced",
            Settings = new List<PrivacySettingDto>
            {
                new() { Id = "ps1", Name = "Telemetry", Category = "Data Collection", IsEnabled = true, RecommendedState = false },
                new() { Id = "ps2", Name = "Location", Category = "Location", IsEnabled = false, RecommendedState = false },
            },
        };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.PrivacyScore.Should().Be(72);
        _privacyVm.CurrentProfile.Should().Be("Balanced");
        _privacyVm.Settings.Should().HaveCount(2);
        _privacyVm.Settings[0].Name.Should().Be("Telemetry");
    }

    [Fact]
    public async Task LoadPrivacyAudit_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Failure("Registry read failed"));

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.ErrorMessage.Should().Contain("Registry read failed");
        _privacyVm.Settings.Should().BeEmpty();
    }

    [Fact]
    public async Task LoadPrivacyAudit_EmptySettings_ScoreStillSet()
    {
        // Arrange
        var audit = new PrivacyAuditDto
        {
            Score = 100,
            CurrentProfile = "Maximum",
            Settings = new List<PrivacySettingDto>(),
        };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.PrivacyScore.Should().Be(100);
        _privacyVm.Settings.Should().BeEmpty();
    }

    // ====================================================================
    // Privacy: ApplyProfile
    // ====================================================================

    [Fact]
    public async Task ApplyPrivacyProfile_Success_SetsSuccessMessageAndReloads()
    {
        // Arrange
        var audit = new PrivacyAuditDto { Score = 50, CurrentProfile = "Default", Settings = new List<PrivacySettingDto>() };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));
        _mockPrivacyService
            .Setup(s => s.ApplyPrivacyProfileAsync("Strict", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _privacyVm.InitializeAsync();

        // Act
        await _privacyVm.ApplyProfileCommand.ExecuteAsync("Strict");

        // Assert
        _privacyVm.SuccessMessage.Should().Contain("Strict");
        _mockPrivacyService.Verify(
            s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(2));
    }

    [Fact]
    public async Task ApplyPrivacyProfile_Failure_SetsErrorMessage()
    {
        // Arrange
        var audit = new PrivacyAuditDto { Score = 50, CurrentProfile = "Default", Settings = new List<PrivacySettingDto>() };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));
        _mockPrivacyService
            .Setup(s => s.ApplyPrivacyProfileAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Profile not found"));

        await _privacyVm.InitializeAsync();

        // Act
        await _privacyVm.ApplyProfileCommand.ExecuteAsync("NonExistent");

        // Assert
        _privacyVm.ErrorMessage.Should().Contain("Profile not found");
    }

    [Fact]
    public async Task ApplyPrivacyProfile_NullProfileName_DoesNotCallService()
    {
        // Arrange
        var audit = new PrivacyAuditDto { Score = 50, CurrentProfile = "Default", Settings = new List<PrivacySettingDto>() };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        await _privacyVm.InitializeAsync();

        // Act
        await _privacyVm.ApplyProfileCommand.ExecuteAsync(null);

        // Assert
        _mockPrivacyService.Verify(
            s => s.ApplyPrivacyProfileAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    // ====================================================================
    // Privacy: SetPrivacySetting (Toggle)
    // ====================================================================

    [Fact]
    public async Task SetPrivacySetting_Toggle_InvertsEnabledState()
    {
        // Arrange
        var setting = new PrivacySettingDto { Id = "ps1", Name = "Telemetry", IsEnabled = true };
        var audit = new PrivacyAuditDto { Score = 50, CurrentProfile = "Default", Settings = new List<PrivacySettingDto> { setting } };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));
        _mockPrivacyService
            .Setup(s => s.SetPrivacySettingAsync("ps1", false, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _privacyVm.InitializeAsync();

        // Act
        await _privacyVm.ToggleSettingCommand.ExecuteAsync(setting);

        // Assert
        setting.IsEnabled.Should().BeFalse();
    }

    [Fact]
    public async Task SetPrivacySetting_Toggle_NullSetting_DoesNotCallService()
    {
        // Arrange
        var audit = new PrivacyAuditDto { Score = 50, CurrentProfile = "Default", Settings = new List<PrivacySettingDto>() };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        await _privacyVm.InitializeAsync();

        // Act
        await _privacyVm.ToggleSettingCommand.ExecuteAsync(null);

        // Assert
        _mockPrivacyService.Verify(
            s => s.SetPrivacySettingAsync(It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    // ====================================================================
    // Privacy: Score and Profile
    // ====================================================================

    [Fact]
    public async Task PrivacyScore_Computed_ReflectsAuditScore()
    {
        // Arrange
        var audit = new PrivacyAuditDto { Score = 88, CurrentProfile = "Strict", Settings = new List<PrivacySettingDto>() };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.PrivacyScore.Should().Be(88);
    }

    [Fact]
    public async Task PrivacyProfile_ReflectsCurrentProfile()
    {
        // Arrange
        var audit = new PrivacyAuditDto { Score = 60, CurrentProfile = "Custom", Settings = new List<PrivacySettingDto>() };
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(audit));

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.CurrentProfile.Should().Be("Custom");
    }

    // ====================================================================
    // Security: LoadStatus
    // ====================================================================

    [Fact]
    public async Task LoadSecurityStatus_Success_PopulatesStatusAndScore()
    {
        // Arrange
        var status = new SecurityStatusDto
        {
            Score = 85,
            FirewallStatus = "Enabled",
            AntivirusStatus = "Up to date",
            UpdateStatus = "Current",
            UacLevel = "High",
            BitLockerStatus = "Encrypted",
        };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));

        // Act
        await _securityVm.InitializeAsync();

        // Assert
        _securityVm.SecurityStatus.Should().NotBeNull();
        _securityVm.SecurityScore.Should().Be(85);
        _securityVm.SecurityStatus!.FirewallStatus.Should().Be("Enabled");
        _securityVm.SecurityStatus.BitLockerStatus.Should().Be("Encrypted");
    }

    [Fact]
    public async Task LoadSecurityStatus_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Failure("WMI query failed"));

        // Act
        await _securityVm.InitializeAsync();

        // Assert
        _securityVm.ErrorMessage.Should().Contain("WMI query failed");
        _securityVm.SecurityStatus.Should().BeNull();
    }

    // ====================================================================
    // Security: RunScan
    // ====================================================================

    [Fact]
    public async Task RunSecurityScan_FindsIssues_PopulatesIssuesCollection()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 60 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        var scan = new SecurityScanDto
        {
            Issues = new List<SecurityIssueDto>
            {
                new() { Id = "si1", Title = "Firewall Disabled", Severity = "High", RemediationActionId = "act1" },
                new() { Id = "si2", Title = "Outdated AV Definitions", Severity = "Medium", RemediationActionId = "act2" },
            },
        };
        _mockSecurityService
            .Setup(s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(scan));

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.RunScanCommand.ExecuteAsync(null);

        // Assert
        _securityVm.Issues.Should().HaveCount(2);
        _securityVm.SuccessMessage.Should().Contain("2 security issue(s)");
    }

    [Fact]
    public async Task RunSecurityScan_Clean_ShowsNoIssuesMessage()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 100 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        var scan = new SecurityScanDto { Issues = new List<SecurityIssueDto>() };
        _mockSecurityService
            .Setup(s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(scan));

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.RunScanCommand.ExecuteAsync(null);

        // Assert
        _securityVm.Issues.Should().BeEmpty();
        _securityVm.SuccessMessage.Should().Contain("No security issues");
    }

    [Fact]
    public async Task RunSecurityScan_Failure_SetsErrorMessage()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 70 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        _mockSecurityService
            .Setup(s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Failure("Scan engine unavailable"));

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.RunScanCommand.ExecuteAsync(null);

        // Assert
        _securityVm.ErrorMessage.Should().Contain("Scan engine unavailable");
    }

    // ====================================================================
    // Security: ApplyHardening
    // ====================================================================

    [Fact]
    public async Task ApplyHardening_Success_SetsSuccessMessage()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 70 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        _mockSecurityService
            .Setup(s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(new SecurityScanDto { Issues = new List<SecurityIssueDto>() }));
        _mockSecurityService
            .Setup(s => s.ApplyHardeningAsync("act1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.ApplyHardeningCommand.ExecuteAsync("act1");

        // Assert
        _securityVm.SuccessMessage.Should().NotBeEmpty();
    }

    [Fact]
    public async Task ApplyHardening_Failure_SetsErrorMessage()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 70 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        _mockSecurityService
            .Setup(s => s.ApplyHardeningAsync("act1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Requires elevated permissions"));

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.ApplyHardeningCommand.ExecuteAsync("act1");

        // Assert
        _securityVm.ErrorMessage.Should().Contain("Requires elevated permissions");
    }

    [Fact]
    public async Task ApplyHardening_NullActionId_DoesNotCallService()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 70 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.ApplyHardeningCommand.ExecuteAsync(null);

        // Assert
        _mockSecurityService.Verify(
            s => s.ApplyHardeningAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task ApplyHardening_Success_RefreshesStatusAndScan()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 70 };
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        _mockSecurityService
            .Setup(s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(new SecurityScanDto { Issues = new List<SecurityIssueDto>() }));
        _mockSecurityService
            .Setup(s => s.ApplyHardeningAsync("act1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _securityVm.InitializeAsync();

        // Act
        await _securityVm.ApplyHardeningCommand.ExecuteAsync("act1");

        // Assert - Status loaded during init + reload after hardening
        _mockSecurityService.Verify(
            s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(2));
        _mockSecurityService.Verify(
            s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(1));
    }

    // ====================================================================
    // Full Privacy Workflow
    // ====================================================================

    [Fact]
    public async Task FullPrivacyWorkflow_AuditThenApplyProfile_UpdatesScoreAndProfile()
    {
        // Arrange
        var initialAudit = new PrivacyAuditDto { Score = 40, CurrentProfile = "Default", Settings = new List<PrivacySettingDto>
        {
            new() { Id = "ps1", Name = "Telemetry", IsEnabled = true },
        }};
        var updatedAudit = new PrivacyAuditDto { Score = 90, CurrentProfile = "Strict", Settings = new List<PrivacySettingDto>
        {
            new() { Id = "ps1", Name = "Telemetry", IsEnabled = false },
        }};
        _mockPrivacyService
            .SetupSequence(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(initialAudit))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(updatedAudit));
        _mockPrivacyService
            .Setup(s => s.ApplyPrivacyProfileAsync("Strict", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act - Step 1: Load audit
        await _privacyVm.InitializeAsync();
        _privacyVm.PrivacyScore.Should().Be(40);

        // Act - Step 2: Apply profile
        await _privacyVm.ApplyProfileCommand.ExecuteAsync("Strict");

        // Assert
        _privacyVm.PrivacyScore.Should().Be(90);
        _privacyVm.CurrentProfile.Should().Be("Strict");
    }

    // ====================================================================
    // Full Security Workflow
    // ====================================================================

    [Fact]
    public async Task FullSecurityWorkflow_ScanThenHarden_ResolvesIssues()
    {
        // Arrange
        var status = new SecurityStatusDto { Score = 60 };
        var scanWithIssues = new SecurityScanDto
        {
            Issues = new List<SecurityIssueDto>
            {
                new() { Id = "si1", Title = "Firewall Off", Severity = "High", RemediationActionId = "enable_fw" },
            },
        };
        var scanClean = new SecurityScanDto { Issues = new List<SecurityIssueDto>() };

        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(status));
        _mockSecurityService
            .SetupSequence(s => s.RunSecurityScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityScanDto>.Success(scanWithIssues))
            .ReturnsAsync(Result<SecurityScanDto>.Success(scanClean));
        _mockSecurityService
            .Setup(s => s.ApplyHardeningAsync("enable_fw", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _securityVm.InitializeAsync();

        // Act - Step 1: Run scan, find issues
        await _securityVm.RunScanCommand.ExecuteAsync(null);
        _securityVm.Issues.Should().HaveCount(1);

        // Act - Step 2: Apply hardening
        await _securityVm.ApplyHardeningCommand.ExecuteAsync("enable_fw");

        // Assert - After hardening, scan is re-run and issues are cleared
        _securityVm.Issues.Should().BeEmpty();
    }

    // ====================================================================
    // ViewModel State
    // ====================================================================

    [Fact]
    public void Privacy_PageTitle_IsCorrect()
    {
        _privacyVm.PageTitle.Should().Be("Privacy Controls");
    }

    [Fact]
    public void Security_PageTitle_IsCorrect()
    {
        _securityVm.PageTitle.Should().Be("Security Center");
    }

    [Fact]
    public async Task Privacy_IsBusy_IsFalseAfterInit()
    {
        // Arrange
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(
                new PrivacyAuditDto { Score = 50, CurrentProfile = "Default", Settings = new List<PrivacySettingDto>() }));

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.IsBusy.Should().BeFalse();
    }

    [Fact]
    public async Task Security_IsBusy_IsFalseAfterInit()
    {
        // Arrange
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(new SecurityStatusDto { Score = 80 }));

        // Act
        await _securityVm.InitializeAsync();

        // Assert
        _securityVm.IsBusy.Should().BeFalse();
    }
}
