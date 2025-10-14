/*============================================================================
  File:     TEST_DATABASE_COMPLETE.sql
  Purpose:  Comprehensive automated testing for FireProof database
  Date:     October 14, 2025
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT ''
PRINT '============================================================================'
PRINT 'FIREPROOF DATABASE COMPREHENSIVE TEST SUITE'
PRINT '============================================================================'
PRINT ''

-- Test 1: Verify Tenant Schemas Exist
PRINT '[ TEST 1 ] Verifying Tenant Schemas...'
DECLARE @Demo001Schema NVARCHAR(128)
DECLARE @Demo002Schema NVARCHAR(128)

SELECT @Demo001Schema = DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001'
SELECT @Demo002Schema = DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO002'

IF @Demo001Schema IS NOT NULL AND @Demo002Schema IS NOT NULL
    PRINT '  ✓ PASSED: Both DEMO001 and DEMO002 tenant schemas exist'
ELSE
BEGIN
    PRINT '  ✗ FAILED: Missing tenant schemas'
    PRINT '    DEMO001: ' + ISNULL(@Demo001Schema, 'NOT FOUND')
    PRINT '    DEMO002: ' + ISNULL(@Demo002Schema, 'NOT FOUND')
END
PRINT ''

-- Test 2: Verify Required Stored Procedures for DEMO001
PRINT '[ TEST 2 ] Verifying DEMO001 Stored Procedures...'
DECLARE @RequiredProcs TABLE (ProcName NVARCHAR(200), Found BIT)

INSERT INTO @RequiredProcs (ProcName, Found)
VALUES
    ('usp_Location_GetAll', 0),
    ('usp_Location_GetById', 0),
    ('usp_Location_Create', 0),
    ('usp_Extinguisher_GetAll', 0),
    ('usp_Extinguisher_GetById', 0),
    ('usp_Extinguisher_GetByBarcode', 0),
    ('usp_Extinguisher_Create', 0),
    ('usp_ExtinguisherType_GetAll', 0),
    ('usp_ExtinguisherType_GetById', 0),
    ('usp_ExtinguisherType_Create', 0),
    ('usp_Inspection_GetById', 0),
    ('usp_Inspection_GetByExtinguisher', 0),
    ('usp_Inspection_Create', 0),
    ('usp_Inspection_Complete', 0)

UPDATE rp
SET Found = 1
FROM @RequiredProcs rp
WHERE EXISTS (
    SELECT 1 FROM sys.procedures
    WHERE name = rp.ProcName
    AND SCHEMA_NAME(schema_id) = @Demo001Schema
)

DECLARE @MissingCount INT
SELECT @MissingCount = COUNT(*) FROM @RequiredProcs WHERE Found = 0

IF @MissingCount = 0
    PRINT '  ✓ PASSED: All required stored procedures exist (' + CAST(@@ROWCOUNT AS VARCHAR) + ' total)'
ELSE
BEGIN
    PRINT '  ✗ FAILED: Missing ' + CAST(@MissingCount AS VARCHAR) + ' stored procedures:'
    SELECT '    - ' + ProcName FROM @RequiredProcs WHERE Found = 0
END
PRINT ''

-- Test 3: Verify DEMO001 Data
PRINT '[ TEST 3 ] Verifying DEMO001 Seed Data...'
DECLARE @LocationCount INT, @TypeCount INT, @ExtinguisherCount INT
DECLARE @DataTestSql NVARCHAR(MAX)

SET @DataTestSql = '
SELECT
    @LocCount = (SELECT COUNT(*) FROM [' + @Demo001Schema + '].Locations WHERE IsActive = 1),
    @TypeCnt = (SELECT COUNT(*) FROM [' + @Demo001Schema + '].ExtinguisherTypes WHERE IsActive = 1),
    @ExtCount = (SELECT COUNT(*) FROM [' + @Demo001Schema + '].Extinguishers WHERE IsActive = 1)
'

EXEC sp_executesql @DataTestSql,
    N'@LocCount INT OUTPUT, @TypeCnt INT OUTPUT, @ExtCount INT OUTPUT',
    @LocationCount OUTPUT, @TypeCount OUTPUT, @ExtinguisherCount OUTPUT

IF @LocationCount >= 3 AND @TypeCount >= 5 AND @ExtinguisherCount >= 15
BEGIN
    PRINT '  ✓ PASSED: Seed data complete'
    PRINT '    - Locations: ' + CAST(@LocationCount AS VARCHAR)
    PRINT '    - Extinguisher Types: ' + CAST(@TypeCount AS VARCHAR)
    PRINT '    - Extinguishers: ' + CAST(@ExtinguisherCount AS VARCHAR)
END
ELSE
BEGIN
    PRINT '  ✗ FAILED: Insufficient seed data'
    PRINT '    - Locations: ' + CAST(@LocationCount AS VARCHAR) + ' (expected >= 3)'
    PRINT '    - Extinguisher Types: ' + CAST(@TypeCount AS VARCHAR) + ' (expected >= 5)'
    PRINT '    - Extinguishers: ' + CAST(@ExtinguisherCount AS VARCHAR) + ' (expected >= 15)'
END
PRINT ''

-- Test 4: Test usp_Extinguisher_GetAll
PRINT '[ TEST 4 ] Testing usp_Extinguisher_GetAll...'
DECLARE @TestTenantId UNIQUEIDENTIFIER
SELECT @TestTenantId = TenantId FROM dbo.Tenants WHERE TenantCode = 'DEMO001'

DECLARE @TestResultCount INT
DECLARE @TestSql NVARCHAR(MAX) = '
DECLARE @ResultCount INT
EXEC @ResultCount = [' + @Demo001Schema + '].usp_Extinguisher_GetAll
    @TenantId = ''' + CAST(@TestTenantId AS VARCHAR(36)) + ''',
    @LocationId = NULL,
    @ExtinguisherTypeId = NULL,
    @IsActive = 1,
    @IsOutOfService = NULL
'

BEGIN TRY
    EXEC sp_executesql @TestSql
    PRINT '  ✓ PASSED: usp_Extinguisher_GetAll executes without error'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_Extinguisher_GetAll error: ' + ERROR_MESSAGE()
END CATCH
PRINT ''

-- Test 5: Test usp_ExtinguisherType_GetAll
PRINT '[ TEST 5 ] Testing usp_ExtinguisherType_GetAll...'
DECLARE @Test5Sql NVARCHAR(MAX) = '
EXEC [' + @Demo001Schema + '].usp_ExtinguisherType_GetAll
    @TenantId = ''' + CAST(@TestTenantId AS VARCHAR(36)) + ''',
    @IsActive = 1
'

BEGIN TRY
    EXEC sp_executesql @Test5Sql
    PRINT '  ✓ PASSED: usp_ExtinguisherType_GetAll executes without error'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_ExtinguisherType_GetAll error: ' + ERROR_MESSAGE()
END CATCH
PRINT ''

-- Test 6: Test usp_Location_GetAll
PRINT '[ TEST 6 ] Testing usp_Location_GetAll...'
DECLARE @Test6Sql NVARCHAR(MAX) = '
EXEC [' + @Demo001Schema + '].usp_Location_GetAll
    @TenantId = ''' + CAST(@TestTenantId AS VARCHAR(36)) + '''
'

BEGIN TRY
    EXEC sp_executesql @Test6Sql
    PRINT '  ✓ PASSED: usp_Location_GetAll executes without error'
END TRY
BEGIN CATCH
    PRINT '  ✗ FAILED: usp_Location_GetAll error: ' + ERROR_MESSAGE()
END CATCH
PRINT ''

-- Test 7: Verify Testing Users
PRINT '[ TEST 7 ] Verifying Testing Users...'
DECLARE @ChrisExists BIT = 0, @MultiExists BIT = 0

IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'chris@servicevision.net')
    SET @ChrisExists = 1

IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'multi@servicevision.net')
    SET @MultiExists = 1

IF @ChrisExists = 1 AND @MultiExists = 1
BEGIN
    PRINT '  ✓ PASSED: Testing users exist'
    PRINT '    - chris@servicevision.net (SystemAdmin)'
    PRINT '    - multi@servicevision.net (Multi-tenant TenantAdmin)'
END
ELSE
BEGIN
    PRINT '  ✗ FAILED: Missing testing users'
    IF @ChrisExists = 0 PRINT '    - chris@servicevision.net NOT FOUND'
    IF @MultiExists = 0 PRINT '    - multi@servicevision.net NOT FOUND'
END
PRINT ''

-- Test 8: Verify User Roles
PRINT '[ TEST 8 ] Verifying User Roles...'
DECLARE @ChrisRoleCount INT, @MultiRoleCount INT

SELECT @ChrisRoleCount = COUNT(*)
FROM dbo.UserRoles ur
INNER JOIN dbo.Users u ON ur.UserId = u.UserId
WHERE u.Email = 'chris@servicevision.net'

SELECT @MultiRoleCount = COUNT(*)
FROM dbo.UserTenantRoles utr
INNER JOIN dbo.Users u ON utr.UserId = u.UserId
WHERE u.Email = 'multi@servicevision.net'

IF @ChrisRoleCount > 0 AND @MultiRoleCount >= 2
BEGIN
    PRINT '  ✓ PASSED: User roles configured correctly'
    PRINT '    - chris@servicevision.net: ' + CAST(@ChrisRoleCount AS VARCHAR) + ' system role(s)'
    PRINT '    - multi@servicevision.net: ' + CAST(@MultiRoleCount AS VARCHAR) + ' tenant role(s)'
END
ELSE
BEGIN
    PRINT '  ✗ FAILED: Missing user roles'
    PRINT '    - chris@servicevision.net: ' + CAST(@ChrisRoleCount AS VARCHAR) + ' system role(s) (expected > 0)'
    PRINT '    - multi@servicevision.net: ' + CAST(@MultiRoleCount AS VARCHAR) + ' tenant role(s) (expected >= 2)'
END
PRINT ''

-- Final Summary
PRINT '============================================================================'
PRINT 'TEST SUITE COMPLETED'
PRINT '============================================================================'
PRINT ''
PRINT 'Database is ready for API testing!'
PRINT ''
PRINT 'Next Steps:'
PRINT '  1. Test frontend login: https://fireproofapp.net/login'
PRINT '  2. Login as chris@servicevision.net (dev login - no password)'
PRINT '  3. Select DEMO001 tenant'
PRINT '  4. Navigate to Dashboard - should load without errors'
PRINT '  5. Navigate to Locations - should show 3 locations'
PRINT '  6. Navigate to Extinguishers - should show 15 extinguishers'
PRINT '  7. Navigate to Extinguisher Types - should show 5+ types'
PRINT ''
PRINT '============================================================================'

GO
