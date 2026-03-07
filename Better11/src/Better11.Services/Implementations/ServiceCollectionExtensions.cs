using Better11.Core.Interfaces;
using Better11.Services.PowerShell;
using Microsoft.Extensions.DependencyInjection;

namespace Better11.Services.Implementations;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddBetter11Services(this IServiceCollection services)
    {
        // Core infrastructure
        services.AddSingleton<IPowerShellService, PowerShellService>();

        return services;
    }
}
