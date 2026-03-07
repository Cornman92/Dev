// Copyright (c) Better11. All rights reserved.

using System.Linq;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.ViewModels.DiskCleanup;
using Better11.ViewModels.Driver;
using Better11.ViewModels.Network;
using Better11.ViewModels.Optimization;
using Better11.ViewModels.Package;
using Better11.ViewModels.Privacy;
using Better11.ViewModels.Security;
using Better11.ViewModels.SystemInfo;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for full system scan workflows, verifying that all service
/// ViewModels can be orchestrated together for a comprehensive system assessment.
/// </summary>
public sealed class FullSystemScanWorkflowTests
{
    private readonly Mock<ISystemInfoService> _mockSystemInfoService;
    private readonly Mock<IPrivacyService> _mockPrivacyService;
    private readonly Mock<ISecurityService> _mockSecurityService;
    private readonly Mock<IOptimizationService> _mockOptimizationService;
    private readonly Mock<INetworkService> _mockNetworkService;
    private readonly Mock<IDriverService> _mockDriverService;
    private readonly Mock<IPackageService> _mockPackageService;
    private readonly Mock<IDiskCleanupService> _mockDiskCleanupService;

    private readonly SystemInfoViewModel _sysInfoVm;
    private readonly PrivacyViewModel _privacyVm;
    private readonly SecurityViewModel _securityVm;
    private readonly OptimizationViewModel _optimizationVm;
    private readonly NetworkViewModel _networkVm;
    private readonly DriverViewModel _driverVm;
    private readonly PackageViewModel _packageVm;

    public FullSystemScanWorkflowTests()
    {
        _mockSystemInfoService = new Mock<ISystemInfoService>();
        _mockPrivacyService = new Mock<IPrivacyService>();
        _mockSecurityService = new Mock<ISecurityService>();
        _mockOptimizationService = new Mock<IOptimizationService>();
        _mockNetworkService = new Mock<INetworkService>();
        _mockDriverService = new Mock<IDriverService>();
        _mockPackageService = new Mock<IPackageService>();
        _mockDiskCleanupService = new Mock<IDiskCleanupService>();

        _sysInfoVm = new SystemInfoViewModel(
            _mockSystemInfoService.Object,
            new Mock<ILogger<SystemInfoViewModel>>().Object);
        _privacyVm = new PrivacyViewModel(
            _mockPrivacyService.Object,
            new Mock<ILogger<PrivacyViewModel>>().Object);
        _securityVm = new SecurityViewModel(
            _mockSecurityService.Object,
            new Mock<ILogger<SecurityViewModel>>().Object);
        _optimizationVm = new OptimizationViewModel(
            _mockOptimizationService.Object,
            new Mock<ILogger<OptimizationViewModel>>().Object);
        _networkVm = new NetworkViewModel(
            _mockNetworkService.Object,
            new Mock<ILogger<NetworkViewModel>>().Object);
        _driverVm = new DriverViewModel(
            _mockDriverService.Object,
            new Mock<ILogger<DriverViewModel>>().Object);
        _packageVm = new PackageViewModel(
            _mockPackageService.Object,
            new Mock<ILogger<PackageViewModel>>().Object);
    }

    // ====================================================================
    // Full Scan: All Services
    // ====================================================================

    [Fact]
    public async Task FullScan_LoadsAllServices_AllInitialized()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert
        _sysInfoVm.IsInitialized.Should().BeTrue();
        _privacyVm.IsInitialized.Should().BeTrue();
        _securityVm.IsInitialized.Should().BeTrue();
        _optimizationVm.IsInitialized.Should().BeTrue();
        _networkVm.IsInitialized.Should().BeTrue();
        _driverVm.IsInitialized.Should().BeTrue();
        _packageVm.IsInitialized.Should().BeTrue();
    }

    [Fact]
    public async Task FullScan_SystemInfo_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _sysInfoVm.InitializeAsync();

        // Assert
        _sysInfoVm.SystemInfo.Should().NotBeNull();
        _sysInfoVm.SystemInfo!.ComputerName.Should().Be("SCAN-PC");
        _sysInfoVm.SystemInfo.OsName.Should().Be("Windows 11 Pro");
    }

    [Fact]
    public async Task FullScan_Privacy_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _privacyVm.InitializeAsync();

        // Assert
        _privacyVm.PrivacyScore.Should().Be(65);
        _privacyVm.Settings.Should().HaveCount(2);
    }

    [Fact]
    public async Task FullScan_Security_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _securityVm.InitializeAsync();

        // Assert
        _securityVm.SecurityStatus.Should().NotBeNull();
        _securityVm.SecurityScore.Should().Be(75);
        _securityVm.SecurityStatus!.FirewallStatus.Should().Be("Enabled");
    }

    [Fact]
    public async Task FullScan_Optimization_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _optimizationVm.InitializeAsync();

        // Assert
        _optimizationVm.Categories.Should().HaveCount(1);
        _optimizationVm.Categories[0].Tweaks.Should().HaveCount(2);
    }

    [Fact]
    public async Task FullScan_Network_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _networkVm.InitializeAsync();

        // Assert
        _networkVm.Adapters.Should().HaveCount(2);
        _networkVm.Adapters[0].Name.Should().Be("Ethernet");
    }

    [Fact]
    public async Task FullScan_Drivers_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _driverVm.InitializeAsync();

        // Assert
        _driverVm.InstalledDrivers.Should().HaveCount(2);
    }

    [Fact]
    public async Task FullScan_Packages_PopulatedCorrectly()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _packageVm.InitializeAsync();

        // Assert
        _packageVm.InstalledPackages.Should().HaveCount(2);
        _packageVm.InstalledPackages[0].Name.Should().Be("Git");
    }

    // ====================================================================
    // Full Scan: Cancellation
    // ====================================================================

    [Fact]
    public async Task FullScan_CancelMidway_PartialResultsAvailable()
    {
        // Arrange
        var cts = new CancellationTokenSource();

        // SystemInfo succeeds immediately
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(new SystemInfoDto { ComputerName = "SCAN-PC" }));

        // Privacy cancels
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .Returns(async (CancellationToken ct) =>
            {
                cts.Cancel();
                ct.ThrowIfCancellationRequested();
                return Result<PrivacyAuditDto>.Success(new PrivacyAuditDto());
            });

        // Act
        await _sysInfoVm.InitializeAsync();
        await _privacyVm.InitializeAsync(cts.Token);

        // Assert - SystemInfo loaded, Privacy was cancelled gracefully
        _sysInfoVm.SystemInfo.Should().NotBeNull();
        _privacyVm.IsBusy.Should().BeFalse();
    }

    // ====================================================================
    // Full Scan: Partial Failures
    // ====================================================================

    [Fact]
    public async Task FullScan_OneServiceFails_OthersContinue()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Override security to fail
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Failure("Security service unavailable"));

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert
        _sysInfoVm.SystemInfo.Should().NotBeNull();
        _privacyVm.PrivacyScore.Should().Be(65);
        _securityVm.ErrorMessage.Should().Contain("Security service unavailable");
        _optimizationVm.Categories.Should().HaveCount(1);
        _networkVm.Adapters.Should().HaveCount(2);
        _driverVm.InstalledDrivers.Should().HaveCount(2);
        _packageVm.InstalledPackages.Should().HaveCount(2);
    }

    [Fact]
    public async Task FullScan_AllFail_ReportsAllErrors()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Failure("SysInfo failed"));
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Failure("Privacy failed"));
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Failure("Security failed"));
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Failure("Optimization failed"));
        _mockNetworkService
            .Setup(s => s.GetAdaptersAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Failure("Network failed"));
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Failure("Driver failed"));
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure("Package failed"));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Failure("Updates failed"));

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert - Each ViewModel reports its own error
        _sysInfoVm.ErrorMessage.Should().Contain("SysInfo failed");
        _privacyVm.ErrorMessage.Should().Contain("Privacy failed");
        _securityVm.ErrorMessage.Should().Contain("Security failed");
        _optimizationVm.ErrorMessage.Should().Contain("Optimization failed");
        _networkVm.ErrorMessage.Should().Contain("Network failed");
        _driverVm.ErrorMessage.Should().Contain("Driver failed");
        _packageVm.ErrorMessage.Should().Contain("Package failed");
    }

    // ====================================================================
    // Full Scan: Summary Report
    // ====================================================================

    [Fact]
    public async Task FullScan_GeneratesSummaryReport_AllDataAvailable()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert - All data available for summary report generation
        var report = new Dictionary<string, object?>
        {
            ["SystemInfo"] = _sysInfoVm.SystemInfo,
            ["PrivacyScore"] = _privacyVm.PrivacyScore,
            ["SecurityScore"] = _securityVm.SecurityScore,
            ["OptimizationCategories"] = _optimizationVm.Categories.Count,
            ["NetworkAdapters"] = _networkVm.Adapters.Count,
            ["InstalledDrivers"] = _driverVm.InstalledDrivers.Count,
            ["InstalledPackages"] = _packageVm.InstalledPackages.Count,
        };

        report["SystemInfo"].Should().NotBeNull();
        ((int)report["PrivacyScore"]!).Should().Be(65);
        ((int)report["SecurityScore"]!).Should().Be(75);
        ((int)report["OptimizationCategories"]!).Should().BeGreaterThan(0);
        ((int)report["NetworkAdapters"]!).Should().BeGreaterThan(0);
        ((int)report["InstalledDrivers"]!).Should().BeGreaterThan(0);
        ((int)report["InstalledPackages"]!).Should().BeGreaterThan(0);
    }

    // ====================================================================
    // Full Scan: IsBusy State
    // ====================================================================

    [Fact]
    public async Task FullScan_AllViewModels_NotBusyAfterCompletion()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert
        _sysInfoVm.IsBusy.Should().BeFalse();
        _privacyVm.IsBusy.Should().BeFalse();
        _securityVm.IsBusy.Should().BeFalse();
        _optimizationVm.IsBusy.Should().BeFalse();
        _networkVm.IsBusy.Should().BeFalse();
        _driverVm.IsBusy.Should().BeFalse();
        _packageVm.IsBusy.Should().BeFalse();
    }

    [Fact]
    public async Task FullScan_AllViewModels_NoErrorsOnSuccess()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert
        _sysInfoVm.HasError.Should().BeFalse();
        _privacyVm.HasError.Should().BeFalse();
        _securityVm.HasError.Should().BeFalse();
        _optimizationVm.HasError.Should().BeFalse();
        _networkVm.HasError.Should().BeFalse();
        _driverVm.HasError.Should().BeFalse();
        _packageVm.HasError.Should().BeFalse();
    }

    // ====================================================================
    // Full Scan: Multiple service exceptions
    // ====================================================================

    [Fact]
    public async Task FullScan_ServicesThrowExceptions_HandledGracefully()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("WMI crash"));
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ThrowsAsync(new TimeoutException("Registry timeout"));
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(new SecurityStatusDto { Score = 80 }));
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));
        _mockNetworkService
            .Setup(s => s.GetAdaptersAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Success(
                new List<NetworkAdapterDto>()));
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto>()));
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert - exceptions caught, error messages set
        _sysInfoVm.ErrorMessage.Should().Contain("WMI crash");
        _privacyVm.ErrorMessage.Should().Contain("Registry timeout");
        _securityVm.SecurityScore.Should().Be(80);
        _sysInfoVm.IsBusy.Should().BeFalse();
        _privacyVm.IsBusy.Should().BeFalse();
    }

    [Fact]
    public async Task FullScan_MultipleServiceFailures_ErrorCountMatchesFailures()
    {
        // Arrange
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Failure("Error 1"));
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Failure("Error 2"));
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Failure("Error 3"));
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>()));
        _mockNetworkService
            .Setup(s => s.GetAdaptersAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Success(
                new List<NetworkAdapterDto>()));
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(new List<DriverDto>()));
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            _privacyVm.InitializeAsync(),
            _securityVm.InitializeAsync(),
            _optimizationVm.InitializeAsync(),
            _networkVm.InitializeAsync(),
            _driverVm.InitializeAsync(),
            _packageVm.InitializeAsync());

        // Assert
        var errorViewModels = new[]
        {
            _sysInfoVm.HasError,
            _privacyVm.HasError,
            _securityVm.HasError,
            _optimizationVm.HasError,
            _networkVm.HasError,
            _driverVm.HasError,
            _packageVm.HasError,
        };
        errorViewModels.Count(e => e).Should().Be(3);
    }

    [Fact]
    public async Task FullScan_DiskCleanup_CanRunAlongsideOtherScans()
    {
        // Arrange
        SetupAllServicesSuccess();
        _mockDiskCleanupService
            .Setup(s => s.GetDiskSpaceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DiskSpaceDto>>.Success(
                new List<DiskSpaceDto>
                {
                    new() { DriveLetter = "C:", TotalBytes = 500_000_000_000, FreeBytes = 100_000_000_000 },
                }));

        var diskVm = new DiskCleanupViewModel(
            _mockDiskCleanupService.Object,
            new Mock<ILogger<DiskCleanupViewModel>>().Object);

        // Act
        await Task.WhenAll(
            _sysInfoVm.InitializeAsync(),
            diskVm.InitializeAsync());

        // Assert
        _sysInfoVm.SystemInfo.Should().NotBeNull();
        diskVm.DiskSpaces.Should().HaveCount(1);
    }

    [Fact]
    public async Task FullScan_InitializeTwice_Idempotent()
    {
        // Arrange
        SetupAllServicesSuccess();

        // Act
        await _sysInfoVm.InitializeAsync();
        await _sysInfoVm.InitializeAsync();

        // Assert - only called once due to IsInitialized guard
        _mockSystemInfoService.Verify(
            s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }

    // ====================================================================
    // Helpers
    // ====================================================================

    private void SetupAllServicesSuccess()
    {
        // SystemInfo
        _mockSystemInfoService
            .Setup(s => s.GetSystemInfoAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SystemInfoDto>.Success(new SystemInfoDto
            {
                ComputerName = "SCAN-PC",
                OsName = "Windows 11 Pro",
                OsVersion = "23H2",
                OsBuild = "22631.3007",
                CpuName = "Intel Core i9-13900K",
                CpuCores = 24,
                TotalRamGb = 32.0,
                GpuName = "RTX 4090",
                Uptime = TimeSpan.FromHours(12),
                ActivationStatus = "Activated",
                BiosVersion = "1.0",
                Motherboard = "ASUS Z790",
            }));

        // Privacy
        _mockPrivacyService
            .Setup(s => s.GetPrivacyAuditAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<PrivacyAuditDto>.Success(new PrivacyAuditDto
            {
                Score = 65,
                CurrentProfile = "Balanced",
                Settings = new List<PrivacySettingDto>
                {
                    new() { Id = "ps1", Name = "Telemetry", IsEnabled = true },
                    new() { Id = "ps2", Name = "Location", IsEnabled = false },
                },
            }));

        // Security
        _mockSecurityService
            .Setup(s => s.GetSecurityStatusAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<SecurityStatusDto>.Success(new SecurityStatusDto
            {
                Score = 75,
                FirewallStatus = "Enabled",
                AntivirusStatus = "Up to date",
                UpdateStatus = "Current",
                UacLevel = "Default",
                BitLockerStatus = "Off",
            }));

        // Optimization
        _mockOptimizationService
            .Setup(s => s.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<OptimizationCategoryDto>>.Success(
                new List<OptimizationCategoryDto>
                {
                    new()
                    {
                        Name = "Performance",
                        Tweaks = new List<TweakDto>
                        {
                            new() { Id = "t1", Name = "Tweak1", IsApplied = false },
                            new() { Id = "t2", Name = "Tweak2", IsApplied = true },
                        },
                    },
                }));

        // Network
        _mockNetworkService
            .Setup(s => s.GetAdaptersAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<NetworkAdapterDto>>.Success(
                new List<NetworkAdapterDto>
                {
                    new() { Id = "eth0", Name = "Ethernet", Status = "Up", IpAddress = "192.168.1.100", SpeedMbps = 1000 },
                    new() { Id = "wlan0", Name = "Wi-Fi", Status = "Down", IpAddress = "", SpeedMbps = 0 },
                }));

        // Drivers
        _mockDriverService
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<DriverDto>>.Success(
                new List<DriverDto>
                {
                    new() { DeviceId = "dev1", DeviceName = "GPU", Category = "Display", DriverVersion = "545.92" },
                    new() { DeviceId = "dev2", DeviceName = "Audio", Category = "Audio", DriverVersion = "6.0" },
                }));

        // Packages
        _mockPackageService
            .Setup(s => s.GetInstalledPackagesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(
                new List<PackageDto>
                {
                    new() { Id = "git", Name = "Git", Version = "2.43.0", Source = "winget" },
                    new() { Id = "vscode", Name = "VS Code", Version = "1.85.0", Source = "winget" },
                }));
        _mockPackageService
            .Setup(s => s.GetAvailableUpdatesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<IReadOnlyList<PackageDto>>.Success(new List<PackageDto>()));
    }
}
