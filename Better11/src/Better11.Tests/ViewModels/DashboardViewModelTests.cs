// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.ViewModels;

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.Dashboard;
using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

public class DashboardViewModelTests
{
    private readonly Mock<ISystemInfoService> _sysInfoMock = new();
    private readonly Mock<IOptimizationService> _optMock = new();
    private readonly Mock<IDiskCleanupService> _diskMock = new();

    [Fact]
    public async Task RefreshAsyncShouldPopulateSystemInfo()
    {
        // Arrange - null sync context so RunOnUIThread runs inline in tests
        var previous = SynchronizationContext.Current;
        SynchronizationContext.SetSynchronizationContext(null);
        try
        {
            var info = new SystemInfoDto { ComputerName = "TEST-PC" };
            var metrics = new PerformanceMetricsDto { CpuUsagePercent = 10, MemoryUsagePercent = 20 };
            var disk = new List<DiskSpaceDto> { new() { DriveLetter = "C:", TotalBytes = 100, FreeBytes = 50 } };
            var categories = new List<OptimizationCategoryDto>
            {
                new()
                {
                    Name = "Cat1",
                    Tweaks = new List<TweakDto> { new() { Name = "T1", IsApplied = true } }
                }
            };

            _sysInfoMock.Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<SystemInfoDto>.Success(info));
            _sysInfoMock.Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<PerformanceMetricsDto>.Success(metrics));
            _diskMock.Setup(s => s.GetDiskSpaceAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(disk));
            _optMock.Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));

            var vm = CreateVm();

            // Act
            await vm.RefreshCommand.ExecuteAsync(null);

            // Assert
            vm.SystemInformation.Should().NotBeNull();
            vm.SystemInformation!.ComputerName.Should().Be("TEST-PC");
            vm.PerformanceMetrics.Should().NotBeNull();
            vm.HealthScore.Should().Be(100);
            vm.DiskSpaces.Should().HaveCount(1);
            vm.AppliedTweakCount.Should().Be(1);
            vm.IsBusy.Should().BeFalse();
        }
        finally
        {
            SynchronizationContext.SetSynchronizationContext(previous);
        }
    }

    [Fact]
    public async Task RefreshAsyncShouldHandleServiceFailure()
    {
        // Arrange
        _sysInfoMock.Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Failure("Service unavailable"));

        // Setup others to return empty but success to avoid null refs if logic continues
        _sysInfoMock.Setup(s => s.GetPerformanceMetricsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PerformanceMetricsDto>.Success(new PerformanceMetricsDto()));
        _diskMock.Setup(s => s.GetDiskSpaceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(new List<DiskSpaceDto>()));
        _optMock.Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(new List<OptimizationCategoryDto>()));

        var vm = CreateVm();

        // Act
        await vm.RefreshCommand.ExecuteAsync(null);

        // Assert
        vm.HasError.Should().BeTrue();
        vm.ErrorMessage.Should().Be("Service unavailable");
        vm.IsBusy.Should().BeFalse();
    }

    private DashboardViewModel CreateVm() => new(
        _sysInfoMock.Object,
        _optMock.Object,
        _diskMock.Object,
        NullLogger<DashboardViewModel>.Instance);
}
