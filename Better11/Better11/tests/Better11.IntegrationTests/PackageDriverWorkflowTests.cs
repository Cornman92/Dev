// Copyright (c) Better11. All rights reserved.

using System.Linq;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.Driver;
using Better11.ViewModels.Package;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for package and driver management workflows, verifying
/// end-to-end ViewModel orchestration through IPackageService and IDriverService.
/// </summary>
public sealed class PackageDriverWorkflowTests
{
    private readonly Mock<IPackageService> _mockPackageService;
    private readonly Mock<IDriverService> _mockDriverService;
    private readonly Mock<ILogger<PackageViewModel>> _mockPkgLogger;
    private readonly Mock<ILogger<DriverViewModel>> _mockDrvLogger;
    private readonly PackageViewModel _packageVm;
    private readonly DriverViewModel _driverVm;

    public PackageDriverWorkflowTests()
    {
        _mockPackageService = new Mock<IPackageService>();
        _mockDriverService = new Mock<IDriverService>();
        _mockPkgLogger = new Mock<ILogger<PackageViewModel>>();
        _mockDrvLogger = new Mock<ILogger<DriverViewModel>>();
        _packageVm = new PackageViewModel(_mockPackageService.Object, _mockPkgLogger.Object);
        _driverVm = new DriverViewModel(_mockDriverService.Object, _mockDrvLogger.Object);
    }

    // ====================================================================
    // Package: Load Installed
    // ====================================================================

    [Fact]
    public async Task LoadInstalledPackages_Success_PopulatesCollection()
    {
        // Arrange
        var packages = new List<PackageDto>
        {
            new() { Id = "pkg1", Name = "7-Zip", Version = "23.01", Source = "winget" },
            new() { Id = "pkg2", Name = "Git", Version = "2.43.0", Source = "winget" },
        };
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(packages));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));

        // Act
        await _packageVm.InitializeAsync();

        // Assert
        _packageVm.InstalledPackages.Should().HaveCount(2);
        _packageVm.InstalledPackages[0].Name.Should().Be("7-Zip");
        _packageVm.InstalledPackages[1].Name.Should().Be("Git");
    }

    [Fact]
    public async Task LoadInstalledPackages_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure("Winget not available"));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));

        // Act
        await _packageVm.InitializeAsync();

        // Assert
        _packageVm.ErrorMessage.Should().Contain("Winget not available");
    }

    // ====================================================================
    // Package: Search
    // ====================================================================

    [Fact]
    public async Task SearchPackages_Success_PopulatesResults()
    {
        // Arrange
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        var searchResults = new List<PackageDto>
        {
            new() { Id = "vscode", Name = "Visual Studio Code", Version = "1.85.0", Source = "winget" },
        };
        _mockPackageService
            .Setup(s => s.SearchPackagesAsync("vscode", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(searchResults));

        await _packageVm.InitializeAsync();
        _packageVm.SearchQuery = "vscode";

        // Act
        await _packageVm.SearchPackagesCommand.ExecuteAsync(null);

        // Assert
        _packageVm.InstalledPackages.Should().HaveCount(1);
        _packageVm.InstalledPackages[0].Name.Should().Be("Visual Studio Code");
    }

    [Fact]
    public async Task SearchPackages_EmptyQuery_DoesNotCallService()
    {
        // Arrange
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));

        await _packageVm.InitializeAsync();
        _packageVm.SearchQuery = "";

        // Act
        await _packageVm.SearchPackagesCommand.ExecuteAsync(null);

        // Assert
        _mockPackageService.Verify(
            s => s.SearchPackagesAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    // ====================================================================
    // Package: Install / Uninstall / Update
    // ====================================================================

    [Fact]
    public async Task InstallPackage_Success_SetsSuccessMessageAndReloads()
    {
        // Arrange
        var pkg = new PackageDto { Id = "notepad++", Name = "Notepad++", Source = "winget" };
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.InstallPackageAsync("notepad++", "winget", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _packageVm.InitializeAsync();

        // Act
        await _packageVm.InstallPackageCommand.ExecuteAsync(pkg);

        // Assert
        _packageVm.SuccessMessage.Should().Contain("Notepad++");
        _mockPackageService.Verify(
            s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(2));
    }

    [Fact]
    public async Task InstallPackage_Failure_SetsErrorMessage()
    {
        // Arrange
        var pkg = new PackageDto { Id = "bad-pkg", Name = "BadPkg", Source = "winget" };
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.InstallPackageAsync("bad-pkg", "winget", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Package not found in source"));

        await _packageVm.InitializeAsync();

        // Act
        await _packageVm.InstallPackageCommand.ExecuteAsync(pkg);

        // Assert
        _packageVm.ErrorMessage.Should().Contain("Package not found");
    }

    [Fact]
    public async Task UninstallPackage_Success_SetsSuccessMessage()
    {
        // Arrange
        var pkg = new PackageDto { Id = "pkg1", Name = "TestPkg" };
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto> { pkg }));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.UninstallPackageAsync("pkg1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _packageVm.InitializeAsync();

        // Act
        await _packageVm.UninstallPackageCommand.ExecuteAsync(pkg);

        // Assert
        _packageVm.SuccessMessage.Should().Contain("TestPkg");
    }

    [Fact]
    public async Task GetAvailableUpdates_Success_PopulatesUpdatesList()
    {
        // Arrange
        var installed = new List<PackageDto> { new() { Id = "pkg1", Name = "Git", Version = "2.42" } };
        var updates = new List<PackageDto>
        {
            new() { Id = "pkg1", Name = "Git", Version = "2.42", AvailableVersion = "2.43" },
        };
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(installed));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(updates));

        // Act
        await _packageVm.InitializeAsync();

        // Assert
        _packageVm.AvailableUpdates.Should().HaveCount(1);
        _packageVm.AvailableUpdates[0].HasUpdate.Should().BeTrue();
    }

    [Fact]
    public async Task InstallPackage_NullPackage_DoesNotCallService()
    {
        // Arrange
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));

        await _packageVm.InitializeAsync();

        // Act
        await _packageVm.InstallPackageCommand.ExecuteAsync(null);

        // Assert
        _mockPackageService.Verify(
            s => s.InstallPackageAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    // ====================================================================
    // Driver: Load Installed
    // ====================================================================

    [Fact]
    public async Task LoadInstalledDrivers_Success_PopulatesCollection()
    {
        // Arrange
        var drivers = new List<DriverDto>
        {
            new() { DeviceId = "dev1", DeviceName = "NVIDIA RTX 4080", Category = "Display", DriverVersion = "545.92", HasUpdate = false },
            new() { DeviceId = "dev2", DeviceName = "Realtek Audio", Category = "Audio", DriverVersion = "6.0.9285.1", HasUpdate = true },
        };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(drivers));

        // Act
        await _driverVm.InitializeAsync();

        // Assert
        _driverVm.InstalledDrivers.Should().HaveCount(2);
        _driverVm.InstalledDrivers[0].DeviceName.Should().Be("NVIDIA RTX 4080");
    }

    [Fact]
    public async Task LoadInstalledDrivers_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Failure("PnP query failed"));

        // Act
        await _driverVm.InitializeAsync();

        // Assert
        _driverVm.ErrorMessage.Should().Contain("PnP query failed");
    }

    // ====================================================================
    // Driver: Scan for Updates
    // ====================================================================

    [Fact]
    public async Task ScanDriverUpdates_Success_PopulatesOutdatedDrivers()
    {
        // Arrange
        var installed = new List<DriverDto>
        {
            new() { DeviceId = "dev1", DeviceName = "GPU", Category = "Display" },
        };
        var outdated = new List<DriverDto>
        {
            new() { DeviceId = "dev1", DeviceName = "GPU", HasUpdate = true },
        };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(installed));
        _mockDriverService
            .Setup(s => s.ScanForUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(outdated));

        await _driverVm.InitializeAsync();

        // Act
        await _driverVm.ScanForUpdatesCommand.ExecuteAsync(null);

        // Assert
        _driverVm.OutdatedDrivers.Should().HaveCount(1);
        _driverVm.SuccessMessage.Should().Contain("1 driver(s)");
    }

    [Fact]
    public async Task ScanDriverUpdates_NoUpdates_ShowsUpToDateMessage()
    {
        // Arrange
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto>()));
        _mockDriverService
            .Setup(s => s.ScanForUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto>()));

        await _driverVm.InitializeAsync();

        // Act
        await _driverVm.ScanForUpdatesCommand.ExecuteAsync(null);

        // Assert
        _driverVm.SuccessMessage.Should().Contain("up to date");
    }

    // ====================================================================
    // Driver: Update / Backup / Rollback
    // ====================================================================

    [Fact]
    public async Task UpdateDriver_Success_SetsSuccessAndReloads()
    {
        // Arrange
        var driver = new DriverDto { DeviceId = "dev1", DeviceName = "GPU Driver" };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto> { driver }));
        _mockDriverService
            .Setup(s => s.UpdateDriverAsync("dev1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _driverVm.InitializeAsync();
        _driverVm.SelectedDriver = driver;

        // Act
        await _driverVm.UpdateSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _driverVm.SuccessMessage.Should().Contain("GPU Driver");
        _mockDriverService.Verify(
            s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()),
            Times.AtLeast(2));
    }

    [Fact]
    public async Task UpdateDriver_Failure_SetsErrorMessage()
    {
        // Arrange
        var driver = new DriverDto { DeviceId = "dev1", DeviceName = "GPU Driver" };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto> { driver }));
        _mockDriverService
            .Setup(s => s.UpdateDriverAsync("dev1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("Driver package corrupted"));

        await _driverVm.InitializeAsync();
        _driverVm.SelectedDriver = driver;

        // Act
        await _driverVm.UpdateSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _driverVm.ErrorMessage.Should().Contain("Driver package corrupted");
    }

    [Fact]
    public async Task UpdateDriver_NoSelection_DoesNotCallService()
    {
        // Arrange
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto>()));

        await _driverVm.InitializeAsync();
        _driverVm.SelectedDriver = null;

        // Act
        await _driverVm.UpdateSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _mockDriverService.Verify(
            s => s.UpdateDriverAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task BackupDriver_ReturnsPath_SetsSuccessMessage()
    {
        // Arrange
        var driver = new DriverDto { DeviceId = "dev1", DeviceName = "Audio Driver" };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto> { driver }));
        _mockDriverService
            .Setup(s => s.BackupDriverAsync("dev1", It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<string>.Success(@"C:\Backups\dev1_backup.zip"));

        await _driverVm.InitializeAsync();
        _driverVm.SelectedDriver = driver;

        // Act
        await _driverVm.BackupSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _driverVm.SuccessMessage.Should().Contain("Audio Driver");
        _driverVm.SuccessMessage.Should().Contain("backup");
    }

    [Fact]
    public async Task RollbackDriver_Success_SetsSuccessAndReloads()
    {
        // Arrange
        var driver = new DriverDto { DeviceId = "dev1", DeviceName = "GPU Driver" };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto> { driver }));
        _mockDriverService
            .Setup(s => s.RollbackDriverAsync("dev1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        await _driverVm.InitializeAsync();
        _driverVm.SelectedDriver = driver;

        // Act
        await _driverVm.RollbackSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _driverVm.SuccessMessage.Should().Contain("Rolled back");
        _driverVm.SuccessMessage.Should().Contain("GPU Driver");
    }

    [Fact]
    public async Task RollbackDriver_Failure_SetsErrorMessage()
    {
        // Arrange
        var driver = new DriverDto { DeviceId = "dev1", DeviceName = "GPU Driver" };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto> { driver }));
        _mockDriverService
            .Setup(s => s.RollbackDriverAsync("dev1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Failure("No previous version available"));

        await _driverVm.InitializeAsync();
        _driverVm.SelectedDriver = driver;

        // Act
        await _driverVm.RollbackSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _driverVm.ErrorMessage.Should().Contain("No previous version");
    }

    // ====================================================================
    // Combined Workflow
    // ====================================================================

    [Fact]
    public async Task CombinedWorkflow_PackageThenDriverUpdate_BothSucceed()
    {
        // Arrange - Package
        var pkg = new PackageDto { Id = "git", Name = "Git", Version = "2.42", Source = "winget" };
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto> { pkg }));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.UpdatePackageAsync("git", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Arrange - Driver
        var driver = new DriverDto { DeviceId = "dev1", DeviceName = "Net Adapter" };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto> { driver }));
        _mockDriverService
            .Setup(s => s.UpdateDriverAsync("dev1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Success());

        // Act - Initialize both
        await _packageVm.InitializeAsync();
        await _driverVm.InitializeAsync();

        // Act - Update driver
        _driverVm.SelectedDriver = driver;
        await _driverVm.UpdateSelectedDriverCommand.ExecuteAsync(null);

        // Assert
        _packageVm.InstalledPackages.Should().HaveCount(1);
        _driverVm.SuccessMessage.Should().Contain("Net Adapter");
    }

    // ====================================================================
    // Page Titles and State
    // ====================================================================

    [Fact]
    public void Package_PageTitle_IsCorrect()
    {
        _packageVm.PageTitle.Should().Be("Package Manager");
    }

    [Fact]
    public void Driver_PageTitle_IsCorrect()
    {
        _driverVm.PageTitle.Should().Be("Driver Manager");
    }

    [Fact]
    public async Task SearchPackages_Failure_SetsErrorMessage()
    {
        // Arrange
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.SearchPackagesAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure("Search service unavailable"));

        await _packageVm.InitializeAsync();
        _packageVm.SearchQuery = "test";

        // Act
        await _packageVm.SearchPackagesCommand.ExecuteAsync(null);

        // Assert
        _packageVm.ErrorMessage.Should().Contain("Search service unavailable");
    }

    [Fact]
    public async Task Driver_Categories_PopulatedFromInstalledDrivers()
    {
        // Arrange
        var drivers = new List<DriverDto>
        {
            new() { DeviceId = "d1", DeviceName = "GPU", Category = "Display" },
            new() { DeviceId = "d2", DeviceName = "NIC", Category = "Network" },
            new() { DeviceId = "d3", DeviceName = "Audio", Category = "Audio" },
            new() { DeviceId = "d4", DeviceName = "GPU2", Category = "Display" },
        };
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(drivers));

        // Act
        await _driverVm.InitializeAsync();

        // Assert
        _driverVm.Categories.Should().HaveCount(3);
        _driverVm.Categories.Should().Contain("Audio");
        _driverVm.Categories.Should().Contain("Display");
        _driverVm.Categories.Should().Contain("Network");
    }
}
