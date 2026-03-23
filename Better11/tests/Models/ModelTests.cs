// <copyright file="ModelTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.Models;

using Better11.Modules.BetterPE.Configuration;
using Better11.Modules.BetterPE.Models;
using FluentAssertions;
using Xunit;

public sealed class WinPEImageTests
{
    [Fact]
    public void NewInstance_ShouldHaveDefaults()
    {
        var image = new WinPEImage();

        image.Id.Should().NotBe(Guid.Empty);
        image.Name.Should().BeEmpty();
        image.Architecture.Should().Be(ImageArchitecture.Amd64);
        image.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public void ImageBuildRequest_ShouldInitializeCollections()
    {
        var request = new ImageBuildRequest();

        request.OptionalComponents.Should().NotBeNull();
        request.DriverPaths.Should().NotBeNull();
    }

    [Fact]
    public void ImageBuildResult_ShouldHaveDefaults()
    {
        var result = new ImageBuildResult();

        result.Success.Should().BeFalse();
        result.ImageSizeMb.Should().Be(0);
    }

    [Fact]
    public void BuildLogEntry_ShouldStoreMessage()
    {
        var entry = new BuildLogEntry { Message = "Test", Timestamp = DateTime.UtcNow };

        entry.Message.Should().Be("Test");
    }

    [Fact]
    public void BuildIssue_ShouldStoreSeverity()
    {
        var issue = new BuildIssue
        {
            Severity = IssueSeverity.Warning,
            Message = "Missing file",
        };

        issue.Severity.Should().Be(IssueSeverity.Warning);
    }

    [Fact]
    public void OperationProgress_ShouldStoreValues()
    {
        var progress = new OperationProgress
        {
            PercentComplete = 50,
            CurrentPhase = "Building",
            CurrentStep = "Copying files",
        };

        progress.PercentComplete.Should().Be(50);
        progress.CurrentPhase.Should().Be("Building");
        progress.CurrentStep.Should().Be("Copying files");
    }
}

public sealed class DriverPackageTests
{
    [Fact]
    public void NewInstance_ShouldHaveDefaults()
    {
        var driver = new DriverPackage();

        driver.Name.Should().BeEmpty();
        driver.Version.Should().BeEmpty();
    }

    [Fact]
    public void DriverInjectionRequest_ShouldInitializeCollections()
    {
        var request = new DriverInjectionRequest();

        request.DriverPaths.Should().NotBeNull();
    }

    [Fact]
    public void DriverInjectionResult_ShouldHaveDefaults()
    {
        var result = new DriverInjectionResult();

        result.Success.Should().BeFalse();
        result.DriversInjected.Should().Be(0);
    }

    [Fact]
    public void DriverScanResult_ShouldInitializeDrivers()
    {
        var result = new DriverScanResult();

        result.Drivers.Should().NotBeNull();
    }
}

public sealed class BootConfigurationTests
{
    [Fact]
    public void BootConfigurationOptions_ShouldHaveDefaults()
    {
        var config = new BootConfigurationOptions();

        config.FirmwareType.Should().Be(FirmwareType.Both);
        config.TimeoutSeconds.Should().Be(30);
        config.Locale.Should().Be("en-US");
    }

    [Fact]
    public void BcdEntry_ShouldStoreValues()
    {
        var entry = new BcdEntry
        {
            Identifier = "{bootmgr}",
            Description = "Windows Boot Manager",
        };

        entry.Identifier.Should().Be("{bootmgr}");
        entry.Description.Should().Be("Windows Boot Manager");
    }
}

public sealed class CustomizationProfileTests
{
    [Fact]
    public void NewInstance_ShouldHaveDefaults()
    {
        var profile = new CustomizationProfile();

        profile.Name.Should().BeEmpty();
        profile.EnablePowerShell.Should().BeFalse();
    }

    [Fact]
    public void CustomizationEntry_ShouldStoreValues()
    {
        var entry = new CustomizationEntry
        {
            Type = CustomizationType.Registry,
            Description = "Set wallpaper",
        };

        entry.Type.Should().Be(CustomizationType.Registry);
    }

    [Fact]
    public void StartupScript_ShouldStoreValues()
    {
        var script = new StartupScript
        {
            Name = "init.cmd",
            Content = "@echo off",
        };

        script.Name.Should().Be("init.cmd");
    }

    [Fact]
    public void FileCopyOperation_ShouldStoreValues()
    {
        var op = new FileCopyOperation
        {
            SourcePath = @"C:\tools\tool.exe",
            DestinationPath = @"X:\Tools\tool.exe",
        };

        op.SourcePath.Should().Contain("tool.exe");
    }
}

public sealed class RecoveryEnvironmentTests
{
    [Fact]
    public void RecoveryBuildRequest_ShouldHaveDefaults()
    {
        var request = new RecoveryBuildRequest();

        request.Type.Should().Be(RecoveryType.WinRE);
    }

    [Fact]
    public void WinReStatus_ShouldStoreValues()
    {
        var status = new WinReStatus
        {
            IsEnabled = true,
            ImagePath = @"C:\Recovery\Winre.wim",
            SizeMB = 450,
        };

        status.IsEnabled.Should().BeTrue();
        status.SizeMB.Should().Be(450);
    }

    [Fact]
    public void RecoveryTool_ShouldStoreValues()
    {
        var tool = new RecoveryTool
        {
            Name = "DiskPart",
            Path = @"X:\Windows\System32\diskpart.exe",
        };

        tool.Name.Should().Be("DiskPart");
    }
}

public sealed class DeploymentTargetTests
{
    [Fact]
    public void DeploymentRequest_ShouldHaveDefaults()
    {
        var request = new DeploymentRequest();

        request.Method.Should().Be(DeploymentMethod.UsbDirect);
    }

    [Fact]
    public void DeploymentResult_ShouldHaveDefaults()
    {
        var result = new DeploymentResult();

        result.Success.Should().BeFalse();
    }

    [Fact]
    public void UsbDriveInfo_ShouldStoreValues()
    {
        var info = new UsbDriveInfo
        {
            DriveLetter = "E:",
            FriendlyName = "SanDisk USB",
            SizeGB = 32,
            FreeSpaceGB = 28.5,
            IsReadOnly = false,
        };

        info.DriveLetter.Should().Be("E:");
        info.SizeGB.Should().Be(32);
        info.IsReadOnly.Should().BeFalse();
    }
}

public sealed class BetterPEOptionsTests
{
    [Fact]
    public void NewInstance_ShouldHaveDefaults()
    {
        var options = new BetterPEOptions();

        options.WorkingDirectory.Should().NotBeNullOrEmpty();
        options.PowerShellModulesPath.Should().Be("PowerShell");
    }

    [Fact]
    public void DriverRepositoryPath_ShouldBeSettable()
    {
        var options = new BetterPEOptions { DriverRepositoryPath = @"C:\Drivers" };
        options.DriverRepositoryPath.Should().Be(@"C:\Drivers");
    }

    [Fact]
    public void ProfilesDirectory_ShouldBeSettable()
    {
        var options = new BetterPEOptions { ProfilesDirectory = @"C:\Profiles" };
        options.ProfilesDirectory.Should().Be(@"C:\Profiles");
    }

    [Fact]
    public void DeploymentHistoryRetentionDays_ShouldDefaultTo30()
    {
        var options = new BetterPEOptions();
        options.DeploymentHistoryRetentionDays.Should().Be(30);
    }
}

public sealed class EnumTests
{
    [Theory]
    [InlineData(ImageArchitecture.Amd64)]
    [InlineData(ImageArchitecture.X86)]
    [InlineData(ImageArchitecture.Arm64)]
    public void ImageArchitecture_AllValues_ShouldBeDefined(ImageArchitecture arch)
    {
        arch.Should().BeDefined();
    }

    [Theory]
    [InlineData(ImageBuildState.NotStarted)]
    [InlineData(ImageBuildState.Preparing)]
    [InlineData(ImageBuildState.Building)]
    [InlineData(ImageBuildState.Customizing)]
    [InlineData(ImageBuildState.Finalizing)]
    [InlineData(ImageBuildState.Completed)]
    [InlineData(ImageBuildState.Failed)]
    [InlineData(ImageBuildState.Cancelled)]
    public void ImageBuildState_AllValues_ShouldBeDefined(ImageBuildState state)
    {
        state.Should().BeDefined();
    }

    [Theory]
    [InlineData(OutputMediaType.Wim)]
    [InlineData(OutputMediaType.Iso)]
    [InlineData(OutputMediaType.Usb)]
    public void OutputMediaType_AllValues_ShouldBeDefined(OutputMediaType type)
    {
        type.Should().BeDefined();
    }

    [Theory]
    [InlineData(FirmwareType.BIOS)]
    [InlineData(FirmwareType.UEFI)]
    [InlineData(FirmwareType.Both)]
    public void FirmwareType_AllValues_ShouldBeDefined(FirmwareType type)
    {
        type.Should().BeDefined();
    }

    [Theory]
    [InlineData(DeploymentMethod.UsbDirect)]
    [InlineData(DeploymentMethod.UsbIso)]
    [InlineData(DeploymentMethod.Pxe)]
    [InlineData(DeploymentMethod.Wds)]
    public void DeploymentMethod_AllValues_ShouldBeDefined(DeploymentMethod method)
    {
        method.Should().BeDefined();
    }

    [Theory]
    [InlineData(DeploymentStatus.Pending)]
    [InlineData(DeploymentStatus.InProgress)]
    [InlineData(DeploymentStatus.Completed)]
    [InlineData(DeploymentStatus.Failed)]
    [InlineData(DeploymentStatus.Cancelled)]
    public void DeploymentStatus_AllValues_ShouldBeDefined(DeploymentStatus status)
    {
        status.Should().BeDefined();
    }

    [Theory]
    [InlineData(RecoveryType.WinRE)]
    [InlineData(RecoveryType.Custom)]
    [InlineData(RecoveryType.Standalone)]
    public void RecoveryType_AllValues_ShouldBeDefined(RecoveryType type)
    {
        type.Should().BeDefined();
    }

    [Theory]
    [InlineData(IssueSeverity.Info)]
    [InlineData(IssueSeverity.Warning)]
    [InlineData(IssueSeverity.Error)]
    public void IssueSeverity_AllValues_ShouldBeDefined(IssueSeverity sev)
    {
        sev.Should().BeDefined();
    }

    [Theory]
    [InlineData(WimCompressionType.None)]
    [InlineData(WimCompressionType.Fast)]
    [InlineData(WimCompressionType.Maximum)]
    public void WimCompressionType_AllValues_ShouldBeDefined(WimCompressionType type)
    {
        type.Should().BeDefined();
    }

    [Theory]
    [InlineData(DriverSigningStatus.Signed)]
    [InlineData(DriverSigningStatus.Unsigned)]
    [InlineData(DriverSigningStatus.Unknown)]
    public void DriverSigningStatus_AllValues_ShouldBeDefined(DriverSigningStatus status)
    {
        status.Should().BeDefined();
    }

    [Theory]
    [InlineData(CustomizationType.Registry)]
    [InlineData(CustomizationType.File)]
    [InlineData(CustomizationType.Script)]
    [InlineData(CustomizationType.Package)]
    [InlineData(CustomizationType.Driver)]
    public void CustomizationType_AllValues_ShouldBeDefined(CustomizationType type)
    {
        type.Should().BeDefined();
    }
}
