// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.Core;

using Better11.Core.Common;
using FluentAssertions;
using Xunit;

public class ResultTests
{
    [Fact]
    public void SuccessShouldCreateSuccessResult()
    {
        var result = Result.Success();
        result.IsSuccess.Should().BeTrue();
        result.IsFailure.Should().BeFalse();
        result.Error.Should().BeNull();
    }

    [Fact]
    public void FailureShouldCreateFailureResult()
    {
        var result = Result.Failure("error");
        result.IsSuccess.Should().BeFalse();
        result.IsFailure.Should().BeTrue();
        result.Error.Should().NotBeNull();
        result.Error!.Message.Should().Be("error");
    }

    [Fact]
    public void SuccessGenericShouldHaveValue()
    {
        var result = Result<int>.Success(10);
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().Be(10);
    }

    [Fact]
    public void MapShouldPropagateFailure()
    {
        var result = Result<int>.Failure("nope").Map(x => x * 2);
        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Be("nope");
    }

    [Fact]
    public void OkShouldCreateBoolSuccess()
    {
        var result = Result.Ok();
        result.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void FailShouldCreateTypedFailure()
    {
        var result = Result.Fail<string>("err");
        result.IsSuccess.Should().BeFalse();
        result.Error!.Message.Should().Be("err");
    }
}
