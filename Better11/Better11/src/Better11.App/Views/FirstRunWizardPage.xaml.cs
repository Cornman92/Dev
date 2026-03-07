// Copyright (c) Better11. All rights reserved.

namespace Better11.App.Views;

using Better11.ViewModels.Wizard;
using Microsoft.UI.Xaml.Controls;

/// <summary>
/// Code-behind for the First Run Wizard page.
/// </summary>
public sealed partial class FirstRunWizardPage : Page
{
    /// <summary>
    /// Initializes a new instance of the <see cref="FirstRunWizardPage"/> class.
    /// </summary>
    public FirstRunWizardPage()
    {
        this.InitializeComponent();
    }

    /// <summary>
    /// Gets or sets the ViewModel for this page.
    /// </summary>
    public FirstRunWizardViewModel ViewModel { get; set; } = null!;
}
