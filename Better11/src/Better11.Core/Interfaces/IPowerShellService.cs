// ============================================================================
// File: src/Better11.Core/Interfaces/IPowerShellService.cs
// Better11 System Enhancement Suite — Canonical PowerShell Service Interface
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;

namespace Better11.Core.Interfaces
{
    /// <summary>
    /// Output model for PowerShell script execution results.
    /// </summary>
    public sealed class PowerShellOutput
    {
        /// <summary>Gets the standard output lines.</summary>
        public IReadOnlyList<string> Output { get; init; } = Array.Empty<string>();

        /// <summary>Gets the error output lines.</summary>
        public IReadOnlyList<string> Errors { get; init; } = Array.Empty<string>();

        /// <summary>Gets the warning output lines.</summary>
        public IReadOnlyList<string> Warnings { get; init; } = Array.Empty<string>();

        /// <summary>Gets the verbose output lines.</summary>
        public IReadOnlyList<string> Verbose { get; init; } = Array.Empty<string>();

        /// <summary>Gets a value indicating whether there were errors.</summary>
        public bool HasErrors => Errors.Count > 0;

        /// <summary>Gets the first output line or empty string.</summary>
        public string FirstOutput => Output.Count > 0 ? Output[0] : string.Empty;

        /// <summary>Gets the combined error message.</summary>
        public string ErrorMessage => string.Join(Environment.NewLine, Errors);

        /// <summary>Gets the execution duration.</summary>
        public TimeSpan Duration { get; init; }
    }

    /// <summary>
    /// Defines the contract for executing PowerShell commands and scripts.
    /// Thread-safe. All methods support cancellation.
    /// </summary>
    public interface IPowerShellService : IAsyncDisposable, IDisposable
    {
        /// <summary>
        /// Invokes a PowerShell command and deserializes the result to a single object.
        /// </summary>
        /// <typeparam name="T">The target deserialization type.</typeparam>
        /// <param name="moduleName">The module containing the command.</param>
        /// <param name="commandName">The command to invoke.</param>
        /// <param name="parameters">Optional parameters.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A result containing the deserialized object.</returns>
        Task<Result<T>> InvokeCommandAsync<T>(
            string moduleName,
            string commandName,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Invokes a PowerShell command and deserializes results to a list.
        /// </summary>
        /// <typeparam name="T">The target deserialization type.</typeparam>
        /// <param name="moduleName">The module containing the command.</param>
        /// <param name="commandName">The command to invoke.</param>
        /// <param name="parameters">Optional parameters.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A result containing the deserialized list.</returns>
        Task<Result<IReadOnlyList<T>>> InvokeCommandListAsync<T>(
            string moduleName,
            string commandName,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Invokes a PowerShell command that returns no value.
        /// </summary>
        /// <param name="moduleName">The module containing the command.</param>
        /// <param name="commandName">The command to invoke.</param>
        /// <param name="parameters">Optional parameters.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A result indicating success or failure.</returns>
        Task<Result> InvokeCommandVoidAsync(
            string moduleName,
            string commandName,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Executes a raw PowerShell script.
        /// </summary>
        /// <param name="script">The script to execute.</param>
        /// <param name="parameters">Optional script parameters.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A result containing the script output.</returns>
        Task<Result<PowerShellOutput>> ExecuteScriptAsync(
            string script,
            IDictionary<string, object>? parameters = null,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Tests whether a PowerShell module is available.
        /// </summary>
        /// <param name="moduleName">The module to check.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>True if the module is importable.</returns>
        Task<bool> TestModuleAvailableAsync(
            string moduleName,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Gets diagnostic information about the PowerShell service.
        /// </summary>
        /// <returns>Diagnostic key-value pairs.</returns>
        IReadOnlyDictionary<string, string> GetDiagnostics();
    }
}
