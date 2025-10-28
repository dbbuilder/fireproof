# Lessons Learned: NULL Value Exceptions in ADO.NET SqlDataReader

**Date**: October 18, 2025
**Issue**: Inspection 500 Error - SqlNullValueException
**Context**: FireProof API using stored procedures with ADO.NET SqlDataReader

## Critical Lesson: NULL Values Cause Multiple Exception Types

### The Problem

When using ADO.NET's `SqlDataReader` with direct `Get*()` methods, NULL values cause **immediate exceptions**:

```csharp
// ❌ THROWS SqlNullValueException if column is NULL
string value = reader.GetString(reader.GetOrdinal("ColumnName"));
bool flag = reader.GetBoolean(reader.GetOrdinal("BoolColumn"));
DateTime date = reader.GetDateTime(reader.GetOrdinal("DateColumn"));
```

### What We Learned (The Hard Way)

1. **String Columns**: `reader.GetString()` throws exception on NULL
2. **Boolean Columns**: `reader.GetBoolean()` throws exception on NULL ⚠️ **CRITICAL**
3. **DateTime Columns**: `reader.GetDateTime()` throws exception on NULL
4. **Numeric Columns**: All `Get*()` methods throw on NULL

### The Fix - Two Approaches

#### Approach 1: Check for NULL in Code (Defensive)
```csharp
// ✅ SAFE - Check for NULL first
string value = reader.IsDBNull(reader.GetOrdinal("ColumnName"))
    ? null
    : reader.GetString(reader.GetOrdinal("ColumnName"));

bool flag = reader.IsDBNull(reader.GetOrdinal("BoolColumn"))
    ? false
    : reader.GetBoolean(reader.GetOrdinal("BoolColumn"));
```

#### Approach 2: Database Schema with NOT NULL Constraints (Preventive) ✅ **RECOMMENDED**
```sql
-- Add DEFAULT constraints and NOT NULL
ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_BoolColumn DEFAULT 0 FOR BoolColumn;
ALTER TABLE dbo.Inspections ALTER COLUMN BoolColumn BIT NOT NULL;
```

**Why Approach 2 is Better:**
- Prevents NULL values at the source
- No performance overhead of NULL checks
- Enforces data integrity
- Makes code simpler and cleaner
- Prevents future bugs

### Our Specific Case

We encountered **two rounds** of NULL value exceptions:

#### Round 1: String Column NULLs
- `InspectionType` → NULL
- `InspectorSignature` → NULL
- `DataHash` → NULL
- Fixed with UPDATE statements

#### Round 2: Boolean Column NULLs (Final Root Cause)
- `NozzleClear` → NULL ⚠️
- `HoseConditionGood` → NULL ⚠️
- Fixed with UPDATE statements + schema changes (NOT NULL constraints)

**Key Insight**: We initially only looked for NULL string values. Boolean NULL values were discovered only after the first fix was deployed and errors persisted.

## Diagnostic Process

### Step 1: Read the Stack Trace
```
System.Data.SqlTypes.SqlNullValueException: Data is Null
   at FireExtinguisherInspection.API.Services.InspectionService.MapInspectionFromReader(SqlDataReader reader) in line 384
```

Line 384 told us exactly which column was failing.

### Step 2: Check Database for NULL Values
```sql
-- Check for NULL string columns
SELECT * FROM Inspections WHERE InspectionType IS NULL OR InspectorSignature IS NULL;

-- Check for NULL boolean columns
SELECT * FROM Inspections WHERE NozzleClear IS NULL OR HoseConditionGood IS NULL;
```

### Step 3: Fix Existing Data
```sql
-- Fix string NULLs
UPDATE dbo.Inspections SET InspectionType = 'Monthly' WHERE InspectionType IS NULL;

-- Fix boolean NULLs
UPDATE dbo.Inspections SET NozzleClear = 0 WHERE NozzleClear IS NULL;
```

### Step 4: Prevent Future NULLs (Schema Changes)
```sql
-- Add NOT NULL constraints with defaults
ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_NozzleClear DEFAULT 0 FOR NozzleClear;
ALTER TABLE dbo.Inspections ALTER COLUMN NozzleClear BIT NOT NULL;
```

### Step 5: Restart App Service
Azure App Service connection pools cache old data. After database changes, restart is **required**:
```bash
az webapp restart --name fireproof-api-test-2025 --resource-group rg-fireproof
```

## Prevention Strategy

### For New Tables
Always define columns with NOT NULL and defaults:
```sql
CREATE TABLE dbo.MyTable (
    Id UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    Name NVARCHAR(100) NOT NULL DEFAULT '',
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
```

### For Existing Tables
Audit and fix nullable columns:
```sql
-- Find all nullable bit columns
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
AND DATA_TYPE = 'bit'
AND IS_NULLABLE = 'YES';
```

### Code Review Checklist
When using `SqlDataReader`:
- [ ] Are all `Get*()` calls protected with `IsDBNull()` checks?
- [ ] OR: Are all columns NOT NULL in the database schema?
- [ ] Have we tested with real production data (which may have NULLs)?

## Common Pitfall: Assumptions About Data

**What We Assumed**: "All boolean columns have values because we set them in the application"
**Reality**: Old data, migrations, manual SQL updates, and imports can create NULL values

**Lesson**: Never assume data integrity. Enforce it at the database level.

## Performance Consideration

Checking for NULL on every `Get*()` call has a small performance cost:
```csharp
// Multiple ordinal lookups
int ordinal = reader.GetOrdinal("ColumnName");
if (!reader.IsDBNull(ordinal)) {
    string value = reader.GetString(ordinal);
}
```

**Better**: Use NOT NULL constraints in schema and trust the database.

## Summary

1. **Root Cause**: NULL values in database + lack of NULL checks in code
2. **Two-Phase Discovery**: String NULLs found first, boolean NULLs found after
3. **Fix**: Update existing data + add NOT NULL constraints with defaults
4. **Prevention**: Always use NOT NULL with defaults for new columns
5. **Restart Required**: App service restart needed after schema changes

## Related Issues Fixed
- JWT Authentication: `/mnt/d/Dev2/fireproof/PRODUCTION_AUTH_FIX.md`
- Extinguisher 500 Error: `/mnt/d/Dev2/fireproof/EXTINGUISHER_500_ERROR_FIX.md`
- Inspection 500 Error: `/mnt/d/Dev2/fireproof/INSPECTION_500_ERROR_FIX.md`
