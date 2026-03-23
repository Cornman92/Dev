// ============================================================================
// Better11 System Enhancement Suite — SystemInfoServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.SystemInfo;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="SystemInfoService"/>.
/// </summary>
public sealed class SystemInfoServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<SystemInfoService>> _mockLogger;
    private readonly SystemInfoService _service;

    public SystemInfoServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<SystemInfoService>>();
        _service = new SystemInfoService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new SystemInfoService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetSystemInfoAsync
    // ========================================================================

    [Fact]
    public async Task GetSystemInfoAsync_ReturnsSuccess_WithAllFields()
    {
        var expected = new SystemInfoDto
        {
            ComputerName = "GAYMERPC",
            OsName = "Windows 11 Pro",
            OsVersion = "10.0.26200",
            OsBuild = "26200",
            CpuName = "AMD Ryzen 9 7950X",
            CpuCores = 32,
            TotalRamGb = 64.0,
            GpuName = "NVIDIA RTX 4090",
            Uptime = TimeSpan.FromHours(48),
            ActivationStatus = "Activated",
            BiosVersion = "1.0.0",
            Motherboard = "ASUS ROG Crosshair X670E",
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<SystemInfoDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(expected));

        var result = await _service.GetSystemInfoAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.ComputerName.Should().Be("GAYMERPC");
        result.Value.CpuCores.Should().Be(32);
        result.Value.TotalRamGb.Should().Be(64.0);
        result.Value.GpuName.Should().Contain("4090");
    }

    [Fact]
    public async Task GetSystemInfoAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<SystemInfoDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetSystemInfoAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.PowerShell);
    }

    [Fact]
    public async Task GetSystemInfoAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<SystemInfoDto>(
            AppConstants.Modules.SystemInfo, "Get-B11SystemInfo",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(new SystemInfoDto()));

        await _service.GetSystemInfoAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<SystemInfoDto>(
            AppConstants.Modules.SystemInfo, "Get-B11SystemInfo",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task GetSystemInfoAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandAsync<SystemInfoDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var result = await _service.GetSystemInfoAsync(cts.Token);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.Cancelled);
    }

    // ========================================================================
    // GetPerformanceMetricsAsync
    // ========================================================================

    [Fact]
    public async Task GetPerformanceMetricsAsync_ReturnsSuccess_WithMetrics()
    {
        var expected = new PerformanceMetricsDto
        {
            CpuUsagePercent = 25.5,
            MemoryUsagePercent = 60.0,
            AvailableMemoryGb = 25.6,
            DiskReadMbps = 500.0,
            DiskWriteMbps = 200.0,
            NetworkSendKbps = 1500.0,
            NetworkReceiveKbps = 5000.0,
            GpuUsagePercent = 10.0,
            ProcessCount = 250,
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<PerformanceMetricsDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(expected));

        var result = await _service.GetPerformanceMetricsAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.CpuUsagePercent.Should().Be(25.5);
        result.Value.ProcessCount.Should().Be(250);
        result.Value.AvailableMemoryGb.Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetPerformanceMetricsAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<PerformanceMetricsDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetPerformanceMetricsAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetPerformanceMetricsAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<PerformanceMetricsDto>(
            AppConstants.Modules.SystemInfo, "Get-B11PerformanceMetrics",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(new PerformanceMetricsDto()));

        await _service.GetPerformanceMetricsAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<PerformanceMetricsDto>(
            AppConstants.Modules.SystemInfo, "Get-B11PerformanceMetrics",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
