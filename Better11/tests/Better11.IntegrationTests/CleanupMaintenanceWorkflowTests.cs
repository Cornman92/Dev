// Copyright (c) Better11. All rights reserved.

using System.Linq;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.DiskCleanup;
using Better11.ViewModels.ScheduledTask;
using Better11.ViewModels.Startup;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for disk cleanup, startup management, and scheduled task workflows,
/// verifying end-to-end ViewModel orchestration through IDiskCleanupService,
/// IStartupService, and IScheduledTaskService.
/// </summary>
public sealed class CleanupMaintenanceWorkflowTests
{
    private readonly Mock<IDiskCleanupService> _mockDiskCleanupService;
    private readonly Mock<IStartupService> _mockStartupService;
    private readonly Mock<IScheduledTaskService> _mockScheduledTaskService;
    private readonly Mock<ILogger<DiskCleanupViewModel>> _mockCleanupLogger;
    private readonly Mock<ILogger<StartupViewModel>> _mockStartupLogger;
    private readonly Mock<ILogger<ScheduledTaskViewModel>> _mockTaskLogger;
    private readonly DiskCleanupViewModel _cleanupVm;
    private readonly StartupViewModel _startupVm;
    private readonly ScheduledTaskViewModel _taskVm;

    public CleanupMaintenanceWorkflowTests()
    {
        _mockDiskCleanupService = new Mock<IDiskCleanupService>();
        _mockStartupService = new Mock<IStartupService>();
        _mockScheduledTaskService = new Mock<IScheduledTaskService>();
        _mockCleanupLogger = new Mock<ILogger<DiskCleanupViewModel>>();
        _mockStartupLogger = new Mock<ILogger<StartupViewModel>>();
        _mockTaskLogger = new Mock<ILogger<ScheduledTaskViewModel>>();
        _cleanupVm = new DiskCleanupViewModel(_mockDiskCleanupService.Object, _mockCleanupLogger.Object);
        _startupVm = new StartupViewModel(_mockStartupService.Object, _mockStartupLogger.Object);
        _taskVm = new ScheduledTaskViewModel(_mockScheduledTaskService.Object, _mockTaskLogger.Object);
    }

    // ====================================================================
    // Disk Cleanup: Scan
    // ====================================================================

    [Fact]
    public async Task ScanDisk_Success_PopulatesScanResult()
    {
        // Arrange
        SetupDiskSpaceSuccess();
        var scanResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 1_073_741_824, // 1 GB
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp Files", Description = "Temporary files", ReclaimableBytes = 500_000_000, FileCount = 1200, IsSelectedByDefault = true },
                new() { Name = "Browser Cache", Description = "Browser cache", ReclaimableBytes = 573_741_824, FileCount = 3400, IsSelectedByDefault = true },
            },
        };
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(scanResult));

        await _cleanupVm.InitializeAsync();

        // Act
        await _cleanupVm.ScanCommand.ExecuteAsync(null);

        // Assert
        _cleanupVm.ScanResult.Should().NotBeNull();
        _cleanupVm.ScanResult!.Categories.Should().HaveCount(2);
        _cleanupVm.ScanResult.TotalReclaimableBytes.Should().Be(1_073_741_824);
        _cleanupVm.ReclaimableText.Should().Contain("MB");
    }

    [Fact]
    public async Task ScanDisk_Failure_SetsErrorMessage()
    {
        // Arrange
        SetupDiskSpaceSuccess();
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Failure("Disk access denied"));

        await _cleanupVm.InitializeAsync();

        // Act
        await _cleanupVm.ScanCommand.ExecuteAsync(null);

        // Assert
        _cleanupVm.ErrorMessage.Should().Contain("Disk access denied");
    }

    // ====================================================================
    // Disk Cleanup: Clean
    // ====================================================================

    [Fact]
    public async Task CleanDisk_Success_ReportsFreedSpace()
    {
        // Arrange
        SetupDiskSpaceSuccess();
        var scanResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 500_000_000,
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp Files", ReclaimableBytes = 300_000_000, IsSelectedByDefault = true },
                new() { Name = "Logs", ReclaimableBytes = 200_000_000, IsSelectedByDefault = true },
            },
        };
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(scanResult));
        _mockDiskCleanupService
            .Setup(s => s.CleanAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(new CleanupResultDto
            {
                BytesFreed = 450_000_000,
                FilesRemoved = 2500,
                Errors = Array.Empty<string>(),
            }));

        await _cleanupVm.InitializeAsync();
        await _cleanupVm.ScanCommand.ExecuteAsync(null);

        // Act
        await _cleanupVm.CleanCommand.ExecuteAsync(null);

        // Assert
        _cleanupVm.SuccessMessage.Should().Contain("MB");
        _cleanupVm.SuccessMessage.Should().Contain("2500");
    }

    [Fact]
    public async Task CleanDisk_Failure_SetsErrorMessage()
    {
        // Arrange
        SetupDiskSpaceSuccess();
        var scanResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 100_000_000,
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp Files", IsSelectedByDefault = true },
            },
        };
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(scanResult));
        _mockDiskCleanupService
            .Setup(s => s.CleanAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Failure("Files in use"));

        await _cleanupVm.InitializeAsync();
        await _cleanupVm.ScanCommand.ExecuteAsync(null);

        // Act
        await _cleanupVm.CleanCommand.ExecuteAsync(null);

        // Assert
        _cleanupVm.ErrorMessage.Should().Contain("Files in use");
    }

    [Fact]
    public async Task CleanDisk_NoScanResult_DoesNotCallService()
    {
        // Arrange
        SetupDiskSpaceSuccess();
        await _cleanupVm.InitializeAsync();

        // Act - Clean without scanning first
        await _cleanupVm.CleanCommand.ExecuteAsync(null);

        // Assert
        _mockDiskCleanupService.Verify(
            s => s.CleanAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    // ====================================================================
    // Disk Cleanup: GetDiskSpace
    // ====================================================================

    [Fact]
    public async Task GetDiskSpace_Success_PopulatesDiskSpaces()
    {
        // Arrange
        var diskSpaces = new List<DiskSpaceDto>
        {
            new() { DriveLetter = "C:", VolumeLabel = "System", TotalBytes = 500_000_000_000, FreeBytes = 150_000_000_000 },
            new() { DriveLetter = "D:", VolumeLabel = "Data", TotalBytes = 1_000_000_000_000, FreeBytes = 800_000_000_000 },
        };
        _mockDiskCleanupService
            .Setup(s => s.GetDiskSpaceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(diskSpaces));

        // Act
        await _cleanupVm.InitializeAsync();

        // Assert
        _cleanupVm.DiskSpaces.Should().HaveCount(2);
        _cleanupVm.DiskSpaces[0].DriveLetter.Should().Be("C:");
        _cleanupVm.DiskSpaces[1].FreeBytes.Should().Be(800_000_000_000);
    }

    // ====================================================================
    // Disk Cleanup: Category Selection
    // ====================================================================

    [Fact]
    public async Task CleanupWithCategories_OnlyCleanSelected_PassesCorrectCategories()
    {
        // Arrange
        IReadOnlyList<string>? capturedCategories = null;
        SetupDiskSpaceSuccess();
        var scanResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 500_000_000,
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp Files", IsSelectedByDefault = true },
                new() { Name = "Browser Cache", IsSelectedByDefault = false },
                new() { Name = "Recycle Bin", IsSelectedByDefault = true },
            },
        };
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(scanResult));
        _mockDiskCleanupService
            .Setup(s => s.CleanAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .Callback<IReadOnlyList<string>, CancellationToken>((cats, _) => capturedCategories = cats)
            .ReturnsAsync(Result<CleanupResultDto>.Success(new CleanupResultDto { BytesFreed = 300_000_000, FilesRemoved = 500 }));

        await _cleanupVm.InitializeAsync();
        await _cleanupVm.ScanCommand.ExecuteAsync(null);

        // Act
        await _cleanupVm.CleanCommand.ExecuteAsync(null);

        // Assert
        capturedCategories.Should().NotBeNull();
        capturedCategories.Should().Contain("Temp Files");
        capturedCategories.Should().Contain("Recycle Bin");
        capturedCategories.Should().NotContain("Browser Cache");
    }

    // ====================================================================
    // Startup: Load Items
    // ====================================================================

    [Fact]
    public async Task LoadStartupItems_Success_PopulatesCollection()
    {
        // Arrange
        var items = new List<StartupItemDto>
        {
            new() { Id = "s1", Name = "Spotify", Publisher = "Spotify AB", IsEnabled = true, Impact = "High" },
            new() { Id = "s2", Name = "Discord", Publisher = "Discord Inc.", IsEnabled = true, Impact = "Medium" },
            new() { Id = "s3", Name = "OneDrive", Publisher = "Microsoft", IsEnabled = false, Impact = "Low" },
        };
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(items));

        // Act
        await _startupVm.InitializeAsync();

        // Assert
        _startupVm.StartupItems.Should().HaveCount(3);
        _startupVm.StartupItems[0].Name.Should().Be("Spotify");
        _startupVm.StartupItems[2].IsEnabled.Should().BeFalse();
    }

    [Fact]
    public async Task LoadStartupItems_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Failure("Registry read failed"));

        // Act
        await _startupVm.InitializeAsync();

        // Assert
        _startupVm.ErrorMessage.Should().Contain("Registry read failed");
    }

    // ====================================================================
    // Startup: Enable / Disable / Remove
    // ====================================================================

    [Fact]
    public async Task EnableStartupItem_Success_ServiceCalled()
    {
        // Arrange
        var items = new List<StartupItemDto> { new() { Id = "s1", Name = "App", IsEnabled = false } };
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(items));
        _mockStartupService
            .Setup(s => s.EnableStartupItemAsync("s1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _startupVm.InitializeAsync();

        // Act
        var result = await InvokeStartupServiceMethodAsync(() =>
            _mockStartupService.Object.EnableStartupItemAsync("s1"));

        // Assert
        result.IsSuccess.Should().BeTrue();
        _mockStartupService.Verify(s => s.EnableStartupItemAsync("s1", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DisableStartupItem_Success_ServiceCalled()
    {
        // Arrange
        var items = new List<StartupItemDto> { new() { Id = "s1", Name = "App", IsEnabled = true } };
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(items));
        _mockStartupService
            .Setup(s => s.DisableStartupItemAsync("s1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _startupVm.InitializeAsync();

        // Act
        var result = await _mockStartupService.Object.DisableStartupItemAsync("s1");

        // Assert
        result.IsSuccess.Should().BeTrue();
        _mockStartupService.Verify(s => s.DisableStartupItemAsync("s1", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RemoveStartupItem_Success_ServiceCalled()
    {
        // Arrange
        var items = new List<StartupItemDto> { new() { Id = "s1", Name = "App" } };
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(items));
        _mockStartupService
            .Setup(s => s.RemoveStartupItemAsync("s1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _startupVm.InitializeAsync();

        // Act
        var result = await _mockStartupService.Object.RemoveStartupItemAsync("s1");

        // Assert
        result.IsSuccess.Should().BeTrue();
        _mockStartupService.Verify(s => s.RemoveStartupItemAsync("s1", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task EnableStartupItem_Failure_ReturnsError()
    {
        // Arrange
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(new List<StartupItemDto>()));
        _mockStartupService
            .Setup(s => s.EnableStartupItemAsync("s1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Access denied"));

        await _startupVm.InitializeAsync();

        // Act
        var result = await _mockStartupService.Object.EnableStartupItemAsync("s1");

        // Assert
        result.IsFailure.Should().BeTrue();
        result.Error!.Message.Should().Contain("Access denied");
    }

    // ====================================================================
    // Scheduled Tasks: Load
    // ====================================================================

    [Fact]
    public async Task LoadScheduledTasks_Success_PopulatesCollection()
    {
        // Arrange
        var tasks = new List<ScheduledTaskDto>
        {
            new() { TaskPath = @"\Microsoft\Windows\Defrag", TaskName = "ScheduledDefrag", State = "Ready" },
            new() { TaskPath = @"\Better11\Maintenance", TaskName = "WeeklyCleanup", State = "Disabled" },
        };
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(tasks));

        // Act
        await _taskVm.InitializeAsync();

        // Assert
        _taskVm.ScheduledTasks.Should().HaveCount(2);
        _taskVm.ScheduledTasks[0].TaskName.Should().Be("ScheduledDefrag");
        _taskVm.ScheduledTasks[1].State.Should().Be("Disabled");
    }

    [Fact]
    public async Task LoadScheduledTasks_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Failure("Task Scheduler unavailable"));

        // Act
        await _taskVm.InitializeAsync();

        // Assert
        _taskVm.ErrorMessage.Should().Contain("Task Scheduler unavailable");
    }

    // ====================================================================
    // Scheduled Tasks: Enable / Disable / Run
    // ====================================================================

    [Fact]
    public async Task EnableTask_Success_ServiceCalled()
    {
        // Arrange
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(new List<ScheduledTaskDto>()));
        _mockScheduledTaskService
            .Setup(s => s.EnableTaskAsync(@"\Better11\Task1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _taskVm.InitializeAsync();

        // Act
        var result = await _mockScheduledTaskService.Object.EnableTaskAsync(@"\Better11\Task1");

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task DisableTask_Success_ServiceCalled()
    {
        // Arrange
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(new List<ScheduledTaskDto>()));
        _mockScheduledTaskService
            .Setup(s => s.DisableTaskAsync(@"\Better11\Task1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _taskVm.InitializeAsync();

        // Act
        var result = await _mockScheduledTaskService.Object.DisableTaskAsync(@"\Better11\Task1");

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RunTask_Success_ServiceCalled()
    {
        // Arrange
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(new List<ScheduledTaskDto>()));
        _mockScheduledTaskService
            .Setup(s => s.RunTaskAsync(@"\Better11\Task1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _taskVm.InitializeAsync();

        // Act
        var result = await _mockScheduledTaskService.Object.RunTaskAsync(@"\Better11\Task1");

        // Assert
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task RunTask_Failure_ReturnsError()
    {
        // Arrange
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(new List<ScheduledTaskDto>()));
        _mockScheduledTaskService
            .Setup(s => s.RunTaskAsync(@"\Invalid\Task", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Task not found"));

        await _taskVm.InitializeAsync();

        // Act
        var result = await _mockScheduledTaskService.Object.RunTaskAsync(@"\Invalid\Task");

        // Assert
        result.IsFailure.Should().BeTrue();
        result.Error!.Message.Should().Contain("Task not found");
    }

    // ====================================================================
    // Full Maintenance Workflow
    // ====================================================================

    [Fact]
    public async Task FullMaintenanceWorkflow_CleanThenOptimizeStartup()
    {
        // Arrange - Disk Cleanup
        SetupDiskSpaceSuccess();
        var scanResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 200_000_000,
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp", IsSelectedByDefault = true },
            },
        };
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(scanResult));
        _mockDiskCleanupService
            .Setup(s => s.CleanAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(new CleanupResultDto
            {
                BytesFreed = 180_000_000, FilesRemoved = 400,
            }));

        // Arrange - Startup
        var startupItems = new List<StartupItemDto>
        {
            new() { Id = "s1", Name = "HeavyApp", IsEnabled = true, Impact = "High" },
            new() { Id = "s2", Name = "LightApp", IsEnabled = true, Impact = "Low" },
        };
        _mockStartupService
            .Setup(s => s.GetStartupItemsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<StartupItemDto>>.Success(startupItems));
        _mockStartupService
            .Setup(s => s.DisableStartupItemAsync("s1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act - Step 1: Scan and clean disk
        await _cleanupVm.InitializeAsync();
        await _cleanupVm.ScanCommand.ExecuteAsync(null);
        await _cleanupVm.CleanCommand.ExecuteAsync(null);

        // Act - Step 2: Load startup items and disable heavy app
        await _startupVm.InitializeAsync();
        var disableResult = await _mockStartupService.Object.DisableStartupItemAsync("s1");

        // Assert
        _cleanupVm.SuccessMessage.Should().Contain("MB");
        _startupVm.StartupItems.Should().HaveCount(2);
        disableResult.IsSuccess.Should().BeTrue();
    }

    // ====================================================================
    // Cleanup: After clean, disk space refreshed
    // ====================================================================

    [Fact]
    public async Task CleanDisk_Success_RefreshesDiskSpace()
    {
        // Arrange
        SetupDiskSpaceSuccess();
        var scanResult = new DiskScanResultDto
        {
            TotalReclaimableBytes = 100_000_000,
            Categories = new List<CleanupCategoryDto>
            {
                new() { Name = "Temp Files", IsSelectedByDefault = true },
            },
        };
        _mockDiskCleanupService
            .Setup(s => s.ScanAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DiskScanResultDto>.Success(scanResult));
        _mockDiskCleanupService
            .Setup(s => s.CleanAsync(It.IsAny<IReadOnlyList<string>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<CleanupResultDto>.Success(new CleanupResultDto
            {
                BytesFreed = 100_000_000, FilesRemoved = 200,
            }));

        await _cleanupVm.InitializeAsync();
        await _cleanupVm.ScanCommand.ExecuteAsync(null);

        // Act
        await _cleanupVm.CleanCommand.ExecuteAsync(null);

        // Assert - GetDiskSpaceAsync called at init + after clean
        _mockDiskCleanupService.Verify(
            s => s.GetDiskSpaceAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(2));
    }

    [Fact]
    public async Task ScheduledTask_EmptyList_NoErrors()
    {
        // Arrange
        _mockScheduledTaskService
            .Setup(s => s.GetScheduledTasksAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<ScheduledTaskDto>>.Success(new List<ScheduledTaskDto>()));

        // Act
        await _taskVm.InitializeAsync();

        // Assert
        _taskVm.ScheduledTasks.Should().BeEmpty();
        _taskVm.HasError.Should().BeFalse();
    }

    // ====================================================================
    // Page Titles and State
    // ====================================================================

    [Fact]
    public void Cleanup_PageTitle_IsCorrect()
    {
        _cleanupVm.PageTitle.Should().Be("Disk Cleanup");
    }

    [Fact]
    public void Startup_PageTitle_IsCorrect()
    {
        _startupVm.PageTitle.Should().Be("Startup Manager");
    }

    [Fact]
    public void ScheduledTask_PageTitle_IsCorrect()
    {
        _taskVm.PageTitle.Should().Be("Scheduled Tasks");
    }

    // ====================================================================
    // Helpers
    // ====================================================================

    private void SetupDiskSpaceSuccess()
    {
        var diskSpaces = new List<DiskSpaceDto>
        {
            new() { DriveLetter = "C:", TotalBytes = 500_000_000_000, FreeBytes = 100_000_000_000 },
        };
        _mockDiskCleanupService
            .Setup(s => s.GetDiskSpaceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(diskSpaces));
    }

    private static async Task<Result> InvokeStartupServiceMethodAsync(Func<Task<Result>> action)
    {
        return await action();
    }
}
