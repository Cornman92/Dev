// ============================================================================
// Better11 System Enhancement Suite — BackupRestoreViewModelTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.BackupRestore;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.ViewModels.Tests;

/// <summary>
/// Unit tests for <see cref="BackupRestoreViewModel"/>.
/// </summary>
public sealed class BackupRestoreViewModelTests
{
    private readonly Mock<IBackupRestoreService> _mockService;
    private readonly Mock<ILogger<BackupRestoreViewModel>> _mockLogger;
    private readonly BackupRestoreViewModel _viewModel;

    /// <summary>
    /// Initializes a new instance of the <see cref="BackupRestoreViewModelTests"/> class.
    /// </summary>
    public BackupRestoreViewModelTests()
    {
        _mockService = new Mock<IBackupRestoreService>();
        _mockLogger = new Mock<ILogger<BackupRestoreViewModel>>();

        _mockService.Setup(x => x.GetRestorePointsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<RestorePointDto>>.Success(new[]
            {
                new RestorePointDto { Description = "Before Better11" },
            }));
        _mockService.Setup(x => x.GetRegistryBackupsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<RegistryBackupDto>>.Success(Array.Empty<RegistryBackupDto>()));
        _mockService.Setup(x => x.GetFileBackupsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<FileBackupDto>>.Success(Array.Empty<FileBackupDto>()));
        _mockService.Setup(x => x.GetSchedulesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<BackupScheduleDto>>.Success(Array.Empty<BackupScheduleDto>()));
        _mockService.Setup(x => x.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Success(true));

        _viewModel = new BackupRestoreViewModel(_mockService.Object, _mockLogger.Object);
    }

    [Fact]
    public void Constructor_SetsPageTitleAndDefaults()
    {
        _viewModel.PageTitle.Should().Be("Backup & Restore");
        _viewModel.Retention.Should().Be(30);
        _viewModel.SchedFreq.Should().Be("Daily");
        _viewModel.IsLoading.Should().BeFalse();
    }

    [Fact]
    public void Constructor_InitializesCollectionsAndCommands()
    {
        _viewModel.RestorePoints.Should().NotBeNull();
        _viewModel.RegBackups.Should().NotBeNull();
        _viewModel.FileBackups.Should().NotBeNull();
        _viewModel.Schedules.Should().NotBeNull();
        _viewModel.RefreshAllCommand.Should().NotBeNull();
        _viewModel.CreateRpCommand.Should().NotBeNull();
        _viewModel.ExportRegCommand.Should().NotBeNull();
        _viewModel.ImportRegCommand.Should().NotBeNull();
        _viewModel.CreateBackupCommand.Should().NotBeNull();
        _viewModel.CreateScheduleCommand.Should().NotBeNull();
        _viewModel.DeleteScheduleCommand.Should().NotBeNull();
    }

    [Fact]
    public async Task InitializeAsync_LoadsCollectionsAndSetsStatusMessage()
    {
        await _viewModel.InitializeAsync();

        _viewModel.IsInitialized.Should().BeTrue();
        _viewModel.StatusMessage.Should().Be("Backup and restore data refreshed.");
        _viewModel.RestorePoints.Should().ContainSingle();
    }

    [Fact]
    public async Task CreateRpCommand_SetsValidationError_WhenDescriptionMissing()
    {
        await _viewModel.CreateRpCommand.ExecuteAsync(null);

        _viewModel.ErrorMessage.Should().Be("Description is required.");
        _mockService.Verify(x => x.CreateRestorePointAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task CreateRpCommand_CallsServiceAndClearsDescription_WhenValid()
    {
        _viewModel.RpDescription = "Checkpoint";

        await _viewModel.CreateRpCommand.ExecuteAsync(null);

        _viewModel.SuccessMessage.Should().Be("System restore point created.");
        _viewModel.RpDescription.Should().BeEmpty();
        _mockService.Verify(x => x.CreateRestorePointAsync("Checkpoint", It.IsAny<CancellationToken>()), Times.Once);
    }
}
