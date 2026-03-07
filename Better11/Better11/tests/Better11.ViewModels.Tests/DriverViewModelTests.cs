// ============================================================================
// Better11 System Enhancement Suite — DriverViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Better11.ViewModels.Driver;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="DriverViewModel"/>.
/// </summary>
public sealed class DriverViewModelTests
{
    private readonly Mock<IDriverService> _mockService;
    private readonly Mock<ILogger<DriverViewModel>> _mockLogger;
    private readonly DriverViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="DriverViewModelTests"/> class.
    /// </summary>
    public DriverViewModelTests()
    {
        _mockService = new Mock<IDriverService>();
        _mockLogger = new Mock<ILogger<DriverViewModel>>();
        _viewModel = new DriverViewModel(_mockService.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitle()
    {
        _viewModel.PageTitle.Should().Be("Driver Manager");
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenServiceIsNull()
    {
        var act = () => new DriverViewModel(null!, _mockLogger.Object);
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
