-- =============================================
-- FireProof CI Test Data Seeding
-- Purpose: Create test tenants and users for GitHub Actions integration tests
-- Database: FireProofDB_Test
-- =============================================

USE FireProofDB_Test;
GO

-- Set required options
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

PRINT 'Starting CI test data seeding...';
GO

-- =============================================
-- Clean up existing test data (if any)
-- =============================================
PRINT 'Cleaning up existing test data...';

DELETE FROM dbo.InspectionDeficiencies WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.InspectionPhotos WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.Inspections WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.ChecklistTemplateItems WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.ChecklistTemplates WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.Extinguishers WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.Locations WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.UserTenantRoles WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
DELETE FROM dbo.Users WHERE UserId IN ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB');
DELETE FROM dbo.Tenants WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

PRINT 'Cleanup complete.';
GO

-- =============================================
-- Create Test Tenants
-- =============================================
PRINT 'Creating test tenants...';

-- Note: Must include all required columns from schema
INSERT INTO dbo.Tenants (
    TenantId,
    TenantCode,
    CompanyName,
    SubscriptionTier,
    IsActive,
    MaxLocations,
    MaxUsers,
    MaxExtinguishers,
    DatabaseSchema,
    CreatedDate,
    ModifiedDate
)
VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'CI-TEST-A',
        'CI Test Tenant A',
        'Standard',
        1,
        100,
        50,
        500,
        'tenant_11111111-1111-1111-1111-111111111111',
        GETUTCDATE(),
        GETUTCDATE()
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'CI-TEST-B',
        'CI Test Tenant B',
        'Standard',
        1,
        100,
        50,
        500,
        'tenant_22222222-2222-2222-2222-222222222222',
        GETUTCDATE(),
        GETUTCDATE()
    );

PRINT 'Test tenants created: CI Test Tenant A, CI Test Tenant B';
GO

-- =============================================
-- Create Test Users
-- =============================================
PRINT 'Creating test users...';

-- Note: Users authenticate via Azure AD B2C, no password stored in database
INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', 'test-a@ci.fireproof.test', 'CI Test', 'User A', 1, GETUTCDATE(), GETUTCDATE()),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', 'test-b@ci.fireproof.test', 'CI Test', 'User B', 1, GETUTCDATE(), GETUTCDATE());

PRINT 'Test users created: test-a@ci.fireproof.test, test-b@ci.fireproof.test';
GO

-- =============================================
-- Assign Users to Tenants
-- =============================================
PRINT 'Assigning users to tenants...';

-- Note: Valid RoleNames are: TenantAdmin, LocationManager, Inspector, Viewer
INSERT INTO dbo.UserTenantRoles (UserTenantRoleId, UserId, TenantId, RoleName, IsActive, CreatedDate)
VALUES
    (NEWID(), 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', '11111111-1111-1111-1111-111111111111', 'TenantAdmin', 1, GETUTCDATE()),
    (NEWID(), 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', '22222222-2222-2222-2222-222222222222', 'TenantAdmin', 1, GETUTCDATE());

PRINT 'User-tenant assignments complete.';
GO

-- =============================================
-- Create Test Locations
-- =============================================
PRINT 'Creating test locations...';

-- Generate LocationIds upfront (stored procedure requires them as INPUT)
DECLARE @LocationA_Id UNIQUEIDENTIFIER = 'AAA00000-0000-0000-0000-000000000001';
DECLARE @LocationB_Id UNIQUEIDENTIFIER = 'BBB00000-0000-0000-0000-000000000001';

-- Location for Tenant A
EXEC dbo.usp_Location_Create
    @LocationId = @LocationA_Id,
    @TenantId = '11111111-1111-1111-1111-111111111111',
    @LocationCode = 'CI-LOC-A-001',
    @LocationName = 'CI Test Location A-1',
    @AddressLine1 = '123 Test Street A',
    @City = 'Test City A',
    @StateProvince = 'TS',
    @PostalCode = '12345',
    @Country = 'USA';

-- Location for Tenant B
EXEC dbo.usp_Location_Create
    @LocationId = @LocationB_Id,
    @TenantId = '22222222-2222-2222-2222-222222222222',
    @LocationCode = 'CI-LOC-B-001',
    @LocationName = 'CI Test Location B-1',
    @AddressLine1 = '456 Test Avenue B',
    @City = 'Test City B',
    @StateProvince = 'TS',
    @PostalCode = '67890',
    @Country = 'USA';

PRINT 'Test locations created.';
GO

-- =============================================
-- Create Test Extinguisher Type (if needed)
-- =============================================
PRINT 'Checking for extinguisher types...';

DECLARE @ExtinguisherTypeId UNIQUEIDENTIFIER;

-- Try to get existing extinguisher type
SELECT TOP 1 @ExtinguisherTypeId = ExtinguisherTypeId
FROM dbo.ExtinguisherTypes
WHERE IsActive = 1;

-- If no extinguisher type exists, create one
IF @ExtinguisherTypeId IS NULL
BEGIN
    SET @ExtinguisherTypeId = NEWID();

    EXEC dbo.usp_ExtinguisherType_Create
        @ExtinguisherTypeId = @ExtinguisherTypeId,
        @TypeCode = 'ABC',
        @TypeName = 'ABC Dry Chemical',
        @Description = 'Standard ABC dry chemical fire extinguisher',
        @MonthlyInspectionRequired = 1,
        @AnnualInspectionRequired = 1,
        @HydrostaticTestYears = 12;

    PRINT 'Created default extinguisher type: ABC Dry Chemical';
END
ELSE
BEGIN
    PRINT 'Using existing extinguisher type';
END

GO

-- =============================================
-- Create Test Extinguishers
-- =============================================
PRINT 'Creating test extinguishers...';

-- Get the extinguisher type
DECLARE @ExtTypeId UNIQUEIDENTIFIER;
SELECT TOP 1 @ExtTypeId = ExtinguisherTypeId
FROM dbo.ExtinguisherTypes
WHERE IsActive = 1;

-- Generate ExtinguisherIds upfront (stored procedure requires them as INPUT)
DECLARE @ExtA1_Id UNIQUEIDENTIFIER = 'AAA10000-0000-0000-0000-000000000001';
DECLARE @ExtA2_Id UNIQUEIDENTIFIER = 'AAA20000-0000-0000-0000-000000000002';
DECLARE @ExtB1_Id UNIQUEIDENTIFIER = 'BBB10000-0000-0000-0000-000000000001';
DECLARE @ExtB2_Id UNIQUEIDENTIFIER = 'BBB20000-0000-0000-0000-000000000002';

-- Extinguishers for Tenant A
EXEC dbo.usp_Extinguisher_Create
    @ExtinguisherId = @ExtA1_Id,
    @TenantId = '11111111-1111-1111-1111-111111111111',
    @LocationId = 'AAA00000-0000-0000-0000-000000000001',
    @ExtinguisherTypeId = @ExtTypeId,
    @AssetTag = 'CI-EXT-A-001',
    @SerialNumber = 'SN-A-001',
    @Manufacturer = 'Test Manufacturer',
    @Model = 'Test Model ABC';

EXEC dbo.usp_Extinguisher_Create
    @ExtinguisherId = @ExtA2_Id,
    @TenantId = '11111111-1111-1111-1111-111111111111',
    @LocationId = 'AAA00000-0000-0000-0000-000000000001',
    @ExtinguisherTypeId = @ExtTypeId,
    @AssetTag = 'CI-EXT-A-002',
    @SerialNumber = 'SN-A-002',
    @Manufacturer = 'Test Manufacturer',
    @Model = 'Test Model ABC';

PRINT 'Created 2 extinguishers for Tenant A';

-- Extinguishers for Tenant B
EXEC dbo.usp_Extinguisher_Create
    @ExtinguisherId = @ExtB1_Id,
    @TenantId = '22222222-2222-2222-2222-222222222222',
    @LocationId = 'BBB00000-0000-0000-0000-000000000001',
    @ExtinguisherTypeId = @ExtTypeId,
    @AssetTag = 'CI-EXT-B-001',
    @SerialNumber = 'SN-B-001',
    @Manufacturer = 'Test Manufacturer',
    @Model = 'Test Model ABC';

EXEC dbo.usp_Extinguisher_Create
    @ExtinguisherId = @ExtB2_Id,
    @TenantId = '22222222-2222-2222-2222-222222222222',
    @LocationId = 'BBB00000-0000-0000-0000-000000000001',
    @ExtinguisherTypeId = @ExtTypeId,
    @AssetTag = 'CI-EXT-B-002',
    @SerialNumber = 'SN-B-002',
    @Manufacturer = 'Test Manufacturer',
    @Model = 'Test Model ABC';

PRINT 'Created 2 extinguishers for Tenant B';

GO

-- =============================================
-- Verification
-- =============================================
PRINT '';
PRINT 'Verifying test data...';
PRINT '======================';

SELECT
    'Tenants' AS DataType,
    COUNT(*) AS RecordCount
FROM dbo.Tenants
WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')

UNION ALL

SELECT
    'Users' AS DataType,
    COUNT(*) AS RecordCount
FROM dbo.Users
WHERE UserId IN ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB')

UNION ALL

SELECT
    'UserTenantRoles' AS DataType,
    COUNT(*) AS RecordCount
FROM dbo.UserTenantRoles
WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')

UNION ALL

SELECT
    'Locations' AS DataType,
    COUNT(*) AS RecordCount
FROM dbo.Locations
WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')

UNION ALL

SELECT
    'Extinguishers' AS DataType,
    COUNT(*) AS RecordCount
FROM dbo.Extinguishers
WHERE TenantId IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

PRINT '';
PRINT 'Test data seeding complete!';
PRINT '';
PRINT 'Summary:';
PRINT '  - Tenant A: 11111111-1111-1111-1111-111111111111 (CI Test Tenant A)';
PRINT '  - Tenant B: 22222222-2222-2222-2222-222222222222 (CI Test Tenant B)';
PRINT '  - User A: test-a@ci.fireproof.test (assigned to Tenant A)';
PRINT '  - User B: test-b@ci.fireproof.test (assigned to Tenant B)';
PRINT '';
PRINT 'Use these tenant IDs in integration tests to verify data isolation.';
GO
