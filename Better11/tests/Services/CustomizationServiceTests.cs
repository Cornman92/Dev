// <copyright file="CustomizationServiceTests.cs" company="Better11">
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

public sealed class CustomizationServiceTests
{
    private readonly Mock<IPowerShellService> psServiceMock;
    private readonly Mock<ILogger<CustomizationService>> loggerMock;
    private readonly Mock<IOptions<BetterPEOptions>> optionsMock;
    private readonly CustomizationService sut;

    public CustomizationServiceTests()
    {
        this.psServiceMock = new Mock<IPowerShellService>();
        this.loggerMock = new Mock<ILogger<CustomizationService>>();
        this.optionsMock = new Mock<IOptions<BetterPEOptions>>();
        this.optionsMock.Setup(o => o.Value).Returns(new BetterPEOptions
        {
            WorkingDirectory = Path.GetTempPath(),
            PowerShellModulesPath = "PowerShell",
            ProfilesDirectory = Path.Combine(Path.GetTempPath(), "BetterPE_Profiles"),
        });

        this.sut = new CustomizationService(
            this.psServiceMock.Object,
            this.loggerMock.Object,
            this.optionsMock.Object);
    }

    [Fact]
    public void Constructor_WithNullPsService_ShouldThrow()
    {
        var act = () => new CustomizationService(null!, this.loggerMock.Object, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new CustomizationService(this.psServiceMock.Object, null!, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullOptions_ShouldThrow()
    {
        var act = () => new CustomizationService(this.psServiceMock.Object, this.loggerMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task ApplyProfileAsync_WithEmptyMountPath_ShouldThrow()
    {
        var act = () => this.sut.ApplyProfileAsync(string.Empty, new CustomizationProfile());
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ApplyProfileAsync_WithNullProfile_ShouldThrow()
    {
        var act = () => this.sut.ApplyProfileAsync(@"C:\mount", null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task ApplyProfileAsync_WhenPsSucceeds_ShouldReturnSuccess()
    {
        var profile = new CustomizationProfile { Name = "TestProfile", EnablePowerShell = true };
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Success = true, EntriesApplied = 3 }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ApplyProfileAsync(@"C:\mount", profile);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ApplyProfileAsync_WhenPsFails_ShouldReturnFailure()
    {
        var profile = new CustomizationProfile { Name = "TestProfile" };

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("Customization error"));

        var result = await this.sut.ApplyProfileAsync(@"C:\mount", profile);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetAvailableComponentsAsync_WhenPsSucceeds_ShouldReturnDictionary()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Name = "WinPE-WMI", Description = "WMI support" }),
            new PSObject(new { Name = "WinPE-NetFx", Description = ".NET Framework" }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.GetAvailableComponentsAsync();

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task SaveProfileAsync_WithNullProfile_ShouldThrow()
    {
        var act = () => this.sut.SaveProfileAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task LoadProfileAsync_WithEmptyName_ShouldThrow()
    {
        var act = () => this.sut.LoadProfileAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task DeleteProfileAsync_WithEmptyName_ShouldThrow()
    {
        var act = () => this.sut.DeleteProfileAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ApplyProfileAsync_WhenException_ShouldReturnFailure()
    {
        var profile = new CustomizationProfile { Name = "TestProfile" };

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Module error"));

        var result = await this.sut.ApplyProfileAsync(@"C:\mount", profile);

        result.IsSuccess.Should().BeFalse();
    }
}
