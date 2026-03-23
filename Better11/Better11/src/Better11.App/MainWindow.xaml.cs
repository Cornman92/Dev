// ============================================================================
// File: src/Better11.App/MainWindow.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.App.Navigation;
using Better11.App.Views;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Better11.App;

/// <summary>
/// The main application window with NavigationView shell.
/// </summary>
public sealed partial class MainWindow : Window
{
    private static readonly Dictionary<string, Type> PageMap = new()
    {
        ["Dashboard"] = typeof(DashboardPage),
        ["Packages"] = typeof(PackageManagerPage),
        ["Drivers"] = typeof(DriverManagerPage),
        ["Startup"] = typeof(StartupManagerPage),
        ["Tasks"] = typeof(ScheduledTasksPage),
        ["Network"] = typeof(NetworkManagerPage),
        ["DiskCleanup"] = typeof(DiskCleanupPage),
        ["BackupRestore"] = typeof(BackupRestorePage),
        ["UserAccount"] = typeof(UserAccountPage),
        ["SystemInfo"] = typeof(SystemInfoPage),
        ["Optimization"] = typeof(OptimizationPage),
        ["Privacy"] = typeof(PrivacyPage),
        ["Security"] = typeof(SecurityPage),
        ["Updates"] = typeof(UpdatesPage),
        ["Settings"] = typeof(SettingsPage),
        ["About"] = typeof(AboutPage),
        ["FirstRunWizard"] = typeof(FirstRunWizardPage),
    };

    /// <summary>
    /// Initializes a new instance of the <see cref="MainWindow"/> class.
    /// </summary>
    public MainWindow()
    {
        this.InitializeComponent();
        this.Title = "Better11 System Enhancement Suite";

        var navigationService = App.GetService<NavigationService>();
        navigationService.SetFrame(ContentFrame);

        foreach (var (key, pageType) in PageMap)
        {
            navigationService.RegisterPage(key, pageType);
        }

        navigationService.NavigateTo("Dashboard");
    }

    private void NavView_ItemInvoked(
        NavigationView sender,
        NavigationViewItemInvokedEventArgs args)
    {
        if (args.IsSettingsInvoked)
        {
            ContentFrame.Navigate(typeof(SettingsPage));
            return;
        }

        if (args.InvokedItemContainer?.Tag is string tag
            && PageMap.TryGetValue(tag, out var pageType))
        {
            ContentFrame.Navigate(pageType);
        }
    }
}
