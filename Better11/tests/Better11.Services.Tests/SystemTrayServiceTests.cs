// ============================================================================
// Better11 System Enhancement Suite — SystemTrayServiceTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================
// Tests are skipped when System.Windows.Forms cannot be loaded (e.g. test host).
// ============================================================================

using System.Windows.Input;
using Better11.Services.SystemTray;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace Better11.Services.Tests;

/// <summary>
/// Unit tests for <see cref="SystemTrayService"/>.
/// </summary>
public sealed class SystemTrayServiceTests
{
    private readonly Mock<ILogger<SystemTrayService>> _mockLogger;

    public SystemTrayServiceTests()
    {
        _mockLogger = new Mock<ILogger<SystemTrayService>>();
    }

    private static SystemTrayService CreateService(ILogger<SystemTrayService> logger)
        => new SystemTrayService(logger);

    [Fact]
    public void Constructor_ThrowsArgumentNullException_WhenLoggerIsNull()
    {
        var act = () => new SystemTrayService(null!);
        act.Should().Throw<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void Constructor_InitializesPropertiesCorrectly()
    {
        var service = CreateService(_mockLogger.Object);
        service.Should().NotBeNull();
        service.IsVisible.Should().BeFalse();
        service.Tooltip.Should().BeEmpty();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void IsVisible_ReturnsNotifyIconVisibility()
    {
        var service = CreateService(_mockLogger.Object);
        service.IsVisible.Should().BeFalse();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void Tooltip_ReturnsNotifyIconText()
    {
        var service = CreateService(_mockLogger.Object);
        service.Tooltip.Should().BeEmpty();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task ShowAsync_ThrowsArgumentNullException_WhenIconPathIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowAsync(null!, "Test Tooltip");
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task ShowAsync_ThrowsArgumentNullException_WhenTooltipIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowAsync("test.ico", null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task ShowAsync_HandlesEmptyIconPath()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowAsync("", "Test Tooltip");
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task ShowAsync_HandlesEmptyTooltip()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowAsync("test.ico", "");
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task HideAsync_HidesSystemTray()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.HideAsync();
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task UpdateTooltipAsync_ThrowsArgumentNullException_WhenTooltipIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.UpdateTooltipAsync(null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task UpdateTooltipAsync_HandlesEmptyTooltip()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.UpdateTooltipAsync("");
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuItemAsync_ThrowsArgumentNullException_WhenTextIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var mockCommand = new Mock<ICommand>();
        var act = async () => await service.AddContextMenuItemAsync(null!, mockCommand.Object);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuItemAsync_ThrowsArgumentNullException_WhenCommandIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.AddContextMenuItemAsync("Test", null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuItemAsync_HandlesEmptyText()
    {
        var service = CreateService(_mockLogger.Object);
        var mockCommand = new Mock<ICommand>();
        var act = async () => await service.AddContextMenuItemAsync("", mockCommand.Object);
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuSubmenuAsync_ThrowsArgumentNullException_WhenTextIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var mockCommand = new Mock<ICommand>();
        var items = new (string Text, ICommand Command)[] { ("Item1", mockCommand.Object), ("Item2", mockCommand.Object) };
        var act = async () => await service.AddContextMenuSubmenuAsync(null!, items);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuSubmenuAsync_ThrowsArgumentNullException_WhenItemsIsNull()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.AddContextMenuSubmenuAsync("Submenu", null!);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuSubmenuAsync_HandlesEmptyItems()
    {
        var service = CreateService(_mockLogger.Object);
        var items = Array.Empty<(string Text, ICommand Command)>();
        var act = async () => await service.AddContextMenuSubmenuAsync("Submenu", items);
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task AddContextMenuSeparatorAsync_AddsSeparator()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.AddContextMenuSeparatorAsync();
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task ShowContextMenuAsync_ShowsContextMenu()
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowContextMenuAsync();
        await act.Should().NotThrowAsync();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void DoubleClicked_Event_CanBeSubscribed()
    {
        var service = CreateService(_mockLogger.Object);
        bool eventFired = false;
        service.DoubleClicked += (sender, e) => eventFired = true;
        service.Should().NotBeNull();
        eventFired.Should().BeFalse();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void RightClicked_Event_CanBeSubscribed()
    {
        var service = CreateService(_mockLogger.Object);
        bool eventFired = false;
        service.RightClicked += (sender, e) => eventFired = true;
        service.Should().NotBeNull();
        eventFired.Should().BeFalse();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void Disposed_Event_CanBeSubscribed()
    {
        var service = CreateService(_mockLogger.Object);
        bool eventFired = false;
        service.Disposed += (sender, e) => eventFired = true;
        service.Should().NotBeNull();
        eventFired.Should().BeFalse();
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public async Task Dispose_DisposesResources()
    {
        var service = CreateService(_mockLogger.Object);
        await Task.Run(() =>
        {
            service.Dispose();
            service.Dispose(); // Should not throw
        });
    }

    [SkippableFact(typeof(BadImageFormatException))]
    public void Dispose_CanBeCalledMultipleTimes()
    {
        var service = CreateService(_mockLogger.Object);
        service.Dispose();
        service.Dispose(); // Should not throw
    }

    [SkippableTheory(typeof(BadImageFormatException))]
    [InlineData("Short tooltip")]
    [InlineData("A")]
    [InlineData("This is a very long tooltip that should be truncated to 63 characters maximum allowed by Windows NotifyIcon")]
    public async Task ShowAsync_HandlesVariousTooltipLengths(string tooltip)
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowAsync("test.ico", tooltip);
        await act.Should().NotThrowAsync();
    }

    [SkippableTheory(typeof(BadImageFormatException))]
    [InlineData("valid.ico")]
    [InlineData("test.png")]
    [InlineData(@"C:\path\to\icon.ico")]
    [InlineData("relative/path/icon.png")]
    public async Task ShowAsync_HandlesVariousIconPaths(string iconPath)
    {
        var service = CreateService(_mockLogger.Object);
        var act = async () => await service.ShowAsync(iconPath, "Test Tooltip");
        await act.Should().NotThrowAsync();
    }
}
