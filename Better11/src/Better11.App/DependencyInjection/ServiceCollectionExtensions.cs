// ============================================================================
// File: src/Better11.App/DependencyInjection/ServiceCollectionExtensions.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.App.Navigation;
using Better11.Core.Interfaces;
using Better11.Services.Analytics;
using Better11.Services.AppUpdate;
using Better11.Services.BackupRestore;
using Better11.Services.Customization;
using Better11.Services.DiskCleanup;
using Better11.Services.Driver;
using Better11.Services.Network;
using Better11.Services.Optimization;
using Better11.Services.Package;
using Better11.Services.PowerShell;
using Better11.Services.Privacy;
using Better11.Services.ScheduledTask;
using Better11.Services.Security;
using Better11.Services.Settings;
using Better11.Services.Startup;
using Better11.Services.SystemInfo;
using Better11.Services.Update;
using Better11.Services.UserAccount;
using Better11.ViewModels.About;
using Better11.ViewModels.BackupRestore;
using Better11.ViewModels.Customization;
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
using Better11.ViewModels.UserAccount;
using Better11.ViewModels.Wizard;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Better11.App.DependencyInjection;

/// <summary>
/// Registers all Better11 services, ViewModels, and navigation.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Adds all Better11 dependencies.
    /// </summary>
    /// <param name="services">The service collection.</param>
    /// <returns>The service collection for chaining.</returns>
    public static IServiceCollection AddBetter11(this IServiceCollection services)
    {
        // Core infrastructure
        services.AddSingleton<IPowerShellService>(sp =>
            new PowerShellService(
                sp.GetRequiredService<ILogger<PowerShellService>>()));

        // Services
        services.AddSingleton<IPackageService, PackageService>();
        services.AddSingleton<IDriverService, DriverService>();
        services.AddSingleton<IStartupService, StartupService>();
        services.AddSingleton<IScheduledTaskService, ScheduledTaskService>();
        services.AddSingleton<INetworkService, NetworkService>();
        services.AddSingleton<IDiskCleanupService, DiskCleanupService>();
        services.AddSingleton<ISystemInfoService, SystemInfoService>();
        services.AddSingleton<IOptimizationService, OptimizationService>();
        services.AddSingleton<IPrivacyService, PrivacyService>();
        services.AddSingleton<ISecurityService, SecurityService>();
        services.AddSingleton<IUpdateService, UpdateService>();
        services.AddSingleton<ISettingsService, SettingsService>();
        services.AddSingleton<IAnalyticsService, AnalyticsService>();
        services.AddSingleton<IAppUpdateService, AppUpdateService>();
        services.AddSingleton<IBackupRestoreService, BackupRestoreService>();
        services.AddSingleton<IUserAccountService, UserAccountService>();
        services.AddSingleton<ICustomizationCatalogService, CustomizationCatalogService>();
        services.AddSingleton<ICustomizationExecutionService, CustomizationExecutionService>();
        services.AddSingleton<IRecipeService, RecipeService>();
        services.AddSingleton<IImageServicingService, ImageServicingService>();

        // Navigation
        services.AddSingleton<NavigationService>();
        services.AddSingleton<INavigationService>(sp =>
            sp.GetRequiredService<NavigationService>());

        // ViewModels
        services.AddTransient<DashboardViewModel>();
        services.AddTransient<CustomizationStudioViewModel>();
        services.AddTransient<PackageViewModel>();
        services.AddTransient<DriverViewModel>();
        services.AddTransient<StartupViewModel>();
        services.AddTransient<ScheduledTaskViewModel>();
        services.AddTransient<NetworkViewModel>();
        services.AddTransient<DiskCleanupViewModel>();
        services.AddTransient<SystemInfoViewModel>();
        services.AddTransient<OptimizationViewModel>();
        services.AddTransient<PrivacyViewModel>();
        services.AddTransient<SecurityViewModel>();
        services.AddTransient<UpdateViewModel>();
        services.AddTransient<SettingsViewModel>();
        services.AddTransient<AboutViewModel>();
        services.AddTransient<BackupRestoreViewModel>();
        services.AddTransient<UserAccountViewModel>();
        services.AddTransient<FirstRunWizardViewModel>();

        return services;
    }
}
