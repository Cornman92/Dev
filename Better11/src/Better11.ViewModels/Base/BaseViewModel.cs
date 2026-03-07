// ============================================================================
// File: src/Better11.ViewModels/Base/BaseViewModel.cs
// Better11 System Enhancement Suite — Canonical ViewModel Base Class
// Copyright (c) 2026 Better11. All rights reserved.
//
// THIS IS THE ONLY ViewModel base class in the codebase.
// All ViewModels must inherit from this class.
// ============================================================================

using System.Runtime.CompilerServices;
using Better11.Core.Common;
using CommunityToolkit.Mvvm.ComponentModel;
using Microsoft.Extensions.Logging;

namespace Better11.ViewModels.Base
{
    /// <summary>
    /// Base class for all Better11 ViewModels. Provides loading state management,
    /// error handling, async safety, and UI thread dispatching.
    /// </summary>
    public abstract partial class BaseViewModel : ObservableObject
    {
        private readonly ILogger _logger;
        private CancellationTokenSource? _viewCts;

        /// <summary>
        /// Initializes a new instance of the <see cref="BaseViewModel"/> class.
        /// </summary>
        /// <param name="logger">The logger instance.</param>
        protected BaseViewModel(ILogger logger)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        // ====================================================================
        // Observable Properties
        // ====================================================================

        /// <summary>Gets or sets a value indicating whether data is loading.</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(IsNotBusy))]
        private bool _isBusy;

        /// <summary>Gets a value indicating whether the ViewModel is not busy.</summary>
        public bool IsNotBusy => !IsBusy;

        /// <summary>Gets or sets the loading message.</summary>
        [ObservableProperty]
        private string _loadingMessage = string.Empty;

        /// <summary>Gets or sets the error message.</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(HasError))]
        private string _errorMessage = string.Empty;

        /// <summary>Gets a value indicating whether there is an error.</summary>
        public bool HasError => !string.IsNullOrEmpty(ErrorMessage);

        /// <summary>Gets or sets the success message.</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(HasSuccess))]
        private string _successMessage = string.Empty;

        /// <summary>Gets a value indicating whether there is a success message.</summary>
        public bool HasSuccess => !string.IsNullOrEmpty(SuccessMessage);

        /// <summary>Gets or sets a value indicating whether the ViewModel is initialized.</summary>
        [ObservableProperty]
        private bool _isInitialized;

        /// <summary>Gets or sets the page title.</summary>
        [ObservableProperty]
        private string _pageTitle = string.Empty;

        // ====================================================================
        // Lifecycle
        // ====================================================================

        /// <summary>
        /// Initializes the ViewModel. Call once when the view is first loaded.
        /// </summary>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A task representing the initialization.</returns>
        public async Task InitializeAsync(CancellationToken cancellationToken = default)
        {
            if (IsInitialized)
            {
                return;
            }

            _viewCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);

            await SafeExecuteAsync(
                async ct =>
                {
                    await OnInitializeAsync(ct).ConfigureAwait(false);
                    IsInitialized = true;
                },
                "Initializing...",
                _viewCts.Token).ConfigureAwait(false);
        }

        /// <summary>
        /// Override to perform initialization logic.
        /// </summary>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>A task representing the initialization.</returns>
        protected virtual Task OnInitializeAsync(CancellationToken cancellationToken = default)
        {
            return Task.CompletedTask;
        }

        /// <summary>
        /// Cleans up resources when the view is unloaded.
        /// </summary>
        public virtual void Cleanup()
        {
            _viewCts?.Cancel();
            _viewCts?.Dispose();
            _viewCts = null;
        }

        // ====================================================================
        // Safe Execution
        // ====================================================================

        /// <summary>
        /// Executes an async operation with automatic loading state and error handling.
        /// </summary>
        /// <param name="operation">The operation to execute.</param>
        /// <param name="loadingMessage">The loading message to display.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <param name="callerName">The calling method name (auto-populated).</param>
        /// <returns>A task representing the operation.</returns>
        protected async Task SafeExecuteAsync(
            Func<CancellationToken, Task> operation,
            string loadingMessage = "Working...",
            CancellationToken cancellationToken = default,
            [CallerMemberName] string callerName = "")
        {
            if (IsBusy)
            {
                _logger.LogWarning(
                    "SafeExecuteAsync skipped — already busy. Caller: {Caller}",
                    callerName);
                return;
            }

            try
            {
                IsBusy = true;
                LoadingMessage = loadingMessage;
                ErrorMessage = string.Empty;
                SuccessMessage = string.Empty;

                await operation(cancellationToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation(
                    "Operation cancelled in {Caller}", callerName);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex, "Error in {Caller}: {Message}", callerName, ex.Message);
                ErrorMessage = ex.Message;
            }
            finally
            {
                IsBusy = false;
                LoadingMessage = string.Empty;
            }
        }

        /// <summary>
        /// Executes an async operation that returns a value.
        /// </summary>
        /// <typeparam name="T">The return type.</typeparam>
        /// <param name="operation">The operation to execute.</param>
        /// <param name="loadingMessage">The loading message.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <param name="callerName">The calling method name.</param>
        /// <returns>The result, or default on failure.</returns>
        protected async Task<T?> SafeExecuteAsync<T>(
            Func<CancellationToken, Task<T>> operation,
            string loadingMessage = "Working...",
            CancellationToken cancellationToken = default,
            [CallerMemberName] string callerName = "")
        {
            T? result = default;

            await SafeExecuteAsync(
                async ct =>
                {
                    result = await operation(ct).ConfigureAwait(false);
                },
                loadingMessage,
                cancellationToken,
                callerName).ConfigureAwait(false);

            return result;
        }

        // ====================================================================
        // Result Helpers
        // ====================================================================

        /// <summary>
        /// Sets the error message from a failed result.
        /// </summary>
        /// <param name="result">The result to check.</param>
        protected void SetErrorFromResult(Result result)
        {
            if (result.IsFailure)
            {
                ErrorMessage = result.Error.Message;
            }
        }

        /// <summary>
        /// Sets the error message from a failed generic result.
        /// </summary>
        /// <typeparam name="T">The result value type.</typeparam>
        /// <param name="result">The result to check.</param>
        protected void SetErrorFromResult<T>(Result<T> result)
        {
            if (result.IsFailure)
            {
                ErrorMessage = result.Error.Message;
            }
        }

        /// <summary>
        /// Sets a success message.
        /// </summary>
        /// <param name="message">The success message.</param>
        protected void SetSuccess(string message)
        {
            ErrorMessage = string.Empty;
            SuccessMessage = message;
        }

        /// <summary>
        /// Sets an error message (e.g. for validation).
        /// </summary>
        /// <param name="message">The error message.</param>
        protected void SetError(string message)
        {
            ErrorMessage = message;
        }

        // ====================================================================
        // UI Thread Helpers
        // ====================================================================

        /// <summary>
        /// Dispatches an action to the UI thread via SynchronizationContext.
        /// </summary>
        /// <param name="action">The action to dispatch.</param>
        protected static void RunOnUIThread(Action action)
        {
            var context = SynchronizationContext.Current;
            if (context is not null)
            {
                context.Post(_ => action(), null);
            }
            else
            {
                action();
            }
        }
    }
}
