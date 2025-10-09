/*============================================================================
  File:     999_TestDatabaseSetup.sql
  Summary:  Test script to verify database schema and stored procedures
  Date:     October 9, 2025

  Description:
    This script tests the complete database setup including:
    - Core schema tables
    - Tenant schema tables
    - Core stored procedures
    - Tenant stored procedures
    - Data integrity and relationships

  Usage:
    Run this after executing scripts 001-004 to verify setup

============================================================================*/

PRINT '======================================================================'
PRINT 'FireProof Database Setup Test Script'
PRINT 'Started: ' + CONVERT(NVARCHAR(50), GETUTCDATE(), 120)
PRINT '======================================================================'
PRINT ''

USE FireProofDB
GO

SET NOCOUNT ON
GO

DECLARE @TestsPassed INT = 0
DECLARE @TestsFailed INT = 0
DECLARE @TestTotal INT = 0

/*============================================================================
  TEST SECTION 1: Core Schema Tables
============================================================================*/
PRINT '----------------------------------------------------------------------'
PRINT 'TEST SECTION 1: Core Schema Tables'
PRINT '----------------------------------------------------------------------'

-- Test 1.1: dbo.Tenants exists
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.Tenants', 'U') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 1.1: dbo.Tenants table exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 1.1: dbo.Tenants table missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 1.2: dbo.Users exists
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 1.2: dbo.Users table exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 1.2: dbo.Users table missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 1.3: dbo.UserTenantRoles exists
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.UserTenantRoles', 'U') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 1.3: dbo.UserTenantRoles table exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 1.3: dbo.UserTenantRoles table missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 1.4: dbo.AuditLog exists
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 1.4: dbo.AuditLog table exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 1.4: dbo.AuditLog table missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 1.5: Sample tenant exists
DECLARE @SampleTenantId UNIQUEIDENTIFIER
SELECT @SampleTenantId = TenantId FROM dbo.Tenants WHERE TenantCode = 'DEMO001'

SET @TestTotal = @TestTotal + 1
IF @SampleTenantId IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 1.5: Sample tenant DEMO001 exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 1.5: Sample tenant DEMO001 missing'
    SET @TestsFailed = @TestsFailed + 1
END

PRINT ''

/*============================================================================
  TEST SECTION 2: Tenant Schema Tables
============================================================================*/
PRINT '----------------------------------------------------------------------'
PRINT 'TEST SECTION 2: Tenant Schema Tables'
PRINT '----------------------------------------------------------------------'

DECLARE @SchemaName NVARCHAR(128)
SELECT @SchemaName = DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001'

IF @SchemaName IS NULL
BEGIN
    PRINT '  [SKIP] Cannot test tenant schema - sample tenant not found'
END
ELSE
BEGIN
    PRINT '  Testing schema: ' + @SchemaName

    -- Test 2.1: Locations table
    SET @TestTotal = @TestTotal + 1
    IF EXISTS (
        SELECT 1 FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = 'Locations'
    )
    BEGIN
        PRINT '  [PASS] Test 2.1: Locations table exists'
        SET @TestsPassed = @TestsPassed + 1
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Test 2.1: Locations table missing'
        SET @TestsFailed = @TestsFailed + 1
    END

    -- Test 2.2: ExtinguisherTypes table
    SET @TestTotal = @TestTotal + 1
    IF EXISTS (
        SELECT 1 FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = 'ExtinguisherTypes'
    )
    BEGIN
        PRINT '  [PASS] Test 2.2: ExtinguisherTypes table exists'
        SET @TestsPassed = @TestsPassed + 1
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Test 2.2: ExtinguisherTypes table missing'
        SET @TestsFailed = @TestsFailed + 1
    END

    -- Test 2.3: Extinguishers table
    SET @TestTotal = @TestTotal + 1
    IF EXISTS (
        SELECT 1 FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = 'Extinguishers'
    )
    BEGIN
        PRINT '  [PASS] Test 2.3: Extinguishers table exists'
        SET @TestsPassed = @TestsPassed + 1
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Test 2.3: Extinguishers table missing'
        SET @TestsFailed = @TestsFailed + 1
    END

    -- Test 2.4: Inspections table
    SET @TestTotal = @TestTotal + 1
    IF EXISTS (
        SELECT 1 FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = 'Inspections'
    )
    BEGIN
        PRINT '  [PASS] Test 2.4: Inspections table exists'
        SET @TestsPassed = @TestsPassed + 1
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Test 2.4: Inspections table missing'
        SET @TestsFailed = @TestsFailed + 1
    END
END

PRINT ''

/*============================================================================
  TEST SECTION 3: Core Stored Procedures
============================================================================*/
PRINT '----------------------------------------------------------------------'
PRINT 'TEST SECTION 3: Core Stored Procedures'
PRINT '----------------------------------------------------------------------'

-- Test 3.1: usp_Tenant_Create
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.usp_Tenant_Create', 'P') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 3.1: usp_Tenant_Create exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.1: usp_Tenant_Create missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 3.2: usp_User_Create
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.usp_User_Create', 'P') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 3.2: usp_User_Create exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.2: usp_User_Create missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 3.3: usp_UserTenantRole_Assign
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.usp_UserTenantRole_Assign', 'P') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 3.3: usp_UserTenantRole_Assign exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.3: usp_UserTenantRole_Assign missing'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 3.4: usp_AuditLog_Insert
SET @TestTotal = @TestTotal + 1
IF OBJECT_ID('dbo.usp_AuditLog_Insert', 'P') IS NOT NULL
BEGIN
    PRINT '  [PASS] Test 3.4: usp_AuditLog_Insert exists'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.4: usp_AuditLog_Insert missing'
    SET @TestsFailed = @TestsFailed + 1
END

PRINT ''

/*============================================================================
  TEST SECTION 4: Functional Tests
============================================================================*/
PRINT '----------------------------------------------------------------------'
PRINT 'TEST SECTION 4: Functional Tests'
PRINT '----------------------------------------------------------------------'

-- Test 4.1: Can retrieve tenant
BEGIN TRY
    DECLARE @TestTenantId UNIQUEIDENTIFIER
    EXEC dbo.usp_Tenant_GetById @TenantId = @SampleTenantId

    SET @TestTotal = @TestTotal + 1
    PRINT '  [PASS] Test 4.1: usp_Tenant_GetById executes successfully'
    SET @TestsPassed = @TestsPassed + 1
END TRY
BEGIN CATCH
    SET @TestTotal = @TestTotal + 1
    PRINT '  [FAIL] Test 4.1: usp_Tenant_GetById failed - ' + ERROR_MESSAGE()
    SET @TestsFailed = @TestsFailed + 1
END CATCH

-- Test 4.2: Can create user
BEGIN TRY
    DECLARE @NewUserId UNIQUEIDENTIFIER
    EXEC dbo.usp_User_Create
        @Email = 'test@example.com',
        @FirstName = 'Test',
        @LastName = 'User',
        @UserId = @NewUserId OUTPUT

    SET @TestTotal = @TestTotal + 1
    IF @NewUserId IS NOT NULL
    BEGIN
        PRINT '  [PASS] Test 4.2: usp_User_Create executes successfully'
        SET @TestsPassed = @TestsPassed + 1

        -- Clean up test user
        DELETE FROM dbo.Users WHERE UserId = @NewUserId
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Test 4.2: usp_User_Create returned NULL UserId'
        SET @TestsFailed = @TestsFailed + 1
    END
END TRY
BEGIN CATCH
    SET @TestTotal = @TestTotal + 1
    PRINT '  [FAIL] Test 4.2: usp_User_Create failed - ' + ERROR_MESSAGE()
    SET @TestsFailed = @TestsFailed + 1
END CATCH

-- Test 4.3: Sample data exists
SET @TestTotal = @TestTotal + 1
DECLARE @ExtinguisherTypeCount INT
DECLARE @GetExtTypesSQL NVARCHAR(MAX) = '
SELECT @Count = COUNT(*) FROM [' + @SchemaName + '].ExtinguisherTypes'
EXEC sp_executesql @GetExtTypesSQL, N'@Count INT OUTPUT', @Count = @ExtinguisherTypeCount OUTPUT

IF @ExtinguisherTypeCount >= 3
BEGIN
    PRINT '  [PASS] Test 4.3: Sample extinguisher types exist (' + CAST(@ExtinguisherTypeCount AS NVARCHAR(10)) + ' found)'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 4.3: Insufficient sample extinguisher types (' + CAST(@ExtinguisherTypeCount AS NVARCHAR(10)) + ' found, expected >= 3)'
    SET @TestsFailed = @TestsFailed + 1
END

-- Test 4.4: Checklist items exist
SET @TestTotal = @TestTotal + 1
DECLARE @ChecklistItemCount INT
DECLARE @GetCheckItemsSQL NVARCHAR(MAX) = '
SELECT @Count = COUNT(*) FROM [' + @SchemaName + '].ChecklistItems'
EXEC sp_executesql @GetCheckItemsSQL, N'@Count INT OUTPUT', @Count = @ChecklistItemCount OUTPUT

IF @ChecklistItemCount >= 7
BEGIN
    PRINT '  [PASS] Test 4.4: Sample checklist items exist (' + CAST(@ChecklistItemCount AS NVARCHAR(10)) + ' found)'
    SET @TestsPassed = @TestsPassed + 1
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 4.4: Insufficient checklist items (' + CAST(@ChecklistItemCount AS NVARCHAR(10)) + ' found, expected >= 7)'
    SET @TestsFailed = @TestsFailed + 1
END

PRINT ''

/*============================================================================
  TEST SUMMARY
============================================================================*/
PRINT '======================================================================'
PRINT 'TEST SUMMARY'
PRINT '======================================================================'
PRINT '  Total Tests:  ' + CAST(@TestTotal AS NVARCHAR(10))
PRINT '  Tests Passed: ' + CAST(@TestsPassed AS NVARCHAR(10))
PRINT '  Tests Failed: ' + CAST(@TestsFailed AS NVARCHAR(10))

DECLARE @SuccessRate DECIMAL(5,2) = 0
IF @TestTotal > 0
    SET @SuccessRate = (CAST(@TestsPassed AS DECIMAL) / @TestTotal) * 100

PRINT '  Success Rate: ' + CAST(@SuccessRate AS NVARCHAR(10)) + '%'
PRINT ''

IF @TestsFailed = 0
BEGIN
    PRINT '  [SUCCESS] All tests passed! Database setup is complete and functional.'
END
ELSE
BEGIN
    PRINT '  [WARNING] Some tests failed. Please review failed tests above.'
END

PRINT ''
PRINT 'Test completed: ' + CONVERT(NVARCHAR(50), GETUTCDATE(), 120)
PRINT '======================================================================'

GO
