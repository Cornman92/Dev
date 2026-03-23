// ============================================================================
// File: src/Better11.App/Views/SecurityPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using Better11.ViewModels.Security;

namespace Better11.App.Views;

/// <summary>
/// Code-behind for the SecurityPage.
/// </summary>
public sealed partial class SecurityPage : Page
{
    /// <summary>
    /// Initializes a new instance of the <see cref="SecurityPage"/> class.
    /// </summary>
    public SecurityPage()
    {
        ViewModel = App.GetService<SecurityViewModel>();
        this.InitializeComponent();
        DataContext = ViewModel;
    }

    /// <summary>Gets the ViewModel.</summary>
    public SecurityViewModel ViewModel { get; }

    /// <inheritdoc/>
    protected override async void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (!ViewModel.IsInitialized)
        {
            await ViewModel.InitializeAsync().ConfigureAwait(false);
        }
    }
}
