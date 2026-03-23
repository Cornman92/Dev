// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Services;

using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Optimization;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class OptimizationServiceTests : IDisposable
{
    private static readonly string[] TestTweakIds = ["T1"];
    private readonly Mock<IPowerShellService> _psMock;
    private readonly Mock<ILogger<OptimizationService>> _loggerMock;
    private readonly OptimizationService _service;
    private bool _disposed;

    public OptimizationServiceTests()
    {
        _psMock = new Mock<IPowerShellService>();
        _loggerMock = new Mock<ILogger<OptimizationService>>();
        _service = new OptimizationService(_psMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetCategoriesAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new[]
        {
            new OptimizationCategoryDto
            {
                Name = "System Performance",
                Tweaks = new[] { new TweakDto { Id = "Tweak1", Name = "Optimize CPU" } }
            }
        };

        _psMock.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            AppConstants.Modules.Optimization,
            "Get-B11OptimizationCategories",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(expectedResult));

        // Act
        var result = await _service.GetCategoriesAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task ApplyOptimizationsAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var tweakIds = new[] { "Tweak1", "Tweak2" };
        var expectedResult = new OptimizationResultDto
        {
            TweaksApplied = 2,
            RebootRequired = true
        };

        _psMock.Setup(x => x.InvokeCommandAsync<OptimizationResultDto>(
            AppConstants.Modules.Optimization,
            "Invoke-B11Optimization",
            It.Is<IDictionary<string, object>>(p => p.ContainsKey("TweakIds")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(expectedResult));

        // Act
        var result = await _service.ApplyOptimizationsAsync(tweakIds);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task CreateRestorePointAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var description = "Before optimization";
        var expectedResult = "Restore point R123 created successully.";

        _psMock.Setup(x => x.InvokeCommandAsync<string>(
            AppConstants.Modules.Optimization,
            "New-B11RestorePoint",
            It.Is<IDictionary<string, object>>(p => p.ContainsKey("Description")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success(expectedResult));

        // Act
        var result = await _service.CreateRestorePointAsync(description);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().Be(expectedResult);
    }

    [Fact]
    public async Task GetCategoriesAsyncShouldCacheResults()
    {
        // Arrange
        var expectedResult = new[]
        {
            new OptimizationCategoryDto { Name = "Performance" }
        };

        _psMock.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            AppConstants.Modules.Optimization,
            "Get-B11OptimizationCategories",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(expectedResult));

        // Act
        var result1 = await _service.GetCategoriesAsync();
        var result2 = await _service.GetCategoriesAsync();

        // Assert
        result1.IsSuccess.Should().BeTrue();
        result2.IsSuccess.Should().BeTrue();
        _psMock.Verify(
            x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
                It.IsAny<string>(),
                "Get-B11OptimizationCategories",
                null,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ApplyOptimizationsAsyncShouldInvalidateCache()
    {
        // Arrange
        _psMock.Setup(x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
            AppConstants.Modules.Optimization,
            "Get-B11OptimizationCategories",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(new[] { new OptimizationCategoryDto() }));

        _psMock.Setup(x => x.InvokeCommandAsync<OptimizationResultDto>(
            AppConstants.Modules.Optimization,
            "Invoke-B11Optimization",
            It.IsAny<IDictionary<string, object>>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<OptimizationResultDto>.Success(new OptimizationResultDto()));

        // Act
        await _service.GetCategoriesAsync(); // Caches
        await _service.ApplyOptimizationsAsync(TestTweakIds); // Should invalidate
        await _service.GetCategoriesAsync(); // Should call PS again

        // Assert
        _psMock.Verify(
            x => x.InvokeCommandListAsync<OptimizationCategoryDto>(
                It.IsAny<string>(),
                "Get-B11OptimizationCategories",
                null,
                It.IsAny<CancellationToken>()),
            Times.Exactly(2));
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            _service.Dispose();
            _disposed = true;
        }
    }
}
