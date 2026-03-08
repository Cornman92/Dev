using Better11.ViewModels.Customization;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Better11.App.Views;

/// <summary>
/// Code-behind for the customization studio page.
/// </summary>
public sealed partial class CustomizationStudioPage : Page
{
    /// <summary>
    /// Initializes a new instance of the <see cref="CustomizationStudioPage"/> class.
    /// </summary>
    public CustomizationStudioPage()
    {
        ViewModel = App.GetService<CustomizationStudioViewModel>();
        InitializeComponent();
        DataContext = ViewModel;
    }

    /// <summary>
    /// Gets the customization studio view model.
    /// </summary>
    public CustomizationStudioViewModel ViewModel { get; }

    /// <inheritdoc />
    protected override async void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (!ViewModel.IsInitialized)
        {
            await ViewModel.InitializeAsync().ConfigureAwait(false);
        }
    }
}
