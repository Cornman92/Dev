// Copyright (c) Better11. All rights reserved.

namespace Better11.ViewModels.BackupRestore;

using System.Collections.ObjectModel;
using Better11.Core.Interfaces;
using Better11.ViewModels.Base;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Extensions.Logging;

/// <summary>
/// ViewModel for the Backup and Restore page.
/// </summary>
public sealed partial class BackupRestoreViewModel : BaseViewModel
{
    private readonly IBackupRestoreService _service;

    [ObservableProperty]
    private string _statusMessage = string.Empty;

    [ObservableProperty]
    private string _rpDescription = string.Empty;

    [ObservableProperty]
    private string _regKeyPath = string.Empty;

    [ObservableProperty]
    private string _regBackupName = string.Empty;

    [ObservableProperty]
    private string _importPath = string.Empty;

    [ObservableProperty]
    private string _backupSource = string.Empty;

    [ObservableProperty]
    private string _backupDest = string.Empty;

    [ObservableProperty]
    private bool _compress;

    [ObservableProperty]
    private bool _encrypt;

    [ObservableProperty]
    private string _schedName = string.Empty;

    [ObservableProperty]
    private string _schedFreq = "Daily";

    [ObservableProperty]
    private int _retention = 30;

    /// <summary>
    /// Initializes a new instance of the <see cref="BackupRestoreViewModel"/> class.
    /// </summary>
    /// <param name="service">The backup and restore service.</param>
    /// <param name="logger">The logger instance.</param>
    public BackupRestoreViewModel(IBackupRestoreService service, ILogger<BackupRestoreViewModel> logger)
        : base(logger)
    {
        ArgumentNullException.ThrowIfNull(service);
        _service = service;
        PageTitle = "Backup & Restore";
    }

    /// <summary>Gets the list of system restore points.</summary>
    public ObservableCollection<RestorePointDto> RestorePoints { get; } = new();

    /// <summary>Gets the list of registry backups.</summary>
    public ObservableCollection<RegistryBackupDto> RegBackups { get; } = new();

    /// <summary>Gets the list of file backups.</summary>
    public ObservableCollection<FileBackupDto> FileBackups { get; } = new();

    /// <summary>Gets the list of backup schedules.</summary>
    public ObservableCollection<BackupScheduleDto> Schedules { get; } = new();

    /// <summary>Gets a value indicating whether the service is currently loading data.</summary>
    public bool IsLoading => IsBusy;

    /// <inheritdoc/>
    protected override async Task OnInitializeAsync(CancellationToken cancellationToken = default)
    {
        await RefreshAllAsync().ConfigureAwait(false);
    }

    /// <summary>Reloads all backup and restore data.</summary>
    [RelayCommand]
    private async Task RefreshAllAsync()
    {
        await LoadRestorePointsAsync().ConfigureAwait(false);
        await LoadRegistryBackupsAsync().ConfigureAwait(false);
        await LoadFileBackupsAsync().ConfigureAwait(false);
        await LoadSchedulesAsync().ConfigureAwait(false);
        StatusMessage = "Backup and restore data refreshed.";
    }

    /// <summary>Creates a new system restore point.</summary>
    [RelayCommand]
    private async Task CreateRpAsync()
    {
        if (string.IsNullOrWhiteSpace(RpDescription))
        {
            SetError("Description is required.");
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.CreateRestorePointAsync(RpDescription, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("System restore point created.");
                    RpDescription = string.Empty;
                    await LoadRestorePointsAsync().ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Creating restore point...").ConfigureAwait(false);
    }

    /// <summary>Exports a registry key to a .reg file.</summary>
    [RelayCommand]
    private async Task ExportRegAsync()
    {
        if (string.IsNullOrWhiteSpace(RegKeyPath))
        {
            SetError("Registry key path is required.");
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.ExportRegistryKeyAsync(RegKeyPath, RegBackupName, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("Registry key exported successfully.");
                    await LoadRegistryBackupsAsync().ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Exporting registry...").ConfigureAwait(false);
    }

    /// <summary>Imports a registry backup from a .reg file.</summary>
    [RelayCommand]
    private async Task ImportRegAsync()
    {
        if (string.IsNullOrWhiteSpace(ImportPath))
        {
            SetError("Import path is required.");
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.ImportRegistryBackupAsync(ImportPath, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("Registry backup imported successfully.");
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Importing registry...").ConfigureAwait(false);
    }

    /// <summary>Creates a file/folder backup with compression/encryption options.</summary>
    [RelayCommand]
    private async Task CreateBackupAsync()
    {
        if (string.IsNullOrWhiteSpace(BackupSource))
        {
            SetError("Backup source path is required.");
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.CreateFileBackupAsync(BackupSource, BackupDest, Compress, Encrypt, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess("File backup created.");
                    await LoadFileBackupsAsync().ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Creating file backup...").ConfigureAwait(false);
    }

    /// <summary>Creates a scheduled backup job.</summary>
    [RelayCommand]
    private async Task CreateScheduleAsync()
    {
        if (string.IsNullOrWhiteSpace(SchedName))
        {
            SetError("Schedule name is required.");
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.CreateScheduleAsync(SchedName, BackupSource, BackupDest, SchedFreq, Retention, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Backup schedule '{SchedName}' created.");
                    await LoadSchedulesAsync().ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Creating schedule...").ConfigureAwait(false);
    }

    /// <summary>Deletes an existing backup schedule.</summary>
    /// <param name="name">Name of the schedule to delete.</param>
    [RelayCommand]
    private async Task DeleteScheduleAsync(string name)
    {
        if (string.IsNullOrEmpty(name))
        {
            return;
        }

        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.DeleteScheduleAsync(name, ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    SetSuccess($"Schedule '{name}' deleted.");
                    await LoadSchedulesAsync().ConfigureAwait(false);
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Deleting schedule...").ConfigureAwait(false);
    }

    private async Task LoadRestorePointsAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetRestorePointsAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        RestorePoints.Clear();
                        foreach (var r in result.Value)
                        {
                            RestorePoints.Add(r);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading restore points...").ConfigureAwait(false);
    }

    private async Task LoadRegistryBackupsAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetRegistryBackupsAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        RegBackups.Clear();
                        foreach (var r in result.Value)
                        {
                            RegBackups.Add(r);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading registry backups...").ConfigureAwait(false);
    }

    private async Task LoadFileBackupsAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetFileBackupsAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        FileBackups.Clear();
                        foreach (var f in result.Value)
                        {
                            FileBackups.Add(f);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading file backups...").ConfigureAwait(false);
    }

    private async Task LoadSchedulesAsync()
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.GetSchedulesAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    RunOnUIThread(() =>
                    {
                        Schedules.Clear();
                        foreach (var s in result.Value)
                        {
                            Schedules.Add(s);
                        }
                    });
                }
                else
                {
                    SetErrorFromResult(result);
                }
            },
            "Loading backup schedules...").ConfigureAwait(false);
    }
}
