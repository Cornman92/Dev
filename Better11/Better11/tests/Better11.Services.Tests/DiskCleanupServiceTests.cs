// ============================================================================
// Better11 System Enhancement Suite — DiskCleanupServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.DiskCleanup;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="DiskCleanupService"/>.
/// </summary>
public sealed class DiskCleanupServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<DiskCleanupService>> _mockLogger;
    private readonly DiskCleanupService _service;

    public DiskCleanupServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<DiskCleanupService>>();
        _service = new DiskCleanupService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new DiskCleanupService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // ScanAsync
    // ========================================================================

    [Fact]
    public async Task ScanAsync_ReturnsSuccess_WithCategories()
    {
        var expected = new DiskScanResultDto
        {
            TotalReclaimableBytes = 1_073_741_824,
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp Files", ReclaimableBytes = 500_000_000, FileCount = 1200 },
                new() { Name = "Recycle Bin", ReclaimableBytes = 573_741_824, FileCount = 50 },
            },
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<DiskScanResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(expected));

        var result = await _service.ScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.TotalReclaimableBytes.Should().BeGreaterThan(0);
        result.Value.Categories.Should().HaveCount(2);
    }

    [Fact]
    public async Task ScanAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<DiskScanResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.ScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task ScanAsync_ReturnsZeroBytes_WhenSystemClean()
    {
        var clean = new DiskScanResultDto
        {
            TotalReclaimableBytes = 0,
            Categories = Array.Empty<CleanupCategoryDto>(),
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<DiskScanResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(clean));

        var result = await _service.ScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.TotalReclaimableBytes.Should().Be(0);
        result.Value.Categories.Should().BeEmpty();
    }

    [Fact]
    public async Task ScanAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<DiskScanResultDto>(
            "B11.DiskCleanup", "Invoke-B11DiskScan",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(new DiskScanResultDto()));

        var result = await _service.ScanAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        _mockPs.Verify(x => x.InvokeCommandAsync<DiskScanResultDto>(
            "B11.DiskCleanup", "Invoke-B11DiskScan",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // CleanAsync
    // ========================================================================

    [Fact]
    public async Task CleanAsync_ReturnsSuccess_WithBytesFreed()
    {
        var expected = new CleanupResultDto
        {
            BytesFreed = 500_000_000,
            FilesRemoved = 1200,
            Errors = Array.Empty<string>(),
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<CleanupResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(expected));

        var result = await _service.CleanAsync(
            new List<string> { "Temp Files", "Recycle Bin" }, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.BytesFreed.Should().Be(500_000_000);
        result.Value.FilesRemoved.Should().Be(1200);
    }

    [Fact]
    public async Task CleanAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<CleanupResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Failure("Access denied", "B11_ACCESS_DENIED"));

        var result = await _service.CleanAsync(
            new List<string> { "Temp Files" }, CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task CleanAsync_ReportsPartialErrors()
    {
        var partial = new CleanupResultDto
        {
            BytesFreed = 300_000_000,
            FilesRemoved = 800,
            Errors = new List<string> { "Could not delete file.lock" },
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<CleanupResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(partial));

        var result = await _service.CleanAsync(
            new List<string> { "Temp Files" }, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.Errors.Should().HaveCount(1);
    }

    [Fact]
    public async Task CleanAsync_PassesCategoriesParameter()
    {
        var categories = new List<string> { "Temp", "Cache", "Logs" };
        _mockPs.Setup(x => x.InvokeCommandAsync<CleanupResultDto>(
            AppConstants.Modules.DiskCleanup, "Invoke-B11DiskClean",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("Categories") &&
                d["Categories"] is List<string>),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(new CleanupResultDto()));

        await _service.CleanAsync(categories, CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<CleanupResultDto>(
            AppConstants.Modules.DiskCleanup, "Invoke-B11DiskClean",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("Categories") &&
                d["Categories"] is List<string>),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // GetDiskSpaceAsync
    // ========================================================================

    [Fact]
    public async Task GetDiskSpaceAsync_ReturnsSuccess_WithMultipleDrives()
    {
        var expected = new List<DiskSpaceDto>
        {
            new() { DriveLetter = "C:", TotalBytes = 500_000_000_000, FreeBytes = 100_000_000_000 },
            new() { DriveLetter = "D:", TotalBytes = 1_000_000_000_000, FreeBytes = 800_000_000_000 },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<DiskSpaceDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(expected));

        var result = await _service.GetDiskSpaceAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value![0].UsagePercent.Should().Be(80.0);
        result.Value[1].UsagePercent.Should().Be(20.0);
    }

    [Fact]
    public async Task GetDiskSpaceAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<DiskSpaceDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetDiskSpaceAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetDiskSpaceAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandListAsync<DiskSpaceDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var result = await _service.GetDiskSpaceAsync(cts.Token);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.Cancelled);
    }
}
