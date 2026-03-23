// <copyright file="DriverIntegrationServiceTests.cs" company="Better11">
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

public sealed class DriverIntegrationServiceTests
{
    private readonly Mock<IPowerShellService> psServiceMock;
    private readonly Mock<ILogger<DriverIntegrationService>> loggerMock;
    private readonly Mock<IOptions<BetterPEOptions>> optionsMock;
    private readonly DriverIntegrationService sut;

    public DriverIntegrationServiceTests()
    {
        this.psServiceMock = new Mock<IPowerShellService>();
        this.loggerMock = new Mock<ILogger<DriverIntegrationService>>();
        this.optionsMock = new Mock<IOptions<BetterPEOptions>>();
        this.optionsMock.Setup(o => o.Value).Returns(new BetterPEOptions
        {
            WorkingDirectory = Path.GetTempPath(),
            PowerShellModulesPath = "PowerShell",
            DriverRepositoryPath = Path.GetTempPath(),
        });

        this.sut = new DriverIntegrationService(
            this.psServiceMock.Object,
            this.loggerMock.Object,
            this.optionsMock.Object);
    }

    [Fact]
    public void Constructor_WithNullPsService_ShouldThrow()
    {
        var act = () => new DriverIntegrationService(null!, this.loggerMock.Object, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new DriverIntegrationService(this.psServiceMock.Object, null!, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullOptions_ShouldThrow()
    {
        var act = () => new DriverIntegrationService(this.psServiceMock.Object, this.loggerMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task ScanDriversAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.ScanDriversAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ScanDriversAsync_WhenPsSucceeds_ShouldReturnDrivers()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Name = "TestDriver", Version = "1.0", Class = "Display" }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ScanDriversAsync(@"C:\drivers");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ScanDriversAsync_WhenPsFails_ShouldReturnFailure()
    {
        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("Access denied"));

        var result = await this.sut.ScanDriversAsync(@"C:\drivers");

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task InjectDriversAsync_WithNullRequest_ShouldThrow()
    {
        var act = () => this.sut.InjectDriversAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task InjectDriversAsync_WhenSucceeds_ShouldReturnResult()
    {
        var request = new DriverInjectionRequest
        {
            MountPath = @"C:\mount",
            DriverPaths = new List<string> { @"C:\drivers" },
        };

        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Success = true, DriversInjected = 5 }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.InjectDriversAsync(request);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task GetDriverInfoAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.GetDriverInfoAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ExportSystemDriversAsync_WithEmptyOutputPath_ShouldThrow()
    {
        var act = () => this.sut.ExportSystemDriversAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task VerifyCompatibilityAsync_WithNullRequest_ShouldThrow()
    {
        var act = () => this.sut.VerifyCompatibilityAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task ScanDriversAsync_WhenException_ShouldReturnFailure()
    {
        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Module error"));

        var result = await this.sut.ScanDriversAsync(@"C:\drivers");

        result.IsSuccess.Should().BeFalse();
    }
}
