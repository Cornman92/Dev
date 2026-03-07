// ============================================================================
// File: src/Better11.App/Views/ScheduledTasksPage.xaml.cs
// Better11 System Enhancement Suite
// Copyright (c) 2026 Better11. All rights reserved.
// ============================================================================

using Better11.ViewModels.ScheduledTask;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views
{
    /// <summary>
    /// Code-behind for <see cref="ScheduledTasksPage"/>.
    /// </summary>
    public sealed partial class ScheduledTasksPage : Page
    {
        /// <summary>Gets the ViewModel.</summary>
        public ScheduledTaskViewModel ViewModel { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ScheduledTasksPage"/> class.
        /// </summary>
        public ScheduledTasksPage()
        {
            ViewModel = App.GetService<ScheduledTaskViewModel>();
            InitializeComponent();
            DataContext = ViewModel;
        }

        /// <inheritdoc/>
        protected override async void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            if (!ViewModel.IsInitialized)
            {
                await ViewModel.InitializeAsync();
            }
        }
    }
}
