// Copyright (c) Better11. All rights reserved.

using Better11.Core.Common;

namespace Better11.Core.Interfaces;

/// <summary>
/// Service interface for backup and restore (restore points, registry, file backup, schedules).
/// </summary>
public interface IBackupRestoreService
{
    /// <summary>Gets the list of system restore points.</summary>
    Task<Result<IReadOnlyList<RestorePointDto>>> GetRestorePointsAsync(CancellationToken ct = default);

    /// <summary>Creates a system restore point with the given description.</summary>
    Task<Result<bool>> CreateRestorePointAsync(string description, CancellationToken ct = default);

    /// <summary>Deletes a restore point by sequence number.</summary>
    Task<Result<bool>> DeleteRestorePointAsync(int sequenceNumber, CancellationToken ct = default);

    /// <summary>Gets the list of registry backups.</summary>
    Task<Result<IReadOnlyList<RegistryBackupDto>>> GetRegistryBackupsAsync(CancellationToken ct = default);

    /// <summary>Exports a registry key to a backup file.</summary>
    Task<Result<bool>> ExportRegistryKeyAsync(string keyPath, string name, CancellationToken ct = default);

    /// <summary>Imports a registry backup from the given file path.</summary>
    Task<Result<bool>> ImportRegistryBackupAsync(string filePath, CancellationToken ct = default);

    /// <summary>Gets the list of file backups.</summary>
    Task<Result<IReadOnlyList<FileBackupDto>>> GetFileBackupsAsync(CancellationToken ct = default);

    /// <summary>Creates a file backup from source to destination.</summary>
    Task<Result<bool>> CreateFileBackupAsync(string source, string dest, bool compress, bool encrypt, CancellationToken ct = default);

    /// <summary>Restores a file backup to the given path.</summary>
    Task<Result<bool>> RestoreFileBackupAsync(string backupPath, string restorePath, CancellationToken ct = default);

    /// <summary>Gets the list of backup schedules.</summary>
    Task<Result<IReadOnlyList<BackupScheduleDto>>> GetSchedulesAsync(CancellationToken ct = default);

    /// <summary>Creates a backup schedule.</summary>
    Task<Result<bool>> CreateScheduleAsync(string name, string source, string dest, string freq, int retention, CancellationToken ct = default);

    /// <summary>Deletes a backup schedule by name.</summary>
    Task<Result<bool>> DeleteScheduleAsync(string name, CancellationToken ct = default);
}
