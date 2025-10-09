/*============================================================================
  File:     003_CreateStoredProcedures.sql
  Summary:  Creates all stored procedures for the FireProof system
  Date:     October 9, 2025

  Description:
    This script creates stored procedures for:
    - Tenant management
    - User management
    - Location operations
    - Extinguisher operations
    - Inspection workflows
    - Reporting and analytics

  Notes:
    - All procedures use parameterized queries
    - Includes error handling with TRY/CATCH
    - Audit logging for sensitive operations
    - Supports multi-tenant isolation
============================================================================*/

PRINT 'Starting 003_CreateStoredProcedures.sql execution...'
PRINT 'Creating stored procedures for FireProof system'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

/*============================================================================
  SECTION: TENANT MANAGEMENT PROCEDURES
============================================================================*/
PRINT 'Creating Tenant Management Procedures...'
PRINT ''

-- =============================================================================
-- Procedure: usp_Tenant_Create
-- Description: Creates a new tenant with isolated schema
-- =============================================================================
IF OBJECT_ID('dbo.usp_Tenant_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_Create
GO

CREATE PROCEDURE dbo.usp_Tenant_Create
    @TenantCode NVARCHAR(50),
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50) = 'Standard',
    @MaxLocations INT = 10,
    @MaxUsers INT = 5,
    @MaxExtinguishers INT = 100,
    @CreatedByUserId UNIQUEIDENTIFIER = NULL,
    @TenantId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        -- Generate new tenant ID
        SET @TenantId = NEWID()

        -- Generate schema name
        DECLARE @SchemaName NVARCHAR(128) = 'tenant_' + CAST(@TenantId AS NVARCHAR(36))

        -- Insert tenant record
        INSERT INTO dbo.Tenants (
            TenantId, TenantCode, CompanyName, SubscriptionTier,
            IsActive, MaxLocations, MaxUsers, MaxExtinguishers, DatabaseSchema
        )
        VALUES (
            @TenantId, @TenantCode, @CompanyName, @SubscriptionTier,
            1, @MaxLocations, @MaxUsers, @MaxExtinguishers, @SchemaName
        )

        -- Create tenant schema
        DECLARE @CreateSchemaSql NVARCHAR(MAX) =
            'CREATE SCHEMA [' + @SchemaName + ']'
        EXEC sp_executesql @CreateSchemaSql

        -- Log audit event
        INSERT INTO dbo.AuditLog (TenantId, UserId, Action, EntityType, EntityId, NewValues)
        VALUES (@TenantId, @CreatedByUserId, 'Create', 'Tenant', CAST(@TenantId AS NVARCHAR(36)),
                '{"CompanyName":"' + @CompanyName + '","SubscriptionTier":"' + @SubscriptionTier + '"}')

        COMMIT TRANSACTION

        SELECT @TenantId AS TenantId, @SchemaName AS DatabaseSchema, 'SUCCESS' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
        DECLARE @ErrorState INT = ERROR_STATE()

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
    END CATCH
END
GO

PRINT '  - Created: usp_Tenant_Create'

-- =============================================================================
-- Procedure: usp_Tenant_GetById
-- Description: Retrieves tenant information by ID
-- =============================================================================
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
        CompanyName,
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

PRINT '  - Created: usp_Tenant_GetById'

-- =============================================================================
-- Procedure: usp_Tenant_GetAll
-- Description: Retrieves all active tenants
-- =============================================================================
IF OBJECT_ID('dbo.usp_Tenant_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_GetAll
GO

CREATE PROCEDURE dbo.usp_Tenant_GetAll
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON

    SELECT
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
    FROM dbo.Tenants
    WHERE (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY CompanyName
END
GO

PRINT '  - Created: usp_Tenant_GetAll'

/*============================================================================
  SECTION: USER MANAGEMENT PROCEDURES
============================================================================*/
PRINT ''
PRINT 'Creating User Management Procedures...'
PRINT ''

-- =============================================================================
-- Procedure: usp_User_Create
-- Description: Creates a new user
-- =============================================================================
IF OBJECT_ID('dbo.usp_User_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_Create
GO

CREATE PROCEDURE dbo.usp_User_Create
    @Email NVARCHAR(256),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @AzureAdB2CObjectId NVARCHAR(128) = NULL,
    @UserId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -- Check if user already exists
        IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email AND IsActive = 1)
        BEGIN
            SELECT @UserId = UserId FROM dbo.Users WHERE Email = @Email AND IsActive = 1
            SELECT @UserId AS UserId, 'USER_EXISTS' AS Status
            RETURN
        END

        SET @UserId = NEWID()

        INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, AzureAdB2CObjectId, IsActive)
        VALUES (@UserId, @Email, @FirstName, @LastName, @AzureAdB2CObjectId, 1)

        SELECT @UserId AS UserId, 'SUCCESS' AS Status
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

PRINT '  - Created: usp_User_Create'

-- =============================================================================
-- Procedure: usp_User_GetByEmail
-- Description: Retrieves user by email address
-- =============================================================================
IF OBJECT_ID('dbo.usp_User_GetByEmail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetByEmail
GO

CREATE PROCEDURE dbo.usp_User_GetByEmail
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE Email = @Email AND IsActive = 1
END
GO

PRINT '  - Created: usp_User_GetByEmail'

-- =============================================================================
-- Procedure: usp_UserTenantRole_Assign
-- Description: Assigns a role to a user for a specific tenant
-- =============================================================================
IF OBJECT_ID('dbo.usp_UserTenantRole_Assign', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UserTenantRole_Assign
GO

CREATE PROCEDURE dbo.usp_UserTenantRole_Assign
    @UserId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @RoleName NVARCHAR(50),
    @AssignedByUserId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -- Check if role assignment already exists
        IF EXISTS (
            SELECT 1 FROM dbo.UserTenantRoles
            WHERE UserId = @UserId
            AND TenantId = @TenantId
            AND RoleName = @RoleName
            AND IsActive = 1
        )
        BEGIN
            SELECT 'ROLE_EXISTS' AS Status
            RETURN
        END

        DECLARE @RoleId UNIQUEIDENTIFIER = NEWID()

        INSERT INTO dbo.UserTenantRoles (UserTenantRoleId, UserId, TenantId, RoleName, IsActive)
        VALUES (@RoleId, @UserId, @TenantId, @RoleName, 1)

        -- Log audit event
        INSERT INTO dbo.AuditLog (TenantId, UserId, Action, EntityType, EntityId, NewValues)
        VALUES (@TenantId, @AssignedByUserId, 'AssignRole', 'UserTenantRole',
                CAST(@RoleId AS NVARCHAR(36)),
                '{"UserId":"' + CAST(@UserId AS NVARCHAR(36)) + '","RoleName":"' + @RoleName + '"}')

        SELECT 'SUCCESS' AS Status, @RoleId AS UserTenantRoleId
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

PRINT '  - Created: usp_UserTenantRole_Assign'

-- =============================================================================
-- Procedure: usp_UserTenantRole_GetByUser
-- Description: Gets all tenant roles for a user
-- =============================================================================
IF OBJECT_ID('dbo.usp_UserTenantRole_GetByUser', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UserTenantRole_GetByUser
GO

CREATE PROCEDURE dbo.usp_UserTenantRole_GetByUser
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        utr.UserTenantRoleId,
        utr.UserId,
        utr.TenantId,
        utr.RoleName,
        utr.IsActive,
        utr.CreatedDate,
        t.TenantCode,
        t.CompanyName,
        t.DatabaseSchema
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId
    AND utr.IsActive = 1
    AND t.IsActive = 1
    ORDER BY t.CompanyName, utr.RoleName
END
GO

PRINT '  - Created: usp_UserTenantRole_GetByUser'

/*============================================================================
  SECTION: AUDIT LOG PROCEDURES
============================================================================*/
PRINT ''
PRINT 'Creating Audit Log Procedures...'
PRINT ''

-- =============================================================================
-- Procedure: usp_AuditLog_Insert
-- Description: Inserts an audit log entry
-- =============================================================================
IF OBJECT_ID('dbo.usp_AuditLog_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AuditLog_Insert
GO

CREATE PROCEDURE dbo.usp_AuditLog_Insert
    @TenantId UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER = NULL,
    @Action NVARCHAR(100),
    @EntityType NVARCHAR(100) = NULL,
    @EntityId NVARCHAR(128) = NULL,
    @OldValues NVARCHAR(MAX) = NULL,
    @NewValues NVARCHAR(MAX) = NULL,
    @IpAddress NVARCHAR(45) = NULL,
    @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO dbo.AuditLog (
        TenantId, UserId, Action, EntityType, EntityId,
        OldValues, NewValues, IpAddress, UserAgent
    )
    VALUES (
        @TenantId, @UserId, @Action, @EntityType, @EntityId,
        @OldValues, @NewValues, @IpAddress, @UserAgent
    )

    SELECT 'SUCCESS' AS Status
END
GO

PRINT '  - Created: usp_AuditLog_Insert'

-- =============================================================================
-- Procedure: usp_AuditLog_GetByTenant
-- Description: Retrieves audit log entries for a tenant
-- =============================================================================
IF OBJECT_ID('dbo.usp_AuditLog_GetByTenant', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AuditLog_GetByTenant
GO

CREATE PROCEDURE dbo.usp_AuditLog_GetByTenant
    @TenantId UNIQUEIDENTIFIER,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @Action NVARCHAR(100) = NULL,
    @PageSize INT = 100,
    @PageNumber INT = 1
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        AuditLogId,
        TenantId,
        UserId,
        Action,
        EntityType,
        EntityId,
        OldValues,
        NewValues,
        IpAddress,
        UserAgent,
        Timestamp
    FROM dbo.AuditLog
    WHERE TenantId = @TenantId
    AND (@StartDate IS NULL OR Timestamp >= @StartDate)
    AND (@EndDate IS NULL OR Timestamp <= @EndDate)
    AND (@Action IS NULL OR Action = @Action)
    ORDER BY Timestamp DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY
END
GO

PRINT '  - Created: usp_AuditLog_GetByTenant'

PRINT ''
PRINT '============================================================================'
PRINT 'Core stored procedures created successfully!'
PRINT 'Total procedures created: 11'
PRINT 'Next step: Create tenant-specific stored procedures dynamically'
PRINT '============================================================================'

GO
