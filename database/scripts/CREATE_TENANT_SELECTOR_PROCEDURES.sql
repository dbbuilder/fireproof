-- =============================================
-- Tenant Selector Stored Procedures
-- Created: October 31, 2025
-- Purpose: Enable SystemAdmin users to switch between tenants
-- =============================================

USE [FireProofDB];
GO

-- =============================================
-- 1. Add LastAccessedTenantId column to Users table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LastAccessedTenantId')
BEGIN
    ALTER TABLE [dbo].[Users]
    ADD LastAccessedTenantId UNIQUEIDENTIFIER NULL,
        LastAccessedDate DATETIME2 NULL;

    PRINT 'Added LastAccessedTenantId and LastAccessedDate columns to Users table';
END
ELSE
BEGIN
    PRINT 'LastAccessedTenantId column already exists in Users table';
END
GO

-- =============================================
-- 2. Get Accessible Tenants for User
-- =============================================
IF OBJECT_ID('dbo.usp_User_GetAccessibleTenants', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetAccessibleTenants;
GO

CREATE PROCEDURE dbo.usp_User_GetAccessibleTenants
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get all tenants the user has access to via UserTenantRoles
    SELECT
        t.TenantId,
        t.CompanyName AS TenantName,
        t.TenantCode,
        utr.RoleName AS UserRole,
        t.IsActive,
        u.LastAccessedDate,
        (SELECT COUNT(*) FROM dbo.Locations WHERE TenantId = t.TenantId AND IsActive = 1) AS LocationCount,
        (SELECT COUNT(*) FROM dbo.Extinguishers WHERE TenantId = t.TenantId AND IsActive = 1) AS ExtinguisherCount
    FROM
        dbo.Tenants t
        INNER JOIN dbo.UserTenantRoles utr ON t.TenantId = utr.TenantId
        INNER JOIN dbo.Users u ON utr.UserId = u.UserId
    WHERE
        utr.UserId = @UserId
        AND t.IsActive = 1
    ORDER BY
        -- Most recently accessed first
        CASE WHEN t.TenantId = u.LastAccessedTenantId THEN 0 ELSE 1 END,
        u.LastAccessedDate DESC,
        t.CompanyName ASC;
END
GO

PRINT 'Created usp_User_GetAccessibleTenants stored procedure';
GO

-- =============================================
-- 3. Update Last Accessed Tenant
-- =============================================
IF OBJECT_ID('dbo.usp_User_UpdateLastAccessedTenant', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_UpdateLastAccessedTenant;
GO

CREATE PROCEDURE dbo.usp_User_UpdateLastAccessedTenant
    @UserId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify user has access to this tenant
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.UserTenantRoles
        WHERE UserId = @UserId AND TenantId = @TenantId
    )
    BEGIN
        RAISERROR('User does not have access to this tenant', 16, 1);
        RETURN;
    END

    -- Update last accessed tenant
    UPDATE dbo.Users
    SET
        LastAccessedTenantId = @TenantId,
        LastAccessedDate = GETUTCDATE(),
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId;

    -- Return updated tenant info
    SELECT
        t.TenantId,
        t.CompanyName AS TenantName,
        t.TenantCode,
        utr.RoleName AS UserRole,
        t.IsActive
    FROM
        dbo.Tenants t
        INNER JOIN dbo.UserTenantRoles utr ON t.TenantId = utr.TenantId
    WHERE
        t.TenantId = @TenantId
        AND utr.UserId = @UserId;
END
GO

PRINT 'Created usp_User_UpdateLastAccessedTenant stored procedure';
GO

-- =============================================
-- 4. Verify Procedures Created Successfully
-- =============================================
PRINT '';
PRINT '=== Tenant Selector Procedures Created ===';
PRINT 'usp_User_GetAccessibleTenants';
PRINT 'usp_User_UpdateLastAccessedTenant';
PRINT '';
PRINT 'Schema changes:';
PRINT '- Added LastAccessedTenantId column to Users table';
PRINT '- Added LastAccessedDate column to Users table';
PRINT '';
PRINT 'Ready for tenant switching functionality!';
GO
