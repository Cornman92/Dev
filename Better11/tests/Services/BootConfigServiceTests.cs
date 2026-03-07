// <copyright file="BootConfigServiceTests.cs" company="Better11">
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

public sealed class BootConfigServiceTests
{
    private readonly Mock<IPowerShellService> psServiceMock;
    private readonly Mock<ILogger<BootConfigService>> loggerMock;
    private readonly Mock<IOptions<BetterPEOptions>> optionsMock;
    private readonly BootConfigService sut;

    public BootConfigServiceTests()
    {
        this.psServiceMock = new Mock<IPowerShellService>();
        this.loggerMock = new Mock<ILogger<BootConfigService>>();
        this.optionsMock = new Mock<IOptions<BetterPEOptions>>();
        this.optionsMock.Setup(o => o.Value).Returns(new BetterPEOptions
        {
            WorkingDirectory = Path.GetTempPath(),
            PowerShellModulesPath = "PowerShell",
        });

        this.sut = new BootConfigService(
            this.psServiceMock.Object,
            this.loggerMock.Object,
            this.optionsMock.Object);
    }

    [Fact]
    public void Constructor_WithNullPsService_ShouldThrow()
    {
        var act = () => new BootConfigService(null!, this.loggerMock.Object, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new BootConfigService(this.psServiceMock.Object, null!, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullOptions_ShouldThrow()
    {
        var act = () => new BootConfigService(this.psServiceMock.Object, this.loggerMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task ConfigureBootAsync_WithEmptyPeDir_ShouldThrow()
    {
        var act = () => this.sut.ConfigureBootAsync(string.Empty, new BootConfigurationOptions());
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ConfigureBootAsync_WithNullOptions_ShouldThrow()
    {
        var act = () => this.sut.ConfigureBootAsync(@"C:\pe", null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task ConfigureBootAsync_WhenPsSucceeds_ShouldReturnSuccess()
    {
        var options = new BootConfigurationOptions { FirmwareType = FirmwareType.Both };
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Success = true, BiosConfigured = true, UefiConfigured = true }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ConfigureBootAsync(@"C:\pe", options);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ConfigureBootAsync_WhenPsFails_ShouldReturnFailure()
    {
        var options = new BootConfigurationOptions();

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("bcdedit failed"));

        var result = await this.sut.ConfigureBootAsync(@"C:\pe", options);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetBootConfigAsync_WhenPsSucceeds_ShouldReturnConfig()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new
            {
                FirmwareType = "UEFI",
                TimeoutSeconds = 15,
                Description = "Test",
                Locale = "en-US",
                EnableSafeMode = false,
                EnableDebug = false,
                DisableIntegrityChecks = false,
                EnableNetworkBoot = false,
                EnableRecovery = true,
            }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.GetBootConfigAsync(@"C:\pe\BCD");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ValidateBootConfigAsync_WithEmptyPeDir_ShouldThrow()
    {
        var act = () => this.sut.ValidateBootConfigAsync(string.Empty, FirmwareType.Both);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ValidateBootConfigAsync_WhenPsSucceeds_ShouldReturnIssues()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new { Severity = "Warning", Component = "BIOS", Message = "Missing bootmgr" }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ValidateBootConfigAsync(@"C:\pe", FirmwareType.Both);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ConfigureSecureBootAsync_WithEmptyPeDir_ShouldThrow()
    {
        var act = () => this.sut.ConfigureSecureBootAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ConfigureSecureBootAsync_WhenPsSucceeds_ShouldReturnSuccess()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(true),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ConfigureSecureBootAsync(@"C:\pe");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ConfigureBootAsync_WhenException_ShouldReturnFailure()
    {
        var options = new BootConfigurationOptions();

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Module error"));

        var result = await this.sut.ConfigureBootAsync(@"C:\pe", options);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task SetBcdEntryAsync_WithEmptyBcdPath_ShouldThrow()
    {
        var act = () => this.sut.SetBcdEntryAsync(string.Empty, "{bootmgr}", "timeout", "30");
        await act.Should().ThrowAsync<ArgumentException>();
    }
}
