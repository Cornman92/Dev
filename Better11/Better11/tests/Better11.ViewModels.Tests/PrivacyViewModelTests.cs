// ============================================================================
// Better11 System Enhancement Suite — PrivacyViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Better11.ViewModels.Privacy;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="PrivacyViewModel"/>.
/// </summary>
public sealed class PrivacyViewModelTests
{
    private readonly Mock<IPrivacyService> _mockService;
    private readonly Mock<ILogger<PrivacyViewModel>> _mockLogger;
    private readonly PrivacyViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="PrivacyViewModelTests"/> class.
    /// </summary>
    public PrivacyViewModelTests()
    {
        _mockService = new Mock<IPrivacyService>();
        _mockLogger = new Mock<ILogger<PrivacyViewModel>>();
        _viewModel = new PrivacyViewModel(_mockService.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitle()
    {
        _viewModel.PageTitle.Should().Be("Privacy Controls");
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenServiceIsNull()
    {
        var act = () => new PrivacyViewModel(null!, _mockLogger.Object);
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
