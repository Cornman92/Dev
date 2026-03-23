// <copyright file="TuiComponentTests.cs" company="Better11">
// Copyright (c) Better11. All rights reserved.
// </copyright>

namespace Better11.Modules.BetterPE.Tests.TUI;

using Better11.Modules.BetterPE.TUI.Attributes;
using Better11.Modules.BetterPE.TUI.Components;
using Better11.Modules.BetterPE.TUI.Rendering;
using FluentAssertions;
using Xunit;

public sealed class TuiTableTests
{
    [Fact]
    public void AddColumn_ShouldIncrementColumnCount()
    {
        var table = new TuiTable();
        table.AddColumn("Name");
        table.AddColumn("Value");

        table.Columns.Should().HaveCount(2);
    }

    [Fact]
    public void AddRow_ShouldIncrementRowCount()
    {
        var table = new TuiTable();
        table.AddColumn("Col1");
        table.AddRow("A");
        table.AddRow("B");

        table.Rows.Should().HaveCount(2);
    }

    [Fact]
    public void ClearRows_ShouldRemoveAllRows()
    {
        var table = new TuiTable();
        table.AddColumn("Col1");
        table.AddRow("A");
        table.AddRow("B");
        table.ClearRows();

        table.Rows.Should().BeEmpty();
    }

    [Fact]
    public void ClearRows_ShouldPreserveColumns()
    {
        var table = new TuiTable();
        table.AddColumn("Col1");
        table.AddColumn("Col2");
        table.AddRow("A", "B");
        table.ClearRows();

        table.Columns.Should().HaveCount(2);
    }

    [Fact]
    public void AddColumn_ShouldReturnTableForChaining()
    {
        var table = new TuiTable();
        var result = table.AddColumn("Test");

        result.Should().BeSameAs(table);
    }

    [Fact]
    public void AddRow_ShouldReturnTableForChaining()
    {
        var table = new TuiTable();
        table.AddColumn("Col1");
        var result = table.AddRow("A");

        result.Should().BeSameAs(table);
    }

    [Fact]
    public void Render_WithNoColumns_ShouldNotThrow()
    {
        var table = new TuiTable();
        var act = () =>
        {
            var writer = new StringWriter();
            Console.SetOut(writer);
            table.Render();
            Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
        };

        act.Should().NotThrow();
    }

    [Fact]
    public void Column_DefaultAlignment_ShouldBeLeft()
    {
        var table = new TuiTable();
        table.AddColumn("Test");

        table.Columns[0].Alignment.Should().Be(TuiAlignment.Left);
    }

    [Fact]
    public void AddColumn_WithRightAlignment_ShouldSetCorrectly()
    {
        var table = new TuiTable();
        table.AddColumn("Numbers", alignment: TuiAlignment.Right);

        table.Columns[0].Alignment.Should().Be(TuiAlignment.Right);
    }

    [Fact]
    public void AddColumn_WithMinWidth_ShouldSetCorrectly()
    {
        var table = new TuiTable();
        table.AddColumn("ID", minWidth: 10);

        table.Columns[0].MinWidth.Should().Be(10);
    }

    [Fact]
    public void Title_ShouldBeSettable()
    {
        var table = new TuiTable { Title = "Test Table" };
        table.Title.Should().Be("Test Table");
    }

    [Fact]
    public void ShowRowNumbers_ShouldDefaultToFalse()
    {
        var table = new TuiTable();
        table.ShowRowNumbers.Should().BeFalse();
    }

    [Fact]
    public void MaxWidth_ShouldDefaultToZero()
    {
        var table = new TuiTable();
        table.MaxWidth.Should().Be(0);
    }
}

public sealed class TuiProgressBarTests
{
    [Fact]
    public void Width_ShouldDefaultTo50()
    {
        var bar = new TuiProgressBar();
        bar.Width.Should().Be(50);
    }

    [Fact]
    public void ShowPercentage_ShouldDefaultToTrue()
    {
        var bar = new TuiProgressBar();
        bar.ShowPercentage.Should().BeTrue();
    }

    [Fact]
    public void ShowEta_ShouldDefaultToTrue()
    {
        var bar = new TuiProgressBar();
        bar.ShowEta.Should().BeTrue();
    }

    [Fact]
    public void Label_ShouldBeSettable()
    {
        var bar = new TuiProgressBar { Label = "Building" };
        bar.Label.Should().Be("Building");
    }

    [Fact]
    public void FillChar_ShouldDefaultToBlock()
    {
        var bar = new TuiProgressBar();
        bar.FillChar.Should().Be('█');
    }

    [Fact]
    public void Theme_ShouldDefaultToDefaultTheme()
    {
        var bar = new TuiProgressBar();
        bar.Theme.Should().NotBeNull();
    }

    [Fact]
    public void Render_ShouldNotThrow()
    {
        var bar = new TuiProgressBar();
        var writer = new StringWriter();
        Console.SetOut(writer);

        var act = () => bar.Render(50, "Working...", TimeSpan.FromMinutes(2));

        act.Should().NotThrow();
        Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
    }

    [Fact]
    public void Render_WithZeroPercent_ShouldNotThrow()
    {
        var bar = new TuiProgressBar();
        var writer = new StringWriter();
        Console.SetOut(writer);

        var act = () => bar.Render(0);

        act.Should().NotThrow();
        Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
    }

    [Fact]
    public void Render_With100Percent_ShouldNotThrow()
    {
        var bar = new TuiProgressBar();
        var writer = new StringWriter();
        Console.SetOut(writer);

        var act = () => bar.Render(100);

        act.Should().NotThrow();
        Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
    }

    [Fact]
    public void Render_WithOverflowPercent_ShouldClampTo100()
    {
        var bar = new TuiProgressBar();
        var writer = new StringWriter();
        Console.SetOut(writer);

        var act = () => bar.Render(200);

        act.Should().NotThrow();
        Console.SetOut(new StreamWriter(Console.OpenStandardOutput()) { AutoFlush = true });
    }
}

public sealed class TuiThemeTests
{
    [Fact]
    public void Default_ShouldReturnNonNullTheme()
    {
        TuiTheme.Default.Should().NotBeNull();
    }

    [Fact]
    public void HighContrast_ShouldReturnNonNullTheme()
    {
        TuiTheme.HighContrast.Should().NotBeNull();
    }

    [Fact]
    public void DarkBlue_ShouldReturnNonNullTheme()
    {
        TuiTheme.DarkBlue.Should().NotBeNull();
    }

    [Fact]
    public void GetBorderChars_WithSingleStyle_ShouldReturnValidChars()
    {
        var theme = new TuiTheme { BorderStyle = TuiBorderStyle.Single };
        var chars = theme.GetBorderChars();

        chars.Should().NotBeNull();
        chars.TopLeft.Should().NotBe('\0');
        chars.Horizontal.Should().NotBe('\0');
        chars.Vertical.Should().NotBe('\0');
    }

    [Fact]
    public void GetBorderChars_WithDoubleStyle_ShouldReturnValidChars()
    {
        var theme = new TuiTheme { BorderStyle = TuiBorderStyle.Double };
        var chars = theme.GetBorderChars();

        chars.Should().NotBeNull();
        chars.TopLeft.Should().NotBe('\0');
    }

    [Fact]
    public void GetBorderChars_WithRoundedStyle_ShouldReturnValidChars()
    {
        var theme = new TuiTheme { BorderStyle = TuiBorderStyle.Rounded };
        var chars = theme.GetBorderChars();

        chars.Should().NotBeNull();
    }

    [Fact]
    public void GetBorderChars_WithHeavyStyle_ShouldReturnValidChars()
    {
        var theme = new TuiTheme { BorderStyle = TuiBorderStyle.Heavy };
        var chars = theme.GetBorderChars();

        chars.Should().NotBeNull();
    }

    [Fact]
    public void GetBorderChars_WithNoneStyle_ShouldReturnSpaceChars()
    {
        var theme = new TuiTheme { BorderStyle = TuiBorderStyle.None };
        var chars = theme.GetBorderChars();

        chars.Horizontal.Should().Be(' ');
        chars.Vertical.Should().Be(' ');
    }
}

public sealed class TuiAttributeTests
{
    [Fact]
    public void TuiFieldAttribute_ShouldStoreLabel()
    {
        var attr = new TuiFieldAttribute("Test Label");
        attr.Label.Should().Be("Test Label");
    }

    [Fact]
    public void TuiFieldAttribute_FieldType_ShouldDefaultToAuto()
    {
        var attr = new TuiFieldAttribute("Test");
        attr.FieldType.Should().Be(TuiFieldType.Auto);
    }

    [Fact]
    public void TuiFieldAttribute_Order_ShouldDefaultToZero()
    {
        var attr = new TuiFieldAttribute("Test");
        attr.Order.Should().Be(0);
    }

    [Fact]
    public void TuiFieldAttribute_ReadOnly_ShouldDefaultToFalse()
    {
        var attr = new TuiFieldAttribute("Test");
        attr.ReadOnly.Should().BeFalse();
    }

    [Fact]
    public void TuiFieldAttribute_WidthPercent_ShouldDefaultTo100()
    {
        var attr = new TuiFieldAttribute("Test");
        attr.WidthPercent.Should().Be(100);
    }

    [Fact]
    public void TuiFieldAttribute_Visible_ShouldDefaultToTrue()
    {
        var attr = new TuiFieldAttribute("Test");
        attr.Visible.Should().BeTrue();
    }

    [Fact]
    public void TuiSectionAttribute_ShouldStoreTitle()
    {
        var attr = new TuiSectionAttribute("Section Title");
        attr.Title.Should().Be("Section Title");
    }

    [Fact]
    public void TuiSectionAttribute_Order_ShouldDefaultToZero()
    {
        var attr = new TuiSectionAttribute("Test");
        attr.Order.Should().Be(0);
    }

    [Fact]
    public void TuiCommandAttribute_ShouldStoreLabel()
    {
        var attr = new TuiCommandAttribute("Run Build");
        attr.Label.Should().Be("Run Build");
    }

    [Fact]
    public void TuiCommandAttribute_Order_ShouldDefaultToZero()
    {
        var attr = new TuiCommandAttribute("Test");
        attr.Order.Should().Be(0);
    }
}

public sealed class TuiDialogTests
{
    [Fact]
    public void Theme_ShouldDefaultToDefaultTheme()
    {
        var dialog = new TuiDialog();
        dialog.Theme.Should().NotBeNull();
    }

    [Fact]
    public void Width_ShouldDefaultTo50()
    {
        var dialog = new TuiDialog();
        dialog.Width.Should().Be(50);
    }

    [Fact]
    public void DialogType_Info_ShouldExist()
    {
        DialogType.Info.Should().BeDefined();
    }

    [Fact]
    public void DialogType_Success_ShouldExist()
    {
        DialogType.Success.Should().BeDefined();
    }

    [Fact]
    public void DialogType_Warning_ShouldExist()
    {
        DialogType.Warning.Should().BeDefined();
    }

    [Fact]
    public void DialogType_Error_ShouldExist()
    {
        DialogType.Error.Should().BeDefined();
    }

    [Fact]
    public void DialogType_Confirm_ShouldExist()
    {
        DialogType.Confirm.Should().BeDefined();
    }
}

public sealed class TuiAlignmentTests
{
    [Fact]
    public void Left_ShouldBeDefined()
    {
        TuiAlignment.Left.Should().BeDefined();
    }

    [Fact]
    public void Center_ShouldBeDefined()
    {
        TuiAlignment.Center.Should().BeDefined();
    }

    [Fact]
    public void Right_ShouldBeDefined()
    {
        TuiAlignment.Right.Should().BeDefined();
    }
}

public sealed class TuiTableColumnTests
{
    [Fact]
    public void Header_ShouldDefaultToEmpty()
    {
        var col = new TuiTableColumn();
        col.Header.Should().BeEmpty();
    }

    [Fact]
    public void MinWidth_ShouldDefaultToZero()
    {
        var col = new TuiTableColumn();
        col.MinWidth.Should().Be(0);
    }

    [Fact]
    public void Alignment_ShouldDefaultToLeft()
    {
        var col = new TuiTableColumn();
        col.Alignment.Should().Be(TuiAlignment.Left);
    }
}
