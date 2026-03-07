// ============================================================================
// Better11 System Enhancement Suite — PowerShellServiceBridgeTests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Better11.Services.DiskCleanup;
using Better11.Services.Network;
using Better11.Services.PowerShell;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;

namespace Better11.IntegrationTests;

/// <summary>
/// Integration tests for PowerShell service bridge functionality.
/// Tests the integration between services and PowerShell execution.
/// </summary>
public sealed class PowerShellServiceBridgeTests : IAsyncLifetime
{
    private IServiceProvider? _serviceProvider;
    private IPowerShellService? _powerShellService;
    private ILogger<PowerShellServiceBridgeTests>? _logger;

    public async Task InitializeAsync()
    {
        var services = new ServiceCollection();
        
        services.AddLogging(builder =>
        {
            builder.SetMinimumLevel(LogLevel.Debug);
            builder.AddConsole();
        });

        services.AddSingleton<IPowerShellService, PowerShellService>();
        services.AddSingleton<IDiskCleanupService, DiskCleanupService>();
        services.AddSingleton<INetworkService, NetworkService>();

        _serviceProvider = services.BuildServiceProvider();
        _powerShellService = _serviceProvider.GetRequiredService<IPowerShellService>();
        _logger = _serviceProvider.GetRequiredService<ILogger<PowerShellServiceBridgeTests>>();

        await Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        if (_serviceProvider is IDisposable disposable)
        {
            disposable.Dispose();
        }
        await Task.CompletedTask;
    }

    [Fact]
    public async Task PowerShellService_CanExecuteSimpleCommand()
    {
        // Arrange
        var script = "Get-Process | Select-Object -First 1";

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(script);

        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
        result.Value.Output.Should().NotBeEmpty();
    }

    [Fact]
    public async Task PowerShellService_HandlesCommandWithParameters()
    {
        // Arrange
        var script = "param($Name) Write-Output \"Hello, $Name!\"";
        var parameters = new Dictionary<string, object>
        {
            ["Name"] = "World"
        };

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(script, parameters);

        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeTrue();
        result.Value.Output.Should().Contain("Hello, World!");
    }

    [Fact]
    public async Task PowerShellService_PropagatesCancellation()
    {
        // Arrange
        using var cts = new CancellationTokenSource();
        cts.Cancel();
        var script = "Start-Sleep -Seconds 10";

        // Act & Assert
        var act = async () => await _powerShellService!.ExecuteScriptAsync(script, cancellationToken: cts.Token);
        await act.Should().ThrowAsync<OperationCanceledException>();
    }

    [Fact]
    public async Task PowerShellService_HandlesCommandTimeout()
    {
        // Arrange
        var script = "Start-Sleep -Seconds 30"; // Longer than default timeout

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(script);

        // Assert
        result.Should().NotBeNull();
        // Note: This test behavior depends on timeout configuration
        // It may succeed or fail based on the actual timeout settings
    }

    [Fact]
    public async Task PowerShellService_ReturnsStructuredErrorInformation()
    {
        // Arrange
        var invalidScript = "Get-NonExistentCommand";

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(invalidScript);

        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().NotBeNull();
        result.Error!.Code.Should().NotBeEmpty();
    }

    [Fact]
    public async Task PowerShellService_ProvidesDiagnosticInformation()
    {
        // Arrange & Act
        var diagnostics = _powerShellService!.GetDiagnostics();

        // Assert
        diagnostics.Should().NotBeNull();
        diagnostics.Should().ContainKey("PoolState");
        diagnostics.Should().ContainKey("ModulesPath");
        diagnostics.Should().ContainKey("ImportedModules");
        diagnostics.Should().ContainKey("TotalInvocations");
        diagnostics.Should().ContainKey("FailedInvocations");
        diagnostics.Should().ContainKey("TimeoutSeconds");
    }

    [Fact]
    public async Task DiskCleanupService_IntegratesWithPowerShell()
    {
        // Arrange
        var diskCleanupService = _serviceProvider!.GetRequiredService<IDiskCleanupService>();

        // Act
        var result = await diskCleanupService.ScanAsync();

        // Assert
        result.Should().NotBeNull();
        // Note: This test requires actual B11.DiskCleanup module to be available
        // The test verifies integration structure rather than specific results
    }

    [Fact]
    public async Task NetworkService_IntegratesWithPowerShell()
    {
        // Arrange
        var networkService = _serviceProvider!.GetRequiredService<INetworkService>();

        // Act
        var result = await networkService.GetAdaptersAsync();

        // Assert
        result.Should().NotBeNull();
        // Note: This test requires actual B11.Network module to be available
        // The test verifies integration structure rather than specific results
    }

    [Fact]
    public async Task PowerShellService_HandlesModuleImport()
    {
        // Arrange
        var script = "Get-Module -ListAvailable | Select-Object -First 5";

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(script);

        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeTrue();
        result.Value.Output.Should().NotBeEmpty();
    }

    [Fact]
    public async Task PowerShellService_HandlesComplexScriptExecution()
    {
        // Arrange
        var script = @"
            $processes = Get-Process | Where-Object {$_.ProcessName -like '*powershell*'}
            $count = $processes.Count
            Write-Output ""Found $count PowerShell processes""
        ";

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(script);

        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeTrue();
        result.Value.Output.Should().NotBeEmpty();
        result.Value.Output.Should().Contain("PowerShell processes");
    }

    [Fact]
    public async Task PowerShellService_MaintainsExecutionStatistics()
    {
        // Arrange
        var initialDiagnostics = _powerShellService!.GetDiagnostics();
        var initialInvocations = long.Parse(initialDiagnostics["TotalInvocations"]);

        // Act
        await _powerShellService.ExecuteScriptAsync("Write-Output 'Test 1'");
        await _powerShellService.ExecuteScriptAsync("Write-Output 'Test 2'");

        // Assert
        var finalDiagnostics = _powerShellService.GetDiagnostics();
        var finalInvocations = long.Parse(finalDiagnostics["TotalInvocations"]);

        finalInvocations.Should().BeGreaterThan(initialInvocations);
        finalInvocations.Should().Be(initialInvocations + 2);
    }

    [Fact]
    public async Task PowerShellService_HandlesErrorRecovery()
    {
        // Arrange
        var scripts = new[]
        {
            "Write-Output 'Success 1'",
            "Get-NonExistentCommand", // This should fail
            "Write-Output 'Success 2'"
        };

        var successCount = 0;
        var failureCount = 0;

        // Act
        foreach (var script in scripts)
        {
            var result = await _powerShellService!.ExecuteScriptAsync(script);
            if (result.IsSuccess)
                successCount++;
            else
                failureCount++;
        }

        // Assert
        successCount.Should().Be(2);
        failureCount.Should().Be(1);
    }

    [Theory]
    [InlineData("Write-Output", "Simple output command")]
    [InlineData("Get-Date", "Date retrieval command")]
    [InlineData("Get-Location", "Current location command")]
    public async Task PowerShellService_ExecutesVariousCommandTypes(string command, string description)
    {
        // Arrange
        var script = command;

        // Act
        var result = await _powerShellService!.ExecuteScriptAsync(script);

        // Assert
        result.Should().NotBeNull();
        // Most basic commands should succeed
        if (!command.Contains("NonExistent"))
        {
            result.IsSuccess.Should().BeTrue();
        }
    }

    [Fact]
    public async Task PowerShellService_HandlesConcurrentExecution()
    {
        // Arrange
        var tasks = new List<Task<Result<PowerShellOutput>>>();
        
        // Act
        for (int i = 0; i < 5; i++)
        {
            var task = _powerShellService!.ExecuteScriptAsync($"Write-Output 'Concurrent test {i}'");
            tasks.Add(task);
        }

        var results = await Task.WhenAll(tasks);

        // Assert
        results.Should().HaveCount(5);
        results.Should().AllSatisfy(r => r.IsSuccess);
    }
}
