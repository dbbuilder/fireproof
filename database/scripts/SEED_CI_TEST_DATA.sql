-- =============================================
-- FireProof CI Test Data Seeding
-- Purpose: Create test tenants and users for GitHub Actions integration tests
-- Database: FireProofDB_Test
-- =============================================

USE FireProofDB_Test;
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

INSERT INTO dbo.Tenants (TenantId, CompanyName, SubscriptionLevel, IsActive, CreatedDate, ModifiedDate)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'CI Test Tenant A', 'Professional', 1, GETUTCDATE(), GETUTCDATE()),
    ('22222222-2222-2222-2222-222222222222', 'CI Test Tenant B', 'Professional', 1, GETUTCDATE(), GETUTCDATE());

PRINT 'Test tenants created: CI Test Tenant A, CI Test Tenant B';
GO

-- =============================================
-- Create Test Users
-- =============================================
PRINT 'Creating test users...';

-- Note: Password hash is for 'TestPassword123!' - DO NOT use in production
INSERT INTO dbo.Users (UserId, Email, PasswordHash, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', 'test-a@ci.fireproof.test', 'AQAAAAEAACcQAAAAEDummyHashForTestingOnly', 'CI Test', 'User A', 1, GETUTCDATE(), GETUTCDATE()),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', 'test-b@ci.fireproof.test', 'AQAAAAEAACcQAAAAEDummyHashForTestingOnly', 'CI Test', 'User B', 1, GETUTCDATE(), GETUTCDATE());

PRINT 'Test users created: test-a@ci.fireproof.test, test-b@ci.fireproof.test';
GO

-- =============================================
-- Assign Users to Tenants
-- =============================================
PRINT 'Assigning users to tenants...';

INSERT INTO dbo.UserTenantRoles (UserTenantRoleId, UserId, TenantId, RoleName, CreatedDate)
VALUES
    (NEWID(), 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', '11111111-1111-1111-1111-111111111111', 'Admin', GETUTCDATE()),
    (NEWID(), 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', '22222222-2222-2222-2222-222222222222', 'Admin', GETUTCDATE());

PRINT 'User-tenant assignments complete.';
GO

-- =============================================
-- Create Test Locations
-- =============================================
PRINT 'Creating test locations...';

DECLARE @LocationA_Id UNIQUEIDENTIFIER = 'AAA00000-0000-0000-0000-000000000001';
DECLARE @LocationB_Id UNIQUEIDENTIFIER = 'BBB00000-0000-0000-0000-000000000001';

-- Locations for Tenant A
EXEC dbo.usp_Location_Create
    @TenantId = '11111111-1111-1111-1111-111111111111',
    @LocationCode = 'CI-LOC-A-001',
    @LocationName = 'CI Test Location A-1',
    @Address = '123 Test Street A',
    @City = 'Test City A',
    @StateProvince = 'TS',
    @PostalCode = '12345',
    @Country = 'USA',
    @Latitude = 40.7128,
    @Longitude = -74.0060,
    @IsActive = 1;

-- Locations for Tenant B
EXEC dbo.usp_Location_Create
    @TenantId = '22222222-2222-2222-2222-222222222222',
    @LocationCode = 'CI-LOC-B-001',
    @LocationName = 'CI Test Location B-1',
    @Address = '456 Test Avenue B',
    @City = 'Test City B',
    @StateProvince = 'TS',
    @PostalCode = '67890',
    @Country = 'USA',
    @Latitude = 34.0522,
    @Longitude = -118.2437,
    @IsActive = 1;

PRINT 'Test locations created.';
GO

-- =============================================
-- Create Test Extinguishers
-- =============================================
PRINT 'Creating test extinguishers...';

-- Get location IDs (created by stored procedures)
DECLARE @TenantA_LocationId UNIQUEIDENTIFIER;
DECLARE @TenantB_LocationId UNIQUEIDENTIFIER;

SELECT TOP 1 @TenantA_LocationId = LocationId
FROM dbo.Locations
WHERE TenantId = '11111111-1111-1111-1111-111111111111'
  AND LocationCode = 'CI-LOC-A-001';

SELECT TOP 1 @TenantB_LocationId = LocationId
FROM dbo.Locations
WHERE TenantId = '22222222-2222-2222-2222-222222222222'
  AND LocationCode = 'CI-LOC-B-001';

-- Extinguishers for Tenant A
IF @TenantA_LocationId IS NOT NULL
BEGIN
    EXEC dbo.usp_Extinguisher_Create
        @TenantId = '11111111-1111-1111-1111-111111111111',
        @LocationId = @TenantA_LocationId,
        @AssetTag = 'CI-EXT-A-001',
        @SerialNumber = 'SN-A-001',
        @IsActive = 1;

    EXEC dbo.usp_Extinguisher_Create
        @TenantId = '11111111-1111-1111-1111-111111111111',
        @LocationId = @TenantA_LocationId,
        @AssetTag = 'CI-EXT-A-002',
        @SerialNumber = 'SN-A-002',
        @IsActive = 1;

    PRINT 'Created 2 extinguishers for Tenant A';
END

-- Extinguishers for Tenant B
IF @TenantB_LocationId IS NOT NULL
BEGIN
    EXEC dbo.usp_Extinguisher_Create
        @TenantId = '22222222-2222-2222-2222-222222222222',
        @LocationId = @TenantB_LocationId,
        @AssetTag = 'CI-EXT-B-001',
        @SerialNumber = 'SN-B-001',
        @IsActive = 1;

    EXEC dbo.usp_Extinguisher_Create
        @TenantId = '22222222-2222-2222-2222-222222222222',
        @LocationId = @TenantB_LocationId,
        @AssetTag = 'CI-EXT-B-002',
        @SerialNumber = 'SN-B-002',
        @IsActive = 1;

    PRINT 'Created 2 extinguishers for Tenant B';
END

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
