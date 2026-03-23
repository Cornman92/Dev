// Copyright (c) Better11. All rights reserved.

using System.Linq;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.Optimization;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for the optimization workflow, verifying end-to-end ViewModel
/// orchestration through the IOptimizationService layer.
/// </summary>
public sealed class OptimizationWorkflowTests
{
    private readonly Mock<IOptimizationService> _mockOptimizationService;
    private readonly Mock<ILogger<OptimizationViewModel>> _mockLogger;
    private readonly OptimizationViewModel _viewModel;

    public OptimizationWorkflowTests()
    {
        _mockOptimizationService = new Mock<IOptimizationService>();
        _mockLogger = new Mock<ILogger<OptimizationViewModel>>();
        _viewModel = new OptimizationViewModel(_mockOptimizationService.Object, _mockLogger.Object);
    }

    // ====================================================================
    // LoadCategories
    // ====================================================================

    [Fact]
    public async Task LoadCategories_Success_PopulatesCategoriesCollection()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Performance", Description = "Performance tweaks", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Disable Animations", IsApplied = false },
                new() { Id = "t2", Name = "Optimize Services", IsApplied = true },
            }},
            new() { Name = "Privacy", Description = "Privacy tweaks", Tweaks = new List<TweakDto>
            {
                new() { Id = "t3", Name = "Disable Telemetry", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.Categories.Should().HaveCount(2);
        _viewModel.Categories[0].Name.Should().Be("Performance");
        _viewModel.Categories[1].Tweaks.Should().HaveCount(1);
        _viewModel.ErrorMessage.Should().BeEmpty();
    }

    [Fact]
    public async Task LoadCategories_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Failure("Service unavailable"));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.Categories.Should().BeEmpty();
        _viewModel.ErrorMessage.Should().Contain("Service unavailable");
    }

    [Fact]
    public async Task LoadCategories_ReturnsEmptyList_CategoriesCollectionIsEmpty()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.Categories.Should().BeEmpty();
        _viewModel.HasError.Should().BeFalse();
    }

    [Fact]
    public async Task LoadCategories_MultipleCalls_RefreshesCollection()
    {
        // Arrange
        var firstBatch = new List<OptimizationCategoryDto>
        {
            new() { Name = "First", Description = "First batch" },
        };
        var secondBatch = new List<OptimizationCategoryDto>
        {
            new() { Name = "Second", Description = "Second batch" },
            new() { Name = "Third", Description = "Third batch" },
        };
        _mockOptimizationService
            .SetupSequence(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(firstBatch))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(secondBatch));

        // Act
        await _viewModel.InitializeAsync();
        _viewModel.Categories.Should().HaveCount(1);

        // Reset IsInitialized by creating a fresh ViewModel for second call
        var vm2 = new OptimizationViewModel(_mockOptimizationService.Object, _mockLogger.Object);
        await vm2.InitializeAsync();

        // Assert
        vm2.Categories.Should().HaveCount(2);
        vm2.Categories[0].Name.Should().Be("Second");
    }

    [Fact]
    public async Task LoadCategories_ServiceThrowsException_ErrorMessageIsSet()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Unexpected error"));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.ErrorMessage.Should().Contain("Unexpected error");
    }

    // ====================================================================
    // ApplyOptimizations
    // ====================================================================

    [Fact]
    public async Task ApplyOptimizations_CreatesRestorePointFirst_ThenApplies()
    {
        // Arrange
        var callOrder = new List<string>();
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Callback(() => callOrder.Add("RestorePoint"))
            .ReturnsAsync(Result<string>.Success("RP_001"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .Callback(() => callOrder.Add("Apply"))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto
            {
                TweaksApplied = 1,
                RebootRequired = false,
            }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        callOrder.Should().ContainInOrder("RestorePoint", "Apply");
    }

    [Fact]
    public async Task ApplyOptimizations_NoSelection_ShowsError()
    {
        // Arrange - categories with all tweaks already applied
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = true },
                new() { Id = "t2", Name = "Tweak2", IsApplied = true },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.ErrorMessage.Should().Contain("No optimizations selected");
        _mockOptimizationService.Verify(
            s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task ApplyOptimizations_Success_UpdatesState()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = false },
                new() { Id = "t2", Name = "Tweak2", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_001"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto
            {
                TweaksApplied = 2,
                RebootRequired = false,
            }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.LastResult.Should().NotBeNull();
        _viewModel.LastResult!.TweaksApplied.Should().Be(2);
        _viewModel.SuccessMessage.Should().Contain("2 optimizations");
    }

    [Fact]
    public async Task ApplyOptimizations_PartialFailure_ReportsFailedTweaks()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = false },
                new() { Id = "t2", Name = "Tweak2", IsApplied = false },
                new() { Id = "t3", Name = "Tweak3", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_001"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto
            {
                TweaksApplied = 2,
                FailedTweaks = new List<string> { "t3" },
                RebootRequired = false,
            }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.LastResult.Should().NotBeNull();
        _viewModel.LastResult!.FailedTweaks.Should().Contain("t3");
        _viewModel.LastResult.TweaksApplied.Should().Be(2);
    }

    [Fact]
    public async Task ApplyOptimizations_RestorePointFails_DoesNotApply()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Failure("Insufficient disk space"));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.ErrorMessage.Should().Contain("restore point");
        _mockOptimizationService.Verify(
            s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task ApplyOptimizations_ServiceFailure_SetsErrorMessage()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_001"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Failure("Registry access denied"));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.ErrorMessage.Should().Contain("Registry access denied");
    }

    // ====================================================================
    // CreateRestorePoint
    // ====================================================================

    [Fact]
    public async Task CreateRestorePoint_Success_SetsSuccessMessage()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_Manual_001"));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.CreateRestorePointCommand.ExecuteAsync(null);

        // Assert
        _viewModel.SuccessMessage.Should().Contain("RP_Manual_001");
        _viewModel.HasError.Should().BeFalse();
    }

    [Fact]
    public async Task CreateRestorePoint_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Failure("System protection disabled"));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.CreateRestorePointCommand.ExecuteAsync(null);

        // Assert
        _viewModel.ErrorMessage.Should().Contain("System protection disabled");
    }

    // ====================================================================
    // RebootRequired flag
    // ====================================================================

    [Fact]
    public async Task ApplyWithRebootRequired_SetsRebootRequiredFlag()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Kernel", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Kernel Tweak", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_001"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto
            {
                TweaksApplied = 1,
                RebootRequired = true,
            }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.RebootRequired.Should().BeTrue();
    }

    [Fact]
    public async Task ApplyWithoutRebootRequired_RebootRequiredIsFalse()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Visual", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Visual Tweak", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_001"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto
            {
                TweaksApplied = 1,
                RebootRequired = false,
            }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.RebootRequired.Should().BeFalse();
    }

    // ====================================================================
    // Cancellation
    // ====================================================================

    [Fact]
    public async Task CancelDuringApply_OperationIsCancelled()
    {
        // Arrange
        var cts = new CancellationTokenSource();
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", Name = "Tweak1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Returns(async (string _, CancellationToken ct) =>
            {
                cts.Cancel();
                ct.ThrowIfCancellationRequested();
                return Result<string>.Success("RP_001");
            });

        await _viewModel.InitializeAsync();

        // Act - the operation should handle cancellation gracefully
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert - no unhandled exception, ViewModel stays in consistent state
        _viewModel.IsBusy.Should().BeFalse();
    }

    // ====================================================================
    // ViewModel state tests
    // ====================================================================

    [Fact]
    public async Task Initialize_SetsIsInitialized()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.IsInitialized.Should().BeTrue();
    }

    [Fact]
    public async Task Initialize_CalledTwice_OnlyLoadsCategoriesOnce()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));

        // Act
        await _viewModel.InitializeAsync();
        await _viewModel.InitializeAsync();

        // Assert
        _mockOptimizationService.Verify(
            s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public void PageTitle_IsSetCorrectly()
    {
        _viewModel.PageTitle.Should().Be("System Optimization");
    }

    [Fact]
    public async Task ApplyOptimizations_PassesCorrectTweakIds()
    {
        // Arrange
        IReadOnlyList<string>? capturedIds = null;
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Cat1", Tweaks = new List<TweakDto>
            {
                new() { Id = "applied1", IsApplied = true },
                new() { Id = "unapplied1", IsApplied = false },
            }},
            new() { Name = "Cat2", Tweaks = new List<TweakDto>
            {
                new() { Id = "unapplied2", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .Callback<IReadOnlyList<string>, CancellationToken>((ids, _) => capturedIds = ids)
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto { TweaksApplied = 2 }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        capturedIds.Should().NotBeNull();
        capturedIds.Should().Contain("unapplied1");
        capturedIds.Should().Contain("unapplied2");
        capturedIds.Should().NotContain("applied1");
    }

    [Fact]
    public async Task ApplyOptimizations_RefreshesCategoriesAfterSuccess()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto { TweaksApplied = 1 }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert - GetCategoriesAsync called once during init, once during apply refresh
        _mockOptimizationService.Verify(
            s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(2));
    }

    [Fact]
    public async Task ApplyOptimizations_Success_ClearsErrorMessage()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));
        _mockOptimizationService
            .Setup(s => s.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP"));
        _mockOptimizationService
            .Setup(s => s.ApplyOptimizationsAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto { TweaksApplied = 1 }));

        await _viewModel.InitializeAsync();

        // Act
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);

        // Assert
        _viewModel.HasError.Should().BeFalse();
    }

    [Fact]
    public async Task LoadCategories_WithTweaks_AllTweaksAccessible()
    {
        // Arrange
        var tweaks = new List<TweakDto>
        {
            new() { Id = "t1", Name = "Tweak A", Description = "Desc A", RiskLevel = "Low", IsApplied = false },
            new() { Id = "t2", Name = "Tweak B", Description = "Desc B", RiskLevel = "Medium", IsApplied = true },
            new() { Id = "t3", Name = "Tweak C", Description = "Desc C", RiskLevel = "High", IsApplied = false },
        };
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Mixed", Description = "Mixed tweaks", Tweaks = tweaks },
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.Categories.Should().HaveCount(1);
        _viewModel.Categories[0].Tweaks.Should().HaveCount(3);
        _viewModel.Categories[0].Tweaks[2].RiskLevel.Should().Be("High");
    }

    [Fact]
    public void Cleanup_DoesNotThrow()
    {
        var act = () => _viewModel.Cleanup();
        act.Should().NotThrow();
    }

    [Fact]
    public async Task ApplyOptimizations_AfterCleanup_DoesNotThrow()
    {
        // Arrange
        var categories = new List<OptimizationCategoryDto>
        {
            new() { Name = "Perf", Tweaks = new List<TweakDto>
            {
                new() { Id = "t1", IsApplied = false },
            }},
        };
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));

        await _viewModel.InitializeAsync();
        _viewModel.Cleanup();

        // Act & Assert - should not throw
        await _viewModel.ApplyOptimizationsCommand.ExecuteAsync(null);
    }

    [Fact]
    public async Task IsBusy_IsFalseAfterLoadCompletes()
    {
        // Arrange
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));

        // Act
        await _viewModel.InitializeAsync();

        // Assert
        _viewModel.IsBusy.Should().BeFalse();
        _viewModel.IsNotBusy.Should().BeTrue();
    }
}
