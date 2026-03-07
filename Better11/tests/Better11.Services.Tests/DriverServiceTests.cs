// ============================================================================
// Better11 System Enhancement Suite — DriverServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Driver;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="DriverService"/>.
/// </summary>
public sealed class DriverServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly Mock<ILogger<DriverService>> _mockLogger;
    private readonly DriverService _service;

    public DriverServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _mockLogger = new Mock<ILogger<DriverService>>();
        _service = new DriverService(_mockPs.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new DriverService(null!, _mockLogger.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    // ========================================================================
    // GetInstalledDriversAsync
    // ========================================================================

    [Fact]
    public async Task GetInstalledDriversAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        var expected = new List<DriverDto>
        {
            new() { DeviceId = "dev-001", DeviceName = "NVIDIA RTX 4090", Category = "Display" },
            new() { DeviceId = "dev-002", DeviceName = "Realtek Audio", Category = "Audio" },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(expected));

        var result = await _service.GetInstalledDriversAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(2);
        result.Value![0].DeviceName.Should().Contain("NVIDIA");
    }

    [Fact]
    public async Task GetInstalledDriversAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.GetInstalledDriversAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task GetInstalledDriversAsync_ReturnsEmptyList_WhenNoDrivers()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(Array.Empty<DriverDto>()));

        var result = await _service.GetInstalledDriversAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEmpty();
    }

    [Fact]
    public async Task GetInstalledDriversAsync_InvokesCorrectCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            AppConstants.Modules.Drivers, "Get-B11InstalledDrivers",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto>()));

        await _service.GetInstalledDriversAsync(CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandListAsync<DriverDto>(
            AppConstants.Modules.Drivers, "Get-B11InstalledDrivers",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // ScanForUpdatesAsync
    // ========================================================================

    [Fact]
    public async Task ScanForUpdatesAsync_ReturnsSuccess_WhenUpdatesFound()
    {
        var expected = new List<DriverDto>
        {
            new() { DeviceId = "dev-001", HasUpdate = true, DriverVersion = "1.0.0" },
        };
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(expected));

        var result = await _service.ScanForUpdatesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().HaveCount(1);
        result.Value![0].HasUpdate.Should().BeTrue();
    }

    [Fact]
    public async Task ScanForUpdatesAsync_ReturnsEmpty_WhenNoUpdatesAvailable()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(Array.Empty<DriverDto>()));

        var result = await _service.ScanForUpdatesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEmpty();
    }

    [Fact]
    public async Task ScanForUpdatesAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.ScanForUpdatesAsync(CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    // ========================================================================
    // UpdateDriverAsync
    // ========================================================================

    [Fact]
    public async Task UpdateDriverAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.UpdateDriverAsync("dev-001", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task UpdateDriverAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "Update failed"));

        var result = await _service.UpdateDriverAsync("dev-001", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Be("Update failed");
    }

    [Fact]
    public async Task UpdateDriverAsync_PassesDeviceIdToCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Drivers, "Update-B11Driver",
            It.Is<IDictionary<string, object>>(d =>
                d.ContainsKey("DeviceId") && (string)d["DeviceId"] == "dev-001"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _service.UpdateDriverAsync("dev-001", CancellationToken.None);

        _mockPs.Verify(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Drivers, "Update-B11Driver",
            It.Is<IDictionary<string, object>>(d => d.ContainsKey("DeviceId")),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ========================================================================
    // BackupDriverAsync
    // ========================================================================

    [Fact]
    public async Task BackupDriverAsync_ReturnsSuccess_WithBackupPath()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<string>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success("C:\\Backups\\driver_dev001.zip"));

        var result = await _service.BackupDriverAsync("dev-001", "C:\\Backups", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        result.Value.Should().Contain("Backups");
    }

    [Fact]
    public async Task BackupDriverAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<string>(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Failure(ErrorCodes.PowerShell, "Backup failed"));

        var result = await _service.BackupDriverAsync("dev-001", "C:\\Backups", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    // ========================================================================
    // RollbackDriverAsync
    // ========================================================================

    [Fact]
    public async Task RollbackDriverAsync_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        var result = await _service.RollbackDriverAsync("dev-001", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RollbackDriverAsync_ReturnsFailure_WhenPowerShellFails()
    {
        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure(ErrorCodes.PowerShell, "PS error"));

        var result = await _service.RollbackDriverAsync("dev-001", CancellationToken.None);

        result.IsSuccess.Should().BeFalse();
    }

    [Fact]
    public async Task RollbackDriverAsync_PropagatesCancellation()
    {
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        _mockPs.Setup(x => x.InvokeCommandVoidAsync(
            It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<IDictionary<string, object>>(), cts.Token))
            .ThrowsAsync(new OperationCanceledException());

        var act = () => _service.RollbackDriverAsync("dev-001", cts.Token);
        await act.Should().ThrowAsync<OperationCanceledException>();
    }
}
