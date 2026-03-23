// <copyright file="BetterPEMainViewModelTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.ViewModels;

using Better11.Modules.BetterPE.ViewModels;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class BetterPEMainViewModelTests
{
    private readonly Mock<ILogger<BetterPEMainViewModel>> loggerMock;
    private readonly Mock<ImageBuilderViewModel> imageBuilderMock;
    private readonly Mock<DriverManagerViewModel> driverManagerMock;
    private readonly Mock<CustomizationViewModel> customizationMock;
    private readonly Mock<BootConfigViewModel> bootConfigMock;
    private readonly Mock<RecoveryViewModel> recoveryMock;
    private readonly Mock<DeploymentViewModel> deploymentMock;

    public BetterPEMainViewModelTests()
    {
        this.loggerMock = new Mock<ILogger<BetterPEMainViewModel>>();

        // Create minimal mocks for the sub-ViewModels
        this.imageBuilderMock = CreateViewModelMock<ImageBuilderViewModel>();
        this.driverManagerMock = CreateViewModelMock<DriverManagerViewModel>();
        this.customizationMock = CreateViewModelMock<CustomizationViewModel>();
        this.bootConfigMock = CreateViewModelMock<BootConfigViewModel>();
        this.recoveryMock = CreateViewModelMock<RecoveryViewModel>();
        this.deploymentMock = CreateViewModelMock<DeploymentViewModel>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            null!,
            this.imageBuilderMock.Object,
            this.driverManagerMock.Object,
            this.customizationMock.Object,
            this.bootConfigMock.Object,
            this.recoveryMock.Object,
            this.deploymentMock.Object);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullImageBuilder_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            this.loggerMock.Object,
            null!,
            this.driverManagerMock.Object,
            this.customizationMock.Object,
            this.bootConfigMock.Object,
            this.recoveryMock.Object,
            this.deploymentMock.Object);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullDriverManager_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            this.loggerMock.Object,
            this.imageBuilderMock.Object,
            null!,
            this.customizationMock.Object,
            this.bootConfigMock.Object,
            this.recoveryMock.Object,
            this.deploymentMock.Object);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullCustomization_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            this.loggerMock.Object,
            this.imageBuilderMock.Object,
            this.driverManagerMock.Object,
            null!,
            this.bootConfigMock.Object,
            this.recoveryMock.Object,
            this.deploymentMock.Object);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullBootConfig_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            this.loggerMock.Object,
            this.imageBuilderMock.Object,
            this.driverManagerMock.Object,
            this.customizationMock.Object,
            null!,
            this.recoveryMock.Object,
            this.deploymentMock.Object);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullRecovery_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            this.loggerMock.Object,
            this.imageBuilderMock.Object,
            this.driverManagerMock.Object,
            this.customizationMock.Object,
            this.bootConfigMock.Object,
            null!,
            this.deploymentMock.Object);

        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullDeployment_ShouldThrow()
    {
        var act = () => new BetterPEMainViewModel(
            this.loggerMock.Object,
            this.imageBuilderMock.Object,
            this.driverManagerMock.Object,
            this.customizationMock.Object,
            this.bootConfigMock.Object,
            this.recoveryMock.Object,
            null!);

        act.Should().Throw<ArgumentNullException>();
    }

    private static Mock<T> CreateViewModelMock<T>()
        where T : class
    {
        return new Mock<T>(MockBehavior.Loose, Array.Empty<object>()) { CallBase = false };
    }
}
