// ============================================================================
// Better11 System Enhancement Suite — StartupServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.Services.Startup;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="StartupService"/>.
/// </summary>
public sealed class StartupServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<StartupService>> _mockLogger;
    private readonly StartupService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="StartupServiceTests"/> class.
    /// </summary>
    public StartupServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<StartupService>>();
        _service = new StartupService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        // Act & Assert
        var act = () => new StartupService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task GetStartupItemsAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        var expected = new List<StartupItemDto> { new() };
        _mockPs.Setup(x => x.InvokeCommandListAsync<StartupItemDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(expected));

        // Act
        var result = await _service.GetStartupItemsAsync(CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
    }

    [Fact]
    public async Task GetStartupItemsAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandListAsync<StartupItemDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.GetStartupItemsAsync(CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task EnableStartupItemAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.EnableStartupItemAsync("item-1", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task EnableStartupItemAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.EnableStartupItemAsync("item-1", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task DisableStartupItemAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.DisableStartupItemAsync("item-1", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task DisableStartupItemAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.DisableStartupItemAsync("item-1", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task RemoveStartupItemAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.RemoveStartupItemAsync("item-1", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RemoveStartupItemAsync_ReturnsFailure_WhenPowerShellFails()
    {
        // Arrange
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        // Act
        var result = await _service.RemoveStartupItemAsync("item-1", CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
    }
}
