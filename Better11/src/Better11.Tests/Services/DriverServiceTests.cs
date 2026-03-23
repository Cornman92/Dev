// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Services;

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Driver;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

public sealed class DriverServiceTests : IDisposable
{
    private readonly Mock<IPowerShellService> _psMock;
    private readonly Mock<ILogger<DriverService>> _loggerMock;
    private readonly DriverService _service;
    private bool _disposed;

    public DriverServiceTests()
    {
        _psMock = new Mock<IPowerShellService>();
        _loggerMock = new Mock<ILogger<DriverService>>();
        _service = new DriverService(_psMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetInstalledDriversAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new[]
        {
            new DriverDto { DeviceId = "D1", DeviceName = "GPU", Manufacturer = "NVIDIA" }
        };

        _psMock.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            AppConstants.Modules.Drivers,
            "Get-B11InstalledDrivers",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(expectedResult));

        // Act
        var result = await _service.GetInstalledDriversAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task ScanForUpdatesAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var expectedResult = new[]
        {
            new DriverDto { DeviceId = "D1", HasUpdate = true }
        };

        _psMock.Setup(x => x.InvokeCommandListAsync<DriverDto>(
            AppConstants.Modules.Drivers,
            "Find-B11DriverUpdates",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(expectedResult));

        // Act
        var result = await _service.ScanForUpdatesAsync();

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedResult);
    }

    [Fact]
    public async Task UpdateDriverAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var deviceId = "D1";

        _psMock.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Drivers,
            "Update-B11Driver",
            It.Is<IDictionary<string, object>>(p => p.ContainsKey("DeviceId")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.UpdateDriverAsync(deviceId);

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task BackupDriverAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var deviceId = "D1";
        var backupPath = "C:\\Backups";
        var expectedResult = "Backup successful";

        _psMock.Setup(x => x.InvokeCommandAsync<string>(
            AppConstants.Modules.Drivers,
            "Backup-B11Driver",
            It.Is<IDictionary<string, object>>(p =>
                p.ContainsKey("DeviceId") &&
                p.ContainsKey("BackupPath")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success(expectedResult));

        // Act
        var result = await _service.BackupDriverAsync(deviceId, backupPath);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().Be(expectedResult);
    }

    [Fact]
    public async Task RollbackDriverAsyncShouldReturnSuccessWhenPowerShellSucceeds()
    {
        // Arrange
        var deviceId = "D1";

        _psMock.Setup(x => x.InvokeCommandVoidAsync(
            AppConstants.Modules.Drivers,
            "Undo-B11DriverUpdate",
            It.Is<IDictionary<string, object>>(p => p.ContainsKey("DeviceId")),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act
        var result = await _service.RollbackDriverAsync(deviceId);

        // Assert
        result.IsSuccess.Should().BeTrue();
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
