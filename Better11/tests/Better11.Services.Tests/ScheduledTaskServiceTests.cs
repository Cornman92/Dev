// ============================================================================
// Better11 System Enhancement Suite — ScheduledTaskServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.ScheduledTask;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="ScheduledTaskService"/>.
/// </summary>
public sealed class ScheduledTaskServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<ScheduledTaskService>> _mockLogger;
    private readonly ScheduledTaskService _service;

    public ScheduledTaskServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<ScheduledTaskService>>();
        _service = new ScheduledTaskService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new ScheduledTaskService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetScheduledTasksAsync
    // ========================================================================

    [Fact]
    public async Task GetScheduledTasksAsync_ReturnsSuccess_WithMultipleTasks()
    {
        var expected = new List<ScheduledTaskDto>
        {
            new()
            {
                TaskPath = "\\Microsoft\\Windows\\Defrag\\ScheduledDefrag",
                TaskName = "ScheduledDefrag",
                State = "Ready",
                Author = "Microsoft",
            },
            new()
            {
                TaskPath = "\\Microsoft\\Windows\\DiskDiagnostic\\Microsoft-Windows-DiskDiagnosticDataCollector",
                TaskName = "Microsoft-Windows-DiskDiagnosticDataCollector",
                State = "Disabled",
                Author = "Microsoft",
            },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<ScheduledTaskDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(expected));

        var result = await _service.GetScheduledTasksAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value![0].State.Should().Be("Ready");
        result.Value[1].State.Should().Be("Disabled");
    }

    [Fact]
    public async Task GetScheduledTasksAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<ScheduledTaskDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetScheduledTasksAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetScheduledTasksAsync_ReturnsEmptyList_WhenNoTasks()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<ScheduledTaskDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(
                Array.Empty<ScheduledTaskDto>()));

        var result = await _service.GetScheduledTasksAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEmpty();
    }

    [Fact]
    public async Task GetScheduledTasksAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<ScheduledTaskDto>(
            AppConstants.Modules.Tasks, "Get-B11ScheduledTasks",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(
                new List<ScheduledTaskDto>()));

        await _service.GetScheduledTasksAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandListAsync<ScheduledTaskDto>(
            AppConstants.Modules.Tasks, "Get-B11ScheduledTasks",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // EnableTaskAsync
    // ========================================================================

    [Fact]
    public async Task EnableTaskAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.EnableTaskAsync("\\Task1", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task EnableTaskAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.AccessDenied, "Access denied"));

        var result = await _service.EnableTaskAsync("\\Task1", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.AccessDenied);
    }

    [Fact]
    public async Task EnableTaskAsync_PassesTaskPath()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Tasks, "Enable-B11ScheduledTask",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("TaskPath") && (string)d["TaskPath"] == "\\Microsoft\\Task1"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.EnableTaskAsync("\\Microsoft\\Task1", CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Tasks, "Enable-B11ScheduledTask",
            It.Is<IDictionary<string, object>>(d => d.ContainsKey("TaskPath")),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // DisableTaskAsync
    // ========================================================================

    [Fact]
    public async Task DisableTaskAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.DisableTaskAsync("\\Task1", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task DisableTaskAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.DisableTaskAsync("\\Task1", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    // ========================================================================
    // RunTaskAsync
    // ========================================================================

    [Fact]
    public async Task RunTaskAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.RunTaskAsync("\\Task1", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RunTaskAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.NotFound, "Task not found"));

        var result = await _service.RunTaskAsync("\\Task1", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Code.Should().Be(ErrorCodes.NotFound);
    }

    [Fact]
    public async Task RunTaskAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var act = () => _service.RunTaskAsync("\\Task1", cts.Token);
        await act.Should().ThrowAsync<OperationCanceledException>();
    }
}
