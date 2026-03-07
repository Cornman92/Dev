// Copyright (c) Better11. All rights reserved.

using Better11.Core.Interfaces;
using Better11.Services.AppUpdate;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="AppUpdateService"/>.
/// </summary>
public sealed class AppUpdateServiceTests
{
    private readonly Mock<ILogger<AppUpdateService>> _mockLogger = new();

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenLoggerIsNull()
    {
        var act = () => new AppUpdateService(null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task InstallUpdateAsync_ReturnsFailure_WhenPathIsNull()
    {
        var service = new AppUpdateService(_mockLogger.Object);
        var result = await service.InstallUpdateAsync(null!);
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task InstallUpdateAsync_ReturnsFailure_WhenPathIsEmpty()
    {
        var service = new AppUpdateService(_mockLogger.Object);
        var result = await service.InstallUpdateAsync(string.Empty);
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task InstallUpdateAsync_ReturnsFailure_WhenFileDoesNotExist()
    {
        var service = new AppUpdateService(_mockLogger.Object);
        var result = await service.InstallUpdateAsync(@"C:\Nonexistent\Better11_99.0.0.0_x64_Release.msix");
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task DownloadUpdateAsync_ReturnsFailure_WhenUpdateInfoIsNull()
    {
        var service = new AppUpdateService(_mockLogger.Object);
        var act = async () => await service.DownloadUpdateAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [Fact]
    public async Task DownloadUpdateAsync_ReturnsFailure_WhenDownloadUrlIsEmpty()
    {
        var service = new AppUpdateService(_mockLogger.Object);
        var updateInfo = new AppUpdateInfo { Version = "1.1.0", DownloadUrl = string.Empty };
        var result = await service.DownloadUpdateAsync(updateInfo);
        result.IsSuccess.Should().BeFalse();
    }
}
