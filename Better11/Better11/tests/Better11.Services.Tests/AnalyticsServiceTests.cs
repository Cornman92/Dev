// Copyright (c) Better11. All rights reserved.

using Better11.Core.Constants;
using Better11.Core.Interfaces;
using Better11.Services.Analytics;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="AnalyticsService"/>.
/// </summary>
public sealed class AnalyticsServiceTests
{
    private readonly Mock<ILogger<AnalyticsService>> _mockLogger = new();
    private readonly Mock<ISettingsService> _mockSettings = new();

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenLoggerIsNull()
    {
        var act = () => new AnalyticsService(null!, _mockSettings.Object);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenSettingsIsNull()
    {
        var act = () => new AnalyticsService(_mockLogger.Object, null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public async Task TrackEventAsync_DoesNotLog_WhenTelemetryDisabled()
    {
        _mockSettings.Setup(s => s.GetValue(SettingsConstants.Telemetry, false)).Returns(false);
        var service = new AnalyticsService(_mockLogger.Object, _mockSettings.Object);
        await service.TrackEventAsync("TestEvent");
        _mockLogger.Invocations.Should().BeEmpty();
    }

    [Fact]
    public async Task TrackEventAsync_Logs_WhenTelemetryEnabled()
    {
        _mockSettings.Setup(s => s.GetValue(SettingsConstants.Telemetry, false)).Returns(true);
        var service = new AnalyticsService(_mockLogger.Object, _mockSettings.Object);
        await service.TrackEventAsync("TestEvent");
        _mockLogger.Invocations.Should().NotBeEmpty();
    }

    [Fact]
    public async Task TrackPageViewAsync_DoesNotLog_WhenTelemetryDisabled()
    {
        _mockSettings.Setup(s => s.GetValue(SettingsConstants.Telemetry, false)).Returns(false);
        var service = new AnalyticsService(_mockLogger.Object, _mockSettings.Object);
        await service.TrackPageViewAsync("Dashboard");
        _mockLogger.Invocations.Should().BeEmpty();
    }
}
