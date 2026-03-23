// ============================================================================
// File: tests/Better11.Core.Tests/ResultTests.cs
// Better11 System Enhancement Suite - Result<T> Unit Tests
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.Core.Common;
using FluentAssertions;
using Xunit;

namespace Better11.Core.Tests
{
    /// <summary>
    /// Tests for <see cref="Result"/> and <see cref="Result{T}"/>.
    /// </summary>
    public sealed class ResultTests
    {
        [Fact]
        public void Success_ShouldBeSuccess()
        {
            var result = Result.Success();
            result.IsSuccess.Should().BeTrue();
            result.IsFailure.Should().BeFalse();
            result.Error.Should().BeNull();
        }

        [Fact]
        public void Failure_ShouldBeFailure()
        {
            var result = Result.Failure("something broke");
            result.IsSuccess.Should().BeFalse();
            result.IsFailure.Should().BeTrue();
            result.Error.Should().NotBeNull();
            result.Error!.Message.Should().Be("something broke");
        }

        [Fact]
        public void GenericSuccess_ShouldContainValue()
        {
            var result = Result<int>.Success(42);
            result.IsSuccess.Should().BeTrue();
            result.Value.Should().Be(42);
        }

        [Fact]
        public void GenericFailure_ShouldContainError()
        {
            var result = Result<int>.Failure("not found");
            result.IsFailure.Should().BeTrue();
            result.Error!.Message.Should().Be("not found");
        }

        [Fact]
        public void Map_OnSuccess_ShouldTransformValue()
        {
            var result = Result<int>.Success(10);
            var mapped = result.Map(x => x * 2);
            mapped.IsSuccess.Should().BeTrue();
            mapped.Value.Should().Be(20);
        }

        [Fact]
        public void Map_OnFailure_ShouldPropagateError()
        {
            var result = Result<int>.Failure("err");
            var mapped = result.Map(x => x * 2);
            mapped.IsFailure.Should().BeTrue();
        }

        [Fact]
        public void Bind_OnSuccess_ShouldChain()
        {
            var result = Result<int>.Success(5);
            var bound = result.Bind(x =>
                x > 0
                    ? Result<string>.Success($"positive: {x}")
                    : Result<string>.Failure("not positive"));
            bound.IsSuccess.Should().BeTrue();
            bound.Value.Should().Be("positive: 5");
        }

        [Fact]
        public void Bind_OnFailure_ShouldShortCircuit()
        {
            var result = Result<int>.Failure("initial error");
            var bound = result.Bind(x => Result<string>.Success(x.ToString()));
            bound.IsFailure.Should().BeTrue();
            bound.Error!.Message.Should().Be("initial error");
        }

        [Fact]
        public void Match_OnSuccess_ShouldCallSuccessFunc()
        {
            var result = Result<int>.Success(42);
            var matched = result.Match(
                v => $"got {v}",
                e => $"error: {e.Message}");
            matched.Should().Be("got 42");
        }

        [Fact]
        public void Match_OnFailure_ShouldCallFailureFunc()
        {
            var result = Result<int>.Failure("oops");
            var matched = result.Match(
                v => $"got {v}",
                e => $"error: {e.Message}");
            matched.Should().Be("error: oops");
        }

        [Fact]
        public void Ensure_WhenPredicateFails_ShouldReturnFailure()
        {
            var result = Result<int>.Success(-1);
            var ensured = result.Ensure(x => x >= 0, "must be non-negative");
            ensured.IsFailure.Should().BeTrue();
        }

        [Fact]
        public void Ensure_WhenPredicatePasses_ShouldReturnOriginal()
        {
            var result = Result<int>.Success(5);
            var ensured = result.Ensure(x => x >= 0, "must be non-negative");
            ensured.IsSuccess.Should().BeTrue();
            ensured.Value.Should().Be(5);
        }

        [Fact]
        public void Tap_OnSuccess_ShouldExecuteAction()
        {
            var called = false;
            var result = Result<int>.Success(1);
            result.Tap(_ => called = true);
            called.Should().BeTrue();
        }

        [Fact]
        public void Tap_OnFailure_ShouldNotExecuteAction()
        {
            var called = false;
            var result = Result<int>.Failure("err");
            result.Tap(_ => called = true);
            called.Should().BeFalse();
        }

        [Fact]
        public void ImplicitConversion_ShouldCreateSuccess()
        {
            Result<string> result = "hello";
            result.IsSuccess.Should().BeTrue();
            result.Value.Should().Be("hello");
        }

        [Fact]
        public void GetValueOrDefault_OnFailure_ShouldReturnFallback()
        {
            var result = Result<int>.Failure("err");
            result.GetValueOrDefault(99).Should().Be(99);
        }

        [Fact]
        public void GetValueOrDefault_OnSuccess_ShouldReturnValue()
        {
            var result = Result<int>.Success(42);
            result.GetValueOrDefault(99).Should().Be(42);
        }

        [Fact]
        public void Combine_AllSuccess_ShouldReturnSuccess()
        {
            var combined = Result.Combine(
                Result.Success(),
                Result.Success(),
                Result.Success());
            combined.IsSuccess.Should().BeTrue();
        }

        [Fact]
        public void Combine_AnyFailure_ShouldReturnFailure()
        {
            var combined = Result.Combine(
                Result.Success(),
                Result.Failure("fail1"),
                Result.Failure("fail2"));
            combined.IsFailure.Should().BeTrue();
            combined.Error!.Message.Should().Contain("fail1");
            combined.Error!.Message.Should().Contain("fail2");
        }

        [Fact]
        public void Warning_ShouldBeSuccessWithMessage()
        {
            var result = Result<int>.Warning(42, "might be stale");
            result.IsSuccess.Should().BeTrue();
            result.Value.Should().Be(42);
            result.Severity.Should().Be(ResultSeverity.Warning);
        }

        [Fact]
        public void FailureFromException_ShouldCaptureException()
        {
            var ex = new InvalidOperationException("bad state");
            var result = Result<int>.Failure(ex);
            result.IsFailure.Should().BeTrue();
            result.Error!.Exception.Should().BeSameAs(ex);
        }

        [Fact]
        public void ErrorInfo_ShouldHaveTimestamp()
        {
            var info = new ErrorInfo("CODE", "msg");
            info.Timestamp.Should().BeCloseTo(
                System.DateTimeOffset.UtcNow, System.TimeSpan.FromSeconds(5));
        }

        [Fact]
        public void ToResult_OnSuccess_ShouldReturnSuccess()
        {
            var generic = Result<int>.Success(42);
            var nonGeneric = generic.ToResult();
            nonGeneric.IsSuccess.Should().BeTrue();
        }

        [Fact]
        public void ToResult_OnFailure_ShouldReturnFailure()
        {
            var generic = Result<int>.Failure("err");
            var nonGeneric = generic.ToResult();
            nonGeneric.IsFailure.Should().BeTrue();
        }

        [Fact]
        public void ErrorCodes_ShouldHaveExpectedValues()
        {
            ErrorCodes.General.Should().Be("B11_GENERAL");
            ErrorCodes.PowerShell.Should().Be("B11_POWERSHELL");
            ErrorCodes.Cancelled.Should().Be("B11_CANCELLED");
            ErrorCodes.Validation.Should().Be("B11_VALIDATION");
        }

        [Fact]
        public void NonGenericWarning_ShouldBeSuccess()
        {
            var result = Result.Warning("watch out");
            result.IsSuccess.Should().BeTrue();
            result.Severity.Should().Be(ResultSeverity.Warning);
        }

        [Fact]
        public void NonGenericMatch_OnSuccess_ShouldCallOnSuccess()
        {
            var result = Result.Success();
            var output = result.Match(
                () => "ok",
                e => "fail");
            output.Should().Be("ok");
        }

        [Fact]
        public void NonGenericMatch_OnFailure_ShouldCallOnFailure()
        {
            var result = Result.Failure("err");
            var output = result.Match(
                () => "ok",
                e => $"fail: {e.Message}");
            output.Should().Be("fail: err");
        }

        [Fact]
        public void NonGenericTap_OnSuccess_ShouldExecute()
        {
            var called = false;
            Result.Success().Tap(() => called = true);
            called.Should().BeTrue();
        }

        [Fact]
        public void FailureWithCode_ShouldSetCode()
        {
            var result = Result<int>.Failure(ErrorCodes.NotFound, "not found");
            result.Error!.Code.Should().Be(ErrorCodes.NotFound);
        }

        [Fact]
        public void FailureWithErrorInfo_ShouldPreserveInfo()
        {
            var info = new ErrorInfo("CUSTOM", "custom msg");
            var result = Result<int>.Failure(info);
            result.Error.Should().BeSameAs(info);
        }

        [Fact]
        public void ToString_Success_ShouldContainValue()
        {
            Result<int>.Success(42).ToString().Should().Contain("42");
        }

        [Fact]
        public void ToString_Failure_ShouldContainError()
        {
            Result<int>.Failure("oops").ToString().Should().Contain("Failure");
        }
    }
}
