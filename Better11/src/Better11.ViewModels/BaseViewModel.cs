// Copyright (c) 2026 Better11. All rights reserved.

namespace Better11.ViewModels;

using System.Runtime.CompilerServices;
using Better11.Core.Common;
using CommunityToolkit.Mvvm.ComponentModel;
using Microsoft.Extensions.Logging;

/// <summary>
/// Base class for all Better11 ViewModels. Provides loading state management,
/// error handling, async safety, and UI thread dispatching.
/// </summary>
public abstract partial class BaseViewModel : ObservableObject, IDisposable
{
    private readonly ILogger _logger;
    private CancellationTokenSource? _viewCts;
    private bool _disposed;
    private int _busyCount;

    /// <summary>
    /// Initializes a new instance of the <see cref="BaseViewModel"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    protected BaseViewModel(ILogger logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>Gets the logger instance.</summary>
    protected ILogger Logger => _logger;

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
    /// Cleans up resources when the view is unloaded.
    /// </summary>
    public virtual void Cleanup()
    {
        _viewCts?.Cancel();
        _viewCts?.Dispose();
        _viewCts = null;
    }

    /// <summary>
    /// Performs application-defined tasks associated with freeing, releasing, or resetting unmanaged resources.
    /// </summary>
    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    /// <summary>
    /// Releases unmanaged and - optionally - managed resources.
    /// </summary>
    /// <param name="disposing"><c>true</c> to release both managed and unmanaged resources; <c>false</c> to release only unmanaged resources.</param>
    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed)
        {
            if (disposing)
            {
                Cleanup();
            }

            _disposed = true;
        }
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
        _busyCount++;
        if (_busyCount == 1)
        {
            IsBusy = true;
            LoadingMessage = loadingMessage;
            ErrorMessage = string.Empty;
            SuccessMessage = string.Empty;
        }

        try
        {
            await operation(cancellationToken).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            LogOperationCancelled(_logger, callerName, null);
        }
        catch (Exception ex)
        {
            LogOperationError(_logger, callerName, ex.Message, ex);
            ErrorMessage = ex.Message;
        }
        finally
        {
            _busyCount--;
            if (_busyCount == 0)
            {
                IsBusy = false;
                LoadingMessage = string.Empty;
            }
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

    /// <summary>
    /// Sets the error message from a failed result.
    /// </summary>
    /// <param name="result">The result to check.</param>
    protected void SetErrorFromResult(Result result)
    {
        if (result != null && result.IsFailure)
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
        if (result != null && result.IsFailure)
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
    /// Sets an error message.
    /// </summary>
    /// <param name="message">The error message.</param>
    protected void SetError(string message)
    {
        SuccessMessage = string.Empty;
        ErrorMessage = message;
    }

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

    [LoggerMessage(EventId = 1, Level = LogLevel.Warning, Message = "SafeExecuteAsync skipped — already busy. Caller: {callerName}")]
    static partial void LogSkippedExecution(ILogger logger, string callerName);

    [LoggerMessage(EventId = 2, Level = LogLevel.Information, Message = "Operation cancelled in {callerName}")]
    static partial void LogOperationCancelled(ILogger logger, string callerName, Exception? ex);

    [LoggerMessage(EventId = 3, Level = LogLevel.Error, Message = "Error in {callerName}: {message}")]
    static partial void LogOperationError(ILogger logger, string callerName, string message, Exception ex);
}
