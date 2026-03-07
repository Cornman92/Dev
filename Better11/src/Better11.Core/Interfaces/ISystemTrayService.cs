// ============================================================================
// File: src/Better11.Core/Interfaces/ISystemTrayService.cs
// Better11 System Enhancement Suite — System Tray Service Interface
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Windows.Input;

namespace Better11.Core.Interfaces;

/// <summary>
/// Provides system tray integration for Better11 with notification and quick action capabilities.
/// </summary>
public interface ISystemTrayService
{
    /// <summary>Gets a value indicating whether the system tray is visible.</summary>
    bool IsVisible { get; }

    /// <summary>Gets the current tooltip text.</summary>
    string Tooltip { get; }

    /// <summary>Shows the system tray icon.</summary>
    /// <param name="iconPath">Path to the icon file.</param>
    /// <param name="tooltip">Tooltip text to display.</param>
    /// <returns>A task representing the operation.</returns>
    Task ShowAsync(string iconPath, string tooltip);

    /// <summary>Hides the system tray icon.</summary>
    /// <returns>A task representing the operation.</returns>
    Task HideAsync();

    /// <summary>Shows a notification balloon.</summary>
    /// <param name="title">The notification title.</param>
    /// <param name="message">The notification message.</param>
    /// <param name="timeout">Optional timeout in milliseconds.</param>
    /// <returns>A task representing the operation.</returns>
    Task ShowNotificationAsync(string title, string message, int timeout = 5000);

    /// <summary>Adds a context menu item.</summary>
    /// <param name="text">The menu item text.</param>
    /// <param name="command">The command to execute when clicked.</param>
    /// <returns>A task representing the operation.</returns>
    Task AddContextMenuItemAsync(string text, ICommand command);

    /// <summary>Adds a context menu separator.</summary>
    /// <returns>A task representing the operation.</returns>
    Task AddContextMenuSeparatorAsync();

    /// <summary>Adds a submenu to the context menu.</summary>
    /// <param name="text">The submenu text.</param>
    /// <param name="items">The submenu items.</param>
    /// <returns>A task representing the operation.</returns>
    Task AddContextMenuSubmenuAsync(string text, params (string Text, ICommand Command)[] items);

    /// <summary>Updates the tooltip text.</summary>
    /// <param name="tooltip">The new tooltip text.</param>
    /// <returns>A task representing the operation.</returns>
    Task UpdateTooltipAsync(string tooltip);

    /// <summary>Updates the system tray icon.</summary>
    /// <param name="iconPath">Path to the new icon file.</param>
    /// <returns>A task representing the operation.</returns>
    Task UpdateIconAsync(string iconPath);

    /// <summary>Shows the context menu at the current cursor position.</summary>
    /// <returns>A task representing the operation.</returns>
    Task ShowContextMenuAsync();

    /// <summary>Event raised when the system tray icon is double-clicked.</summary>
    event EventHandler? DoubleClicked;

    /// <summary>Event raised when the system tray icon is right-clicked.</summary>
    event EventHandler? RightClicked;

    /// <summary>Event raised when the system tray service is disposed.</summary>
    event EventHandler? Disposed;
}
