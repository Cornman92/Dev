// <copyright file="DeploymentViewModelTests.cs" company="Better11">
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

public sealed class DeploymentViewModelTests
{
    private readonly Mock<IDeploymentService> deploymentServiceMock;
    private readonly Mock<ILogger<DeploymentViewModel>> loggerMock;
    private readonly DeploymentViewModel sut;

    public DeploymentViewModelTests()
    {
        this.deploymentServiceMock = new Mock<IDeploymentService>();
        this.loggerMock = new Mock<ILogger<DeploymentViewModel>>();
        this.sut = new DeploymentViewModel(this.deploymentServiceMock.Object, this.loggerMock.Object);
    }

    [Fact]
    public void Constructor_ShouldInitializeWithDefaults()
    {
        this.sut.ImageId.Should().BeEmpty();
        this.sut.DeploymentMethod.Should().Be(DeploymentMethod.UsbDirect);
        this.sut.TargetPath.Should().BeEmpty();
        this.sut.FormatTarget.Should().BeFalse();
        this.sut.FileSystem.Should().Be("FAT32");
        this.sut.VolumeLabel.Should().Be("BETTER11PE");
        this.sut.VerifyAfterDeploy.Should().BeTrue();
        this.sut.Status.Should().Be("Ready");
        this.sut.IsDeploying.Should().BeFalse();
        this.sut.ProgressPercent.Should().Be(0);
    }

    [Fact]
    public void Constructor_WithNullService_ShouldThrow()
    {
        var act = () => new DeploymentViewModel(null!, this.loggerMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new DeploymentViewModel(this.deploymentServiceMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task RefreshUsbDrivesAsync_WhenSuccessful_ShouldPopulateList()
    {
        var drives = new List<UsbDriveInfo>
        {
            new() { DriveLetter = "E:", FriendlyName = "USB Drive 1", SizeGB = 32 },
            new() { DriveLetter = "F:", FriendlyName = "USB Drive 2", SizeGB = 16 },
        };

        this.deploymentServiceMock
            .Setup(s => s.GetAvailableUsbDrivesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<UsbDriveInfo>>.Ok(drives));

        await this.sut.RefreshUsbDrivesCommand.ExecuteAsync(null);

        this.sut.AvailableUsbDrives.Should().HaveCount(2);
        this.sut.Status.Should().Contain("2 USB");
    }

    [Fact]
    public async Task RefreshUsbDrivesAsync_WhenFails_ShouldSetError()
    {
        this.deploymentServiceMock
            .Setup(s => s.GetAvailableUsbDrivesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<UsbDriveInfo>>.Fail("Access denied"));

        await this.sut.RefreshUsbDrivesCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Scan failed");
    }

    [Fact]
    public async Task DeployAsync_WithInvalidImageId_ShouldSetError()
    {
        this.sut.ImageId = "not-a-guid";
        this.sut.TargetPath = @"E:\";

        await this.sut.DeployCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Invalid image ID");
    }

    [Fact]
    public async Task DeployAsync_WithEmptyTargetPath_ShouldSetError()
    {
        this.sut.ImageId = Guid.NewGuid().ToString();
        this.sut.TargetPath = string.Empty;

        await this.sut.DeployCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task DeployAsync_WhenSuccessful_ShouldSetSuccess()
    {
        this.sut.ImageId = Guid.NewGuid().ToString();
        this.sut.TargetPath = @"E:\";

        var deployResult = new DeploymentResult
        {
            Success = true,
            VerificationPassed = true,
        };

        this.deploymentServiceMock
            .Setup(s => s.DeployAsync(It.IsAny<DeploymentRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DeploymentResult>.Ok(deployResult));

        this.deploymentServiceMock
            .Setup(s => s.GetDeploymentHistoryAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DeploymentResult>>.Ok(Array.Empty<DeploymentResult>()));

        await this.sut.DeployCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("succeeded");
        this.sut.Status.Should().Contain("verified");
        this.sut.IsDeploying.Should().BeFalse();
    }

    [Fact]
    public async Task DeployAsync_WhenVerificationFails_ShouldIndicateInStatus()
    {
        this.sut.ImageId = Guid.NewGuid().ToString();
        this.sut.TargetPath = @"E:\";

        var deployResult = new DeploymentResult
        {
            Success = true,
            VerificationPassed = false,
        };

        this.deploymentServiceMock
            .Setup(s => s.DeployAsync(It.IsAny<DeploymentRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DeploymentResult>.Ok(deployResult));

        this.deploymentServiceMock
            .Setup(s => s.GetDeploymentHistoryAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DeploymentResult>>.Ok(Array.Empty<DeploymentResult>()));

        await this.sut.DeployCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("verification failed");
    }

    [Fact]
    public async Task DeployAsync_WhenFails_ShouldSetError()
    {
        this.sut.ImageId = Guid.NewGuid().ToString();
        this.sut.TargetPath = @"E:\";

        this.deploymentServiceMock
            .Setup(s => s.DeployAsync(It.IsAny<DeploymentRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DeploymentResult>.Fail("Write error"));

        await this.sut.DeployCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("failed");
        this.sut.IsDeploying.Should().BeFalse();
    }

    [Fact]
    public async Task DeployAsync_WhenException_ShouldCatchAndSetError()
    {
        this.sut.ImageId = Guid.NewGuid().ToString();
        this.sut.TargetPath = @"E:\";

        this.deploymentServiceMock
            .Setup(s => s.DeployAsync(It.IsAny<DeploymentRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new IOException("USB disconnected"));

        await this.sut.DeployCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
        this.sut.IsDeploying.Should().BeFalse();
    }

    [Fact]
    public async Task VerifyAsync_WithEmptyTargetPath_ShouldSetError()
    {
        this.sut.TargetPath = string.Empty;
        await this.sut.VerifyCommand.ExecuteAsync(null);
        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task VerifyAsync_WhenPassed_ShouldSetSuccess()
    {
        this.sut.TargetPath = @"E:\";
        this.deploymentServiceMock
            .Setup(s => s.VerifyDeploymentAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));

        await this.sut.VerifyCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("passed");
    }

    [Fact]
    public async Task VerifyAsync_WhenHashMismatch_ShouldSetFailure()
    {
        this.sut.TargetPath = @"E:\";
        this.deploymentServiceMock
            .Setup(s => s.VerifyDeploymentAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(false));

        await this.sut.VerifyCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("failed");
    }

    [Fact]
    public async Task LoadHistoryAsync_ShouldPopulateHistory()
    {
        var history = new List<DeploymentResult>
        {
            new() { Success = true, TargetPath = @"E:\" },
        };

        this.deploymentServiceMock
            .Setup(s => s.GetDeploymentHistoryAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DeploymentResult>>.Ok(history));

        await this.sut.LoadHistoryCommand.ExecuteAsync(null);

        this.sut.DeploymentHistory.Should().HaveCount(1);
    }

    [Fact]
    public void PropertyChanges_ShouldRaiseNotification()
    {
        bool raised = false;
        this.sut.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(DeploymentViewModel.DeploymentMethod))
            {
                raised = true;
            }
        };

        this.sut.DeploymentMethod = DeploymentMethod.Pxe;
        raised.Should().BeTrue();
    }

    [Fact]
    public void AvailableUsbDrives_ShouldBeEmptyByDefault()
    {
        this.sut.AvailableUsbDrives.Should().BeEmpty();
    }

    [Fact]
    public void DeploymentHistory_ShouldBeEmptyByDefault()
    {
        this.sut.DeploymentHistory.Should().BeEmpty();
    }
}
