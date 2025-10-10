# SQL Server Backup Strategy (VM-Based)

## Database Information
- **Server**: sqltest.schoolvision.net:14333
- **Database**: FireProofDB
- **Type**: SQL Server on Azure VM (not Azure SQL Database)
- **Connection**: VM-to-VM networking

## Backup Options

### Option 1: SQL Server Native Backup (Recommended)

**Automated Backup Jobs via SQL Server Agent**

```sql
-- Connect to sqltest.schoolvision.net,14333

-- 1. Create backup directory (if not exists)
EXEC xp_cmdshell 'mkdir D:\SQLBackups\FireProofDB'
GO

-- 2. Full Backup Job (Daily at 2 AM)
USE msdb;
GO

EXEC sp_add_job
    @job_name = N'FireProofDB_FullBackup',
    @enabled = 1,
    @description = N'Daily full backup of FireProofDB';

EXEC sp_add_jobstep
    @job_name = N'FireProofDB_FullBackup',
    @step_name = N'Backup Database',
    @subsystem = N'TSQL',
    @command = N'
        DECLARE @BackupFile NVARCHAR(500)
        SET @BackupFile = ''D:\SQLBackups\FireProofDB\FireProofDB_''
            + CONVERT(VARCHAR, GETDATE(), 112) + ''_''
            + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.bak''

        BACKUP DATABASE [FireProofDB]
        TO DISK = @BackupFile
        WITH COMPRESSION, CHECKSUM, INIT,
            NAME = ''FireProofDB Full Backup'',
            STATS = 10;
    ',
    @on_success_action = 1;

EXEC sp_add_schedule
    @schedule_name = N'Daily_2AM',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 020000;  -- 2:00 AM

EXEC sp_attach_schedule
    @job_name = N'FireProofDB_FullBackup',
    @schedule_name = N'Daily_2AM';

EXEC sp_add_jobserver
    @job_name = N'FireProofDB_FullBackup';
GO

-- 3. Transaction Log Backup Job (Every 15 minutes)
-- Only if database is in FULL recovery model
EXEC sp_add_job
    @job_name = N'FireProofDB_LogBackup',
    @enabled = 1,
    @description = N'Transaction log backup every 15 minutes';

EXEC sp_add_jobstep
    @job_name = N'FireProofDB_LogBackup',
    @step_name = N'Backup Transaction Log',
    @subsystem = N'TSQL',
    @command = N'
        IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''FireProofDB'' AND recovery_model = 1)
        BEGIN
            DECLARE @LogFile NVARCHAR(500)
            SET @LogFile = ''D:\SQLBackups\FireProofDB\Logs\FireProofDB_Log_''
                + CONVERT(VARCHAR, GETDATE(), 112) + ''_''
                + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.trn''

            BACKUP LOG [FireProofDB]
            TO DISK = @LogFile
            WITH COMPRESSION, CHECKSUM, INIT,
                NAME = ''FireProofDB Log Backup'',
                STATS = 10;
        END
    ',
    @on_success_action = 1;

EXEC sp_add_schedule
    @schedule_name = N'Every_15_Minutes',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 4,  -- Minutes
    @freq_subday_interval = 15,
    @active_start_time = 000000,
    @active_end_time = 235959;

EXEC sp_attach_schedule
    @job_name = N'FireProofDB_LogBackup',
    @schedule_name = N'Every_15_Minutes';

EXEC sp_add_jobserver
    @job_name = N'FireProofDB_LogBackup';
GO

-- 4. Cleanup Job (Weekly - Delete backups older than 30 days)
EXEC sp_add_job
    @job_name = N'FireProofDB_BackupCleanup',
    @enabled = 1,
    @description = N'Clean up old backup files';

EXEC sp_add_jobstep
    @job_name = N'FireProofDB_BackupCleanup',
    @step_name = N'Delete Old Backups',
    @subsystem = N'TSQL',
    @command = N'
        EXEC xp_cmdshell ''forfiles /p "D:\SQLBackups\FireProofDB" /s /m *.* /d -30 /c "cmd /c del @path"''
    ',
    @on_success_action = 1;

EXEC sp_add_schedule
    @schedule_name = N'Weekly_Sunday_3AM',
    @freq_type = 8,  -- Weekly
    @freq_interval = 1,  -- Sunday
    @active_start_time = 030000;  -- 3:00 AM

EXEC sp_attach_schedule
    @job_name = N'FireProofDB_BackupCleanup',
    @schedule_name = N'Weekly_Sunday_3AM';

EXEC sp_add_jobserver
    @job_name = N'FireProofDB_BackupCleanup';
GO
```

### Option 2: Azure Backup for SQL Server

**Prerequisites**:
- Recovery Services Vault in Azure
- Backup agent installed on VM

**Setup**:
1. Create Recovery Services Vault
2. Install Microsoft Azure Recovery Services Agent on SQL VM
3. Register VM with vault
4. Configure backup policy (daily/hourly)

**Command**:
```bash
az backup vault create \
  --resource-group rg-fireproof \
  --name rsv-fireproof-backups \
  --location eastus2
```

### Option 3: Copy to Azure Storage

**Automated backup to Azure Blob Storage**:

```sql
-- 1. Create credential for Azure Storage
CREATE CREDENTIAL [https://fireproofbackups.blob.core.windows.net/sqlbackups]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'sv=2022-11-02&ss=b&srt=sco&sp=rwdlacupiytfx&se=...';

-- 2. Backup directly to blob
BACKUP DATABASE [FireProofDB]
TO URL = 'https://fireproofbackups.blob.core.windows.net/sqlbackups/FireProofDB_Full.bak'
WITH COMPRESSION, CHECKSUM, STATS = 10;
```

## Recommended Strategy

**For Production**:
1. **Full Backup**: Daily at 2:00 AM
2. **Transaction Log Backup**: Every 15 minutes (if FULL recovery model)
3. **Retention**: 30 days local, 90 days in Azure Blob Storage
4. **Test Restores**: Monthly validation

**Implementation Steps**:
1. Verify SQL Server Agent is running
2. Create backup directories
3. Run the SQL Agent job creation scripts above
4. Configure alerts for backup failures
5. Test restore procedure

## Monitoring Backup Jobs

```sql
-- Check backup history
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.backup_size / 1024 / 1024 AS BackupSizeMB,
    bs.compressed_backup_size / 1024 / 1024 AS CompressedSizeMB,
    bmf.physical_device_name,
    CASE bs.type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Transaction Log'
    END AS BackupType
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'FireProofDB'
ORDER BY bs.backup_start_date DESC;

-- Check job status
SELECT
    j.name AS JobName,
    ja.run_requested_date,
    CASE ja.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS Status
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobactivity ja ON j.job_id = ja.job_id
WHERE j.name LIKE 'FireProofDB%'
ORDER BY ja.run_requested_date DESC;
```

## Disaster Recovery Testing

**Monthly Test Procedure**:
1. Restore most recent full backup to test database
2. Apply transaction log backups
3. Verify data integrity
4. Test application connectivity
5. Document results

```sql
-- Test restore script
RESTORE DATABASE [FireProofDB_Test]
FROM DISK = 'D:\SQLBackups\FireProofDB\FireProofDB_20251010_020000.bak'
WITH MOVE 'FireProofDB' TO 'D:\SQLData\FireProofDB_Test.mdf',
     MOVE 'FireProofDB_log' TO 'D:\SQLData\FireProofDB_Test_log.ldf',
     NORECOVERY;

-- Apply log backups
RESTORE LOG [FireProofDB_Test]
FROM DISK = 'D:\SQLBackups\FireProofDB\Logs\FireProofDB_Log_20251010_100000.trn'
WITH RECOVERY;
```

## Contact Information

For backup configuration assistance:
- VM Administrator: [Contact info needed]
- DBA: [Contact info needed]
- Azure Support: [Support ticket process]
