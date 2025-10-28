# FireProof Database Schema Deployment Guide

## Current Production State (October 18, 2025)

### Quick Stats
- **18 Tables** with complete schema
- **69 Stored Procedures** operational
- **35 Foreign Keys** enforcing integrity
- **32 Indexes** optimized for performance
- **RLS Enabled** for multi-tenant isolation
- **3 Super Admin Users** active

## Fresh Database Deployment

For deploying to a new environment (staging, DR, new production):

### Step 1: Create Database
```sql
CREATE DATABASE FireProofDB
GO
```

### Step 2: Deploy Schema (In Order)
Execute these files from `/database/schema-archive/2025-10-18/`:

```bash
# 1. Create schemas
sqlcmd -S <server> -d FireProofDB -U <user> -P <password> -i 01_CREATE_SCHEMAS.sql

# 2. Create tables
sqlcmd -S <server> -d FireProofDB -U <user> -P <password> -i 02_CREATE_TABLES.sql

# 3. Add constraints
sqlcmd -S <server> -d FireProofDB -U <user> -P <password> -i 03_CREATE_CONSTRAINTS.sql

# 4. Create indexes
sqlcmd -S <server> -d FireProofDB -U <user> -P <password> -i 04_CREATE_INDEXES.sql

# 5. Create stored procedures
sqlcmd -S <server> -d FireProofDB -U <user> -P <password> -i 06_CREATE_PROCEDURES.sql
```

### Step 3: Seed Initial Data
```bash
# Seed test data (CI/CD environments)
sqlcmd -S <server> -d FireProofDB -U <user> -P <password> -i /database/scripts/SEED_CI_TEST_DATA.sql
```

### Step 4: Create Super Admin User
```sql
EXEC dbo.usp_CreateSuperAdmin
    @FirstName = 'Your',
    @LastName = 'Name',
    @Email = 'your.email@example.com',
    @TemplateUserEmail = 'chris@servicevision.net'  -- Copy roles from existing admin
```

Default password: `FireProofIt!`

## Schema Evolution Process

### Making Schema Changes

1. **Create Migration Script**
   - Name: `database/scripts/YYYY_MMDD_DescriptiveNameMigration.sql`
   - Include rollback script (commented)
   - Test on development database first

2. **Test Migration**
   ```bash
   # Apply to development
   sqlcmd -S dev-server -d FireProofDB -U user -P password -i your_migration.sql

   # Verify no errors
   # Test affected functionality
   ```

3. **Deploy to Staging**
   ```bash
   sqlcmd -S staging-server -d FireProofDB -U user -P password -i your_migration.sql
   ```

4. **Deploy to Production**
   ```bash
   sqlcmd -S prod-server -d FireProofDB -U user -P password -i your_migration.sql
   ```

5. **Archive Current Schema**
   ```bash
   cd /mnt/d/dev2/dbbuilder/SQLExtract
   source venv/bin/activate

   python sqlextract.py \
       --server prod-server \
       --port 14333 \
       --database FireProofDB \
       --user sv \
       --password 'your-password' \
       --trust-cert \
       --output /mnt/d/Dev2/fireproof/database/schema-archive/$(date +%Y-%m-%d)
   ```

6. **Archive Old Scripts**
   ```bash
   mkdir -p database/scripts-archive/$(date +%Y-%m-%d)-description
   cp database/scripts/affected-scripts.sql database/scripts-archive/$(date +%Y-%m-%d)-description/
   ```

## Common Operations

### Add New Table

```sql
-- database/scripts/2025_MMDD_AddNewTable.sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE dbo.NewTable (
    NewTableId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_NewTable_Tenant FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId)
)
GO

CREATE NONCLUSTERED INDEX IX_NewTable_TenantId ON dbo.NewTable(TenantId)
GO
```

### Add Column to Existing Table

```sql
-- database/scripts/2025_MMDD_AddColumnToTable.sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Add column with default
ALTER TABLE dbo.TableName
ADD NewColumn NVARCHAR(100) NULL
GO

-- If NOT NULL required, add default constraint first
ALTER TABLE dbo.TableName
ADD CONSTRAINT DF_TableName_NewColumn DEFAULT 'DefaultValue' FOR NewColumn
GO

-- Then make NOT NULL
ALTER TABLE dbo.TableName
ALTER COLUMN NewColumn NVARCHAR(100) NOT NULL
GO
```

### Add Stored Procedure

```sql
-- database/scripts/2025_MMDD_CreateNewProcedure.sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.usp_NewProcedure
    @TenantId UNIQUEIDENTIFIER,
    @Parameter NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT * FROM dbo.TableName
        WHERE TenantId = @TenantId
          AND Column = @Parameter
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END
GO
```

## Important Schema Constraints

### Boolean Columns
**ALWAYS** use NOT NULL with DEFAULT:

```sql
ALTER TABLE dbo.TableName
ADD BooleanColumn BIT NOT NULL DEFAULT 0
```

**Why:** Prevents SqlNullValueException when using `reader.GetBoolean()`

### String Columns
For optional strings, either:

```sql
-- Option 1: Allow NULL, use defensive code
StringColumn NVARCHAR(100) NULL

-- Option 2: Use empty string default
StringColumn NVARCHAR(100) NOT NULL DEFAULT ''
```

### TenantId Column
**REQUIRED** for all tenant-specific tables:

```sql
TenantId UNIQUEIDENTIFIER NOT NULL,
CONSTRAINT FK_TableName_Tenant FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId)
```

### Audit Columns
**RECOMMENDED** for all tables:

```sql
CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
IsActive BIT NOT NULL DEFAULT 1
```

## Connection Strings

### Development
```
Server=sqltest.schoolvision.net,14333;Database=FireProofDB;User Id=sv;Password=Gv51076!;TrustServerCertificate=True;Encrypt=Optional;MultipleActiveResultSets=true;Connection Timeout=30
```

**Key Points:**
- Use `Connection Timeout` (with space), NOT `ConnectTimeout`
- Use `Encrypt=Optional` for SQL Server named instances
- `TrustServerCertificate=True` for self-signed certs
- `MultipleActiveResultSets=true` for concurrent queries

### Production (Azure SQL)
```
Server=tcp:fireproof-db.database.windows.net,1433;Database=FireProofDB;User Id=sqladmin;Password=<from-keyvault>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30
```

## Disaster Recovery

### Backup Current Schema
Always before major changes:

```bash
# Extract schema
cd /mnt/d/dev2/dbbuilder/SQLExtract
source venv/bin/activate

python sqlextract.py \
    --server prod-server \
    --database FireProofDB \
    --user sv \
    --password 'password' \
    --trust-cert \
    --output ./backup-$(date +%Y%m%d-%H%M%S)
```

### Restore Schema
Use deployment files from schema archive.

### Restore Data
```sql
-- Export data
bcp dbo.TableName out table_data.bcp -S server -d FireProofDB -U user -P password -n

-- Import data
bcp dbo.TableName in table_data.bcp -S server -d FireProofDB -U user -P password -n
```

## Troubleshooting

### NULL Value Exceptions
```
Error: Data is Null. This method or property cannot be called on Null values.
```

**Fix:** Add NOT NULL constraints with defaults

```sql
-- Update existing data
UPDATE dbo.TableName SET BooleanColumn = 0 WHERE BooleanColumn IS NULL

-- Add constraint
ALTER TABLE dbo.TableName
ALTER COLUMN BooleanColumn BIT NOT NULL
```

### Connection Timeout
```
Error: Keyword not supported: 'connecttimeout'
```

**Fix:** Use `Connection Timeout` (with space)

### RLS Not Working
Check tenant context is being passed:

```sql
-- In stored procedure
WHERE TableName.TenantId = @TenantId
```

All queries MUST filter by TenantId.

## Best Practices

1. **Always test migrations on development first**
2. **Keep schema archives after every major change**
3. **Document all schema changes in migration scripts**
4. **Use transactions for data migrations**
5. **Add indexes for foreign keys and common queries**
6. **Use NOT NULL constraints for required fields**
7. **Default values prevent NULL exceptions**
8. **All stored procedures need TRY/CATCH blocks**
9. **Filter by TenantId in all tenant-specific queries**
10. **Archive old scripts after schema extraction**

## References

- **Current Schema**: `/database/schema-archive/2025-10-18/`
- **Archive Scripts**: `/database/scripts-archive/2025-10-18-pre-schema-extract/`
- **SQLExtract Tool**: `https://github.com/dbbuilder/SQLExtract`
- **TODO.md**: Updated October 18, 2025
- **Lessons Learned**: `/LESSONS_LEARNED_NULL_VALUES.md`

---
Last Updated: October 18, 2025
Maintained by: FireProof Development Team
