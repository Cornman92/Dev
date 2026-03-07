// <copyright file="TuiAdapterTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.TUI;

using System.Windows.Input;
using Better11.Modules.BetterPE.TUI;
using Better11.Modules.BetterPE.TUI.Attributes;
using Better11.Modules.BetterPE.TUI.Rendering;
using CommunityToolkit.Mvvm.Input;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

/// <summary>
/// Unit tests for <see cref="TuiAdapter"/>.
/// </summary>
public sealed class TuiAdapterTests
{
    private readonly Mock<ITuiRenderer> mockRenderer;
    private readonly Mock<ILogger<TuiAdapter>> mockLogger;

    /// <summary>
    /// Initializes a new instance of the <see cref="TuiAdapterTests"/> class.
    /// </summary>
    public TuiAdapterTests()
    {
        this.mockRenderer = new Mock<ITuiRenderer>();
        this.mockLogger = new Mock<ILogger<TuiAdapter>>();
    }

    /// <summary>Verifies constructor throws on null renderer.</summary>
    [Fact]
    public void Constructor_NullRenderer_ThrowsArgumentNullException()
    {
        var act = () => new TuiAdapter(null!, this.mockLogger.Object);
        act.Should().Throw<ArgumentNullException>().WithParameterName("renderer");
    }

    /// <summary>Verifies constructor throws on null logger.</summary>
    [Fact]
    public void Constructor_NullLogger_ThrowsArgumentNullException()
    {
        var act = () => new TuiAdapter(this.mockRenderer.Object, null!);
        act.Should().Throw<ArgumentNullException>().WithParameterName("logger");
    }

    /// <summary>Verifies constructor succeeds with valid parameters.</summary>
    [Fact]
    public void Constructor_ValidParams_Succeeds()
    {
        var adapter = new TuiAdapter(this.mockRenderer.Object, this.mockLogger.Object);
        adapter.Should().NotBeNull();
    }

    /// <summary>Verifies AnalyzeViewModel extracts class-level TuiSection title.</summary>
    [Fact]
    public void AnalyzeViewModel_WithSectionAttribute_ExtractsTitle()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Title.Should().Be("Sample Panel");
        descriptor.ViewModelType.Should().Be(typeof(SampleDecoratedViewModel));
    }

    /// <summary>Verifies AnalyzeViewModel falls back to class name when no section attribute.</summary>
    [Fact]
    public void AnalyzeViewModel_WithoutSectionAttribute_UsesClassName()
    {
        var viewModel = new UndecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Title.Should().Be(nameof(UndecoratedViewModel));
    }

    /// <summary>Verifies AnalyzeViewModel discovers TuiField-attributed properties.</summary>
    [Fact]
    public void AnalyzeViewModel_DiscoversTuiFields()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields.Should().HaveCount(5);
    }

    /// <summary>Verifies fields are sorted by Order attribute.</summary>
    [Fact]
    public void AnalyzeViewModel_FieldsSortedByOrder()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var orders = descriptor.Fields.Select(f => f.Order).ToList();
        orders.Should().BeInAscendingOrder();
    }

    /// <summary>Verifies field label extraction.</summary>
    [Fact]
    public void AnalyzeViewModel_ExtractsFieldLabels()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields.Select(f => f.Label).Should().Contain("User Name");
        descriptor.Fields.Select(f => f.Label).Should().Contain("Enable Feature");
        descriptor.Fields.Select(f => f.Label).Should().Contain("Count");
    }

    /// <summary>Verifies explicit ControlType is preserved.</summary>
    [Fact]
    public void AnalyzeViewModel_ExplicitControlType_IsPreserved()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var pathField = descriptor.Fields.First(f => f.Label == "Output Path");
        pathField.ControlType.Should().Be(TuiControlType.PathSelector);
    }

    /// <summary>Verifies Auto ControlType infers Checkbox for bool.</summary>
    [Fact]
    public void AnalyzeViewModel_AutoControlType_InfersCheckboxForBool()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var boolField = descriptor.Fields.First(f => f.Label == "Enable Feature");
        boolField.ControlType.Should().Be(TuiControlType.Checkbox);
    }

    /// <summary>Verifies Auto ControlType infers NumericInput for int.</summary>
    [Fact]
    public void AnalyzeViewModel_AutoControlType_InfersNumericInputForInt()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var intField = descriptor.Fields.First(f => f.Label == "Count");
        intField.ControlType.Should().Be(TuiControlType.NumericInput);
    }

    /// <summary>Verifies Auto ControlType infers TextInput for string.</summary>
    [Fact]
    public void AnalyzeViewModel_AutoControlType_InfersTextInputForString()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var stringField = descriptor.Fields.First(f => f.Label == "User Name");
        stringField.ControlType.Should().Be(TuiControlType.TextInput);
    }

    /// <summary>Verifies Auto ControlType infers Dropdown for enums.</summary>
    [Fact]
    public void AnalyzeViewModel_AutoControlType_InfersDropdownForEnum()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var enumField = descriptor.Fields.First(f => f.Label == "Mode");
        enumField.ControlType.Should().Be(TuiControlType.Dropdown);
    }

    /// <summary>Verifies AnalyzeViewModel discovers TuiCommand-attributed ICommand properties.</summary>
    [Fact]
    public void AnalyzeViewModel_DiscoversTuiCommands()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Commands.Should().HaveCount(2);
    }

    /// <summary>Verifies commands are sorted by Order attribute.</summary>
    [Fact]
    public void AnalyzeViewModel_CommandsSortedByOrder()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var orders = descriptor.Commands.Select(c => c.Order).ToList();
        orders.Should().BeInAscendingOrder();
    }

    /// <summary>Verifies command metadata extraction (label, shortcut, primary, color).</summary>
    [Fact]
    public void AnalyzeViewModel_ExtractsCommandMetadata()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var primary = descriptor.Commands.First(c => c.IsPrimary);
        primary.Label.Should().Be("Execute");
        primary.Shortcut.Should().Be("F5");
        primary.Color.Should().Be("Green");
    }

    /// <summary>Verifies read-only field detection.</summary>
    [Fact]
    public void AnalyzeViewModel_ReadOnlyField_MarkedCorrectly()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var statusField = descriptor.Fields.First(f => f.Label == "Status");
        statusField.IsReadOnly.Should().BeTrue();
    }

    /// <summary>Verifies field section association via property-level TuiSection.</summary>
    [Fact]
    public void AnalyzeViewModel_FieldSectionAssociation()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var pathField = descriptor.Fields.First(f => f.Label == "Output Path");
        pathField.Section.Should().Be("Configuration");
    }

    /// <summary>Verifies help text extraction.</summary>
    [Fact]
    public void AnalyzeViewModel_ExtractsHelpText()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var pathField = descriptor.Fields.First(f => f.Label == "Output Path");
        pathField.HelpText.Should().Be("Select output directory");
    }

    /// <summary>Verifies properties without TuiField are ignored.</summary>
    [Fact]
    public void AnalyzeViewModel_UndecoratedProperties_AreIgnored()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields.Select(f => f.PropertyInfo.Name).Should().NotContain("HiddenProperty");
    }

    /// <summary>Verifies ViewModel with no decorations produces empty descriptor.</summary>
    [Fact]
    public void AnalyzeViewModel_NoDecorations_ProducesEmptyCollections()
    {
        var viewModel = new UndecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields.Should().BeEmpty();
        descriptor.Commands.Should().BeEmpty();
    }

    /// <summary>Verifies RenderOnce throws on null viewModel.</summary>
    [Fact]
    public void RenderOnce_NullViewModel_ThrowsArgumentNullException()
    {
        var adapter = new TuiAdapter(this.mockRenderer.Object, this.mockLogger.Object);

        var act = () => adapter.RenderOnce(null!);
        act.Should().Throw<ArgumentNullException>();
    }

    /// <summary>Verifies RunAsync throws on null viewModel.</summary>
    [Fact]
    public async Task RunAsync_NullViewModel_ThrowsArgumentNullException()
    {
        var adapter = new TuiAdapter(this.mockRenderer.Object, this.mockLogger.Object);
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        var act = () => adapter.RunAsync(null!, cts.Token);
        await act.Should().ThrowAsync<ArgumentNullException>();
    }

    /// <summary>Verifies TuiCommand on non-ICommand property is ignored.</summary>
    [Fact]
    public void AnalyzeViewModel_NonCommandPropertyWithAttribute_IsIgnored()
    {
        var viewModel = new BadCommandViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Commands.Should().BeEmpty();
    }

    /// <summary>Verifies RequiresConfirmation and ConfirmationMessage propagation.</summary>
    [Fact]
    public void AnalyzeViewModel_CommandConfirmation_IsPropagated()
    {
        var viewModel = new SampleDecoratedViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        var deleteCmd = descriptor.Commands.First(c => c.Label == "Delete");
        deleteCmd.RequiresConfirmation.Should().BeTrue();
        deleteCmd.ConfirmationMessage.Should().Be("Are you sure?");
    }

    /// <summary>Verifies Visible=false fields are still discovered but marked.</summary>
    [Fact]
    public void AnalyzeViewModel_HiddenField_DiscoveredWithVisibleFalse()
    {
        var viewModel = new HiddenFieldViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields.Should().HaveCount(1);
        descriptor.Fields[0].Visible.Should().BeFalse();
    }

    /// <summary>Verifies Width property propagation.</summary>
    [Fact]
    public void AnalyzeViewModel_FieldWidth_IsPropagated()
    {
        var viewModel = new WidthFieldViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields[0].Width.Should().Be(40);
    }

    /// <summary>Verifies Format string propagation.</summary>
    [Fact]
    public void AnalyzeViewModel_FieldFormat_IsPropagated()
    {
        var viewModel = new FormatFieldViewModel();

        var descriptor = TuiAdapter.AnalyzeViewModel(viewModel);

        descriptor.Fields[0].Format.Should().Be("N2");
    }

    #region Test ViewModels

    [TuiSection("Sample Panel")]
    private sealed class SampleDecoratedViewModel
    {
        [TuiField("User Name", Order = 0)]
        public string UserName { get; set; } = string.Empty;

        [TuiField("Enable Feature", Order = 1)]
        public bool IsEnabled { get; set; }

        [TuiField("Count", Order = 2)]
        public int ItemCount { get; set; }

        [TuiField("Output Path", ControlType = TuiControlType.PathSelector, Order = 3, HelpText = "Select output directory")]
        [TuiSection("Configuration")]
        public string OutputPath { get; set; } = string.Empty;

        [TuiField("Mode", Order = 4)]
        public SampleMode SelectedMode { get; set; }

        [TuiField("Status", IsReadOnly = true, Order = 10)]
        public string Status { get; set; } = "Ready";

        public string HiddenProperty { get; set; } = "Not visible in TUI";

        [TuiCommand("Execute", Shortcut = "F5", IsPrimary = true, Order = 0, Color = "Green")]
        public IRelayCommand ExecuteCommand { get; } = new RelayCommand(() => { });

        [TuiCommand("Delete", Shortcut = "Del", Order = 1, RequiresConfirmation = true, ConfirmationMessage = "Are you sure?", Color = "Red")]
        public IRelayCommand DeleteCommand { get; } = new RelayCommand(() => { });
    }

    private enum SampleMode
    {
        Fast,
        Normal,
        Thorough,
    }

    private sealed class UndecoratedViewModel
    {
        public string Name { get; set; } = string.Empty;

        public int Count { get; set; }
    }

    private sealed class BadCommandViewModel
    {
        [TuiCommand("Bad", Shortcut = "F1")]
        public string NotACommand { get; set; } = "oops";
    }

    private sealed class HiddenFieldViewModel
    {
        [TuiField("Secret", Visible = false)]
        public string SecretValue { get; set; } = string.Empty;
    }

    private sealed class WidthFieldViewModel
    {
        [TuiField("Wide", Width = 40)]
        public string WideField { get; set; } = string.Empty;
    }

    private sealed class FormatFieldViewModel
    {
        [TuiField("Price", Format = "N2")]
        public double Price { get; set; }
    }

    #endregion
}
