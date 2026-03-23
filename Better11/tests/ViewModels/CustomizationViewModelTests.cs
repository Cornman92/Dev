// <copyright file="CustomizationViewModelTests.cs" company="Better11">
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

public sealed class CustomizationViewModelTests
{
    private readonly Mock<ICustomizationService> customizationServiceMock;
    private readonly Mock<ILogger<CustomizationViewModel>> loggerMock;
    private readonly CustomizationViewModel sut;

    public CustomizationViewModelTests()
    {
        this.customizationServiceMock = new Mock<ICustomizationService>();
        this.loggerMock = new Mock<ILogger<CustomizationViewModel>>();
        this.sut = new CustomizationViewModel(this.customizationServiceMock.Object, this.loggerMock.Object);
    }

    [Fact]
    public void Constructor_ShouldInitializeWithDefaults()
    {
        this.sut.Status.Should().Be("Ready");
        this.sut.MountPath.Should().BeEmpty();
        this.sut.EnablePowerShell.Should().BeTrue();
        this.sut.EnableWmi.Should().BeTrue();
        this.sut.EnableNetworking.Should().BeTrue();
        this.sut.EnableDotNet.Should().BeFalse();
        this.sut.ScratchSpaceMb.Should().Be(512);
        this.sut.IsApplying.Should().BeFalse();
    }

    [Fact]
    public void Constructor_WithNullService_ShouldThrow()
    {
        var act = () => new CustomizationViewModel(null!, this.loggerMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new CustomizationViewModel(this.customizationServiceMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task LoadProfilesAsync_WhenSuccessful_ShouldPopulateProfiles()
    {
        var profiles = new List<CustomizationProfile>
        {
            new() { Name = "Profile1" },
            new() { Name = "Profile2" },
        };

        this.customizationServiceMock
            .Setup(s => s.ListProfilesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<CustomizationProfile>>.Ok(profiles));

        await this.sut.LoadProfilesCommand.ExecuteAsync(null);

        this.sut.Profiles.Should().HaveCount(2);
    }

    [Fact]
    public async Task LoadAvailableComponentsAsync_WhenSuccessful_ShouldPopulate()
    {
        var components = new Dictionary<string, object>
        {
            ["WinPE-PowerShell"] = new { },
            ["WinPE-WMI"] = new { },
        };

        this.customizationServiceMock
            .Setup(s => s.GetAvailableComponentsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyDictionary<string, object>>.Ok(components));

        await this.sut.LoadAvailableComponentsCommand.ExecuteAsync(null);

        this.sut.AvailableComponents.Should().HaveCount(2);
    }

    [Fact]
    public async Task ApplyCustomizationsAsync_WithEmptyMountPath_ShouldSetError()
    {
        this.sut.MountPath = string.Empty;

        await this.sut.ApplyCustomizationsCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task ApplyCustomizationsAsync_WhenSuccessful_ShouldSetSuccessStatus()
    {
        this.sut.MountPath = @"C:\mount";
        this.customizationServiceMock
            .Setup(s => s.ApplyProfileAsync(It.IsAny<string>(), It.IsAny<CustomizationProfile>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));

        await this.sut.ApplyCustomizationsCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("success");
        this.sut.IsApplying.Should().BeFalse();
    }

    [Fact]
    public async Task ApplyCustomizationsAsync_WhenFails_ShouldSetError()
    {
        this.sut.MountPath = @"C:\mount";
        this.customizationServiceMock
            .Setup(s => s.ApplyProfileAsync(It.IsAny<string>(), It.IsAny<CustomizationProfile>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Fail("Apply failed"));

        await this.sut.ApplyCustomizationsCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task SaveProfileAsync_WhenSuccessful_ShouldReloadProfiles()
    {
        var profiles = new List<CustomizationProfile>();
        this.customizationServiceMock
            .Setup(s => s.SaveProfileAsync(It.IsAny<CustomizationProfile>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));
        this.customizationServiceMock
            .Setup(s => s.ListProfilesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<CustomizationProfile>>.Ok(profiles));

        await this.sut.SaveProfileCommand.ExecuteAsync("TestProfile");

        this.sut.Status.Should().Contain("saved");
        this.customizationServiceMock.Verify(s => s.ListProfilesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public void LoadSelectedProfile_WithNullProfile_ShouldDoNothing()
    {
        this.sut.SelectedProfile = null;
        string originalStatus = this.sut.Status;

        this.sut.LoadSelectedProfileCommand.Execute(null);

        this.sut.Status.Should().Be(originalStatus);
    }

    [Fact]
    public void LoadSelectedProfile_WithProfile_ShouldApplySettings()
    {
        this.sut.SelectedProfile = new CustomizationProfile
        {
            Name = "Test",
            EnablePowerShell = false,
            EnableDotNet = true,
            EnableWmi = false,
            EnableNetworking = false,
            ScratchSpaceMb = 1024,
            Entries = [new CustomizationEntry { Name = "Entry1" }],
            OptionalComponents = ["WinPE-HTA"],
        };

        this.sut.LoadSelectedProfileCommand.Execute(null);

        this.sut.EnablePowerShell.Should().BeFalse();
        this.sut.EnableDotNet.Should().BeTrue();
        this.sut.EnableWmi.Should().BeFalse();
        this.sut.EnableNetworking.Should().BeFalse();
        this.sut.ScratchSpaceMb.Should().Be(1024);
        this.sut.Entries.Should().HaveCount(1);
        this.sut.SelectedComponents.Should().HaveCount(1);
        this.sut.Status.Should().Contain("Test");
    }

    [Fact]
    public void Collections_ShouldBeEmptyInitially()
    {
        this.sut.Profiles.Should().BeEmpty();
        this.sut.Entries.Should().BeEmpty();
        this.sut.AvailableComponents.Should().BeEmpty();
        this.sut.SelectedComponents.Should().BeEmpty();
        this.sut.StartupScripts.Should().BeEmpty();
    }
}
