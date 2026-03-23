// ============================================================================
// Better11 System Enhancement Suite — OptimizationServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Optimization;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="OptimizationService"/>.
/// </summary>
public sealed class OptimizationServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<OptimizationService>> _mockLogger;
    private readonly OptimizationService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="OptimizationServiceTests"/> class.
    /// </summary>
    public OptimizationServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<OptimizationService>>();
        _service = new OptimizationService(_mockPs.Object, _mockLogger.Object);
    }

    // ========================================================================
    // Constructor
    // ========================================================================

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new OptimizationService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetCategoriesAsync
    // ========================================================================

    [Fact]
    public async Task GetCategoriesAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new List<OptimizationCategoryDto> { new() { Name = "Performance" } };
        _mockPs.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(expected));

        var result = await _service.GetCategoriesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
        result.Value![0].Name.Should().Be("Performance");
    }

    [Fact]
    public async Task GetCategoriesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetCategoriesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Be("PS error");
    }

    [Fact]
    public async Task GetCategoriesAsync_ReturnsEmptyList_WhenNoCategories()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                Array.Empty<OptimizationCategoryDto>()));

        var result = await _service.GetCategoriesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEmpty();
    }

    [Fact]
    public async Task GetCategoriesAsync_InvokesCorrectPowerShellCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            AppConstants.Modules.Optimization, "Get-B11OptimizationCategories",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));

        await _service.GetCategoriesAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            AppConstants.Modules.Optimization, "Get-B11OptimizationCategories",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task GetCategoriesAsync_PropagatesCancellationToken()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var result = await _service.GetCategoriesAsync(cts.Token);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.Cancelled);
    }

    [Fact]
    public async Task GetCategoriesAsync_ReturnsMultipleCategories_WithTweaks()
    {
        var categories = new List<OptimizationCategoryDto>
        {
            new()
            {
                Name = "Performance",
                Tweaks = new List<TweakDto>
                {
                    new() { Id = "t1", Name = "Disable Animations", IsApplied = false },
                    new() { Id = "t2", Name = "GPU Scheduling", IsApplied = true },
                },
            },
            new()
            {
                Name = "Privacy",
                Tweaks = new List<TweakDto>
                {
                    new() { Id = "t3", Name = "Disable Telemetry", IsApplied = false },
                },
            },
        };

        _mockPs.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(categories));

        var result = await _service.GetCategoriesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value![0].Tweaks.Should().HaveCount(2);
        result.Value![1].Tweaks.Should().HaveCount(1);
    }

    // ========================================================================
    // ApplyOptimizationsAsync
    // ========================================================================

    [Fact]
    public async Task ApplyOptimizationsAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new OptimizationResultDto { TweaksApplied = 3, RebootRequired = true };
        _mockPs.Setup(x => x.InvokeCommandAsync<OptimizationResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(expected));

        var result = await _service.ApplyOptimizationsAsync(
            new List<string> { "tweak1", "tweak2", "tweak3" }, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value!.TweaksApplied.Should().Be(3);
        result.Value.RebootRequired.Should().BeTrue();
    }

    [Fact]
    public async Task ApplyOptimizationsAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<OptimizationResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.ApplyOptimizationsAsync(
            new List<string> { "tweak1" }, CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task ApplyOptimizationsAsync_PassesTweakIdsToCommand()
    {
        var tweakIds = new List<string> { "t1", "t2" };
        _mockPs.Setup(x => x.InvokeCommandAsync<OptimizationResultDto>(
            AppConstants.Modules.Optimization, "Invoke-B11Optimization",
            It.Is<IDictionary<string, object>>(d => d.ContainsKey("TweakIds")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto()));

        await _service.ApplyOptimizationsAsync(tweakIds, CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<OptimizationResultDto>(
            AppConstants.Modules.Optimization, "Invoke-B11Optimization",
            It.Is<IDictionary<string, object>>(d => d.ContainsKey("TweakIds")),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ApplyOptimizationsAsync_ReportsFailedTweaks()
    {
        var result = new OptimizationResultDto
        {
            TweaksApplied = 1,
            FailedTweaks = new List<string> { "tweak2" },
            RebootRequired = false,
        };
        _mockPs.Setup(x => x.InvokeCommandAsync<OptimizationResultDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(result));

        var actual = await _service.ApplyOptimizationsAsync(
            new List<string> { "tweak1", "tweak2" }, CancellationToken.None);

        actual.IsSuccess.Should().BeTrue();
        actual.Value!.FailedTweaks.Should().Contain("tweak2");
    }

    // ========================================================================
    // CreateRestorePointAsync
    // ========================================================================

    [Fact]
    public async Task CreateRestorePointAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<string>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("RP_20260226_120000"));

        var result = await _service.CreateRestorePointAsync("Better11 RP", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().Contain("RP_");
    }

    [Fact]
    public async Task CreateRestorePointAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<string>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.CreateRestorePointAsync("Better11 RP", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task CreateRestorePointAsync_PassesDescriptionToCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<string>(
            AppConstants.Modules.Optimization, "New-B11RestorePoint",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("Description") && (string)d["Description"] == "Test RP"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("done"));

        await _service.CreateRestorePointAsync("Test RP", CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandAsync<string>(
            AppConstants.Modules.Optimization, "New-B11RestorePoint",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("Description") && (string)d["Description"] == "Test RP"),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
