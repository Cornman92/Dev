// ============================================================================
// Better11 System Enhancement Suite — PackageServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.Services.Package;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="PackageService"/>.
/// </summary>
public sealed class PackageServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<PackageService>> _mockLogger;
    private readonly PackageService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="PackageServiceTests"/> class.
    /// </summary>
    public PackageServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<PackageService>>();
        _service = new PackageService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        // Act & Assert
        var act = () => new PackageService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task GetInstalledPackagesAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        var expected = new List<PackageDto> { new() };
        _mockPs.Setup(x => x.InvokeCommandListAsync<PackageDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(expected));

        // Act
        var result = await _service.GetInstalledPackagesAsync(CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
    }

    [Fact]
    public async Task GetInstalledPackagesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandListAsync<PackageDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.GetInstalledPackagesAsync(CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetAvailableUpdatesAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        var expected = new List<PackageDto> { new() };
        _mockPs.Setup(x => x.InvokeCommandListAsync<PackageDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(expected));

        // Act
        var result = await _service.GetAvailableUpdatesAsync(CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
    }

    [Fact]
    public async Task GetAvailableUpdatesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandListAsync<PackageDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.GetAvailableUpdatesAsync(CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task InstallPackageAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.InstallPackageAsync("test-pkg", "winget", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task InstallPackageAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.InstallPackageAsync("test-pkg", "winget", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task UninstallPackageAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.UninstallPackageAsync("test-pkg", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task UninstallPackageAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.UninstallPackageAsync("test-pkg", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task UpdatePackageAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.UpdatePackageAsync("test-pkg", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task UpdatePackageAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.UpdatePackageAsync("test-pkg", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task SearchPackagesAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        var expected = new List<PackageDto> { new() };
        _mockPs.Setup(x => x.InvokeCommandListAsync<PackageDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(expected));

        // Act
        var result = await _service.SearchPackagesAsync("query", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
    }

    [Fact]
    public async Task SearchPackagesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandListAsync<PackageDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.SearchPackagesAsync("query", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }
}
