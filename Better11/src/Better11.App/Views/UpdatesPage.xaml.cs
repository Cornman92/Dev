// ============================================================================
// File: src/Better11.App/Views/UpdatesPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Update;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views;

/// <summary>
/// Code-behind for the UpdatesPage.
/// </summary>
public sealed partial class UpdatesPage : Page
{
    /// <summary>
    /// Initializes a new instance of the <see cref="UpdatesPage"/> class.
    /// </summary>
    public UpdatesPage()
    {
        ViewModel = App.GetService<UpdateViewModel>();
        this.InitializeComponent();
        DataContext = ViewModel;
    }

    /// <summary>Gets the ViewModel.</summary>
    public UpdateViewModel ViewModel { get; }

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
