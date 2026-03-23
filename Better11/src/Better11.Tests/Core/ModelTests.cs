// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Core;

using Better11.Core.Models;
using FluentAssertions;
using Xunit;

public class ModelTests
{
    [Fact]
    public void SystemInfoTotalMemoryFormattedShouldFormatCorrectly()
    {
        var info = new SystemInfo { TotalMemoryBytes = 17179869184L }; // 16 GB
        info.TotalMemoryFormatted.Should().Be("16.0 GB");
    }

    [Fact]
    public void SystemInfoUptimeFormattedShouldShowDaysWhenOverOneDay()
    {
        var info = new SystemInfo { Uptime = TimeSpan.FromHours(25.5) };
        info.UptimeFormatted.Should().Be("1d 1h");
    }

    [Fact]
    public void SystemInfoUptimeFormattedShouldShowHoursWhenUnderOneDay()
    {
        var info = new SystemInfo { Uptime = TimeSpan.FromHours(5.5) };
        info.UptimeFormatted.Should().Be("5h 30m");
    }

    [Fact]
    public void PackageHasUpdateShouldBeTrueWhenVersionsDiffer()
    {
        var pkg = new Package { Version = "1.0", AvailableVersion = "2.0" };
        pkg.HasUpdate.Should().BeTrue();
    }

    [Fact]
    public void PackageHasUpdateShouldBeFalseWhenVersionsMatch()
    {
        var pkg = new Package { Version = "1.0", AvailableVersion = "1.0" };
        pkg.HasUpdate.Should().BeFalse();
    }

    [Fact]
    public void DriverHasUpdateShouldBeFalseWhenNoAvailableVersion()
    {
        var drv = new Driver { DriverVersion = "1.0" };
        drv.HasUpdate.Should().BeFalse();
    }

    [Fact]
    public void OptimizationItemShouldDefaultToReversible()
    {
        var item = new OptimizationItem();
        item.IsReversible.Should().BeTrue();
    }

    [Fact]
    public void UndoEntryShouldGenerateUniqueId()
    {
        var a = new UndoEntry();
        var b = new UndoEntry();
        a.Id.Should().NotBe(b.Id);
    }
}
