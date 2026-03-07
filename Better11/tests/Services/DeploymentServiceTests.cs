// <copyright file="DeploymentServiceTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.Services;

using System.Management.Automation;
using Better11.Core.Services;
using Better11.Modules.BetterPE.Configuration;
using Better11.Modules.BetterPE.Models;
using Better11.Modules.BetterPE.Services.Implementations;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using Xunit;

public sealed class DeploymentServiceTests
{
    private readonly Mock<IPowerShellService> psServiceMock;
    private readonly Mock<ILogger<DeploymentService>> loggerMock;
    private readonly Mock<IOptions<BetterPEOptions>> optionsMock;
    private readonly DeploymentService sut;

    public DeploymentServiceTests()
    {
        this.psServiceMock = new Mock<IPowerShellService>();
        this.loggerMock = new Mock<ILogger<DeploymentService>>();
        this.optionsMock = new Mock<IOptions<BetterPEOptions>>();
        this.optionsMock.Setup(o => o.Value).Returns(new BetterPEOptions
        {
            WorkingDirectory = Path.GetTempPath(),
            PowerShellModulesPath = "PowerShell",
            DeploymentHistoryRetentionDays = 30,
        });

        this.sut = new DeploymentService(
            this.psServiceMock.Object,
            this.loggerMock.Object,
            this.optionsMock.Object);
    }

    [Fact]
    public void Constructor_WithNullPsService_ShouldThrow()
    {
        var act = () => new DeploymentService(null!, this.loggerMock.Object, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new DeploymentService(this.psServiceMock.Object, null!, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullOptions_ShouldThrow()
    {
        var act = () => new DeploymentService(this.psServiceMock.Object, this.loggerMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task DeployAsync_WithNullRequest_ShouldThrow()
    {
        var act = () => this.sut.DeployAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task DeployAsync_WhenPsSucceeds_ShouldReturnResult()
    {
        var request = new DeploymentRequest
        {
            ImageId = Guid.NewGuid(),
            Method = DeploymentMethod.UsbDirect,
            TargetPath = @"E:\",
        };

        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new
            {
                Success = true,
                Method = "UsbDirect",
                TargetPath = @"E:\",
                FilesCopied = 150,
                TotalSizeMB = 256.0,
                VerificationPassed = true,
            }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.DeployAsync(request);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task DeployAsync_WhenPsFails_ShouldReturnFailure()
    {
        var request = new DeploymentRequest
        {
            ImageId = Guid.NewGuid(),
            Method = DeploymentMethod.UsbDirect,
            TargetPath = @"E:\",
        };

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("USB disconnected"));

        var result = await this.sut.DeployAsync(request);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetAvailableUsbDrivesAsync_WhenPsSucceeds_ShouldReturnDrives()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new
            {
                DiskNumber = 1,
                DriveLetter = "E:",
                FriendlyName = "SanDisk USB",
                SizeGB = 32.0,
                FreeSpaceGB = 28.5,
                FileSystem = "FAT32",
                IsBootable = false,
                IsReadOnly = false,
            }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.GetAvailableUsbDrivesAsync();

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task FormatUsbDriveAsync_WithEmptyDriveLetter_ShouldThrow()
    {
        var act = () => this.sut.FormatUsbDriveAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task FormatUsbDriveAsync_WhenPsSucceeds_ShouldReturnSuccess()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(true),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.FormatUsbDriveAsync("E:");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task VerifyDeploymentAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.VerifyDeploymentAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task VerifyDeploymentAsync_WhenPsSucceeds_ShouldReturnBool()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(true),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.VerifyDeploymentAsync(@"E:\");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ConfigurePxeDeploymentAsync_WithEmptyServerAddr_ShouldThrow()
    {
        var act = () => this.sut.ConfigurePxeDeploymentAsync(@"C:\pe", string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task DeployAsync_WhenException_ShouldReturnFailure()
    {
        var request = new DeploymentRequest
        {
            ImageId = Guid.NewGuid(),
            Method = DeploymentMethod.UsbDirect,
            TargetPath = @"E:\",
        };

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new IOException("Device removed"));

        var result = await this.sut.DeployAsync(request);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task DeployAsync_ShouldReportProgress()
    {
        var request = new DeploymentRequest
        {
            ImageId = Guid.NewGuid(),
            Method = DeploymentMethod.UsbDirect,
            TargetPath = @"E:\",
        };

        var progressValues = new List<int>();
        var progress = new Progress<OperationProgress>(p => progressValues.Add(p.PercentComplete));

        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Success = true, FilesCopied = 10, TotalSizeMB = 100.0 }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        await this.sut.DeployAsync(request, progress);

        progressValues.Should().NotBeEmpty();
    }

    [Fact]
    public async Task GetDeploymentHistoryAsync_WhenSucceeds_ShouldReturnHistory()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>());

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.GetDeploymentHistoryAsync();

        result.IsSuccess.Should().BeTrue();
    }
}
