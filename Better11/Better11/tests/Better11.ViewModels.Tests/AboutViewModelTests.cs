// ============================================================================
// Better11 System Enhancement Suite — AboutViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Better11.ViewModels.About;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="AboutViewModel"/>.
/// </summary>
public sealed class AboutViewModelTests
{
    private readonly Mock<ISystemInfoService> _mockService;
    private readonly Mock<IAppUpdateService> _mockAppUpdateService;
    private readonly Mock<ILogger<AboutViewModel>> _mockLogger;
    private readonly AboutViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="AboutViewModelTests"/> class.
    /// </summary>
    public AboutViewModelTests()
    {
        _mockService = new Mock<ISystemInfoService>();
        _mockAppUpdateService = new Mock<IAppUpdateService>();
        _mockLogger = new Mock<ILogger<AboutViewModel>>();
        _viewModel = new AboutViewModel(_mockService.Object, _mockAppUpdateService.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitle()
    {
        _viewModel.PageTitle.Should().Be("About");
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenSystemInfoServiceIsNull()
    {
        var act = () => new AboutViewModel(null!, _mockAppUpdateService.Object, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void IsBusy_DefaultIsFalse()
    {
        _viewModel.IsBusy.Should().BeFalse();
    }

    [Fact]
    public void Cleanup_DoesNotThrow()
    {
        var act = () => _viewModel.Cleanup();
        act.Should().NotThrow();
    }
}
