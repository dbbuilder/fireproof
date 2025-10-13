/*============================================================================
  File:     003_CreateTenantStoredProcedures.sql
  Summary:  Creates stored procedures for tenant management operations
  Date:     October 13, 2025

  Description:
    This script creates stored procedures for:
    - Getting all tenants (SystemAdmin)
    - Getting tenants available to a specific user
    - Getting specific tenant by ID
    - Creating new tenants
    - Updating existing tenants

  Notes:
    - Run this after 001_CreateCoreSchema.sql
    - These procedures support the tenant selection functionality
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Creating Tenant Management Stored Procedures...'
PRINT ''

/*============================================================================
  PROCEDURE: usp_Tenant_GetAll
  Description: Returns all tenants (SystemAdmin only)
  Parameters: None
  Returns: All active tenants
============================================================================*/
IF OBJECT_ID('dbo.usp_Tenant_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_GetAll
GO

CREATE PROCEDURE dbo.usp_Tenant_GetAll
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        TenantId,
        TenantCode,
        CompanyName AS TenantName,
        SubscriptionTier,
        IsActive,
        MaxLocations,
        MaxUsers,
        MaxExtinguishers,
        DatabaseSchema,
        CreatedDate,
        ModifiedDate
    FROM dbo.Tenants
    WHERE IsActive = 1
    ORDER BY CompanyName
END
GO

PRINT '  ✓ Created usp_Tenant_GetAll'

/*============================================================================
  PROCEDURE: usp_Tenant_GetById
  Description: Returns a specific tenant by ID
  Parameters: @TenantId - GUID of the tenant
  Returns: Tenant details or NULL if not found
============================================================================*/
IF OBJECT_ID('dbo.usp_Tenant_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_GetById
GO

CREATE PROCEDURE dbo.usp_Tenant_GetById
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        TenantId,
        TenantCode,
        CompanyName AS TenantName,
        SubscriptionTier,
        IsActive,
        MaxLocations,
        MaxUsers,
        MaxExtinguishers,
        DatabaseSchema,
        CreatedDate,
        ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId
END
GO

PRINT '  ✓ Created usp_Tenant_GetById'

/*============================================================================
  PROCEDURE: usp_Tenant_GetAvailableForUser
  Description: Returns tenants that a specific user has access to
  Parameters: @UserId - GUID of the user
  Returns: List of tenants with user's role information
============================================================================*/
IF OBJECT_ID('dbo.usp_Tenant_GetAvailableForUser', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_GetAvailableForUser
GO

CREATE PROCEDURE dbo.usp_Tenant_GetAvailableForUser
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT DISTINCT
        t.TenantId,
        t.TenantCode,
        t.CompanyName AS TenantName,
        t.SubscriptionTier,
        t.IsActive,
        t.MaxLocations,
        t.MaxUsers,
        t.MaxExtinguishers,
        t.DatabaseSchema,
        t.CreatedDate,
        t.ModifiedDate,
        utr.RoleName
    FROM dbo.Tenants t
    INNER JOIN dbo.UserTenantRoles utr ON t.TenantId = utr.TenantId
    WHERE utr.UserId = @UserId
        AND t.IsActive = 1
        AND utr.IsActive = 1
    ORDER BY t.CompanyName
END
GO

PRINT '  ✓ Created usp_Tenant_GetAvailableForUser'

/*============================================================================
  PROCEDURE: usp_Tenant_Create
  Description: Creates a new tenant
  Parameters: Multiple tenant properties
  Returns: The newly created tenant ID
============================================================================*/
IF OBJECT_ID('dbo.usp_Tenant_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_Create
GO

CREATE PROCEDURE dbo.usp_Tenant_Create
    @TenantCode NVARCHAR(50),
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50) = 'Free',
    @MaxLocations INT = 10,
    @MaxUsers INT = 5,
    @MaxExtinguishers INT = 100
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @NewTenantId UNIQUEIDENTIFIER = NEWID()
    DECLARE @DatabaseSchema NVARCHAR(128) = 'tenant_' + CAST(@NewTenantId AS NVARCHAR(36))

    -- Validate subscription tier
    IF @SubscriptionTier NOT IN ('Free', 'Standard', 'Premium')
    BEGIN
        RAISERROR('Invalid subscription tier. Must be Free, Standard, or Premium', 16, 1)
        RETURN
    END

    -- Check if tenant code already exists
    IF EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantCode = @TenantCode)
    BEGIN
        RAISERROR('Tenant code already exists', 16, 1)
        RETURN
    END

    -- Insert new tenant
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
    VALUES (
        @NewTenantId,
        @TenantCode,
        @CompanyName,
        @SubscriptionTier,
        1, -- IsActive
        @MaxLocations,
        @MaxUsers,
        @MaxExtinguishers,
        @DatabaseSchema,
        GETUTCDATE(),
        GETUTCDATE()
    )

    -- Return the new tenant
    SELECT
        TenantId,
        TenantCode,
        CompanyName AS TenantName,
        SubscriptionTier,
        IsActive,
        MaxLocations,
        MaxUsers,
        MaxExtinguishers,
        DatabaseSchema,
        CreatedDate,
        ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @NewTenantId
END
GO

PRINT '  ✓ Created usp_Tenant_Create'

/*============================================================================
  PROCEDURE: usp_Tenant_Update
  Description: Updates an existing tenant
  Parameters: Tenant ID and properties to update
  Returns: Updated tenant record
============================================================================*/
IF OBJECT_ID('dbo.usp_Tenant_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_Update
GO

CREATE PROCEDURE dbo.usp_Tenant_Update
    @TenantId UNIQUEIDENTIFIER,
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50),
    @MaxLocations INT,
    @MaxUsers INT,
    @MaxExtinguishers INT,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON

    -- Validate subscription tier
    IF @SubscriptionTier NOT IN ('Free', 'Standard', 'Premium')
    BEGIN
        RAISERROR('Invalid subscription tier. Must be Free, Standard, or Premium', 16, 1)
        RETURN
    END

    -- Check if tenant exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantId = @TenantId)
    BEGIN
        RAISERROR('Tenant not found', 16, 1)
        RETURN
    END

    -- Update tenant
    UPDATE dbo.Tenants
    SET
        CompanyName = @CompanyName,
        SubscriptionTier = @SubscriptionTier,
        MaxLocations = @MaxLocations,
        MaxUsers = @MaxUsers,
        MaxExtinguishers = @MaxExtinguishers,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId

    -- Return updated tenant
    SELECT
        TenantId,
        TenantCode,
        CompanyName AS TenantName,
        SubscriptionTier,
        IsActive,
        MaxLocations,
        MaxUsers,
        MaxExtinguishers,
        DatabaseSchema,
        CreatedDate,
        ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId
END
GO

PRINT '  ✓ Created usp_Tenant_Update'

PRINT ''
PRINT '============================================================================'
PRINT 'Tenant Management Stored Procedures created successfully!'
PRINT '============================================================================'
GO
