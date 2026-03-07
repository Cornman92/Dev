// ============================================================================
// Better11 System Enhancement Suite — StartupViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Better11.ViewModels.Startup;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="StartupViewModel"/>.
/// </summary>
public sealed class StartupViewModelTests
{
    private readonly Mock<IStartupService> _mockService;
    private readonly Mock<ILogger<StartupViewModel>> _mockLogger;
    private readonly StartupViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="StartupViewModelTests"/> class.
    /// </summary>
    public StartupViewModelTests()
    {
        _mockService = new Mock<IStartupService>();
        _mockLogger = new Mock<ILogger<StartupViewModel>>();
        _viewModel = new StartupViewModel(_mockService.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitle()
    {
        _viewModel.PageTitle.Should().Be("Startup Manager");
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenServiceIsNull()
    {
        var act = () => new StartupViewModel(null!, _mockLogger.Object);
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
