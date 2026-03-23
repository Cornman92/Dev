// Copyright (c) Better11. All rights reserved.

namespace Better11.Tests.ViewModels;

using Better11.ViewModels;
using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

public class ConcreteViewModel : BaseViewModel
{
    public ConcreteViewModel()
        : base(NullLogger<ConcreteViewModel>.Instance)
    {
    }

    public void TestSetError(string msg) => SetError(msg);

    public void TestSetSuccess(string msg) => SetSuccess(msg);
}

public class BaseViewModelTests
{
    [Fact]
    public void SetErrorShouldSetHasErrorAndMessage()
    {
        var vm = new ConcreteViewModel();
        vm.TestSetError("test error");

        vm.HasError.Should().BeTrue();
        vm.ErrorMessage.Should().Be("test error");
        vm.HasSuccess.Should().BeFalse();
        vm.SuccessMessage.Should().BeEmpty();
    }

    [Fact]
    public void SetSuccessShouldClearErrorAndSetMessage()
    {
        var vm = new ConcreteViewModel();
        vm.TestSetError("previous error");
        vm.TestSetSuccess("all good");

        vm.HasError.Should().BeFalse();
        vm.ErrorMessage.Should().BeEmpty();
        vm.HasSuccess.Should().BeTrue();
        vm.SuccessMessage.Should().Be("all good");
    }

    [Fact]
    public void IsBusyShouldNotifyOnChange()
    {
        var vm = new ConcreteViewModel();
        var changed = false;
        vm.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(BaseViewModel.IsBusy))
            {
                changed = true;
            }
        };

        vm.IsBusy = true;
        changed.Should().BeTrue();
    }

    [Fact]
    public void IsNotBusyShouldBeOppositeOfIsBusy()
    {
        var vm = new ConcreteViewModel();
        vm.IsBusy = true;
        vm.IsNotBusy.Should().BeFalse();
        vm.IsBusy = false;
        vm.IsNotBusy.Should().BeTrue();
    }
}
