// ============================================================================
// Better11 System Enhancement Suite — DashboardViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Better11.ViewModels.Dashboard;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="DashboardViewModel"/>.
/// </summary>
public sealed class DashboardViewModelTests
{
    private readonly Mock<ISystemInfoService> _mockSystemInfo;
    private readonly Mock<IOptimizationService> _mockOptimization;
    private readonly Mock<IDiskCleanupService> _mockDiskCleanup;
    private readonly Mock<ILogger<DashboardViewModel>> _mockLogger;
    private readonly DashboardViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="DashboardViewModelTests"/> class.
    /// </summary>
    public DashboardViewModelTests()
    {
        _mockSystemInfo = new Mock<ISystemInfoService>();
        _mockOptimization = new Mock<IOptimizationService>();
        _mockDiskCleanup = new Mock<IDiskCleanupService>();
        _mockLogger = new Mock<ILogger<DashboardViewModel>>();
        _viewModel = new DashboardViewModel(
            _mockSystemInfo.Object, _mockOptimization.Object,
            _mockDiskCleanup.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitle()
    {
        _viewModel.PageTitle.Should().Be("Dashboard");
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenServiceIsNull()
    {
        var act = () => new DashboardViewModel(
            null!, _mockOptimization.Object, _mockDiskCleanup.Object, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void IsBusy_DefaultIsFalse()
    {
        _viewModel.IsBusy.Should().BeFalse();
    }

    [Fact]
    public void IsNotBusy_IsInverseOfIsBusy()
    {
        _viewModel.IsNotBusy.Should().BeTrue();
    }

    [Fact]
    public void HasError_DefaultIsFalse()
    {
        _viewModel.HasError.Should().BeFalse();
    }

    [Fact]
    public void HasSuccess_DefaultIsFalse()
    {
        _viewModel.HasSuccess.Should().BeFalse();
    }

    [Fact]
    public void IsInitialized_DefaultIsFalse()
    {
        _viewModel.IsInitialized.Should().BeFalse();
    }

    [Fact]
    public void Cleanup_DoesNotThrow()
    {
        var act = () => _viewModel.Cleanup();
        act.Should().NotThrow();
    }
}
