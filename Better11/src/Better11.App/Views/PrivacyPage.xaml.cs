// ============================================================================
// File: src/Better11.App/Views/PrivacyPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.Privacy;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views;

/// <summary>
/// Code-behind for the PrivacyPage.
/// </summary>
public sealed partial class PrivacyPage : Page
{
    /// <summary>
    /// Initializes a new instance of the <see cref="PrivacyPage"/> class.
    /// </summary>
    public PrivacyPage()
    {
        ViewModel = App.GetService<PrivacyViewModel>();
        this.InitializeComponent();
        DataContext = ViewModel;
    }

    /// <summary>Gets the ViewModel.</summary>
    public PrivacyViewModel ViewModel { get; }

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
