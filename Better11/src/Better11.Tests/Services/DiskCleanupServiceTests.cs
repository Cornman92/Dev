// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Services;

using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.DiskCleanup;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class DiskCleanupServiceTests : IDisposable
{
    private readonly Mock<IPowerShellService> _psMock;
    private readonly Mock<ILogger<DiskCleanupService>> _loggerMock;
    private readonly DiskCleanupService _service;
    private bool _disposed;

    public DiskCleanupServiceTests()
    {
        _psMock = new Mock<IPowerShellService>();
        _loggerMock = new Mock<ILogger<DiskCleanupService>>();
        _service = new DiskCleanupService(_psMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task ScanAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 1024,
            Categories = new[]
            {
                new CleanupCategoryDto { Name = "Temp", ReclaimableBytes = 1024 }
            }
        };

        _psMock.Setup(x => x.InvokeCommandAsync<DiskScanResultDto>(
            AppConstants.Modules.DiskCleanup,
            "Invoke-B11DiskScan",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(expectedResult));

        // Act
        var result = await _service.ScanAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
        _psMock.Verify(
            x => x.InvokeCommandAsync<DiskScanResultDto>(
                AppConstants.Modules.DiskCleanup,
                "Invoke-B11DiskScan",
                null,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ScanAsyncShouldReturnFailureWhenPowerShellFails()
    {
        // Arrange
        var expectedError = "PowerShell Error";
        _psMock.Setup(x => x.InvokeCommandAsync<DiskScanResultDto>(
            It.IsAny<string>(),
            It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Failure(ErrorCodes.PowerShell, expectedError));

        // Act
        var result = await _service.ScanAsync();

        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Be(expectedError);
    }

    [Fact]
    public async Task CleanAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var categories = new[] { "Temp", "Logs" };
        var expectedResult = new CleanupResultDto
        {
            BytesFreed = 2048,
            FilesRemoved = 10
        };

        _psMock.Setup(x => x.InvokeCommandAsync<CleanupResultDto>(
            AppConstants.Modules.DiskCleanup,
            "Invoke-B11DiskClean",
            It.Is<IDictionary<string, object>>(p => p.ContainsKey("Categories")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(expectedResult));

        // Act
        var result = await _service.CleanAsync(categories);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task GetDiskSpaceAsyncShouldCacheResults()
    {
        // Arrange
        var expectedResult = new[]
        {
            new DiskSpaceDto { DriveLetter = "C:", TotalBytes = 1000, FreeBytes = 500 }
        };

        _psMock.Setup(x => x.InvokeCommandListAsync<DiskSpaceDto>(
            AppConstants.Modules.DiskCleanup,
            "Get-B11DiskSpace",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(expectedResult));

        // Act
        var result1 = await _service.GetDiskSpaceAsync();
        var result2 = await _service.GetDiskSpaceAsync();

        // Assert
        result1.IsSuccess.Should().BeTrue();
        result2.IsSuccess.Should().BeTrue();
        result1.Value.Should().BeEquivalentTo(expectedResult);
        result2.Value.Should().BeEquivalentTo(expectedResult);

        // Verify PowerShell service was only called once
        _psMock.Verify(
            x => x.InvokeCommandListAsync<DiskSpaceDto>(
                It.IsAny<string>(),
                "Get-B11DiskSpace",
                null,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            _service.Dispose();
            _disposed = true;
        }
    }
}
