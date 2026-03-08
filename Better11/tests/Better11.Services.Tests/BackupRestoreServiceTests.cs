// ============================================================================
// Better11 System Enhancement Suite — BackupRestoreServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.Services.BackupRestore;
using FluentAssertions;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="BackupRestoreService"/>.
/// </summary>
public sealed class BackupRestoreServiceTests
{
    private const string ModuleName = "B11.BackupRestore";

    private readonly Mock<IPowerShellService> _mockPs;
    private readonly BackupRestoreService _service;

    /// <summary>
    /// Initializes a new instance of the <see cref="BackupRestoreServiceTests"/> class.
    /// </summary>
    public BackupRestoreServiceTests()
    {
        _mockPs = new Mock<IPowerShellService>();
        _service = new BackupRestoreService(_mockPs.Object);
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenPowerShellIsNull()
    {
        var act = () => new BackupRestoreService(null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task GetRestorePointsAsync_InvokesExpectedCommand()
    {
        _mockPs.Setup(x => x.InvokeCommandListAsync<RestorePointDto>(
            ModuleName,
            "Get-B11RestorePoint",
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<RestorePointDto>>.Success(Array.Empty<RestorePointDto>()));

        var result = await _service.GetRestorePointsAsync(CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
        _mockPs.Verify(x => x.InvokeCommandListAsync<RestorePointDto>(
            ModuleName,
            "Get-B11RestorePoint",
            null,
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateRestorePointAsync_PassesDescription()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "New-B11RestorePoint",
            It.Is<IDictionary<string, object>>(parameters =>
                (string)parameters["Description"] == "Before tweak"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.CreateRestorePointAsync("Before tweak", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task ExportRegistryKeyAsync_PassesKeyPathAndName()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "Export-B11RegistryKey",
            It.Is<IDictionary<string, object>>(parameters =>
                (string)parameters["KeyPath"] == @"HKCU\Software\Test"
                && (string)parameters["Name"] == "backup"),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.ExportRegistryKeyAsync(@"HKCU\Software\Test", "backup", CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task CreateFileBackupAsync_PassesSourceDestinationAndFlags()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "New-B11FileBackup",
            It.Is<IDictionary<string, object>>(parameters =>
                (string)parameters["Source"] == @"C:\Source"
                && (string)parameters["Destination"] == @"D:\Backup"
                && (bool)parameters["Compress"]
                && !(bool)parameters["Encrypt"]),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.CreateFileBackupAsync(@"C:\Source", @"D:\Backup", true, false, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task CreateScheduleAsync_PassesExpectedParameters()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<bool>(
            ModuleName,
            "New-B11BackupSchedule",
            It.Is<IDictionary<string, object>>(parameters =>
                (string)parameters["Name"] == "nightly"
                && (string)parameters["Source"] == @"C:\Source"
                && (string)parameters["Destination"] == @"D:\Backup"
                && (string)parameters["Frequency"] == "Daily"
                && (int)parameters["RetentionDays"] == 14),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        var result = await _service.CreateScheduleAsync("nightly", @"C:\Source", @"D:\Backup", "Daily", 14, CancellationToken.None);

        result.IsSuccess.Should().BeTrue();
    }
}
