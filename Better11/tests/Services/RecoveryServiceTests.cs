// <copyright file="RecoveryServiceTests.cs" company="Better11">
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

public sealed class RecoveryServiceTests
{
    private readonly Mock<IPowerShellService> psServiceMock;
    private readonly Mock<ILogger<RecoveryService>> loggerMock;
    private readonly Mock<IOptions<BetterPEOptions>> optionsMock;
    private readonly RecoveryService sut;

    public RecoveryServiceTests()
    {
        this.psServiceMock = new Mock<IPowerShellService>();
        this.loggerMock = new Mock<ILogger<RecoveryService>>();
        this.optionsMock = new Mock<IOptions<BetterPEOptions>>();
        this.optionsMock.Setup(o => o.Value).Returns(new BetterPEOptions
        {
            WorkingDirectory = Path.GetTempPath(),
            PowerShellModulesPath = "PowerShell",
        });

        this.sut = new RecoveryService(
            this.psServiceMock.Object,
            this.loggerMock.Object,
            this.optionsMock.Object);
    }

    [Fact]
    public void Constructor_WithNullPsService_ShouldThrow()
    {
        var act = () => new RecoveryService(null!, this.loggerMock.Object, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullLogger_ShouldThrow()
    {
        var act = () => new RecoveryService(this.psServiceMock.Object, null!, this.optionsMock.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_WithNullOptions_ShouldThrow()
    {
        var act = () => new RecoveryService(this.psServiceMock.Object, this.loggerMock.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task GetWinReStatusAsync_WhenPsSucceeds_ShouldReturnStatus()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new
            {
                IsEnabled = true,
                ImagePath = @"C:\Recovery\Winre.wim",
                Version = "10.0.26100",
                Partition = "partition4",
                SizeMB = 450.0,
            }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.GetWinReStatusAsync();

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task GetWinReStatusAsync_WhenPsFails_ShouldReturnFailure()
    {
        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("reagentc not found"));

        var result = await this.sut.GetWinReStatusAsync();

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task SetWinReEnabledAsync_WhenPsSucceeds_ShouldReturnSuccess()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(true),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.SetWinReEnabledAsync(true);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task BuildRecoveryEnvironmentAsync_WithNullRequest_ShouldThrow()
    {
        var act = () => this.sut.BuildRecoveryEnvironmentAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task BuildRecoveryEnvironmentAsync_WhenPsSucceeds_ShouldReturnResult()
    {
        var request = new RecoveryBuildRequest
        {
            Name = "TestRecovery",
            OutputDirectory = @"C:\output",
            Type = RecoveryType.WinRE,
        };

        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(new
            {
                Success = true,
                OutputPath = @"C:\output\TestRecovery.wim",
                ImageSizeMB = 450.0,
                DriversInjected = 0,
                ToolsIncluded = 0,
            }),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.BuildRecoveryEnvironmentAsync(request);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task BuildRecoveryEnvironmentAsync_WhenPsFails_ShouldReturnFailure()
    {
        var request = new RecoveryBuildRequest
        {
            Name = "TestRecovery",
            OutputDirectory = @"C:\output",
        };

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PSObject>>.Fail("WinRE not found"));

        var result = await this.sut.BuildRecoveryEnvironmentAsync(request);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task BackupWinReImageAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.BackupWinReImageAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task BackupWinReImageAsync_WhenPsSucceeds_ShouldReturnPath()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>
        {
            new PSObject(@"C:\backups\winre_backup.wim"),
        });

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.BackupWinReImageAsync(@"C:\backups\winre_backup.wim");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RestoreWinReImageAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.RestoreWinReImageAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task RegisterWinReImageAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.RegisterWinReImageAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ValidateRecoveryEnvironmentAsync_WithEmptyPath_ShouldThrow()
    {
        var act = () => this.sut.ValidateRecoveryEnvironmentAsync(string.Empty);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task ValidateRecoveryEnvironmentAsync_WhenPsSucceeds_ShouldReturnIssues()
    {
        var psResult = Result<IReadOnlyList<PSObject>>.Ok(new List<PSObject>());

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(psResult);

        var result = await this.sut.ValidateRecoveryEnvironmentAsync(@"C:\recovery.wim");

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task BuildRecoveryEnvironmentAsync_WhenException_ShouldReturnFailure()
    {
        var request = new RecoveryBuildRequest
        {
            Name = "TestRecovery",
            OutputDirectory = @"C:\output",
        };

        this.psServiceMock
            .Setup(s => s.ExecuteScriptAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Module error"));

        var result = await this.sut.BuildRecoveryEnvironmentAsync(request);

        result.IsSuccess.Should().BeFalse();
    }
}
