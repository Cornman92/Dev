// ============================================================================
// Better11 System Enhancement Suite — RecipeServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Text.Json;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.Services.Customization;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="RecipeService"/>.
/// </summary>
public sealed class RecipeServiceTests
{
    private static readonly string[] ExpectedRecipeNames =
    {
        "Gaming",
        "Developer",
        "Privacy",
        "Balanced",
        "Minimal",
    };

    private static readonly string[] ExpectedBalancedItems =
    {
        "perf-basic",
        "perf-advanced",
        "privacy-profile",
    };

    private static readonly string[] ExpectedMinimalItems =
    {
        "perf-basic",
    };

    private readonly Mock<ICustomizationCatalogService> _mockCatalogService;
    private readonly Mock<ILogger<RecipeService>> _mockLogger;
    private readonly RecipeService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="RecipeServiceTests"/> class.
    /// </summary>
    public RecipeServiceTests()
    {
        _mockCatalogService = new Mock<ICustomizationCatalogService>();
        _mockLogger = new Mock<ILogger<RecipeService>>();
        _service = new RecipeService(_mockCatalogService.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetBuiltInRecipesAsync_ReturnsExpectedRecipeSet()
    {
        var catalog = new[]
        {
            new CatalogCategoryDto
            {
                Key = "performance",
                Title = "Performance",
                Items = new[]
                {
                    new CatalogItemDto
                    {
                        Id = "perf-basic",
                        Title = "Disable Background Effects",
                        CategoryKey = "performance",
                        CategoryTitle = "Performance",
                        Recommended = true,
                        SafetyTier = SafetyTier.Basic,
                        Tags = new[] { "performance", "gaming" },
                        SourceModule = "B11.Optimization",
                    },
                    new CatalogItemDto
                    {
                        Id = "perf-advanced",
                        Title = "High Performance Plan",
                        CategoryKey = "performance",
                        CategoryTitle = "Performance",
                        Recommended = true,
                        SafetyTier = SafetyTier.Advanced,
                        Tags = new[] { "performance" },
                        SourceModule = "B11.Optimization",
                    },
                },
            },
            new CatalogCategoryDto
            {
                Key = "privacy",
                Title = "Privacy Profiles",
                Items = new[]
                {
                    new CatalogItemDto
                    {
                        Id = "privacy-profile",
                        Title = "Privacy Baseline",
                        CategoryKey = "privacy",
                        CategoryTitle = "Privacy Profiles",
                        Recommended = true,
                        SafetyTier = SafetyTier.Advanced,
                        Tags = new[] { "privacy" },
                        SourceModule = "B11.Privacy",
                    },
                },
            },
            new CatalogCategoryDto
            {
                Key = "security",
                Title = "Security Hardening",
                Items = new[]
                {
                    new CatalogItemDto
                    {
                        Id = "security-hardening",
                        Title = "Exploit Protection Baseline",
                        CategoryKey = "security",
                        CategoryTitle = "Security Hardening",
                        Recommended = true,
                        SafetyTier = SafetyTier.Expert,
                        Tags = new[] { "security" },
                        SourceModule = "B11.Security",
                    },
                },
            },
            new CatalogCategoryDto
            {
                Key = "startup",
                Title = "Startup Policy",
                Items = new[]
                {
                    new CatalogItemDto
                    {
                        Id = "startup-disable",
                        Title = "Disable Chat Auto Start",
                        CategoryKey = "startup",
                        CategoryTitle = "Startup Policy",
                        Recommended = false,
                        SafetyTier = SafetyTier.Advanced,
                        Tags = new[] { "developer" },
                        SourceModule = "B11.Startup",
                    },
                },
            },
        };

        _mockCatalogService
            .Setup(service => service.GetCatalogAsync(
                CustomizationTargetKind.LiveSystem,
                SafetyTier.Expert,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<CatalogCategoryDto>>.Success(catalog));

        var result = await _service.GetBuiltInRecipesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
        var recipes = result.Value!;
        recipes.Select(recipe => recipe.Name).Should().Contain(ExpectedRecipeNames);

        var balanced = recipes.Single(recipe => recipe.Name == "Balanced");
        balanced.Items.Select(item => item.ItemId).Should().BeEquivalentTo(ExpectedBalancedItems);

        var minimal = recipes.Single(recipe => recipe.Name == "Minimal");
        minimal.Items.Select(item => item.ItemId).Should().Equal(ExpectedMinimalItems);
    }

    [Fact]
    public async Task ExportRecipeAsync_WritesExpectedJson()
    {
        var recipe = new RecipeDto
        {
            Name = "Test Recipe",
            Description = "Export validation",
            Items = new[]
            {
                new RecipeItemDto { ItemId = "item-1", Enabled = true },
            },
        };

        var tempPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid():N}-recipe.json");

        try
        {
            var result = await _service.ExportRecipeAsync(recipe, tempPath, CancellationToken.None);

            result.IsSuccess.Should().BeTrue();
            File.Exists(tempPath).Should().BeTrue();

            var exported = JsonSerializer.Deserialize<RecipeDto>(await File.ReadAllTextAsync(tempPath));
            exported.Should().NotBeNull();
            exported!.Name.Should().Be("Test Recipe");
            exported.Items.Should().ContainSingle(item => item.ItemId == "item-1");
        }
        finally
        {
            if (File.Exists(tempPath))
            {
                File.Delete(tempPath);
            }
        }
    }

    [Fact]
    public async Task ImportRecipeAsync_ReturnsFailure_WhenFileDoesNotExist()
    {
        var missingPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid():N}-missing.json");

        var result = await _service.ImportRecipeAsync(missingPath, CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Contain("Recipe file not found");
    }
}
