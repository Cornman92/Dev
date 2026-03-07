// ============================================================================
// File: src/Better11.Core/Common/Result.cs
// Better11 System Enhancement Suite — Canonical Result Pattern
// Copyright (c) 2026 Better11. All rights reserved.
//
// THIS IS THE ONLY Result IMPLEMENTATION IN THE CODEBASE.
// ============================================================================

using System.Diagnostics.CodeAnalysis;

namespace Better11.Core.Common
{
    /// <summary>
    /// Provides structured error information for failed operations.
    /// </summary>
    public sealed class ErrorInfo
    {
        /// <summary>Gets the error code.</summary>
        public string Code { get; }

        /// <summary>Gets the error message.</summary>
        public string Message { get; }

        /// <summary>Gets the exception that caused the error, if any.</summary>
        public Exception? Exception { get; }

        /// <summary>Gets the timestamp when the error occurred.</summary>
        public DateTimeOffset Timestamp { get; }

        /// <summary>Gets optional metadata associated with the error.</summary>
        public IReadOnlyDictionary<string, object> Metadata { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ErrorInfo"/> class.
        /// </summary>
        /// <param name="code">The error code.</param>
        /// <param name="message">The error message.</param>
        /// <param name="exception">The exception that caused the error.</param>
        /// <param name="metadata">Optional metadata.</param>
        public ErrorInfo(
            string code,
            string message,
            Exception? exception = null,
            IReadOnlyDictionary<string, object>? metadata = null)
        {
            Code = code ?? throw new ArgumentNullException(nameof(code));
            Message = message ?? throw new ArgumentNullException(nameof(message));
            Exception = exception;
            Timestamp = DateTimeOffset.UtcNow;
            Metadata = metadata ?? new Dictionary<string, object>();
        }

        /// <inheritdoc/>
        public override string ToString() =>
            Exception is not null
                ? $"[{Code}] {Message} — {Exception.Message}"
                : $"[{Code}] {Message}";
    }

    /// <summary>
    /// Severity levels for result outcomes.
    /// </summary>
    public enum ResultSeverity
    {
        /// <summary>No severity (success).</summary>
        None = 0,

        /// <summary>Informational message.</summary>
        Info = 1,

        /// <summary>Warning — operation succeeded with caveats.</summary>
        Warning = 2,

        /// <summary>Error — operation failed.</summary>
        Error = 3,

        /// <summary>Critical — operation failed with severe consequences.</summary>
        Critical = 4,
    }

    /// <summary>
    /// Non-generic result for void operations.
    /// </summary>
    public sealed class Result
    {
        /// <summary>Gets a value indicating whether the operation succeeded.</summary>
        [MemberNotNullWhen(false, nameof(Error))]
        public bool IsSuccess { get; }

        /// <summary>Gets a value indicating whether the operation failed.</summary>
        [MemberNotNullWhen(true, nameof(Error))]
        public bool IsFailure => !IsSuccess;

        /// <summary>Gets the error information, if any.</summary>
        public ErrorInfo? Error { get; }

        /// <summary>Gets the severity of the result.</summary>
        public ResultSeverity Severity { get; }

        private Result(bool isSuccess, ErrorInfo? error, ResultSeverity severity)
        {
            IsSuccess = isSuccess;
            Error = error;
            Severity = severity;
        }

        /// <summary>Creates a successful result.</summary>
        /// <returns>A successful <see cref="Result"/>.</returns>
        public static Result Success() => new(true, null, ResultSeverity.None);

        /// <summary>Creates a warning result (success with caveats).</summary>
        /// <param name="message">The warning message.</param>
        /// <returns>A warning <see cref="Result"/>.</returns>
        public static Result Warning(string message) =>
            new(true, new ErrorInfo(ErrorCodes.Warning, message), ResultSeverity.Warning);

        /// <summary>Creates a failed result.</summary>
        /// <param name="error">The error message.</param>
        /// <returns>A failed <see cref="Result"/>.</returns>
        public static Result Failure(string error) =>
            new(false, new ErrorInfo(ErrorCodes.General, error), ResultSeverity.Error);

        /// <summary>Creates a failed result with an error code.</summary>
        /// <param name="code">The error code.</param>
        /// <param name="error">The error message.</param>
        /// <returns>A failed <see cref="Result"/>.</returns>
        public static Result Failure(string code, string error) =>
            new(false, new ErrorInfo(code, error), ResultSeverity.Error);

        /// <summary>Creates a failed result from an exception.</summary>
        /// <param name="exception">The exception.</param>
        /// <returns>A failed <see cref="Result"/>.</returns>
        public static Result Failure(Exception exception) =>
            new(false, new ErrorInfo(ErrorCodes.Exception, exception.Message, exception), ResultSeverity.Error);

        /// <summary>Creates a failed result from an <see cref="ErrorInfo"/>.</summary>
        /// <param name="error">The error information.</param>
        /// <returns>A failed <see cref="Result"/>.</returns>
        public static Result Failure(ErrorInfo error) =>
            new(false, error, ResultSeverity.Error);

        /// <summary>Combines multiple results, returning failure if any failed.</summary>
        /// <param name="results">The results to combine.</param>
        /// <returns>A combined <see cref="Result"/>.</returns>
        public static Result Combine(params Result[] results)
        {
            var failures = results.Where(r => r.IsFailure).ToList();
            if (failures.Count == 0)
            {
                return Success();
            }

            var messages = string.Join("; ", failures.Select(f => f.Error!.Message));
            return Failure(ErrorCodes.Aggregate, messages);
        }

        /// <summary>Executes an action if the result is successful.</summary>
        /// <param name="action">The action to execute.</param>
        /// <returns>The current result.</returns>
        public Result Tap(Action action)
        {
            if (IsSuccess)
            {
                action();
            }

            return this;
        }

        /// <summary>Matches the result to a value.</summary>
        /// <typeparam name="TOut">The output type.</typeparam>
        /// <param name="onSuccess">Function to execute on success.</param>
        /// <param name="onFailure">Function to execute on failure.</param>
        /// <returns>The matched value.</returns>
        public TOut Match<TOut>(Func<TOut> onSuccess, Func<ErrorInfo, TOut> onFailure) =>
            IsSuccess ? onSuccess() : onFailure(Error!);

        /// <inheritdoc/>
        public override string ToString() =>
            IsSuccess ? "Result: Success" : $"Result: Failure — {Error}";
    }

    /// <summary>
    /// Generic result wrapping a value or error.
    /// </summary>
    /// <typeparam name="T">The type of the value.</typeparam>
    public sealed class Result<T>
    {
        /// <summary>Gets a value indicating whether the operation succeeded.</summary>
        [MemberNotNullWhen(true, nameof(Value))]
        [MemberNotNullWhen(false, nameof(Error))]
        public bool IsSuccess { get; }

        /// <summary>Gets a value indicating whether the operation failed.</summary>
        [MemberNotNullWhen(true, nameof(Error))]
        [MemberNotNullWhen(false, nameof(Value))]
        public bool IsFailure => !IsSuccess;

        /// <summary>Gets the value if successful.</summary>
        public T? Value { get; }

        /// <summary>Gets the error information if failed.</summary>
        public ErrorInfo? Error { get; }

        /// <summary>Gets the severity of the result.</summary>
        public ResultSeverity Severity { get; }

        private Result(bool isSuccess, T? value, ErrorInfo? error, ResultSeverity severity)
        {
            IsSuccess = isSuccess;
            Value = value;
            Error = error;
            Severity = severity;
        }

        /// <summary>Creates a successful result with a value.</summary>
        /// <param name="value">The value.</param>
        /// <returns>A successful result.</returns>
        public static Result<T> Success(T value) =>
            new(true, value, null, ResultSeverity.None);

        /// <summary>Creates a warning result (success with caveats).</summary>
        /// <param name="value">The value.</param>
        /// <param name="message">The warning message.</param>
        /// <returns>A warning result.</returns>
        public static Result<T> Warning(T value, string message) =>
            new(true, value, new ErrorInfo(ErrorCodes.Warning, message), ResultSeverity.Warning);

        /// <summary>Creates a failed result.</summary>
        /// <param name="error">The error message.</param>
        /// <returns>A failed result.</returns>
        public static Result<T> Failure(string error) =>
            new(false, default, new ErrorInfo(ErrorCodes.General, error), ResultSeverity.Error);

        /// <summary>Creates a failed result with an error code.</summary>
        /// <param name="code">The error code.</param>
        /// <param name="error">The error message.</param>
        /// <returns>A failed result.</returns>
        public static Result<T> Failure(string code, string error) =>
            new(false, default, new ErrorInfo(code, error), ResultSeverity.Error);

        /// <summary>Creates a failed result from an exception.</summary>
        /// <param name="exception">The exception.</param>
        /// <returns>A failed result.</returns>
        public static Result<T> Failure(Exception exception) =>
            new(false, default, new ErrorInfo(ErrorCodes.Exception, exception.Message, exception), ResultSeverity.Error);

        /// <summary>Creates a failed result from an <see cref="ErrorInfo"/>.</summary>
        /// <param name="error">The error information.</param>
        /// <returns>A failed result.</returns>
        public static Result<T> Failure(ErrorInfo error) =>
            new(false, default, error, ResultSeverity.Error);

        /// <summary>Implicit conversion from value to success result.</summary>
        /// <param name="value">The value.</param>
        public static implicit operator Result<T>(T value) => Success(value);

        /// <summary>Maps the value to a new type.</summary>
        /// <typeparam name="TOut">The output type.</typeparam>
        /// <param name="mapper">The mapping function.</param>
        /// <returns>A mapped result.</returns>
        public Result<TOut> Map<TOut>(Func<T, TOut> mapper) =>
            IsSuccess
                ? Result<TOut>.Success(mapper(Value))
                : Result<TOut>.Failure(Error!);

        /// <summary>Flat-maps the value to a new result.</summary>
        /// <typeparam name="TOut">The output type.</typeparam>
        /// <param name="binder">The binding function.</param>
        /// <returns>A bound result.</returns>
        public Result<TOut> Bind<TOut>(Func<T, Result<TOut>> binder) =>
            IsSuccess ? binder(Value) : Result<TOut>.Failure(Error!);

        /// <summary>Matches the result to a value.</summary>
        /// <typeparam name="TOut">The output type.</typeparam>
        /// <param name="onSuccess">Function to execute on success.</param>
        /// <param name="onFailure">Function to execute on failure.</param>
        /// <returns>The matched value.</returns>
        public TOut Match<TOut>(Func<T, TOut> onSuccess, Func<ErrorInfo, TOut> onFailure) =>
            IsSuccess ? onSuccess(Value) : onFailure(Error!);

        /// <summary>Executes an action on the value if successful.</summary>
        /// <param name="action">The action.</param>
        /// <returns>The current result.</returns>
        public Result<T> Tap(Action<T> action)
        {
            if (IsSuccess)
            {
                action(Value);
            }

            return this;
        }

        /// <summary>Validates the value against a predicate.</summary>
        /// <param name="predicate">The validation predicate.</param>
        /// <param name="error">The error message if validation fails.</param>
        /// <returns>The validated result.</returns>
        public Result<T> Ensure(Func<T, bool> predicate, string error) =>
            IsSuccess && !predicate(Value)
                ? Failure(ErrorCodes.Validation, error)
                : this;

        /// <summary>Returns the value or a default.</summary>
        /// <param name="fallback">The fallback value.</param>
        /// <returns>The value or fallback.</returns>
        public T GetValueOrDefault(T fallback) =>
            IsSuccess ? Value : fallback;

        /// <summary>Converts to a non-generic result.</summary>
        /// <returns>A non-generic result.</returns>
        public Result ToResult() =>
            IsSuccess ? Result.Success() : Result.Failure(Error!);

        /// <inheritdoc/>
        public override string ToString() =>
            IsSuccess ? $"Result<{typeof(T).Name}>: {Value}" : $"Result<{typeof(T).Name}>: Failure — {Error}";
    }

    /// <summary>
    /// Well-known error codes used throughout Better11.
    /// </summary>
    public static class ErrorCodes
    {
        /// <summary>General error.</summary>
        public const string General = "B11_GENERAL";

        /// <summary>Exception-based error.</summary>
        public const string Exception = "B11_EXCEPTION";

        /// <summary>Validation error.</summary>
        public const string Validation = "B11_VALIDATION";

        /// <summary>Warning (non-fatal).</summary>
        public const string Warning = "B11_WARNING";

        /// <summary>Aggregate of multiple errors.</summary>
        public const string Aggregate = "B11_AGGREGATE";

        /// <summary>Operation was cancelled.</summary>
        public const string Cancelled = "B11_CANCELLED";

        /// <summary>Operation timed out.</summary>
        public const string Timeout = "B11_TIMEOUT";

        /// <summary>Resource not found.</summary>
        public const string NotFound = "B11_NOT_FOUND";

        /// <summary>Access denied.</summary>
        public const string AccessDenied = "B11_ACCESS_DENIED";

        /// <summary>PowerShell execution error.</summary>
        public const string PowerShell = "B11_POWERSHELL";

        /// <summary>Configuration error.</summary>
        public const string Configuration = "B11_CONFIG";
    }
}
