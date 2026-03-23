// ============================================================================
// Better11 System Enhancement Suite — UpdateServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Update;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="UpdateService"/>.
/// </summary>
public sealed class UpdateServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<UpdateService>> _mockLogger;
    private readonly UpdateService _service;

    public UpdateServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<UpdateService>>();
        _service = new UpdateService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new UpdateService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // CheckForUpdatesAsync
    // ========================================================================

    [Fact]
    public async Task CheckForUpdatesAsync_ReturnsSuccess_WithUpdates()
    {
        var expected = new List<WindowsUpdateDto>
        {
            new()
            {
                Id = "update-1",
                Title = "2026-02 Cumulative Update",
                KbNumber = "KB5040000",
                SizeBytes = 500_000_000,
                Category = "Security",
                IsInstalled = false,
            },
            new()
            {
                Id = "update-2",
                Title = ".NET Runtime 8.0.15",
                KbNumber = "KB5040001",
                SizeBytes = 50_000_000,
                Category = "Feature Pack",
                IsInstalled = false,
            },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<WindowsUpdateDto>>.Success(expected));

        var result = await _service.CheckForUpdatesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value![0].KbNumber.Should().Be("KB5040000");
    }

    [Fact]
    public async Task CheckForUpdatesAsync_ReturnsEmpty_WhenUpToDate()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<WindowsUpdateDto>>.Success(
                Array.Empty<WindowsUpdateDto>()));

        var result = await _service.CheckForUpdatesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEmpty();
    }

    [Fact]
    public async Task CheckForUpdatesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<WindowsUpdateDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.CheckForUpdatesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task CheckForUpdatesAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            AppConstants.Modules.Update, "Get-B11AvailableUpdates",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<WindowsUpdateDto>>.Success(
                new List<WindowsUpdateDto>()));

        await _service.CheckForUpdatesAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            AppConstants.Modules.Update, "Get-B11AvailableUpdates",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // InstallUpdatesAsync
    // ========================================================================

    [Fact]
    public async Task InstallUpdatesAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.InstallUpdatesAsync(
            new List<string> { "update-1", "update-2" }, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task InstallUpdatesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "Installation failed"));

        var result = await _service.InstallUpdatesAsync(
            new List<string> { "update-1" }, CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Be("Installation failed");
    }

    [Fact]
    public async Task InstallUpdatesAsync_PassesUpdateIds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Update, "Install-B11Updates",
            It.Is<IDictionary<string, object>>(d => d.ContainsKey("UpdateIds")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.InstallUpdatesAsync(
            new List<string> { "u1", "u2" }, CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Update, "Install-B11Updates",
            It.Is<IDictionary<string, object>>(d => d.ContainsKey("UpdateIds")),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // GetUpdateHistoryAsync
    // ========================================================================

    [Fact]
    public async Task GetUpdateHistoryAsync_ReturnsSuccess_WithHistory()
    {
        var expected = new List<WindowsUpdateDto>
        {
            new()
            {
                Id = "hist-1",
                Title = "Previous Update",
                IsInstalled = true,
                InstalledDate = new DateTime(2026, 2, 20),
            },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<WindowsUpdateDto>>.Success(expected));

        var result = await _service.GetUpdateHistoryAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
        result.Value![0].IsInstalled.Should().BeTrue();
    }

    [Fact]
    public async Task GetUpdateHistoryAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<WindowsUpdateDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetUpdateHistoryAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetUpdateHistoryAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandListAsync<WindowsUpdateDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var result = await _service.GetUpdateHistoryAsync(cts.Token);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.Cancelled);
    }
}
