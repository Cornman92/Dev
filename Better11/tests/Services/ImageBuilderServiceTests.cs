// <copyright file="ImageBuilderServiceTests.cs" company="Better11">
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

public sealed class ImageBuilderServiceTests
{
    private readonly Mock<IPowerShellService> psServiceMock;
    private readonly Mock<ILogger<ImageBuilderService>> loggerMock;
    private readonly Mock<IOptions<BetterPEOptions>> optionsMock;
    private readonly ImageBuilderService sut;

    public ImageBuilderServiceTests()
    {
        this.psServiceMock = new Mock<IPowerShellService>();
        this.loggerMock = new Mock<ILogger<ImageBuilderService>>();
        this.optionsMock = new Mock<IOptions<BetterPEOptions>>();
        this.optionsMock.Setup(o => o.Value).Returns(new BetterPEOptions
        {
            WorkingDirectory = Path.GetTempPath(),
            PowerShellModulesPath = "PowerShell",
        });

        this.sut = new ImageBuilderService(
            this.psServiceMock.Object,
            this.loggerMock.Object,
            this.optionsMock.Object);
    }

    [Fact]
    public void Constructor_WithNullPsService_ShouldThrow()
    {
        var act = () => new ImageBuilderService(null!, this.loggerMock.Object, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new ImageBuilderService(this.psServiceMock.Object, null!, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullOptions_ShouldThrow()
    {
        var act = () => new ImageBuilderService(this.psServiceMock.Object, this.loggerMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task BuildImageAsync_WithNullRequest_ShouldThrow()
    {
        var act = () => this.sut.BuildImageAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task BuildImageAsync_WhenPsSucceeds_ShouldReturnSuccess()
    {
        var request = CreateTestRequest();
        var psResult = CreateSuccessPsResult(new PSObject(new
        {
            Success = true,
            ImagePath = @"C:\output\boot.wim",
            ImageSizeMb = 256.0,
            Duration = TimeSpan.FromMinutes(5),
            OutputPath = @"C:\output",
        }));

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.BuildImageAsync(request);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task BuildImageAsync_WhenPsFails_ShouldReturnFailure()
    {
        var request = CreateTestRequest();

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("DISM error"));

        var result = await this.sut.BuildImageAsync(request);

        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain("failed");
    }

    [Fact]
    public async Task BuildImageAsync_WhenCancelled_ShouldReturnFailure()
    {
        var request = CreateTestRequest();
        var cts = new CancellationTokenSource();
        await cts.CancelAsync();

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new OperationCanceledException());

        var result = await this.sut.BuildImageAsync(request, cancellationToken: cts.Token);

        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain("cancelled");
    }

    [Fact]
    public async Task BuildImageAsync_WhenException_ShouldReturnFailure()
    {
        var request = CreateTestRequest();

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Unexpected"));

        var result = await this.sut.BuildImageAsync(request);

        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain("Unexpected");
    }

    [Fact]
    public async Task BuildImageAsync_ShouldReportProgress()
    {
        var request = CreateTestRequest();
        var progressValues = new List<int>();
        var progress = new Progress<OperationProgress>(p => progressValues.Add(p.PercentComplete));

        var psResult = CreateSuccessPsResult(new PSObject(new
        {
            Success = true,
            ImagePath = @"C:\output\boot.wim",
            ImageSizeMb = 256.0,
        }));

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        await this.sut.BuildImageAsync(request, progress);

        // Progress should have been reported (0%, 5%, 10%, 100%)
        progressValues.Should().NotBeEmpty();
    }

    [Fact]
    public async Task MountImageAsync_WithEmptyWimPath_ShouldThrow()
    {
        var act = () => this.sut.MountImageAsync(string.Empty, @"C:\mount");
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task MountImageAsync_WithEmptyMountPath_ShouldThrow()
    {
        var act = () => this.sut.MountImageAsync(@"C:\boot.wim", string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ValidateAdkInstallationAsync_WhenPsSucceeds_ShouldReturnResult()
    {
        var psResult = CreateSuccessPsResult(new PSObject(new
        {
            IsInstalled = true,
            AdkPath = @"C:\ADK",
            Version = "10.0.26100",
        }));

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ValidateAdkInstallationAsync();

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ValidateAdkInstallationAsync_WhenPsFails_ShouldReturnFailure()
    {
        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("Module not found"));

        var result = await this.sut.ValidateAdkInstallationAsync();

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetImageInfoAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.GetImageInfoAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task CreateBootableIsoAsync_WithEmptySourceDir_ShouldThrow()
    {
        var act = () => this.sut.CreateBootableIsoAsync(string.Empty, @"C:\output.iso");
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task CreateBootableIsoAsync_WithEmptyOutputPath_ShouldThrow()
    {
        var act = () => this.sut.CreateBootableIsoAsync(@"C:\source", string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    private static ImageBuildRequest CreateTestRequest()
    {
        return new ImageBuildRequest
        {
            Name = "TestImage",
            SourcePath = @"C:\source",
            OutputDirectory = @"C:\output",
            Architecture = ImageArchitecture.Amd64,
        };
    }

    private static Result<IReadOnlyList<PSObject>> CreateSuccessPsResult(PSObject obj)
    {
        return Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject> { obj });
    }
}
