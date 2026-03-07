// <copyright file="ServiceCollectionExtensions.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE;

using Better11.Modules.BetterPE.Configuration;
using Better11.Modules.BetterPE.Services.Implementations;
using Better11.Modules.BetterPE.Services.Interfaces;
using Better11.Modules.BetterPE.TUI;
using Better11.Modules.BetterPE.TUI.Rendering;
using Better11.Modules.BetterPE.ViewModels;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// Extension methods for registering BetterPE module services.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Registers all BetterPE module services, ViewModels, and TUI components.
    /// </summary>
    /// <param name="services">The service collection.</param>
    /// <param name="configuration">The application configuration.</param>
    /// <returns>The service collection for chaining.</returns>
    public static IServiceCollection AddBetterPE(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(services);
        ArgumentNullException.ThrowIfNull(configuration);

        // Configuration
        services.Configure<BetterPEOptions>(
            configuration.GetSection(BetterPEOptions.SectionName));

        // Services
        services.AddSingleton<IImageBuilderService, ImageBuilderService>();
        services.AddSingleton<IDriverIntegrationService, DriverIntegrationService>();
        services.AddSingleton<ICustomizationService, CustomizationService>();
        services.AddSingleton<IBootConfigService, BootConfigService>();
        services.AddSingleton<IRecoveryService, RecoveryService>();
        services.AddSingleton<IDeploymentService, DeploymentService>();

        // ViewModels
        services.AddTransient<BetterPEMainViewModel>();
        services.AddTransient<ImageBuilderViewModel>();
        services.AddTransient<DriverManagerViewModel>();
        services.AddTransient<CustomizationViewModel>();
        services.AddTransient<BootConfigViewModel>();
        services.AddTransient<RecoveryViewModel>();
        services.AddTransient<DeploymentViewModel>();

        // TUI
        services.AddSingleton<ITuiRenderer, ConsoleTuiRenderer>();
        services.AddSingleton<TuiAdapter>();

        return services;
    }
}
