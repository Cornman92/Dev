// ============================================================================
// File: src/Better11.Services/PowerShell/PowerShellService.cs
// Better11 System Enhancement Suite - Canonical PowerShell Service
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using System.Collections.Concurrent;
using System.Diagnostics;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using Better11.Core.Common;
using Better11.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Better11.Services.PowerShell
{
    /// <summary>
    /// RunspacePool-based PowerShell service. Thread-safe, concurrent, cancellation-aware.
    /// </summary>
    public sealed class PowerShellService : IPowerShellService
    {
        private readonly ILogger<PowerShellService> _logger;
        private readonly RunspacePool _runspacePool;
        private readonly ConcurrentDictionary<string, bool> _importedModules = new();
        private readonly string _modulesPath;
        private readonly int _commandTimeoutSeconds;
        private bool _disposed;
        private long _totalInvocations;
        private long _failedInvocations;

        /// <summary>
        /// Initializes a new instance of the <see cref="PowerShellService"/> class.
        /// </summary>
        /// <param name="logger">The logger instance.</param>
        /// <param name="modulesPath">Path to PowerShell modules.</param>
        /// <param name="minRunspaces">Minimum pool size.</param>
        /// <param name="maxRunspaces">Maximum pool size.</param>
        /// <param name="commandTimeoutSeconds">Default command timeout.</param>
        public PowerShellService(
            ILogger<PowerShellService> logger,
            string? modulesPath = null,
            int minRunspaces = 1,
            int maxRunspaces = 5,
            int commandTimeoutSeconds = 120)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _modulesPath = modulesPath ?? System.IO.Path.Combine(
                AppContext.BaseDirectory, "modules");
            _commandTimeoutSeconds = commandTimeoutSeconds;

            var iss = InitialSessionState.CreateDefault2();
            iss.ExecutionPolicy = Microsoft.PowerShell.ExecutionPolicy.RemoteSigned;

            _runspacePool = RunspaceFactory.CreateRunspacePool(iss);
            _runspacePool.Open();

            _logger.LogInformation(
                "PowerShellService initialized. Pool: {Min}-{Max}, Modules: {Path}",
                minRunspaces, maxRunspaces, _modulesPath);
        }

        /// <inheritdoc/>
        public async Task<Result<T>> InvokeCommandAsync<T>(
            string moduleName,
            string commandName,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(moduleName);
            ArgumentNullException.ThrowIfNull(commandName);

            Interlocked.Increment(ref _totalInvocations);

            try
            {
                await EnsureModuleImportedAsync(moduleName, cancellationToken)
                    .ConfigureAwait(false);

                using var ps = System.Management.Automation.PowerShell.Create();
                ps.RunspacePool = _runspacePool;
                ps.AddCommand(commandName);

                if (parameters is not null)
                {
                    foreach (var kvp in parameters)
                    {
                        ps.AddParameter(kvp.Key, kvp.Value);
                    }
                }

                var sw = Stopwatch.StartNew();
                using var cts = CancellationTokenSource
                    .CreateLinkedTokenSource(cancellationToken);
                cts.CancelAfter(TimeSpan.FromSeconds(_commandTimeoutSeconds));

                var results = await Task.Run(
                    () => ps.Invoke(),
                    cts.Token).ConfigureAwait(false);

                sw.Stop();
                _logger.LogDebug(
                    "Command {Module}\\{Command} completed in {Ms}ms, {Count} results",
                    moduleName, commandName, sw.ElapsedMilliseconds, results.Count);

                if (ps.HadErrors)
                {
                    var errors = string.Join("; ",
                        ps.Streams.Error.Select(e => e.ToString()));
                    _logger.LogWarning("PS errors for {Command}: {Errors}",
                        commandName, errors);
                    Interlocked.Increment(ref _failedInvocations);
                    return Result<T>.Failure(ErrorCodes.PowerShell, errors);
                }

                if (results.Count == 0)
                {
                    return Result<T>.Failure(
                        ErrorCodes.NotFound,
                        $"Command {commandName} returned no results.");
                }

                var value = DeserializePSObject<T>(results[0]);
                return Result<T>.Success(value);
            }
            catch (OperationCanceledException)
            {
                _logger.LogWarning("Command {Command} was cancelled.", commandName);
                Interlocked.Increment(ref _failedInvocations);
                return Result<T>.Failure(ErrorCodes.Cancelled, "Operation was cancelled.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error invoking {Module}\\{Command}",
                    moduleName, commandName);
                Interlocked.Increment(ref _failedInvocations);
                return Result<T>.Failure(ex);
            }
        }

        /// <inheritdoc/>
        public async Task<Result<IReadOnlyList<T>>> InvokeCommandListAsync<T>(
            string moduleName,
            string commandName,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(moduleName);
            ArgumentNullException.ThrowIfNull(commandName);

            Interlocked.Increment(ref _totalInvocations);

            try
            {
                await EnsureModuleImportedAsync(moduleName, cancellationToken)
                    .ConfigureAwait(false);

                using var ps = System.Management.Automation.PowerShell.Create();
                ps.RunspacePool = _runspacePool;
                ps.AddCommand(commandName);

                if (parameters is not null)
                {
                    foreach (var kvp in parameters)
                    {
                        ps.AddParameter(kvp.Key, kvp.Value);
                    }
                }

                var sw = Stopwatch.StartNew();
                using var cts = CancellationTokenSource
                    .CreateLinkedTokenSource(cancellationToken);
                cts.CancelAfter(TimeSpan.FromSeconds(_commandTimeoutSeconds));

                var results = await Task.Run(
                    () => ps.Invoke(),
                    cts.Token).ConfigureAwait(false);
                sw.Stop();

                _logger.LogDebug(
                    "ListCommand {Module}\\{Command} completed in {Ms}ms, {Count} items",
                    moduleName, commandName, sw.ElapsedMilliseconds, results.Count);

                if (ps.HadErrors)
                {
                    var errors = string.Join("; ",
                        ps.Streams.Error.Select(e => e.ToString()));
                    Interlocked.Increment(ref _failedInvocations);
                    return Result<IReadOnlyList<T>>.Failure(
                        ErrorCodes.PowerShell, errors);
                }

                var list = results.Select(DeserializePSObject<T>).ToList();
                return Result<IReadOnlyList<T>>.Success(list.AsReadOnly());
            }
            catch (OperationCanceledException)
            {
                Interlocked.Increment(ref _failedInvocations);
                return Result<IReadOnlyList<T>>.Failure(
                    ErrorCodes.Cancelled, "Operation was cancelled.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in list invoke {Module}\\{Command}",
                    moduleName, commandName);
                Interlocked.Increment(ref _failedInvocations);
                return Result<IReadOnlyList<T>>.Failure(ex);
            }
        }

        /// <inheritdoc/>
        public async Task<Result> InvokeCommandVoidAsync(
            string moduleName,
            string commandName,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default)
        {
            var result = await InvokeCommandAsync<object>(
                moduleName, commandName, parameters, cancellationToken)
                .ConfigureAwait(false);

            return result.IsSuccess ? Result.Success() : Result.Failure(result.Error!);
        }

        /// <inheritdoc/>
        public async Task<Result<PowerShellOutput>> ExecuteScriptAsync(
            string script,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(script);
            return await ExecuteScriptWithRetryAsync(script, parameters, maxRetries: 2, cancellationToken).ConfigureAwait(false);
        }

        /// <summary>
        /// Executes PowerShell script with retry logic for transient failures.
        /// </summary>
        private async Task<Result<PowerShellOutput>> ExecuteScriptWithRetryAsync(
            string script,
            IDictionary<string, object>? parameters,
            int maxRetries,
            CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref _totalInvocations);

            for (int attempt = 0; attempt <= maxRetries; attempt++)
            {
                try
                {
                    using var ps = System.Management.Automation.PowerShell.Create();
                    ps.RunspacePool = _runspacePool;
                    ps.AddScript(script);

                    if (parameters is not null)
                    {
                        foreach (var kvp in parameters)
                        {
                            ps.AddParameter(kvp.Key, kvp.Value);
                        }
                    }

                    var sw = Stopwatch.StartNew();
                    using var cts = CancellationTokenSource
                        .CreateLinkedTokenSource(cancellationToken);
                    cts.CancelAfter(TimeSpan.FromSeconds(_commandTimeoutSeconds));

                    var results = await Task.Run(
                        () => ps.Invoke(),
                        cts.Token).ConfigureAwait(false);
                    sw.Stop();

                    var output = new PowerShellOutput
                    {
                        Output = results.Select(r => r?.ToString() ?? string.Empty).ToList(),
                        Errors = ps.Streams.Error.Select(e => e.ToString()).ToList(),
                        Warnings = ps.Streams.Warning.Select(w => w.ToString()).ToList(),
                        Verbose = ps.Streams.Verbose.Select(v => v.ToString()).ToList(),
                        Duration = sw.Elapsed,
                    };

                    if (ps.HadErrors)
                    {
                        Interlocked.Increment(ref _failedInvocations);
                        return Result<PowerShellOutput>.Failure(
                            ErrorCodes.PowerShell, output.ErrorMessage);
                    }

                    return Result<PowerShellOutput>.Success(output);
                }
                catch (OperationCanceledException)
                {
                    Interlocked.Increment(ref _failedInvocations);
                    return Result<PowerShellOutput>.Failure(
                        ErrorCodes.Cancelled, "Script execution was cancelled.");
                }
                catch (Exception ex) when (attempt < maxRetries && IsTransientError(ex))
                {
                    _logger.LogWarning(
                        ex,
                        "Transient error executing script (attempt {Attempt}/{MaxRetries}), retrying...",
                        attempt + 1, maxRetries + 1);

                    // Exponential backoff with jitter
                    var delay = TimeSpan.FromMilliseconds(
                        Math.Min(1000 * Math.Pow(2, attempt), 5000) +
                        Random.Shared.Next(0, 500));

                    await Task.Delay(delay, cancellationToken).ConfigureAwait(false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error executing script");
                    Interlocked.Increment(ref _failedInvocations);
                    return Result<PowerShellOutput>.Failure(ex);
                }
            }

            // This should not be reached, but just in case
            return Result<PowerShellOutput>.Failure(
                ErrorCodes.PowerShell, "All retry attempts failed.");
        }

        /// <summary>
        /// Determines if an exception is transient and worth retrying.
        /// </summary>
        private static bool IsTransientError(Exception ex)
        {
            return ex is TimeoutException ||
                   ex is System.Management.Automation.PSInvalidOperationException ||
                   (ex.Message.Contains("timeout", StringComparison.OrdinalIgnoreCase) &&
                    !ex.Message.Contains("command timeout", StringComparison.OrdinalIgnoreCase));
        }

        /// <inheritdoc/>
        public async Task<bool> TestModuleAvailableAsync(
            string moduleName,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(moduleName);
            if (string.IsNullOrWhiteSpace(moduleName))
            {
                throw new ArgumentException("Module name cannot be empty or whitespace.", nameof(moduleName));
            }

            try
            {
                var script = $"Get-Module -ListAvailable -Name '{moduleName}' | Select-Object -First 1";
                var result = await ExecuteScriptAsync(script, cancellationToken: cancellationToken)
                    .ConfigureAwait(false);
                return result.IsSuccess && result.Value.Output.Count > 0;
            }
            catch
            {
                return false;
            }
        }

        /// <inheritdoc/>
        public IReadOnlyDictionary<string, string> GetDiagnostics()
        {
            return new Dictionary<string, string>
            {
                ["PoolState"] = _runspacePool.RunspacePoolStateInfo.State.ToString(),
                ["ModulesPath"] = _modulesPath,
                ["ImportedModules"] = string.Join(", ", _importedModules.Keys),
                ["TotalInvocations"] = Interlocked.Read(ref _totalInvocations).ToString(),
                ["FailedInvocations"] = Interlocked.Read(ref _failedInvocations).ToString(),
                ["TimeoutSeconds"] = _commandTimeoutSeconds.ToString(),
            };
        }

        private async Task EnsureModuleImportedAsync(
            string moduleName, CancellationToken ct)
        {
            if (_importedModules.ContainsKey(moduleName))
            {
                return;
            }

            var modulePath = System.IO.Path.Combine(
                _modulesPath, moduleName, $"{moduleName}.psm1");

            if (System.IO.File.Exists(modulePath))
            {
                var script = $"Import-Module '{modulePath}' -Force -DisableNameChecking";
                var result = await ExecuteScriptAsync(script, cancellationToken: ct)
                    .ConfigureAwait(false);

                if (result.IsSuccess)
                {
                    _importedModules.TryAdd(moduleName, true);
                    _logger.LogInformation("Imported module: {Module}", moduleName);
                }
                else
                {
                    _logger.LogWarning(
                        "Failed to import module {Module}: {Error}",
                        moduleName, result.Error?.Message);
                }
            }
            else
            {
                _logger.LogDebug(
                    "Module file not found at {Path}, assuming system module",
                    modulePath);
                _importedModules.TryAdd(moduleName, true);
            }
        }

        private static T DeserializePSObject<T>(PSObject psObj)
        {
            if (psObj.BaseObject is T direct)
            {
                return direct;
            }

            var target = Activator.CreateInstance<T>();
            var props = typeof(T).GetProperties(
                BindingFlags.Public | BindingFlags.Instance);

            foreach (var prop in props)
            {
                if (!prop.CanWrite)
                {
                    continue;
                }

                var psProp = psObj.Properties.FirstOrDefault(
                    p => string.Equals(p.Name, prop.Name,
                        StringComparison.OrdinalIgnoreCase));

                if (psProp?.Value is not null)
                {
                    try
                    {
                        var converted = Convert.ChangeType(
                            psProp.Value, prop.PropertyType);
                        prop.SetValue(target, converted);
                    }
                    catch
                    {
                        // Skip properties that cannot be converted
                    }
                }
            }

            return target;
        }

        /// <inheritdoc/>
        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            _runspacePool.Close();
            _runspacePool.Dispose();
            _disposed = true;
        }

        /// <inheritdoc/>
        public ValueTask DisposeAsync()
        {
            Dispose();
            return ValueTask.CompletedTask;
        }
    }
}
