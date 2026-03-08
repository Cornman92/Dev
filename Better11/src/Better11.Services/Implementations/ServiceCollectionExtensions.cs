using Better11.Core.Interfaces;
using Better11.Services.PowerShell;
using Microsoft.Extensions.DependencyInjection;

namespace Better11.Services.Implementations;

/// <summary>
/// Provides dependency injection registration helpers for Better11 services.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Registers the Better11 service implementations required by the application.
    /// </summary>
    /// <param name="services">The service collection to populate.</param>
    /// <returns>The same service collection for chaining.</returns>
    public static IServiceCollection AddBetter11Services(this IServiceCollection services)
    {
        // Core infrastructure
        services.AddSingleton<IPowerShellService, PowerShellService>();

        return services;
    }
}
