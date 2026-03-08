// ============================================================================
// Better11 System Enhancement Suite — CustomizationStudioViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Interfaces;
using Better11.ViewModels.Customization;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="CustomizationStudioViewModel"/>.
/// </summary>
public sealed class CustomizationStudioViewModelTests
{
    private static readonly CustomizationTargetKind[] ExpectedTargets =
    {
        CustomizationTargetKind.LiveSystem,
        CustomizationTargetKind.OfflineImage,
    };

    private static readonly SafetyTier[] ExpectedSafetyTiers =
    {
        SafetyTier.Basic,
        SafetyTier.Advanced,
        SafetyTier.Expert,
        SafetyTier.Lab,
    };

    private readonly Mock<ICustomizationCatalogService> _mockCatalogService;
    private readonly Mock<ICustomizationExecutionService> _mockExecutionService;
    private readonly Mock<IRecipeService> _mockRecipeService;
    private readonly Mock<ISettingsService> _mockSettingsService;
    private readonly Mock<ILogger<CustomizationStudioViewModel>> _mockLogger;
    private readonly CustomizationStudioViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="CustomizationStudioViewModelTests"/> class.
    /// </summary>
    public CustomizationStudioViewModelTests()
    {
        _mockCatalogService = new Mock<ICustomizationCatalogService>();
        _mockExecutionService = new Mock<ICustomizationExecutionService>();
        _mockRecipeService = new Mock<IRecipeService>();
        _mockSettingsService = new Mock<ISettingsService>();
        _mockLogger = new Mock<ILogger<CustomizationStudioViewModel>>();

        _viewModel = new CustomizationStudioViewModel(
            _mockCatalogService.Object,
            _mockExecutionService.Object,
            _mockRecipeService.Object,
            _mockSettingsService.Object,
            _mockLogger.Object);
    }

    [Fact]
    public void Constructor_InitializesTitleAndOptionSets()
    {
        _viewModel.PageTitle.Should().Be("Customization Studio");
        _viewModel.TargetOptions.Should().BeEquivalentTo(ExpectedTargets);
        _viewModel.SafetyTierOptions.Should().BeEquivalentTo(ExpectedSafetyTiers);
    }

    [Fact]
    public void QueueSelectedItemCommand_AddsOnlyUniqueItems()
    {
        var item = new CatalogItemDto
        {
            Id = "catalog-item",
            Title = "Catalog Item",
        };

        _viewModel.SelectedCatalogItem = item;

        _viewModel.QueueSelectedItemCommand.Execute(null);
        _viewModel.QueueSelectedItemCommand.Execute(null);

        _viewModel.QueueItems.Should().ContainSingle(queued => queued.Id == "catalog-item");
        _viewModel.QueueCount.Should().Be(1);
    }

    [Fact]
    public void RemoveQueuedItemCommand_RemovesItemAndUpdatesCount()
    {
        var item = new CatalogItemDto
        {
            Id = "catalog-item",
            Title = "Catalog Item",
        };

        _viewModel.QueueItems.Add(item);

        _viewModel.RemoveQueuedItemCommand.Execute(item);

        _viewModel.QueueItems.Should().BeEmpty();
        _viewModel.QueueCount.Should().Be(0);
    }
}
