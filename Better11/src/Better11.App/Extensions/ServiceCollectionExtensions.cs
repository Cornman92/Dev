// Copyright (c) Better11. All rights reserved.

using Better11.App.Navigation;
using Better11.Core.Interfaces;
using Better11.Services.DiskCleanup;
using Better11.Services.Driver;
using Better11.Services.Network;
using Better11.Services.Optimization;
using Better11.Services.Package;
using Better11.Services.PowerShell;
using Better11.Services.Privacy;
using Better11.Services.ScheduledTask;
using Better11.Services.Security;
using Better11.Services.Startup;
using Better11.Services.SystemInfo;
using Better11.Services.Update;
using Better11.ViewModels.About;
using Better11.ViewModels.Dashboard;
using Better11.ViewModels.DiskCleanup;
using Better11.ViewModels.Driver;
using Better11.ViewModels.Network;
using Better11.ViewModels.Optimization;
using Better11.ViewModels.Package;
using Better11.ViewModels.Privacy;
using Better11.ViewModels.ScheduledTask;
using Better11.ViewModels.Security;
using Better11.ViewModels.Settings;
using Better11.ViewModels.Startup;
using Better11.ViewModels.SystemInfo;
using Better11.ViewModels.Update;
using Better11.ViewModels.Wizard;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Better11.App.Extensions;

/// <summary>
/// Extension methods for registering all Better11 services and ViewModels in the DI container.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Registers all Better11 services, ViewModels, navigation, and settings into the
    /// <see cref="IServiceCollection"/>.
    /// </summary>
    /// <param name="services">The service collection to add registrations to.</param>
    /// <returns>The same <see cref="IServiceCollection"/> for chaining.</returns>
    public static IServiceCollection AddBetter11Services(this IServiceCollection services)
    {
        // ==================================================================
        // Core Infrastructure (Singletons)
        // ==================================================================

        services.AddSingleton<IPowerShellService>(sp =>
            new PowerShellService(
                sp.GetRequiredService<ILogger<PowerShellService>>()));

        // ==================================================================
        // Services (Singletons)
        // ==================================================================

        services.AddSingleton<IOptimizationService, OptimizationService>();
        services.AddSingleton<IPrivacyService, PrivacyService>();
        services.AddSingleton<ISecurityService, SecurityService>();
        services.AddSingleton<IPackageService, PackageService>();
        services.AddSingleton<IDriverService, DriverService>();
        services.AddSingleton<IStartupService, StartupService>();
        services.AddSingleton<IScheduledTaskService, ScheduledTaskService>();
        services.AddSingleton<INetworkService, NetworkService>();
        services.AddSingleton<IDiskCleanupService, DiskCleanupService>();
        services.AddSingleton<ISystemInfoService, SystemInfoService>();
        services.AddSingleton<IUpdateService, UpdateService>();

        // ==================================================================
        // Navigation & Settings (Singletons)
        // ==================================================================

        services.AddSingleton<NavigationService>();
        services.AddSingleton<INavigationService>(sp =>
            sp.GetRequiredService<NavigationService>());

        // ==================================================================
        // ViewModels (Transient)
        // ==================================================================

        services.AddTransient<DashboardViewModel>();
        services.AddTransient<OptimizationViewModel>();
        services.AddTransient<PrivacyViewModel>();
        services.AddTransient<SecurityViewModel>();
        services.AddTransient<PackageViewModel>();
        services.AddTransient<DriverViewModel>();
        services.AddTransient<StartupViewModel>();
        services.AddTransient<ScheduledTaskViewModel>();
        services.AddTransient<NetworkViewModel>();
        services.AddTransient<DiskCleanupViewModel>();
        services.AddTransient<SystemInfoViewModel>();
        services.AddTransient<UpdateViewModel>();
        services.AddTransient<SettingsViewModel>();
        services.AddTransient<AboutViewModel>();
        services.AddTransient<FirstRunWizardViewModel>();

        return services;
    }
}
