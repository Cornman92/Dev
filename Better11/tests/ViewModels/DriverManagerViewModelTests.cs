// <copyright file="DriverManagerViewModelTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.ViewModels;

using Better11.Modules.BetterPE.Models;
using Better11.Modules.BetterPE.Services.Interfaces;
using Better11.Modules.BetterPE.ViewModels;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

/// <summary>
/// Unit tests for <see cref="DriverManagerViewModel"/>.
/// </summary>
public sealed class DriverManagerViewModelTests
{
    private readonly Mock<IDriverIntegrationService> driverServiceMock;
    private readonly Mock<ILogger<DriverManagerViewModel>> loggerMock;
    private readonly DriverManagerViewModel sut;

    /// <summary>
    /// Initializes a new instance of the <see cref="DriverManagerViewModelTests"/> class.
    /// </summary>
    public DriverManagerViewModelTests()
    {
        this.driverServiceMock = new Mock<IDriverIntegrationService>();
        this.loggerMock = new Mock<ILogger<DriverManagerViewModel>>();
        this.sut = new DriverManagerViewModel(this.driverServiceMock.Object, this.loggerMock.Object);
    }

    /// <summary>Verifies default initialization state.</summary>
    [Fact]
    public void Constructor_ShouldInitializeWithDefaults()
    {
        this.sut.StatusMessage.Should().Be("Ready");
        this.sut.ScanPath.Should().BeEmpty();
        this.sut.TargetImagePath.Should().BeEmpty();
        this.sut.IsScanning.Should().BeFalse();
        this.sut.IsInjecting.Should().BeFalse();
        this.sut.IsVerifying.Should().BeFalse();
        this.sut.Recurse.Should().BeTrue();
        this.sut.ForceUnsigned.Should().BeFalse();
        this.sut.VerifyAfterInject.Should().BeTrue();
        this.sut.ArchitectureFilter.Should().Be(ImageArchitecture.Amd64);
        this.sut.DriversFound.Should().Be(0);
        this.sut.DriversInjected.Should().Be(0);
        this.sut.CompatibilityIssueCount.Should().Be(0);
    }

    /// <summary>Verifies constructor throws on null driver service.</summary>
    [Fact]
    public void Constructor_NullDriverService_ThrowsArgumentNullException()
    {
        var act = () => new DriverManagerViewModel(null!, this.loggerMock.Object);
        act.Should().Throw<ArgumentNullException>().WithParameterName("driverService");
    }

    /// <summary>Verifies constructor throws on null logger.</summary>
    [Fact]
    public void Constructor_NullLogger_ThrowsArgumentNullException()
    {
        var act = () => new DriverManagerViewModel(this.driverServiceMock.Object, null!);
        act.Should().Throw<ArgumentNullException>().WithParameterName("logger");
    }

    /// <summary>Verifies collections are initialized empty.</summary>
    [Fact]
    public void Collections_ShouldBeEmptyInitially()
    {
        this.sut.DiscoveredDrivers.Should().BeEmpty();
        this.sut.InstalledDrivers.Should().BeEmpty();
        this.sut.SelectedDriversForInjection.Should().BeEmpty();
        this.sut.CompatibilityIssues.Should().BeEmpty();
    }

    /// <summary>Verifies successful driver scan populates DiscoveredDrivers.</summary>
    [Fact]
    public async Task ScanDriversAsync_Success_PopulatesDiscoveredDrivers()
    {
        this.sut.ScanPath = @"C:\Drivers";
        this.sut.ArchitectureFilter = ImageArchitecture.Amd64;

        var scanResult = new DriverScanResult
        {
            SourcePath = @"C:\Drivers",
        };
        scanResult.Drivers.Add(new DriverPackage { Name = "NetDriver", Architecture = ImageArchitecture.Amd64, InfPath = @"C:\Drivers\net.inf" });
        scanResult.Drivers.Add(new DriverPackage { Name = "DisplayDriver", Architecture = ImageArchitecture.Amd64, InfPath = @"C:\Drivers\display.inf" });

        this.driverServiceMock
            .Setup(s => s.ScanDriversAsync(It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverScanResult>.Ok(scanResult));

        await this.sut.ScanDriversCommand.ExecuteAsync(null);

        this.sut.DiscoveredDrivers.Should().HaveCount(2);
        this.sut.DriversFound.Should().Be(2);
        this.sut.StatusMessage.Should().Contain("2");
        this.sut.IsScanning.Should().BeFalse();
    }

    /// <summary>Verifies scan filters by architecture.</summary>
    [Fact]
    public async Task ScanDriversAsync_FiltersArchitecture()
    {
        this.sut.ScanPath = @"C:\Drivers";
        this.sut.ArchitectureFilter = ImageArchitecture.Amd64;

        var scanResult = new DriverScanResult();
        scanResult.Drivers.Add(new DriverPackage { Name = "Amd64Driver", Architecture = ImageArchitecture.Amd64 });
        scanResult.Drivers.Add(new DriverPackage { Name = "Arm64Driver", Architecture = ImageArchitecture.Arm64 });

        this.driverServiceMock
            .Setup(s => s.ScanDriversAsync(It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverScanResult>.Ok(scanResult));

        await this.sut.ScanDriversCommand.ExecuteAsync(null);

        this.sut.DiscoveredDrivers.Should().HaveCount(1);
        this.sut.DiscoveredDrivers[0].Name.Should().Be("Amd64Driver");
    }

    /// <summary>Verifies scan failure sets error status.</summary>
    [Fact]
    public async Task ScanDriversAsync_Failure_SetsErrorStatus()
    {
        this.sut.ScanPath = @"C:\Drivers";
        this.driverServiceMock
            .Setup(s => s.ScanDriversAsync(It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverScanResult>.Fail("Access denied"));

        await this.sut.ScanDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("failed");
        this.sut.IsScanning.Should().BeFalse();
    }

    /// <summary>Verifies scan exception is handled gracefully.</summary>
    [Fact]
    public async Task ScanDriversAsync_Exception_SetsErrorStatus()
    {
        this.sut.ScanPath = @"C:\Drivers";
        this.driverServiceMock
            .Setup(s => s.ScanDriversAsync(It.IsAny<string>(), It.IsAny<bool>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Service crashed"));

        await this.sut.ScanDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("error");
        this.sut.IsScanning.Should().BeFalse();
    }

    /// <summary>Verifies successful driver injection updates status.</summary>
    [Fact]
    public async Task InjectDriversAsync_Success_UpdatesStatusAndCount()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.VerifyAfterInject = false;

        var driver = new DriverPackage { Name = "TestDriver", InfPath = @"C:\drv\test.inf" };
        this.sut.SelectedDriversForInjection.Add(driver);

        var injectionResult = new DriverInjectionResult { Success = true };
        injectionResult.InjectedDrivers.Add(driver);

        this.driverServiceMock
            .Setup(s => s.InjectDriversAsync(It.IsAny<DriverInjectionRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverInjectionResult>.Ok(injectionResult));

        await this.sut.InjectDriversCommand.ExecuteAsync(null);

        this.sut.DriversInjected.Should().Be(1);
        this.sut.StatusMessage.Should().Contain("1/1");
        this.sut.IsInjecting.Should().BeFalse();
    }

    /// <summary>Verifies injection reports failed drivers.</summary>
    [Fact]
    public async Task InjectDriversAsync_PartialFailure_ReportsFailedCount()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.VerifyAfterInject = false;

        var driver1 = new DriverPackage { Name = "Good", InfPath = @"C:\drv\good.inf" };
        var driver2 = new DriverPackage { Name = "Bad", InfPath = @"C:\drv\bad.inf" };
        this.sut.SelectedDriversForInjection.Add(driver1);
        this.sut.SelectedDriversForInjection.Add(driver2);

        var injectionResult = new DriverInjectionResult { Success = true };
        injectionResult.InjectedDrivers.Add(driver1);
        injectionResult.FailedDrivers.Add(driver2);

        this.driverServiceMock
            .Setup(s => s.InjectDriversAsync(It.IsAny<DriverInjectionRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverInjectionResult>.Ok(injectionResult));

        await this.sut.InjectDriversCommand.ExecuteAsync(null);

        this.sut.DriversInjected.Should().Be(1);
        this.sut.StatusMessage.Should().Contain("1 failed");
    }

    /// <summary>Verifies empty selection does not attempt injection.</summary>
    [Fact]
    public async Task InjectDriversAsync_NoSelection_SetsStatusMessage()
    {
        this.sut.TargetImagePath = @"C:\mount";

        await this.sut.InjectDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("No drivers selected");
    }

    /// <summary>Verifies injection failure sets error status.</summary>
    [Fact]
    public async Task InjectDriversAsync_Failure_SetsErrorStatus()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.VerifyAfterInject = false;
        this.sut.SelectedDriversForInjection.Add(new DriverPackage { InfPath = @"C:\drv\test.inf" });

        this.driverServiceMock
            .Setup(s => s.InjectDriversAsync(It.IsAny<DriverInjectionRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverInjectionResult>.Fail("DISM error"));

        await this.sut.InjectDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("failed");
    }

    /// <summary>Verifies ForceUnsigned is passed in injection request.</summary>
    [Fact]
    public async Task InjectDriversAsync_ForceUnsigned_SetsRequestFlag()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.ForceUnsigned = true;
        this.sut.VerifyAfterInject = false;
        this.sut.SelectedDriversForInjection.Add(new DriverPackage { InfPath = @"C:\drv\test.inf" });

        var injectionResult = new DriverInjectionResult { Success = true };
        this.driverServiceMock
            .Setup(s => s.InjectDriversAsync(It.Is<DriverInjectionRequest>(r => r.ForceUnsigned), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<DriverInjectionResult>.Ok(injectionResult));

        await this.sut.InjectDriversCommand.ExecuteAsync(null);

        this.driverServiceMock.Verify(
            s => s.InjectDriversAsync(It.Is<DriverInjectionRequest>(r => r.ForceUnsigned), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    /// <summary>Verifies compatibility check reports compatible drivers.</summary>
    [Fact]
    public async Task VerifyCompatibilityAsync_AllCompatible_SetsSuccessStatus()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.DiscoveredDrivers.Add(new DriverPackage { Name = "Driver1", InfPath = @"C:\d\a.inf" });

        this.driverServiceMock
            .Setup(s => s.VerifyCompatibilityAsync(It.IsAny<string>(), It.IsAny<ImageArchitecture>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));

        await this.sut.VerifyCompatibilityCommand.ExecuteAsync(null);

        this.sut.CompatibilityIssueCount.Should().Be(0);
        this.sut.StatusMessage.Should().Contain("compatible");
    }

    /// <summary>Verifies compatibility check reports incompatible drivers.</summary>
    [Fact]
    public async Task VerifyCompatibilityAsync_Incompatible_AddsIssues()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.DiscoveredDrivers.Add(new DriverPackage { Name = "BadDriver", InfPath = @"C:\d\bad.inf" });

        this.driverServiceMock
            .Setup(s => s.VerifyCompatibilityAsync(It.IsAny<string>(), It.IsAny<ImageArchitecture>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(false));

        await this.sut.VerifyCompatibilityCommand.ExecuteAsync(null);

        this.sut.CompatibilityIssueCount.Should().Be(1);
        this.sut.CompatibilityIssues[0].Severity.Should().Be(IssueSeverity.Warning);
        this.sut.StatusMessage.Should().Contain("issue");
    }

    /// <summary>Verifies verification errors produce error issues.</summary>
    [Fact]
    public async Task VerifyCompatibilityAsync_ServiceFailure_AddsErrorIssue()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.DiscoveredDrivers.Add(new DriverPackage { Name = "ErrorDriver", InfPath = @"C:\d\err.inf" });

        this.driverServiceMock
            .Setup(s => s.VerifyCompatibilityAsync(It.IsAny<string>(), It.IsAny<ImageArchitecture>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Fail("INF parse error"));

        await this.sut.VerifyCompatibilityCommand.ExecuteAsync(null);

        this.sut.CompatibilityIssueCount.Should().Be(1);
        this.sut.CompatibilityIssues[0].Severity.Should().Be(IssueSeverity.Error);
    }

    /// <summary>Verifies driver removal on success.</summary>
    [Fact]
    public async Task RemoveDriverAsync_Success_RemovesFromList()
    {
        this.sut.TargetImagePath = @"C:\mount";
        var driver = new DriverPackage { FriendlyName = "OldDriver", PublishedName = "oem5.inf" };
        this.sut.InstalledDrivers.Add(driver);
        this.sut.SelectedDriver = driver;

        this.driverServiceMock
            .Setup(s => s.RemoveDriverAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Ok(true));

        await this.sut.RemoveDriverCommand.ExecuteAsync(null);

        this.sut.InstalledDrivers.Should().BeEmpty();
        this.sut.SelectedDriver.Should().BeNull();
        this.sut.StatusMessage.Should().Contain("Removed");
    }

    /// <summary>Verifies driver removal failure.</summary>
    [Fact]
    public async Task RemoveDriverAsync_Failure_SetsErrorStatus()
    {
        this.sut.TargetImagePath = @"C:\mount";
        var driver = new DriverPackage { FriendlyName = "LockedDriver", PublishedName = "oem3.inf" };
        this.sut.InstalledDrivers.Add(driver);
        this.sut.SelectedDriver = driver;

        this.driverServiceMock
            .Setup(s => s.RemoveDriverAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<bool>.Fail("Driver in use"));

        await this.sut.RemoveDriverCommand.ExecuteAsync(null);

        this.sut.InstalledDrivers.Should().HaveCount(1);
        this.sut.StatusMessage.Should().Contain("failed");
    }

    /// <summary>Verifies remove with no selection does nothing.</summary>
    [Fact]
    public async Task RemoveDriverAsync_NoSelection_DoesNothing()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.SelectedDriver = null;

        await this.sut.RemoveDriverCommand.ExecuteAsync(null);

        this.driverServiceMock.Verify(
            s => s.RemoveDriverAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    /// <summary>Verifies system driver export updates status.</summary>
    [Fact]
    public async Task ExportSystemDriversAsync_Success_UpdatesStatus()
    {
        this.sut.ScanPath = @"C:\Output";

        var exportedDrivers = new List<DriverPackage>
        {
            new() { Name = "Exported1" },
            new() { Name = "Exported2" },
        };

        this.driverServiceMock
            .Setup(s => s.ExportSystemDriversAsync(It.IsAny<string>(), It.IsAny<List<DriverClass>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<List<DriverPackage>>.Ok(exportedDrivers));

        await this.sut.ExportSystemDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("2");
        this.sut.IsScanning.Should().BeFalse();
    }

    /// <summary>Verifies list installed drivers populates InstalledDrivers.</summary>
    [Fact]
    public async Task ListInstalledDriversAsync_Success_PopulatesInstalledDrivers()
    {
        this.sut.TargetImagePath = @"C:\mount";

        var drivers = new List<DriverPackage>
        {
            new() { Name = "Installed1", PublishedName = "oem1.inf" },
            new() { Name = "Installed2", PublishedName = "oem2.inf" },
        };

        this.driverServiceMock
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<List<DriverPackage>>.Ok(drivers));

        await this.sut.ListInstalledDriversCommand.ExecuteAsync(null);

        this.sut.InstalledDrivers.Should().HaveCount(2);
        this.sut.StatusMessage.Should().Contain("2");
    }

    /// <summary>Verifies list installed drivers handles failure.</summary>
    [Fact]
    public async Task ListInstalledDriversAsync_Failure_SetsErrorStatus()
    {
        this.sut.TargetImagePath = @"C:\mount";

        this.driverServiceMock
            .Setup(s => s.GetInstalledDriversAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<List<DriverPackage>>.Fail("Image not mounted"));

        await this.sut.ListInstalledDriversCommand.ExecuteAsync(null);

        this.sut.InstalledDrivers.Should().BeEmpty();
        this.sut.StatusMessage.Should().Contain("Failed");
    }

    /// <summary>Verifies SelectAll selects all discovered drivers.</summary>
    [Fact]
    public void SelectAllCommand_SelectsAllDiscoveredDrivers()
    {
        this.sut.DiscoveredDrivers.Add(new DriverPackage { Name = "D1" });
        this.sut.DiscoveredDrivers.Add(new DriverPackage { Name = "D2" });
        this.sut.DiscoveredDrivers.Add(new DriverPackage { Name = "D3" });

        this.sut.SelectAllCommand.Execute(null);

        this.sut.SelectedDriversForInjection.Should().HaveCount(3);
        this.sut.StatusMessage.Should().Contain("3");
    }

    /// <summary>Verifies ClearSelection empties the injection selection.</summary>
    [Fact]
    public void ClearSelectionCommand_ClearsSelection()
    {
        this.sut.SelectedDriversForInjection.Add(new DriverPackage { Name = "D1" });
        this.sut.SelectedDriversForInjection.Add(new DriverPackage { Name = "D2" });

        this.sut.ClearSelectionCommand.Execute(null);

        this.sut.SelectedDriversForInjection.Should().BeEmpty();
    }

    /// <summary>Verifies property change notifications for ScanPath.</summary>
    [Fact]
    public void ScanPath_PropertyChanged_RaisesNotification()
    {
        bool raised = false;
        this.sut.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(this.sut.ScanPath))
            {
                raised = true;
            }
        };

        this.sut.ScanPath = @"C:\NewPath";
        raised.Should().BeTrue();
    }

    /// <summary>Verifies property change notifications for TargetImagePath.</summary>
    [Fact]
    public void TargetImagePath_PropertyChanged_RaisesNotification()
    {
        bool raised = false;
        this.sut.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(this.sut.TargetImagePath))
            {
                raised = true;
            }
        };

        this.sut.TargetImagePath = @"C:\Mount";
        raised.Should().BeTrue();
    }

    /// <summary>Verifies injection exception is handled gracefully.</summary>
    [Fact]
    public async Task InjectDriversAsync_Exception_SetsErrorStatus()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.VerifyAfterInject = false;
        this.sut.SelectedDriversForInjection.Add(new DriverPackage { InfPath = @"C:\drv\x.inf" });

        this.driverServiceMock
            .Setup(s => s.InjectDriversAsync(It.IsAny<DriverInjectionRequest>(), It.IsAny<IProgress<OperationProgress>>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Service down"));

        await this.sut.InjectDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("error");
        this.sut.IsInjecting.Should().BeFalse();
        this.sut.ProgressPercent.Should().Be(0);
    }

    /// <summary>Verifies remove driver exception is handled gracefully.</summary>
    [Fact]
    public async Task RemoveDriverAsync_Exception_SetsErrorStatus()
    {
        this.sut.TargetImagePath = @"C:\mount";
        this.sut.SelectedDriver = new DriverPackage { FriendlyName = "CrashDriver", PublishedName = "oem9.inf" };

        this.driverServiceMock
            .Setup(s => s.RemoveDriverAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Unexpected"));

        await this.sut.RemoveDriverCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("error");
    }

    /// <summary>Verifies export exception is handled gracefully.</summary>
    [Fact]
    public async Task ExportSystemDriversAsync_Exception_SetsErrorStatus()
    {
        this.sut.ScanPath = @"C:\Output";

        this.driverServiceMock
            .Setup(s => s.ExportSystemDriversAsync(It.IsAny<string>(), It.IsAny<List<DriverClass>>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Disk full"));

        await this.sut.ExportSystemDriversCommand.ExecuteAsync(null);

        this.sut.StatusMessage.Should().Contain("error");
        this.sut.IsScanning.Should().BeFalse();
    }
}
