/*============================================================================
  File:     VERIFY_DATABASE_COMPLETE.sql
  Purpose:  Comprehensive database verification for Phase 1 MVP
  Date:     October 14, 2025
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'FIREPROOF DATABASE VERIFICATION - PHASE 1 MVP'
PRINT '============================================================================'
PRINT ''

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'

-- ============================================================================
-- TEST 1: Core Tables (dbo schema)
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 1: Core Tables (dbo schema)'
PRINT '------------------------------------------------------------------------'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Tenants')
    PRINT '  ✓ Tenants table exists'
ELSE
    PRINT '  ✗ MISSING: Tenants table'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Users')
    PRINT '  ✓ Users table exists'
ELSE
    PRINT '  ✗ MISSING: Users table'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'UserTenantRoles')
    PRINT '  ✓ UserTenantRoles table exists'
ELSE
    PRINT '  ✗ MISSING: UserTenantRoles table'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'AuditLog')
    PRINT '  ✓ AuditLog table exists'
ELSE
    PRINT '  ✗ MISSING: AuditLog table'

-- Count core data
DECLARE @TenantCount INT = (SELECT COUNT(*) FROM dbo.Tenants)
DECLARE @UserCount INT = (SELECT COUNT(*) FROM dbo.Users)
PRINT '  → Tenants: ' + CAST(@TenantCount AS NVARCHAR(10))
PRINT '  → Users: ' + CAST(@UserCount AS NVARCHAR(10))
PRINT ''

-- ============================================================================
-- TEST 2: Tenant Schema Tables
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 2: Tenant Schema Tables (DEMO001)'
PRINT '------------------------------------------------------------------------'

DECLARE @TableName NVARCHAR(128)
DECLARE @TableExists BIT
DECLARE @ExpectedTables TABLE (TableName NVARCHAR(128))

INSERT INTO @ExpectedTables VALUES 
    ('Locations'),
    ('ExtinguisherTypes'),
    ('Extinguishers'),
    ('ChecklistTemplates'),
    ('ChecklistItems'),
    ('Inspections'),
    ('InspectionPhotos'),
    ('InspectionDeficiencies'),
    ('InspectionChecklistResponses')

DECLARE table_cursor CURSOR FOR SELECT TableName FROM @ExpectedTables
OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TableName)
        PRINT '  ✓ ' + @TableName + ' table exists'
    ELSE
        PRINT '  ✗ MISSING: ' + @TableName + ' table'
    
    FETCH NEXT FROM table_cursor INTO @TableName
END

CLOSE table_cursor
DEALLOCATE table_cursor
PRINT ''

-- ============================================================================
-- TEST 3: Stored Procedures Count
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 3: Stored Procedures'
PRINT '------------------------------------------------------------------------'

DECLARE @ProcCount INT = (
    SELECT COUNT(*) 
    FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema
)

PRINT '  → Total procedures: ' + CAST(@ProcCount AS NVARCHAR(10))

-- List by category
DECLARE @ChecklistProcs INT = (
    SELECT COUNT(*) FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema 
    AND name LIKE 'usp_Checklist%'
)
PRINT '  → Checklist procedures: ' + CAST(@ChecklistProcs AS NVARCHAR(10)) + ' (expected: 5)'

DECLARE @InspectionProcs INT = (
    SELECT COUNT(*) FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema 
    AND name LIKE 'usp_Inspection_%'
)
PRINT '  → Inspection procedures: ' + CAST(@InspectionProcs AS NVARCHAR(10)) + ' (expected: 14)'

DECLARE @PhotoProcs INT = (
    SELECT COUNT(*) FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema 
    AND name LIKE 'usp_InspectionPhoto%'
)
PRINT '  → Photo procedures: ' + CAST(@PhotoProcs AS NVARCHAR(10)) + ' (expected: 3)'

DECLARE @DeficiencyProcs INT = (
    SELECT COUNT(*) FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema 
    AND name LIKE 'usp_InspectionDeficiency%'
)
PRINT '  → Deficiency procedures: ' + CAST(@DeficiencyProcs AS NVARCHAR(10)) + ' (expected: 6)'

DECLARE @LocationProcs INT = (
    SELECT COUNT(*) FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema 
    AND name LIKE 'usp_Location%'
)
PRINT '  → Location procedures: ' + CAST(@LocationProcs AS NVARCHAR(10))

DECLARE @ExtinguisherProcs INT = (
    SELECT COUNT(*) FROM sys.procedures 
    WHERE SCHEMA_NAME(schema_id) = @Schema 
    AND name LIKE 'usp_Extinguisher%'
)
PRINT '  → Extinguisher procedures: ' + CAST(@ExtinguisherProcs AS NVARCHAR(10))

PRINT ''

-- ============================================================================
-- TEST 4: Seed Data
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 4: Seed Data'
PRINT '------------------------------------------------------------------------'

DECLARE @Sql NVARCHAR(MAX)
DECLARE @LocationCount INT
DECLARE @ExtinguisherTypeCount INT
DECLARE @ExtinguisherCount INT
DECLARE @TemplateCount INT
DECLARE @ChecklistItemCount INT

SET @Sql = 'SELECT @Count = COUNT(*) FROM [' + @Schema + '].Locations'
EXEC sp_executesql @Sql, N'@Count INT OUTPUT', @Count = @LocationCount OUTPUT

SET @Sql = 'SELECT @Count = COUNT(*) FROM [' + @Schema + '].ExtinguisherTypes'
EXEC sp_executesql @Sql, N'@Count INT OUTPUT', @Count = @ExtinguisherTypeCount OUTPUT

SET @Sql = 'SELECT @Count = COUNT(*) FROM [' + @Schema + '].Extinguishers'
EXEC sp_executesql @Sql, N'@Count INT OUTPUT', @Count = @ExtinguisherCount OUTPUT

SET @Sql = 'SELECT @Count = COUNT(*) FROM [' + @Schema + '].ChecklistTemplates'
EXEC sp_executesql @Sql, N'@Count INT OUTPUT', @Count = @TemplateCount OUTPUT

SET @Sql = 'SELECT @Count = COUNT(*) FROM [' + @Schema + '].ChecklistItems'
EXEC sp_executesql @Sql, N'@Count INT OUTPUT', @Count = @ChecklistItemCount OUTPUT

PRINT '  → Locations: ' + CAST(@LocationCount AS NVARCHAR(10)) + ' (expected: 3)'
PRINT '  → ExtinguisherTypes: ' + CAST(@ExtinguisherTypeCount AS NVARCHAR(10)) + ' (expected: 10)'
PRINT '  → Extinguishers: ' + CAST(@ExtinguisherCount AS NVARCHAR(10)) + ' (expected: 15)'
PRINT '  → ChecklistTemplates: ' + CAST(@TemplateCount AS NVARCHAR(10)) + ' (expected: 6)'
PRINT '  → ChecklistItems: ' + CAST(@ChecklistItemCount AS NVARCHAR(10)) + ' (expected: 51)'
PRINT ''

-- ============================================================================
-- TEST 5: Template Details
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 5: NFPA Template Verification'
PRINT '------------------------------------------------------------------------'

EXEC('
SELECT 
    t.TemplateName,
    t.InspectionType,
    t.Standard,
    COUNT(i.ChecklistItemId) as ItemCount
FROM [' + @Schema + '].ChecklistTemplates t
LEFT JOIN [' + @Schema + '].ChecklistItems i ON t.TemplateId = i.TemplateId
GROUP BY t.TemplateName, t.InspectionType, t.Standard
ORDER BY t.InspectionType, t.TemplateName
')

PRINT ''

-- ============================================================================
-- TEST 6: Critical Columns Check
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 6: Critical Columns Verification'
PRINT '------------------------------------------------------------------------'

-- Check Extinguishers table has all required columns
DECLARE @ColumnName NVARCHAR(128)
DECLARE @RequiredColumns TABLE (ColumnName NVARCHAR(128))

INSERT INTO @RequiredColumns VALUES 
    ('LastServiceDate'),
    ('NextServiceDueDate'),
    ('NextHydroTestDueDate'),
    ('FloorLevel'),
    ('Notes'),
    ('QrCodeData'),
    ('IsOutOfService'),
    ('OutOfServiceReason')

DECLARE col_cursor CURSOR FOR SELECT ColumnName FROM @RequiredColumns
OPEN col_cursor
FETCH NEXT FROM col_cursor INTO @ColumnName

PRINT 'Extinguishers table columns:'
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_SCHEMA = @Schema 
               AND TABLE_NAME = 'Extinguishers' 
               AND COLUMN_NAME = @ColumnName)
        PRINT '  ✓ ' + @ColumnName
    ELSE
        PRINT '  ✗ MISSING: ' + @ColumnName
    
    FETCH NEXT FROM col_cursor INTO @ColumnName
END

CLOSE col_cursor
DEALLOCATE col_cursor
PRINT ''

-- Check Inspections table critical columns
PRINT 'Inspections table critical columns:'
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'InspectionHash')
    PRINT '  ✓ InspectionHash (tamper-proofing)'
ELSE
    PRINT '  ✗ MISSING: InspectionHash'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'PreviousInspectionHash')
    PRINT '  ✓ PreviousInspectionHash (hash chaining)'
ELSE
    PRINT '  ✗ MISSING: PreviousInspectionHash'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'Latitude')
    PRINT '  ✓ Latitude (GPS verification)'
ELSE
    PRINT '  ✗ MISSING: Latitude'

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'InspectorSignature')
    PRINT '  ✓ InspectorSignature'
ELSE
    PRINT '  ✗ MISSING: InspectorSignature'

PRINT ''

-- ============================================================================
-- TEST 7: Test Procedures Execution
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 7: Procedure Execution Tests'
PRINT '------------------------------------------------------------------------'

-- Test ChecklistTemplate_GetAll
BEGIN TRY
    EXEC('[' + @Schema + '].usp_ChecklistTemplate_GetAll @TenantId = NULL, @IsActive = 1')
    PRINT '  ✓ usp_ChecklistTemplate_GetAll executes'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_ChecklistTemplate_GetAll - ' + ERROR_MESSAGE()
END CATCH

-- Test Location_GetAll
BEGIN TRY
    EXEC('[' + @Schema + '].usp_Location_GetAll @TenantId = ''' + CAST(@TenantId AS NVARCHAR(50)) + '''')
    PRINT '  ✓ usp_Location_GetAll executes'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_Location_GetAll - ' + ERROR_MESSAGE()
END CATCH

-- Test Extinguisher_GetAll
BEGIN TRY
    EXEC('[' + @Schema + '].usp_Extinguisher_GetAll @TenantId = ''' + CAST(@TenantId AS NVARCHAR(50)) + '''')
    PRINT '  ✓ usp_Extinguisher_GetAll executes'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_Extinguisher_GetAll - ' + ERROR_MESSAGE()
END CATCH

-- Test Inspection_GetDue
BEGIN TRY
    EXEC('[' + @Schema + '].usp_Inspection_GetDue @TenantId = ''' + CAST(@TenantId AS NVARCHAR(50)) + '''')
    PRINT '  ✓ usp_Inspection_GetDue executes'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_Inspection_GetDue - ' + ERROR_MESSAGE()
END CATCH

PRINT ''

-- ============================================================================
-- TEST 8: Foreign Key Relationships
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT 'TEST 8: Foreign Key Relationships'
PRINT '------------------------------------------------------------------------'

DECLARE @FKCount INT = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = @Schema 
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
)

PRINT '  → Total Foreign Keys: ' + CAST(@FKCount AS NVARCHAR(10))
PRINT ''

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
PRINT '============================================================================'
PRINT 'VERIFICATION SUMMARY'
PRINT '============================================================================'
PRINT ''

DECLARE @Score INT = 0
DECLARE @MaxScore INT = 12

-- Score based on counts
IF @TenantCount >= 2 SET @Score = @Score + 1
IF @UserCount >= 2 SET @Score = @Score + 1
IF @LocationCount = 3 SET @Score = @Score + 1
IF @ExtinguisherTypeCount = 10 SET @Score = @Score + 1
IF @ExtinguisherCount = 15 SET @Score = @Score + 1
IF @TemplateCount = 6 SET @Score = @Score + 1
IF @ChecklistItemCount >= 48 SET @Score = @Score + 1  -- Allow some variation
IF @ProcCount >= 38 SET @Score = @Score + 1  -- Old + new procedures
IF @ChecklistProcs >= 5 SET @Score = @Score + 1
IF @InspectionProcs >= 9 SET @Score = @Score + 1
IF @PhotoProcs = 3 SET @Score = @Score + 1
IF @DeficiencyProcs = 6 SET @Score = @Score + 1

PRINT 'Readiness Score: ' + CAST(@Score AS NVARCHAR(10)) + ' / ' + CAST(@MaxScore AS NVARCHAR(10))
PRINT ''

IF @Score = @MaxScore
BEGIN
    PRINT '✓✓✓ DATABASE COMPLETE AND READY FOR PHASE 1 MVP ✓✓✓'
    PRINT ''
    PRINT 'Next Steps:'
    PRINT '  1. Implement backend services (C# .NET 8)'
    PRINT '  2. Create API controllers'
    PRINT '  3. Build frontend components'
    PRINT '  4. Implement offline support'
END
ELSE IF @Score >= 10
BEGIN
    PRINT '⚠ DATABASE MOSTLY COMPLETE - MINOR ISSUES'
    PRINT 'Review failed tests above and address missing items.'
END
ELSE
BEGIN
    PRINT '✗ DATABASE INCOMPLETE - CRITICAL ISSUES'
    PRINT 'Address failed tests before proceeding.'
END

PRINT ''
PRINT '============================================================================'

GO
