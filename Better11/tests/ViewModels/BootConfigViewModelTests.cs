// <copyright file="BootConfigViewModelTests.cs" company="Better11">
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

public sealed class BootConfigViewModelTests
{
    private readonly Mock<IBootConfigService> bootConfigServiceMock;
    private readonly Mock<ILogger<BootConfigViewModel>> loggerMock;
    private readonly BootConfigViewModel sut;

    public BootConfigViewModelTests()
    {
        this.bootConfigServiceMock = new Mock<IBootConfigService>();
        this.loggerMock = new Mock<ILogger<BootConfigViewModel>>();
        this.sut = new BootConfigViewModel(this.bootConfigServiceMock.Object, this.loggerMock.Object);
    }

    [Fact]
    public void Constructor_ShouldInitializeWithDefaults()
    {
        this.sut.Status.Should().Be("Ready");
        this.sut.FirmwareType.Should().Be(FirmwareType.Both);
        this.sut.TimeoutSeconds.Should().Be(30);
        this.sut.Description.Should().Be("Better11 WinPE");
        this.sut.Locale.Should().Be("en-US");
        this.sut.EnableRecovery.Should().BeTrue();
        this.sut.IsConfiguring.Should().BeFalse();
    }

    [Fact]
    public void Constructor_WithNullService_ShouldThrow()
    {
        var act = () => new BootConfigViewModel(null!, this.loggerMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new BootConfigViewModel(this.bootConfigServiceMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task ApplyConfigAsync_WithEmptyPeDirectory_ShouldSetError()
    {
        this.sut.PeDirectory = string.Empty;

        await this.sut.ApplyConfigCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task ApplyConfigAsync_WhenSuccessful_ShouldSetSuccessStatus()
    {
        this.sut.PeDirectory = @"C:\pe";
        this.bootConfigServiceMock
            .Setup(s => s.ConfigureBootAsync(It.IsAny<string>(), It.IsAny<BootConfigurationOptions>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));

        await this.sut.ApplyConfigCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("applied");
        this.sut.IsConfiguring.Should().BeFalse();
    }

    [Fact]
    public async Task ValidateConfigAsync_WithEmptyPeDirectory_ShouldSetError()
    {
        this.sut.PeDirectory = string.Empty;

        await this.sut.ValidateConfigCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task ValidateConfigAsync_WhenNoIssues_ShouldShowPassed()
    {
        this.sut.PeDirectory = @"C:\pe";
        var issues = new List<BuildIssue>();
        this.bootConfigServiceMock
            .Setup(s => s.ValidateBootConfigAsync(It.IsAny<string>(), It.IsAny<FirmwareType>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<BuildIssue>>.Ok(issues));

        await this.sut.ValidateConfigCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("passed");
        this.sut.ValidationIssues.Should().BeEmpty();
    }

    [Fact]
    public async Task ValidateConfigAsync_WithIssues_ShouldPopulateIssues()
    {
        this.sut.PeDirectory = @"C:\pe";
        var issues = new List<BuildIssue>
        {
            new() { Severity = IssueSeverity.Warning, Description = "Missing boot.sdi" },
            new() { Severity = IssueSeverity.Error, Description = "No BCD store" },
        };
        this.bootConfigServiceMock
            .Setup(s => s.ValidateBootConfigAsync(It.IsAny<string>(), It.IsAny<FirmwareType>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<BuildIssue>>.Ok(issues));

        await this.sut.ValidateConfigCommand.ExecuteAsync(null);

        this.sut.ValidationIssues.Should().HaveCount(2);
        this.sut.Status.Should().Contain("2");
    }

    [Fact]
    public async Task ConfigureSecureBootAsync_WithEmptyPeDirectory_ShouldSetError()
    {
        this.sut.PeDirectory = string.Empty;

        await this.sut.ConfigureSecureBootCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Error");
    }

    [Fact]
    public async Task ConfigureSecureBootAsync_WhenSuccessful_ShouldSetSuccessStatus()
    {
        this.sut.PeDirectory = @"C:\pe";
        this.bootConfigServiceMock
            .Setup(s => s.ConfigureSecureBootAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));

        await this.sut.ConfigureSecureBootCommand.ExecuteAsync(null);

        this.sut.Status.Should().Contain("Secure Boot");
    }
}
