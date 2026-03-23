// <copyright file="ImageBuilderViewModelTests.cs" company="Better11">
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

public sealed class ImageBuilderViewModelTests
{
    private readonly Mock<IImageBuilderService> imageBuilderServiceMock;
    private readonly Mock<ILogger<ImageBuilderViewModel>> loggerMock;
    private readonly ImageBuilderViewModel sut;

    public ImageBuilderViewModelTests()
    {
        this.imageBuilderServiceMock = new Mock<IImageBuilderService>();
        this.loggerMock = new Mock<ILogger<ImageBuilderViewModel>>();
        this.sut = new ImageBuilderViewModel(this.imageBuilderServiceMock.Object, this.loggerMock.Object);
    }

    [Fact]
    public void Constructor_ShouldInitializeWithDefaults()
    {
        this.sut.ImageName.Should().BeEmpty();
        this.sut.Status.Should().Be("Ready");
        this.sut.IsBuilding.Should().BeFalse();
        this.sut.ProgressPercent.Should().Be(0);
    }

    [Fact]
    public void Constructor_WithNullService_ShouldThrow()
    {
        var act = () => new ImageBuilderViewModel(null!, this.loggerMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new ImageBuilderViewModel(this.imageBuilderServiceMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task ValidateAdkAsync_WhenInstalled_ShouldSetStatusToReady()
    {
        var adkResult = new AdkValidationResult
        {
            IsInstalled = true,
            AdkPath = @"C:\ADK",
            Version = "10.0",
        };
        this.imageBuilderServiceMock
            .Setup(s => s.ValidateAdkInstallationAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AdkValidationResult>.Ok(adkResult));

        await this.sut.ValidateAdkCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("ADK");
    }

    [Fact]
    public async Task ValidateAdkAsync_WhenNotInstalled_ShouldSetErrorStatus()
    {
        this.imageBuilderServiceMock
            .Setup(s => s.ValidateAdkInstallationAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AdkValidationResult>.Fail("ADK not found"));

        await this.sut.ValidateAdkCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task BuildImageAsync_WithEmptyName_ShouldSetError()
    {
        this.sut.ImageName = string.Empty;
        this.sut.OutputDirectory = @"C:\output";

        await this.sut.BuildImageCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task BuildImageAsync_WithEmptyOutputDir_ShouldSetError()
    {
        this.sut.ImageName = "TestImage";
        this.sut.OutputDirectory = string.Empty;

        await this.sut.BuildImageCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task BuildImageAsync_WhenSuccessful_ShouldUpdateStatus()
    {
        this.sut.ImageName = "TestImage";
        this.sut.OutputDirectory = @"C:\output";

        var buildResult = new ImageBuildResult
        {
            Success = true,
            ImagePath = @"C:\output\boot.wim",
            ImageSizeMb = 256,
        };

        this.imageBuilderServiceMock
            .Setup(s => s.BuildImageAsync(It.IsAny<ImageBuildRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<ImageBuildResult>.Ok(buildResult));

        await this.sut.BuildImageCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("success");
        this.sut.IsBuilding.Should().BeFalse();
    }

    [Fact]
    public async Task BuildImageAsync_WhenFails_ShouldSetErrorAndNotBuilding()
    {
        this.sut.ImageName = "TestImage";
        this.sut.OutputDirectory = @"C:\output";

        this.imageBuilderServiceMock
            .Setup(s => s.BuildImageAsync(It.IsAny<ImageBuildRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<ImageBuildResult>.Fail("DISM error"));

        await this.sut.BuildImageCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
        this.sut.IsBuilding.Should().BeFalse();
    }

    [Fact]
    public async Task BuildImageAsync_WhenException_ShouldCatchAndSetError()
    {
        this.sut.ImageName = "TestImage";
        this.sut.OutputDirectory = @"C:\output";

        this.imageBuilderServiceMock
            .Setup(s => s.BuildImageAsync(It.IsAny<ImageBuildRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Unexpected error"));

        await this.sut.BuildImageCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
        this.sut.IsBuilding.Should().BeFalse();
    }

    [Fact]
    public void PropertyChanges_ShouldRaiseNotification()
    {
        bool raised = false;
        this.sut.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(ImageBuilderViewModel.ImageName))
            {
                raised = true;
            }
        };

        this.sut.ImageName = "NewName";

        raised.Should().BeTrue();
    }

    [Fact]
    public void ScratchSpaceMb_ShouldDefaultTo512()
    {
        this.sut.ScratchSpaceMb.Should().Be(512);
    }

    [Fact]
    public void EnablePowerShell_ShouldDefaultToTrue()
    {
        this.sut.EnablePowerShell.Should().BeTrue();
    }
}
