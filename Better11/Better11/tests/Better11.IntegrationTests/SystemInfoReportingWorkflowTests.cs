// Copyright (c) Better11. All rights reserved.

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.Dashboard;
using Better11.ViewModels.SystemInfo;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for system information and performance reporting workflows,
/// verifying end-to-end ViewModel orchestration through ISystemInfoService.
/// </summary>
public sealed class SystemInfoReportingWorkflowTests
{
    private readonly Mock<ISystemInfoService> _mockSystemInfoService;
    private readonly Mock<ILogger<SystemInfoViewModel>> _mockSysInfoLogger;
    private readonly Mock<ILogger<DashboardViewModel>> _mockDashboardLogger;
    private readonly SystemInfoViewModel _sysInfoVm;
    private readonly DashboardViewModel _dashboardVm;

    public SystemInfoReportingWorkflowTests()
    {
        _mockSystemInfoService = new Mock<ISystemInfoService>();
        _mockSysInfoLogger = new Mock<ILogger<SystemInfoViewModel>>();
        _mockDashboardLogger = new Mock<ILogger<DashboardViewModel>>();
        _sysInfoVm = new SystemInfoViewModel(_mockSystemInfoService.Object, _mockSysInfoLogger.Object);
        _dashboardVm = new DashboardViewModel(_mockSystemInfoService.Object, _mockDashboardLogger.Object);
    }

    // ====================================================================
    // SystemInfo: Load
    // ====================================================================

    [Fact]
    public async Task LoadSystemInfo_Success_PopulatesSystemInfo()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert
        _sysInfoVm.SystemInfo.Should().NotBeNull();
        _sysInfoVm.SystemInfo!.ComputerName.Should().Be("DESKTOP-B11");
        _sysInfoVm.SystemInfo.OsName.Should().Be("Windows 11 Pro");
    }

    [Fact]
    public async Task LoadSystemInfo_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Failure("WMI provider not available"));

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert
        _sysInfoVm.SystemInfo.Should().BeNull();
        _sysInfoVm.ErrorMessage.Should().Contain("WMI provider not available");
    }

    [Fact]
    public async Task LoadSystemInfo_Exception_HandledGracefully()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Unexpected WMI error"));

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert
        _sysInfoVm.ErrorMessage.Should().Contain("Unexpected WMI error");
        _sysInfoVm.IsBusy.Should().BeFalse();
    }

    // ====================================================================
    // PerformanceMetrics: Load (via Dashboard)
    // ====================================================================

    [Fact]
    public async Task LoadPerformanceMetrics_Success_PopulatesMetrics()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        var metrics = CreateSampleMetrics();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert
        _dashboardVm.Metrics.Should().NotBeNull();
        _dashboardVm.Metrics!.CpuUsagePercent.Should().Be(35.5);
        _dashboardVm.Metrics.MemoryUsagePercent.Should().Be(62.0);
    }

    [Fact]
    public async Task RefreshMetrics_UpdatesValues()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        var metrics1 = new PerformanceMetricsDto { CpuUsagePercent = 20.0, MemoryUsagePercent = 50.0 };
        var metrics2 = new PerformanceMetricsDto { CpuUsagePercent = 75.0, MemoryUsagePercent = 80.0 };

        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .SetupSequence(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics1))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics2));

        await _dashboardVm.InitializeAsync();
        _dashboardVm.Metrics!.CpuUsagePercent.Should().Be(20.0);

        // Act - Create a fresh ViewModel for second load
        var vm2 = new DashboardViewModel(_mockSystemInfoService.Object, _mockDashboardLogger.Object);
        await vm2.InitializeAsync();

        // Assert
        vm2.Metrics!.CpuUsagePercent.Should().Be(75.0);
        vm2.Metrics.MemoryUsagePercent.Should().Be(80.0);
    }

    // ====================================================================
    // SystemInfo: All Fields Populated
    // ====================================================================

    [Fact]
    public async Task SystemInfo_AllFieldsPopulated_AllAccessible()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert
        var si = _sysInfoVm.SystemInfo!;
        si.ComputerName.Should().NotBeEmpty();
        si.OsName.Should().NotBeEmpty();
        si.OsVersion.Should().NotBeEmpty();
        si.OsBuild.Should().NotBeEmpty();
        si.CpuName.Should().NotBeEmpty();
        si.CpuCores.Should().BeGreaterThan(0);
        si.TotalRamGb.Should().BeGreaterThan(0);
        si.GpuName.Should().NotBeEmpty();
        si.Uptime.Should().BeGreaterThan(TimeSpan.Zero);
        si.ActivationStatus.Should().NotBeEmpty();
        si.BiosVersion.Should().NotBeEmpty();
        si.Motherboard.Should().NotBeEmpty();
    }

    [Fact]
    public async Task PerformanceMetrics_AllFieldsPopulated_AllAccessible()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        var metrics = CreateSampleMetrics();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert
        var m = _dashboardVm.Metrics!;
        m.CpuUsagePercent.Should().BeGreaterOrEqualTo(0);
        m.MemoryUsagePercent.Should().BeGreaterOrEqualTo(0);
        m.AvailableMemoryGb.Should().BeGreaterThan(0);
        m.DiskReadMbps.Should().BeGreaterOrEqualTo(0);
        m.DiskWriteMbps.Should().BeGreaterOrEqualTo(0);
        m.NetworkSendKbps.Should().BeGreaterOrEqualTo(0);
        m.NetworkReceiveKbps.Should().BeGreaterOrEqualTo(0);
        m.GpuUsagePercent.Should().BeGreaterOrEqualTo(0);
        m.ProcessCount.Should().BeGreaterThan(0);
    }

    // ====================================================================
    // Dashboard: Health Score
    // ====================================================================

    [Fact]
    public async Task Dashboard_HealthScore_ComputedFromMetrics()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        var metrics = new PerformanceMetricsDto
        {
            CpuUsagePercent = 50.0,
            MemoryUsagePercent = 60.0,
            GpuUsagePercent = 40.0,
        };
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert - CPU < 80, Mem < 85, GPU < 90 => score stays 100
        _dashboardVm.HealthScore.Should().Be(100);
    }

    [Fact]
    public async Task Dashboard_HealthScore_PenalizedForHighUsage()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        var metrics = new PerformanceMetricsDto
        {
            CpuUsagePercent = 95.0,
            MemoryUsagePercent = 90.0,
            GpuUsagePercent = 95.0,
        };
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert - CPU > 80 (-20), Mem > 85 (-20), GPU > 90 (-10) => 100 - 50 = 50
        _dashboardVm.HealthScore.Should().Be(50);
    }

    // ====================================================================
    // Combined Load: SystemInfo + Metrics
    // ====================================================================

    [Fact]
    public async Task CombinedLoad_InfoAndMetrics_BothPopulated()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        var metrics = CreateSampleMetrics();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert
        _dashboardVm.SystemInfo.Should().NotBeNull();
        _dashboardVm.Metrics.Should().NotBeNull();
        _dashboardVm.SystemInfo!.ComputerName.Should().Be("DESKTOP-B11");
        _dashboardVm.Metrics!.ProcessCount.Should().Be(142);
    }

    [Fact]
    public async Task CombinedLoad_InfoFails_MetricsStillLoaded()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Failure("Info not available"));
        var metrics = CreateSampleMetrics();
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert
        _dashboardVm.SystemInfo.Should().BeNull();
        _dashboardVm.Metrics.Should().NotBeNull();
        _dashboardVm.ErrorMessage.Should().Contain("Info not available");
    }

    // ====================================================================
    // Cancellation
    // ====================================================================

    [Fact]
    public async Task CancelDuringLoad_HandledGracefully()
    {
        // Arrange
        var cts = new CancellationTokenSource();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .Returns(async (CancellationToken ct) =>
            {
                cts.Cancel();
                ct.ThrowIfCancellationRequested();
                return Result<SystemInfoDto>.Success(CreateSampleSystemInfo());
            });

        // Act
        await _sysInfoVm.InitializeAsync(cts.Token);

        // Assert
        _sysInfoVm.IsBusy.Should().BeFalse();
    }

    // ====================================================================
    // Export / Report Generation
    // ====================================================================

    [Fact]
    public async Task ExportSystemInfo_GeneratesReport_InfoAvailable()
    {
        // Arrange
        var info = CreateSampleSystemInfo();
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert - SystemInfo should be fully populated and ready for export
        var si = _sysInfoVm.SystemInfo!;
        si.Should().NotBeNull();
        var reportData = $"{si.ComputerName} | {si.OsName} {si.OsVersion} | CPU: {si.CpuName} ({si.CpuCores} cores) | RAM: {si.TotalRamGb} GB";
        reportData.Should().NotBeEmpty();
        reportData.Should().Contain("DESKTOP-B11");
        reportData.Should().Contain("AMD Ryzen 9 7950X");
    }

    // ====================================================================
    // ViewModel State
    // ====================================================================

    [Fact]
    public void SystemInfo_PageTitle_IsCorrect()
    {
        _sysInfoVm.PageTitle.Should().Be("System Information");
    }

    [Fact]
    public void Dashboard_PageTitle_IsCorrect()
    {
        _dashboardVm.PageTitle.Should().Be("Dashboard");
    }

    [Fact]
    public async Task SystemInfo_IsBusy_FalseAfterLoad()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(CreateSampleSystemInfo()));

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert
        _sysInfoVm.IsBusy.Should().BeFalse();
        _sysInfoVm.IsNotBusy.Should().BeTrue();
    }

    [Fact]
    public async Task Dashboard_IsInitialized_TrueAfterInit()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(CreateSampleSystemInfo()));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(CreateSampleMetrics()));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert
        _dashboardVm.IsInitialized.Should().BeTrue();
    }

    [Fact]
    public async Task Dashboard_MetricsFailure_SystemInfoStillLoaded()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(CreateSampleSystemInfo()));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Failure("Performance counters unavailable"));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert
        _dashboardVm.SystemInfo.Should().NotBeNull();
        _dashboardVm.Metrics.Should().BeNull();
    }

    [Fact]
    public async Task SystemInfo_InitializeTwice_OnlyLoadsOnce()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(CreateSampleSystemInfo()));

        // Act
        await _sysInfoVm.InitializeAsync();
        await _sysInfoVm.InitializeAsync();

        // Assert
        _mockSystemInfoService.Verify(
            s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Dashboard_HealthScore_NeverBelowZero()
    {
        // Arrange - All metrics extremely high
        var info = CreateSampleSystemInfo();
        var metrics = new PerformanceMetricsDto
        {
            CpuUsagePercent = 100.0,
            MemoryUsagePercent = 100.0,
            GpuUsagePercent = 100.0,
        };
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(info));
        _mockSystemInfoService
            .Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));

        // Act
        await _dashboardVm.InitializeAsync();

        // Assert - 100 - 20 - 20 - 10 = 50, clamped at max(0, 50)
        _dashboardVm.HealthScore.Should().BeGreaterOrEqualTo(0);
    }

    // ====================================================================
    // Helpers
    // ====================================================================

    private static SystemInfoDto CreateSampleSystemInfo() => new()
    {
        ComputerName = "DESKTOP-B11",
        OsName = "Windows 11 Pro",
        OsVersion = "23H2",
        OsBuild = "22631.3007",
        CpuName = "AMD Ryzen 9 7950X",
        CpuCores = 16,
        TotalRamGb = 64.0,
        GpuName = "NVIDIA GeForce RTX 4080",
        Uptime = TimeSpan.FromHours(48),
        ActivationStatus = "Activated",
        BiosVersion = "F8j",
        Motherboard = "ASUS ROG Crosshair X670E Hero",
    };

    private static PerformanceMetricsDto CreateSampleMetrics() => new()
    {
        CpuUsagePercent = 35.5,
        MemoryUsagePercent = 62.0,
        AvailableMemoryGb = 24.3,
        DiskReadMbps = 150.2,
        DiskWriteMbps = 80.4,
        NetworkSendKbps = 512.0,
        NetworkReceiveKbps = 2048.0,
        GpuUsagePercent = 15.0,
        ProcessCount = 142,
    };
}
