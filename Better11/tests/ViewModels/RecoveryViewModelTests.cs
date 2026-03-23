// <copyright file="RecoveryViewModelTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.ViewModels;

using Better11.Modules.BetterPE.Models;
using Better11.Modules.BetterPE.Services.Interfaces;
using Better11.Modules.BetterPE.ViewModels;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class RecoveryViewModelTests
{
    private readonly Mock<IRecoveryService> recoveryServiceMock;
    private readonly Mock<ILogger<RecoveryViewModel>> loggerMock;
    private readonly RecoveryViewModel sut;

    public RecoveryViewModelTests()
    {
        this.recoveryServiceMock = new Mock<IRecoveryService>();
        this.loggerMock = new Mock<ILogger<RecoveryViewModel>>();
        this.sut = new RecoveryViewModel(this.recoveryServiceMock.Object, this.loggerMock.Object);
    }

    [Fact]
    public void Constructor_ShouldInitializeWithDefaults()
    {
        this.sut.Status.Should().Be("Ready");
        this.sut.WinReStatus.Should().Be("Unknown");
        this.sut.RecoveryName.Should().Be("Better11 Recovery");
        this.sut.RecoveryType.Should().Be(RecoveryType.WinRE);
        this.sut.IsBuilding.Should().BeFalse();
    }

    [Fact]
    public void Constructor_WithNullService_ShouldThrow()
    {
        var act = () => new RecoveryViewModel(null!, this.loggerMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task CheckWinReStatusAsync_WhenEnabled_ShouldSetStatus()
    {
        var winReStatus = new WinReStatus
        {
            IsEnabled = true,
            ImagePath = @"C:\Recovery\winre.wim",
            Version = "10.0.22621",
            Partition = @"\\?\GLOBALROOT\device\harddisk0\partition4",
        };

        this.recoveryServiceMock
            .Setup(s => s.GetWinReStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<WinReStatus>.Ok(winReStatus));

        await this.sut.CheckWinReStatusCommand.ExecuteAsync(null);

        this.sut.WinReStatus.Should().Be("Enabled");
        this.sut.WinReImagePath.Should().Be(@"C:\Recovery\winre.wim");
        this.sut.WinReVersion.Should().Be("10.0.22621");
    }

    [Fact]
    public async Task CheckWinReStatusAsync_WhenDisabled_ShouldSetDisabled()
    {
        var winReStatus = new WinReStatus { IsEnabled = false };
        this.recoveryServiceMock
            .Setup(s => s.GetWinReStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<WinReStatus>.Ok(winReStatus));

        await this.sut.CheckWinReStatusCommand.ExecuteAsync(null);

        this.sut.WinReStatus.Should().Be("Disabled");
    }

    [Fact]
    public async Task CheckWinReStatusAsync_WhenFails_ShouldSetError()
    {
        this.recoveryServiceMock
            .Setup(s => s.GetWinReStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<WinReStatus>.Fail("Access denied"));

        await this.sut.CheckWinReStatusCommand.ExecuteAsync(null);

        this.sut.WinReStatus.Should().Be("Error");
        this.sut.Status.Should().Contain("failed");
    }

    [Fact]
    public async Task BuildRecoveryAsync_WithEmptyOutputDir_ShouldSetError()
    {
        this.sut.OutputDirectory = string.Empty;

        await this.sut.BuildRecoveryCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task BuildRecoveryAsync_WhenSuccessful_ShouldSetSuccessAndReload()
    {
        this.sut.OutputDirectory = @"C:\recovery";
        this.recoveryServiceMock
            .Setup(s => s.BuildRecoveryEnvironmentAsync(It.IsAny<RecoveryBuildRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<RecoveryEnvironment>.Ok(new RecoveryEnvironment { Name = "Test" }));
        this.recoveryServiceMock
            .Setup(s => s.ListRecoveryEnvironmentsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<RecoveryEnvironment>>.Ok(new List<RecoveryEnvironment>()));

        await this.sut.BuildRecoveryCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("success");
        this.sut.IsBuilding.Should().BeFalse();
    }

    [Fact]
    public async Task LoadEnvironmentsAsync_ShouldPopulateCollection()
    {
        var envs = new List<RecoveryEnvironment>
        {
            new() { Name = "RE1" },
            new() { Name = "RE2" },
        };
        this.recoveryServiceMock
            .Setup(s => s.ListRecoveryEnvironmentsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<RecoveryEnvironment>>.Ok(envs));

        await this.sut.LoadEnvironmentsCommand.ExecuteAsync(null);

        this.sut.Environments.Should().HaveCount(2);
    }

    [Fact]
    public async Task BackupWinReAsync_WhenSuccessful_ShouldSetStatus()
    {
        this.recoveryServiceMock
            .Setup(s => s.BackupWinReImageAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Ok(@"C:\backup\winre.wim"));

        await this.sut.BackupWinReCommand.ExecuteAsync(@"C:\backup\winre.wim");

        this.sut.Status.Should().Contain("Backup");
    }

    [Fact]
    public async Task ToggleWinReAsync_WhenEnableSucceeds_ShouldRefreshStatus()
    {
        this.recoveryServiceMock
            .Setup(s => s.SetWinReEnabledAsync(true, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));
        this.recoveryServiceMock
            .Setup(s => s.GetWinReStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<WinReStatus>.Ok(new WinReStatus { IsEnabled = true }));

        await this.sut.ToggleWinReCommand.ExecuteAsync(true);

        this.sut.Status.Should().Contain("enabled");
    }

    [Fact]
    public void Collections_ShouldBeEmptyInitially()
    {
        this.sut.Environments.Should().BeEmpty();
        this.sut.DriverPaths.Should().BeEmpty();
        this.sut.ValidationIssues.Should().BeEmpty();
    }
}
