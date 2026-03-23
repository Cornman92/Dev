// ============================================================================
// File: src/Better11.Services/SystemTray/SystemTrayService.cs
// Better11 System Enhancement Suite — System Tray Service Implementation
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Drawing;
using System.Windows.Forms;
using System.Windows.Input;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.SystemTray;

/// <summary>
/// Windows Forms-based system tray service implementation for Better11.
/// Provides notification capabilities and context menu integration.
/// </summary>
public sealed class SystemTrayService : ISystemTrayService, IDisposable
{
    private readonly ILogger<SystemTrayService> _logger;
    private readonly NotifyIcon _notifyIcon;
    private readonly ContextMenuStrip _contextMenu;
    private bool _disposed;

    /// <summary>Gets a value indicating whether the system tray is visible.</summary>
    public bool IsVisible => _notifyIcon.Visible;

    /// <summary>Gets the current tooltip text.</summary>
    public string Tooltip => _notifyIcon.Text;

    /// <summary>Event raised when the system tray icon is double-clicked.</summary>
    public event EventHandler? DoubleClicked;

    /// <summary>Event raised when the system tray icon is right-clicked.</summary>
    public event EventHandler? RightClicked;

    /// <summary>Event raised when the system tray service is disposed.</summary>
    public event EventHandler? Disposed;

    /// <summary>
    /// Initializes a new instance of the <see cref="SystemTrayService"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    public SystemTrayService(ILogger<SystemTrayService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        _notifyIcon = new NotifyIcon
        {
            Visible = false,
        };

        _contextMenu = new ContextMenuStrip();

        // Hook up event handlers
        _notifyIcon.DoubleClick += OnNotifyIconDoubleClick;
        _notifyIcon.MouseClick += OnNotifyIconMouseClick;

        _logger.LogDebug("SystemTrayService initialized");
    }

    /// <inheritdoc/>
    public async Task ShowAsync(string iconPath, string tooltip)
    {
        if (_disposed)
        {
            _logger.LogWarning("Attempted to show disposed system tray");
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                if (File.Exists(iconPath))
                {
                    _notifyIcon.Icon = new Icon(iconPath);
                    _logger.LogDebug("Loaded system tray icon from {IconPath}", iconPath);
                }
                else
                {
                    _logger.LogWarning("Icon file not found: {IconPath}", iconPath);
                    // Use default system icon
                    _notifyIcon.Icon = SystemIcons.Application;
                }

                _notifyIcon.Text = tooltip.Length > 63 ? string.Concat(tooltip.AsSpan(0, 60), "...") : tooltip;
                _notifyIcon.ContextMenuStrip = _contextMenu;
                _notifyIcon.Visible = true;

                _logger.LogInformation("System tray shown with tooltip: {Tooltip}", tooltip);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to show system tray");
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task HideAsync()
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                _notifyIcon.Visible = false;
                _logger.LogDebug("System tray hidden");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to hide system tray");
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task ShowNotificationAsync(string title, string message, int timeout = 5000)
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                _notifyIcon.ShowBalloonTip(timeout, title, message, ToolTipIcon.Info);
                _logger.LogDebug("Notification shown: {Title} - {Message}", title, message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to show notification");
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task AddContextMenuItemAsync(string text, ICommand command)
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                var menuItem = new ToolStripMenuItem(text);
                menuItem.Click += (s, e) =>
                {
                    if (command.CanExecute(null))
                    {
                        command.Execute(null);
                    }
                };

                _contextMenu.Items.Add(menuItem);
                _logger.LogDebug("Added context menu item: {Text}", text);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to add context menu item: {Text}", text);
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task AddContextMenuSeparatorAsync()
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                _contextMenu.Items.Add(new ToolStripSeparator());
                _logger.LogDebug("Added context menu separator");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to add context menu separator");
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task AddContextMenuSubmenuAsync(string text, params (string Text, ICommand Command)[] items)
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                var submenu = new ToolStripMenuItem(text);

                foreach (var (itemText, command) in items)
                {
                    var menuItem = new ToolStripMenuItem(itemText);
                    menuItem.Click += (s, e) =>
                    {
                        if (command.CanExecute(null))
                        {
                            command.Execute(null);
                        }
                    };
                    submenu.DropDownItems.Add(menuItem);
                }

                _contextMenu.Items.Add(submenu);
                _logger.LogDebug("Added context menu submenu: {Text} with {Count} items", text, items.Length);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to add context menu submenu: {Text}", text);
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task UpdateTooltipAsync(string tooltip)
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                _notifyIcon.Text = tooltip.Length > 63 ? string.Concat(tooltip.AsSpan(0, 60), "...") : tooltip;
                _logger.LogDebug("Updated tooltip: {Tooltip}", tooltip);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update tooltip");
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task UpdateIconAsync(string iconPath)
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                if (File.Exists(iconPath))
                {
                    _notifyIcon.Icon = new Icon(iconPath);
                    _logger.LogDebug("Updated system tray icon from {IconPath}", iconPath);
                }
                else
                {
                    _logger.LogWarning("Icon file not found for update: {IconPath}", iconPath);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update system tray icon");
                throw;
            }
        });
    }

    /// <inheritdoc/>
    public async Task ShowContextMenuAsync()
    {
        if (_disposed)
        {
            return;
        }

        await Task.Run(() =>
        {
            try
            {
                var mousePosition = Cursor.Position;
                _contextMenu.Show(mousePosition);
                _logger.LogDebug("Context menu shown at position: {X}, {Y}", mousePosition.X, mousePosition.Y);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to show context menu");
                throw;
            }
        });
    }

    private void OnNotifyIconDoubleClick(object? sender, EventArgs e)
    {
        DoubleClicked?.Invoke(this, e);
        _logger.LogDebug("System tray double-clicked");
    }

    private void OnNotifyIconMouseClick(object? sender, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Right)
        {
            RightClicked?.Invoke(this, e);
            _logger.LogDebug("System tray right-clicked");
        }
    }

    /// <summary>
    /// Releases all resources used by the SystemTrayService.
    /// </summary>
    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        try
        {
            _notifyIcon?.Dispose();
            _contextMenu?.Dispose();
            _disposed = true;

            Disposed?.Invoke(this, EventArgs.Empty);
            _logger.LogDebug("SystemTrayService disposed");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during SystemTrayService disposal");
        }
    }
}
