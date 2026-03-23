// Copyright (c) Better11. All rights reserved.

using Better11.Core.Common;
using Better11.Core.Interfaces;

namespace Better11.Services.BackupRestore;

/// <summary>
/// Service for managing system restore points and registry/file backups via PowerShell.
/// </summary>
public sealed class BackupRestoreService : IBackupRestoreService
{
    private const string Module = "B11.BackupRestore";
    private readonly IPowerShellService _ps;

    /// <summary>
    /// Initializes a new instance of the <see cref="BackupRestoreService"/> class.
    /// </summary>
    /// <param name="ps">The PowerShell service instance.</param>
    public BackupRestoreService(IPowerShellService ps)
    {
        ArgumentNullException.ThrowIfNull(ps);
        _ps = ps;
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<RestorePointDto>>> GetRestorePointsAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<RestorePointDto>(Module, "Get-B11RestorePoint", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> CreateRestorePointAsync(string description, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object> { ["Description"] = description };
        return await _ps.InvokeCommandAsync<bool>(Module, "New-B11RestorePoint", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<bool>> DeleteRestorePointAsync(int sequenceNumber, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object> { ["SequenceNumber"] = sequenceNumber };
        return await _ps.InvokeCommandAsync<bool>(Module, "Remove-B11RestorePoint", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<RegistryBackupDto>>> GetRegistryBackupsAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<RegistryBackupDto>(Module, "Get-B11RegistryBackup", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> ExportRegistryKeyAsync(string keyPath, string name, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object> { ["KeyPath"] = keyPath, ["Name"] = name };
        return await _ps.InvokeCommandAsync<bool>(Module, "Export-B11RegistryKey", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<bool>> ImportRegistryBackupAsync(string filePath, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object> { ["FilePath"] = filePath };
        return await _ps.InvokeCommandAsync<bool>(Module, "Import-B11RegistryBackup", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<FileBackupDto>>> GetFileBackupsAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<FileBackupDto>(Module, "Get-B11FileBackup", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> CreateFileBackupAsync(string source, string dest, bool compress, bool encrypt, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object>
        {
            ["Source"] = source,
            ["Destination"] = dest,
            ["Compress"] = compress,
            ["Encrypt"] = encrypt,
        };
        return await _ps.InvokeCommandAsync<bool>(Module, "New-B11FileBackup", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<bool>> RestoreFileBackupAsync(string backupPath, string restorePath, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object>
        {
            ["BackupPath"] = backupPath,
            ["RestorePath"] = restorePath,
        };
        return await _ps.InvokeCommandAsync<bool>(Module, "Restore-B11FileBackup", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<IReadOnlyList<BackupScheduleDto>>> GetSchedulesAsync(CancellationToken ct = default) =>
        await _ps.InvokeCommandListAsync<BackupScheduleDto>(Module, "Get-B11BackupSchedule", null, ct).ConfigureAwait(false);

    /// <inheritdoc/>
    public async Task<Result<bool>> CreateScheduleAsync(string name, string source, string dest, string freq, int retention, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object>
        {
            ["Name"] = name,
            ["Source"] = source,
            ["Destination"] = dest,
            ["Frequency"] = freq,
            ["RetentionDays"] = retention,
        };
        return await _ps.InvokeCommandAsync<bool>(Module, "New-B11BackupSchedule", parameters, ct).ConfigureAwait(false);
    }

    /// <inheritdoc/>
    public async Task<Result<bool>> DeleteScheduleAsync(string name, CancellationToken ct = default)
    {
        var parameters = new Dictionary<string, object> { ["Name"] = name };
        return await _ps.InvokeCommandAsync<bool>(Module, "Remove-B11BackupSchedule", parameters, ct).ConfigureAwait(false);
    }
}
