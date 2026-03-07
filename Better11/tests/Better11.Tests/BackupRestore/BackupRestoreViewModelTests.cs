using System;using System.Collections.Generic;using System.Threading;using System.Threading.Tasks;
using Better11.Core.Interfaces;using Better11.ViewModels.BackupRestore;using Moq;using Xunit;
namespace Better11.Tests.BackupRestore;
public class BackupRestoreViewModelTests{
private readonly Mock<IBackupRestoreService> _m;private readonly BackupRestoreViewModel _s;
public BackupRestoreViewModelTests(){_m=new Mock<IBackupRestoreService>();
_m.Setup(s=>s.GetRestorePointsAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<RestorePointDto>>.Ok(new List<RestorePointDto>{new(){Description="RP1"}}));
_m.Setup(s=>s.GetRegistryBackupsAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<RegistryBackupDto>>.Ok(new List<RegistryBackupDto>()));
_m.Setup(s=>s.GetFileBackupsAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<FileBackupDto>>.Ok(new List<FileBackupDto>()));
_m.Setup(s=>s.GetSchedulesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Result<IReadOnlyList<BackupScheduleDto>>.Ok(new List<BackupScheduleDto>()));
_s=new BackupRestoreViewModel(_m.Object);}
[Fact] public void Ctor()=>Assert.Throws<ArgumentNullException>(()=>new BackupRestoreViewModel(null!));
[Fact] public void Coll(){Assert.NotNull(_s.RestorePoints);Assert.NotNull(_s.RegBackups);Assert.NotNull(_s.FileBackups);Assert.NotNull(_s.Schedules);}
[Fact] public void Cmds(){Assert.NotNull(_s.RefreshCommand);Assert.NotNull(_s.CreateRpCommand);Assert.NotNull(_s.ExportRegCommand);Assert.NotNull(_s.CreateBackupCommand);Assert.NotNull(_s.CreateScheduleCommand);}
[Fact] public void Defs(){Assert.False(_s.IsLoading);Assert.Equal(30,_s.Retention);}
[Fact] public void Prop(){var r=false;_s.PropertyChanged+=(o,e)=>{if(e.PropertyName=="Retention")r=true;};_s.Retention=7;Assert.True(r);}
[Fact] public void RestorePointDto_D(){var d=new RestorePointDto();Assert.Equal(0,d.SequenceNumber);}
[Fact] public void RegistryBackupDto_D(){var d=new RegistryBackupDto();Assert.Equal(0,d.SizeKb);}
[Fact] public void FileBackupDto_D(){var d=new FileBackupDto();Assert.False(d.Compressed);Assert.False(d.Encrypted);}
[Fact] public void BackupScheduleDto_D(){var d=new BackupScheduleDto();Assert.False(d.Enabled);}
[Fact] public async Task Init(){await _s.InitializeAsync();Assert.Contains("ready",_s.StatusMessage,StringComparison.OrdinalIgnoreCase);}
[Fact] public async Task Init_Err(){_m.Setup(s=>s.GetRestorePointsAsync(It.IsAny<CancellationToken>())).ThrowsAsync(new InvalidOperationException("x"));await _s.InitializeAsync();Assert.Contains("Error",_s.StatusMessage);}
}