# Transparent Data Encryption (TDE) for SQL Server on VM

## Overview

Transparent Data Encryption (TDE) encrypts SQL Server data files at rest, protecting against unauthorized access to backup files and data files.

## Database Information
- **Server**: sqltest.schoolvision.net:14333
- **Database**: FireProofDB
- **Type**: SQL Server on Azure VM (not Azure SQL Database)

## Prerequisites

1. **SQL Server Edition**: TDE requires Enterprise, Developer, or Standard Edition (2016 SP1+)
2. **Permissions**: `CONTROL SERVER` permission
3. **Backup Space**: Ensure sufficient disk space for backup before enabling TDE
4. **Performance**: Minimal impact (typically 3-5% CPU overhead)

## TDE Implementation Steps

### Step 1: Check SQL Server Edition

```sql
-- Connect to sqltest.schoolvision.net,14333
SELECT
    SERVERPROPERTY('ProductVersion') AS Version,
    SERVERPROPERTY('ProductLevel') AS ServicePack,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('EngineEdition') AS EngineEdition;

-- Check if TDE is available
SELECT
    CASE
        WHEN SERVERPROPERTY('EngineEdition') IN (2,3,4,8) THEN 'TDE Available'
        ELSE 'TDE NOT Available (Express/Web Edition)'
    END AS TDEStatus;
```

### Step 2: Create Master Key

```sql
-- Run on master database
USE master;
GO

-- Create master key (if not exists)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!ChangeMeInProduction';
    PRINT 'Master key created successfully';
END
ELSE
BEGIN
    PRINT 'Master key already exists';
END
GO
```

### Step 3: Create Certificate

```sql
-- Create certificate for TDE
USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'FireProofDB_TDE_Certificate')
BEGIN
    CREATE CERTIFICATE FireProofDB_TDE_Certificate
    WITH SUBJECT = 'FireProofDB TDE Certificate',
         EXPIRY_DATE = '2027-12-31';
    PRINT 'Certificate created successfully';
END
ELSE
BEGIN
    PRINT 'Certificate already exists';
END
GO
```

### Step 4: Backup Certificate (CRITICAL!)

```sql
-- IMPORTANT: Backup certificate and private key to secure location
-- Without this backup, you CANNOT restore the database on another server

USE master;
GO

BACKUP CERTIFICATE FireProofDB_TDE_Certificate
TO FILE = 'D:\SQLBackups\Certificates\FireProofDB_TDE_Certificate.cer'
WITH PRIVATE KEY (
    FILE = 'D:\SQLBackups\Certificates\FireProofDB_TDE_Certificate.key',
    ENCRYPTION BY PASSWORD = 'VeryStrongPassword456!ChangeMe'
);

PRINT 'Certificate backed up successfully';
PRINT 'Store these files in a secure location separate from database backups';
GO
```

### Step 5: Create Database Encryption Key

```sql
-- Create encryption key on target database
USE FireProofDB;
GO

IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('FireProofDB'))
BEGIN
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE FireProofDB_TDE_Certificate;
    PRINT 'Database encryption key created successfully';
END
ELSE
BEGIN
    PRINT 'Database encryption key already exists';
END
GO
```

### Step 6: Enable TDE

```sql
-- Enable encryption
USE master;
GO

ALTER DATABASE FireProofDB
SET ENCRYPTION ON;
GO

PRINT 'TDE enabled on FireProofDB';
PRINT 'Encryption process started in background';
GO
```

### Step 7: Monitor Encryption Progress

```sql
-- Check encryption status
SELECT
    db_name(database_id) AS DatabaseName,
    encryption_state,
    CASE encryption_state
        WHEN 0 THEN 'No database encryption key present, no encryption'
        WHEN 1 THEN 'Unencrypted'
        WHEN 2 THEN 'Encryption in progress'
        WHEN 3 THEN 'Encrypted'
        WHEN 4 THEN 'Key change in progress'
        WHEN 5 THEN 'Decryption in progress'
        WHEN 6 THEN 'Protection change in progress'
    END AS EncryptionState,
    percent_complete,
    encryptor_type,
    key_algorithm,
    key_length
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID('FireProofDB');

-- For large databases, encryption can take time
-- Monitor until encryption_state = 3 and percent_complete = 100
```

## Complete Implementation Script

```sql
-- Complete TDE setup script for FireProofDB
-- Run as sysadmin on sqltest.schoolvision.net,14333

USE master;
GO

PRINT '========================================';
PRINT 'FireProofDB TDE Setup';
PRINT '========================================';
PRINT '';

-- 1. Check edition
PRINT 'Step 1: Checking SQL Server Edition...';
SELECT
    SERVERPROPERTY('Edition') AS Edition,
    CASE
        WHEN SERVERPROPERTY('EngineEdition') IN (2,3,4,8) THEN 'TDE Available'
        ELSE 'TDE NOT Available'
    END AS TDEStatus;
PRINT '';

-- 2. Create master key
PRINT 'Step 2: Creating Master Key...';
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey_ChangeMeInProduction_2025!';
    PRINT 'Master key created';
END
ELSE
    PRINT 'Master key already exists';
PRINT '';

-- 3. Create certificate
PRINT 'Step 3: Creating TDE Certificate...';
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'FireProofDB_TDE_Certificate')
BEGIN
    CREATE CERTIFICATE FireProofDB_TDE_Certificate
    WITH SUBJECT = 'FireProofDB TDE Certificate - Created ' + CONVERT(VARCHAR, GETDATE(), 120),
         EXPIRY_DATE = '2027-12-31';
    PRINT 'Certificate created';
END
ELSE
    PRINT 'Certificate already exists';
PRINT '';

-- 4. Backup certificate
PRINT 'Step 4: Backing up Certificate...';
PRINT 'Creating backup directory...';
EXEC xp_cmdshell 'mkdir D:\SQLBackups\Certificates';

BACKUP CERTIFICATE FireProofDB_TDE_Certificate
TO FILE = 'D:\SQLBackups\Certificates\FireProofDB_TDE_Certificate.cer'
WITH PRIVATE KEY (
    FILE = 'D:\SQLBackups\Certificates\FireProofDB_TDE_Certificate.key',
    ENCRYPTION BY PASSWORD = 'CertificatePassword_ChangeMeInProduction_2025!'
);
PRINT 'Certificate backed up to D:\SQLBackups\Certificates\';
PRINT 'WARNING: Store these files in Azure Key Vault or secure location!';
PRINT '';

-- 5. Create database encryption key
PRINT 'Step 5: Creating Database Encryption Key...';
USE FireProofDB;
IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID('FireProofDB'))
BEGIN
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE FireProofDB_TDE_Certificate;
    PRINT 'Encryption key created';
END
ELSE
    PRINT 'Encryption key already exists';
PRINT '';

-- 6. Enable TDE
PRINT 'Step 6: Enabling TDE...';
USE master;
ALTER DATABASE FireProofDB SET ENCRYPTION ON;
PRINT 'TDE enabled - encryption in progress';
PRINT '';

-- 7. Show status
PRINT 'Step 7: Current Encryption Status...';
SELECT
    db_name(database_id) AS DatabaseName,
    CASE encryption_state
        WHEN 0 THEN 'No encryption key'
        WHEN 1 THEN 'Unencrypted'
        WHEN 2 THEN 'Encryption in progress'
        WHEN 3 THEN 'Encrypted'
        WHEN 4 THEN 'Key change in progress'
        WHEN 5 THEN 'Decryption in progress'
    END AS EncryptionState,
    percent_complete AS PercentComplete,
    key_algorithm AS Algorithm,
    key_length AS KeyLength
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID('FireProofDB');

PRINT '';
PRINT '========================================';
PRINT 'TDE Setup Complete!';
PRINT '========================================';
PRINT 'Next Steps:';
PRINT '1. Copy certificate files to secure location';
PRINT '2. Store certificate password in Azure Key Vault';
PRINT '3. Document certificate location';
PRINT '4. Test database restore on another server';
PRINT '5. Monitor encryption progress';
GO
```

## Certificate Management

### Store Certificate in Azure Key Vault

```bash
# Upload certificate to Key Vault
az keyvault certificate import \
  --vault-name kv-fireproof-prod \
  --name FireProofDB-TDE-Certificate \
  --file D:\SQLBackups\Certificates\FireProofDB_TDE_Certificate.cer

# Store private key password as secret
az keyvault secret set \
  --vault-name kv-fireproof-prod \
  --name TDECertificatePassword \
  --value "CertificatePassword_ChangeMeInProduction_2025!"
```

### Restore Certificate on Another Server

```sql
-- On new server, restore certificate before restoring database
USE master;
GO

-- Create master key on new server
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKey_ChangeMeInProduction_2025!';
GO

-- Restore certificate
CREATE CERTIFICATE FireProofDB_TDE_Certificate
FROM FILE = 'D:\Certificates\FireProofDB_TDE_Certificate.cer'
WITH PRIVATE KEY (
    FILE = 'D:\Certificates\FireProofDB_TDE_Certificate.key',
    DECRYPTION BY PASSWORD = 'CertificatePassword_ChangeMeInProduction_2025!'
);
GO

-- Now you can restore the encrypted database
RESTORE DATABASE FireProofDB
FROM DISK = 'D:\Backups\FireProofDB.bak'
WITH MOVE 'FireProofDB' TO 'D:\Data\FireProofDB.mdf',
     MOVE 'FireProofDB_log' TO 'D:\Data\FireProofDB_log.ldf';
GO
```

## Performance Impact

**Expected Impact**:
- CPU: 3-5% increase
- I/O: Minimal impact (encryption/decryption in memory)
- Backup Size: No change (backups are also encrypted)

**Monitor Performance**:
```sql
-- Check TDE performance counters
SELECT
    cntr_value AS TDE_IO_Operations
FROM sys.dm_os_performance_counters
WHERE counter_name = 'TDE Database Pages Read/sec';
```

## Verification

```sql
-- Verify TDE is enabled
SELECT
    db_name(database_id) AS DatabaseName,
    CASE encryption_state
        WHEN 3 THEN 'ENCRYPTED - TDE ACTIVE'
        ELSE 'NOT ENCRYPTED'
    END AS Status,
    percent_complete,
    key_algorithm,
    key_length
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID('FireProofDB');

-- Verify certificate exists
SELECT name, expiry_date, subject
FROM sys.certificates
WHERE name = 'FireProofDB_TDE_Certificate';

-- Verify backups are encrypted
SELECT
    database_name,
    backup_start_date,
    is_encrypted,
    encryptor_type,
    encryptor_thumbprint
FROM msdb.dbo.backupset
WHERE database_name = 'FireProofDB'
ORDER BY backup_start_date DESC;
```

## Troubleshooting

### Error: "CREATE DATABASE ENCRYPTION KEY failed"

**Cause**: No certificate available
**Solution**: Create certificate first (Steps 2-3)

### Error: "Cannot restore encrypted database"

**Cause**: Certificate not present on target server
**Solution**: Restore certificate and private key first

### Encryption stuck at 99%

**Cause**: Active transactions
**Solution**: Wait for completion during low-activity period

## Security Best Practices

1. Store certificate backups separate from database backups
2. Use Azure Key Vault for certificate password
3. Document certificate location in runbook
4. Test restore procedure quarterly
5. Monitor certificate expiration (2027-12-31)
6. Rotate certificates before expiration
7. Use strong passwords (32+ characters)
8. Restrict access to certificate files

## Compliance

TDE helps meet compliance requirements for:
- PCI DSS Requirement 3.4 (protect stored data)
- HIPAA Security Rule (encryption at rest)
- GDPR Article 32 (encryption of personal data)
- SOC 2 Type II (data protection controls)

## References

- [SQL Server TDE Documentation](https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption)
- [TDE Performance Best Practices](https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption-performance)
