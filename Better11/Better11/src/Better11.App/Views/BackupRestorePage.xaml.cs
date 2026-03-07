// Copyright (c) Better11. All rights reserved.

namespace Better11.App.Views;

using Better11.ViewModels.BackupRestore;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

/// <summary>
/// View for Backup and Restore page.
/// </summary>
public sealed partial class BackupRestorePage : Page
{
    private readonly BackupRestoreViewModel _vm;

    /// <summary>
    /// Initializes a new instance of the <see cref="BackupRestorePage"/> class.
    /// </summary>
    public BackupRestorePage()
    {
        InitializeComponent();
        _vm = App.GetService<BackupRestoreViewModel>();
        DataContext = _vm;

        _vm.PropertyChanged += (s, e) =>
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                StatusText.Text = _vm.StatusMessage;
                LoadingRing.IsActive = _vm.IsLoading;
            });
        };

        RpList.ItemsSource = _vm.RestorePoints;
        RegList.ItemsSource = _vm.RegBackups;
        BkpList.ItemsSource = _vm.FileBackups;
        SchedList.ItemsSource = _vm.Schedules;
    }

    private async void Page_Loaded(object sender, RoutedEventArgs e)
    {
        await _vm.InitializeAsync().ConfigureAwait(false);
    }

    private void CreateRp_Click(object sender, RoutedEventArgs e)
    {
        _vm.RpDescription = RpDescBox.Text;
        _vm.CreateRpCommand.Execute(null);
    }

    private void ExportReg_Click(object sender, RoutedEventArgs e)
    {
        _vm.RegKeyPath = RegKeyBox.Text;
        _vm.RegBackupName = RegNameBox.Text;
        _vm.ExportRegCommand.Execute(null);
    }

    private void ImportReg_Click(object sender, RoutedEventArgs e)
    {
        _vm.ImportPath = RegImportBox.Text;
        _vm.ImportRegCommand.Execute(null);
    }

    private void CreateBkp_Click(object sender, RoutedEventArgs e)
    {
        _vm.BackupSource = SrcBox.Text;
        _vm.BackupDest = DstBox.Text;
        _vm.Compress = CompressSwitch.IsOn;
        _vm.Encrypt = EncryptSwitch.IsOn;
        _vm.CreateBackupCommand.Execute(null);
    }

    private void CreateSched_Click(object sender, RoutedEventArgs e)
    {
        _vm.SchedName = SchedNameBox.Text;
        _vm.BackupSource = SrcBox.Text;
        _vm.BackupDest = DstBox.Text;

        if (FreqBox.SelectedItem is ComboBoxItem item)
        {
            _vm.SchedFreq = item.Content?.ToString() ?? "Daily";
        }

        _vm.Retention = (int)RetBox.Value;
        _vm.CreateScheduleCommand.Execute(null);
    }

    private void DeleteSched_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string name)
        {
            _vm.DeleteScheduleCommand.Execute(name);
        }
    }
}
