/*============================================================================
  File:     006_CreateAuthStoredProcedures.sql
  Summary:  Creates stored procedures for JWT authentication
  Date:     October 9, 2025

  Description:
    This script creates all stored procedures needed for JWT authentication
    including user registration, login, token refresh, and password reset.

  Stored Procedures:
    - usp_User_Register: Register new user
    - usp_User_GetByEmail: Get user by email for login
    - usp_User_UpdateRefreshToken: Update refresh token
    - usp_User_GetByRefreshToken: Get user by refresh token
    - usp_User_UpdatePassword: Update password hash
    - usp_User_UpdateLastLogin: Update last login date
    - usp_User_GetRoles: Get all roles for a user (system + tenant roles)
============================================================================*/

PRINT 'Starting 006_CreateAuthStoredProcedures.sql execution...'
PRINT 'Creating authentication stored procedures'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

/*============================================================================
  PROCEDURE: usp_User_Register
  Description: Register a new user with password
============================================================================*/
PRINT 'Creating procedure: usp_User_Register'

IF OBJECT_ID('dbo.usp_User_Register', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_Register
GO

CREATE PROCEDURE dbo.usp_User_Register
    @Email NVARCHAR(256),
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @PasswordHash NVARCHAR(500),
    @PasswordSalt NVARCHAR(500),
    @PhoneNumber NVARCHAR(20) = NULL,
    @UserId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email AND IsActive = 1)
    BEGIN
        RAISERROR('User with this email already exists', 16, 1)
        RETURN
    END

    -- Create new user
    SET @UserId = NEWID()

    INSERT INTO dbo.Users (
        UserId,
        Email,
        FirstName,
        LastName,
        PasswordHash,
        PasswordSalt,
        PhoneNumber,
        EmailConfirmed,
        IsActive,
        CreatedDate,
        ModifiedDate
    )
    VALUES (
        @UserId,
        @Email,
        @FirstName,
        @LastName,
        @PasswordHash,
        @PasswordSalt,
        @PhoneNumber,
        0, -- Email not confirmed by default
        1,
        GETUTCDATE(),
        GETUTCDATE()
    )

    -- Return the created user
    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE UserId = @UserId
END
GO

PRINT '  - Created usp_User_Register'

/*============================================================================
  PROCEDURE: usp_User_GetByEmail
  Description: Get user by email for login authentication
============================================================================*/
PRINT 'Creating procedure: usp_User_GetByEmail'

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
        PasswordHash,
        PasswordSalt,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE Email = @Email AND IsActive = 1
END
GO

PRINT '  - Created usp_User_GetByEmail'

/*============================================================================
  PROCEDURE: usp_User_UpdateRefreshToken
  Description: Update user's refresh token and expiry
============================================================================*/
PRINT 'Creating procedure: usp_User_UpdateRefreshToken'

IF OBJECT_ID('dbo.usp_User_UpdateRefreshToken', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_UpdateRefreshToken
GO

CREATE PROCEDURE dbo.usp_User_UpdateRefreshToken
    @UserId UNIQUEIDENTIFIER,
    @RefreshToken NVARCHAR(500),
    @RefreshTokenExpiryDate DATETIME2
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        RefreshToken = @RefreshToken,
        RefreshTokenExpiryDate = @RefreshTokenExpiryDate,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END
GO

PRINT '  - Created usp_User_UpdateRefreshToken'

/*============================================================================
  PROCEDURE: usp_User_GetByRefreshToken
  Description: Get user by refresh token for token refresh
============================================================================*/
PRINT 'Creating procedure: usp_User_GetByRefreshToken'

IF OBJECT_ID('dbo.usp_User_GetByRefreshToken', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetByRefreshToken
GO

CREATE PROCEDURE dbo.usp_User_GetByRefreshToken
    @RefreshToken NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE RefreshToken = @RefreshToken
        AND RefreshTokenExpiryDate > GETUTCDATE()
        AND IsActive = 1
END
GO

PRINT '  - Created usp_User_GetByRefreshToken'

/*============================================================================
  PROCEDURE: usp_User_UpdatePassword
  Description: Update user's password hash and salt
============================================================================*/
PRINT 'Creating procedure: usp_User_UpdatePassword'

IF OBJECT_ID('dbo.usp_User_UpdatePassword', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_UpdatePassword
GO

CREATE PROCEDURE dbo.usp_User_UpdatePassword
    @UserId UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(500),
    @PasswordSalt NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        PasswordHash = @PasswordHash,
        PasswordSalt = @PasswordSalt,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END
GO

PRINT '  - Created usp_User_UpdatePassword'

/*============================================================================
  PROCEDURE: usp_User_UpdateLastLogin
  Description: Update user's last login date
============================================================================*/
PRINT 'Creating procedure: usp_User_UpdateLastLogin'

IF OBJECT_ID('dbo.usp_User_UpdateLastLogin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_UpdateLastLogin
GO

CREATE PROCEDURE dbo.usp_User_UpdateLastLogin
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        LastLoginDate = GETUTCDATE(),
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END
GO

PRINT '  - Created usp_User_UpdateLastLogin'

/*============================================================================
  PROCEDURE: usp_User_GetRoles
  Description: Get all roles for a user (both system and tenant roles)
============================================================================*/
PRINT 'Creating procedure: usp_User_GetRoles'

IF OBJECT_ID('dbo.usp_User_GetRoles', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetRoles
GO

CREATE PROCEDURE dbo.usp_User_GetRoles
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    -- Get system roles
    SELECT
        'System' AS RoleType,
        NULL AS TenantId,
        sr.RoleName,
        sr.Description,
        usr.IsActive
    FROM dbo.UserSystemRoles usr
    INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
    WHERE usr.UserId = @UserId AND usr.IsActive = 1

    UNION ALL

    -- Get tenant roles
    SELECT
        'Tenant' AS RoleType,
        utr.TenantId,
        utr.RoleName,
        t.CompanyName AS Description,
        utr.IsActive
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId AND utr.IsActive = 1
    ORDER BY RoleType, RoleName
END
GO

PRINT '  - Created usp_User_GetRoles'

/*============================================================================
  PROCEDURE: usp_User_ConfirmEmail
  Description: Confirm user's email address
============================================================================*/
PRINT 'Creating procedure: usp_User_ConfirmEmail'

IF OBJECT_ID('dbo.usp_User_ConfirmEmail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_ConfirmEmail
GO

CREATE PROCEDURE dbo.usp_User_ConfirmEmail
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    UPDATE dbo.Users
    SET
        EmailConfirmed = 1,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    SELECT @@ROWCOUNT AS RowsAffected
END
GO

PRINT '  - Created usp_User_ConfirmEmail'

/*============================================================================
  PROCEDURE: usp_User_GetById
  Description: Get user by ID (without password fields)
============================================================================*/
PRINT 'Creating procedure: usp_User_GetById'

IF OBJECT_ID('dbo.usp_User_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetById
GO

CREATE PROCEDURE dbo.usp_User_GetById
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE UserId = @UserId
END
GO

PRINT '  - Created usp_User_GetById'

/*============================================================================
  PROCEDURE: usp_User_AssignToTenant
  Description: Assign a user to a tenant with a specific role
============================================================================*/
PRINT 'Creating procedure: usp_User_AssignToTenant'

IF OBJECT_ID('dbo.usp_User_AssignToTenant', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_AssignToTenant
GO

CREATE PROCEDURE dbo.usp_User_AssignToTenant
    @UserId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserId = @UserId AND IsActive = 1)
    BEGIN
        RAISERROR('User not found', 16, 1)
        RETURN
    END

    -- Check if tenant exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantId = @TenantId AND IsActive = 1)
    BEGIN
        RAISERROR('Tenant not found', 16, 1)
        RETURN
    END

    -- Check if assignment already exists
    IF EXISTS (
        SELECT 1 FROM dbo.UserTenantRoles
        WHERE UserId = @UserId AND TenantId = @TenantId AND RoleName = @RoleName AND IsActive = 1
    )
    BEGIN
        RAISERROR('User already assigned to this tenant with this role', 16, 1)
        RETURN
    END

    -- Create assignment
    INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
    VALUES (@UserId, @TenantId, @RoleName, 1, GETUTCDATE())

    -- Return the created assignment
    SELECT
        UserTenantRoleId,
        UserId,
        TenantId,
        RoleName,
        IsActive,
        CreatedDate
    FROM dbo.UserTenantRoles
    WHERE UserId = @UserId AND TenantId = @TenantId AND RoleName = @RoleName AND IsActive = 1
END
GO

PRINT '  - Created usp_User_AssignToTenant'

/*============================================================================
  PROCEDURE: usp_User_DevLogin
  Description: Development-only login bypass (NO PASSWORD CHECK)
  WARNING: Only use in development! Must be disabled in production!
============================================================================*/
PRINT 'Creating procedure: usp_User_DevLogin'

IF OBJECT_ID('dbo.usp_User_DevLogin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_DevLogin
GO

CREATE PROCEDURE dbo.usp_User_DevLogin
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON

    -- Return user WITHOUT password verification
    -- This allows instant login for testing
    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE Email = @Email AND IsActive = 1

    -- Update last login
    UPDATE dbo.Users
    SET LastLoginDate = GETUTCDATE()
    WHERE Email = @Email AND IsActive = 1
END
GO

PRINT '  - Created usp_User_DevLogin (DEVELOPMENT ONLY - DISABLE IN PRODUCTION!)'

/*============================================================================
  SEED DATA: Create development test users
============================================================================*/
PRINT 'Creating development test users...'

-- Create dev admin user (if not exists)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'dev@fireproof.local')
BEGIN
    DECLARE @DevAdminId UNIQUEIDENTIFIER = NEWID()

    INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, EmailConfirmed, IsActive)
    VALUES (@DevAdminId, 'dev@fireproof.local', 'Dev', 'Admin', 1, 1)

    -- Get a tenant to assign to
    DECLARE @FirstTenantId UNIQUEIDENTIFIER = (SELECT TOP 1 TenantId FROM dbo.Tenants WHERE IsActive = 1)

    IF @FirstTenantId IS NOT NULL
    BEGIN
        INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive)
        VALUES (@DevAdminId, @FirstTenantId, 'TenantAdmin', 1)
    END

    PRINT '  - Created dev@fireproof.local (TenantAdmin)'
END

-- Create dev inspector user (if not exists)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'inspector@fireproof.local')
BEGIN
    DECLARE @DevInspectorId UNIQUEIDENTIFIER = NEWID()

    INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, EmailConfirmed, IsActive)
    VALUES (@DevInspectorId, 'inspector@fireproof.local', 'Dev', 'Inspector', 1, 1)

    -- Get a tenant to assign to
    DECLARE @FirstTenant UNIQUEIDENTIFIER = (SELECT TOP 1 TenantId FROM dbo.Tenants WHERE IsActive = 1)

    IF @FirstTenant IS NOT NULL
    BEGIN
        INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive)
        VALUES (@DevInspectorId, @FirstTenant, 'Inspector', 1)
    END

    PRINT '  - Created inspector@fireproof.local (Inspector)'
END

-- Create dev system admin user (if not exists)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'sysadmin@fireproof.local')
BEGIN
    DECLARE @DevSysAdminId UNIQUEIDENTIFIER = NEWID()

    INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, EmailConfirmed, IsActive)
    VALUES (@DevSysAdminId, 'sysadmin@fireproof.local', 'System', 'Admin', 1, 1)

    -- Assign system admin role
    DECLARE @SystemAdminRole UNIQUEIDENTIFIER = (SELECT SystemRoleId FROM dbo.SystemRoles WHERE RoleName = 'SystemAdmin')

    IF @SystemAdminRole IS NOT NULL
    BEGIN
        INSERT INTO dbo.UserSystemRoles (UserId, SystemRoleId, IsActive)
        VALUES (@DevSysAdminId, @SystemAdminRole, 1)
    END

    PRINT '  - Created sysadmin@fireproof.local (SystemAdmin)'
END

PRINT ''
PRINT 'Development test users created:'
PRINT '  Email: dev@fireproof.local (TenantAdmin)'
PRINT '  Email: inspector@fireproof.local (Inspector)'
PRINT '  Email: sysadmin@fireproof.local (SystemAdmin)'
PRINT ''
PRINT 'Use these emails with /api/auth/dev-login endpoint for instant login'
PRINT 'WARNING: Disable dev-login endpoint in production!'
PRINT ''

/*============================================================================
  VERIFICATION: Check that all procedures were created successfully
============================================================================*/
PRINT ''
PRINT 'Verifying stored procedure creation...'

IF OBJECT_ID('dbo.usp_User_Register', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_Register'
ELSE
    PRINT '  ✗ ERROR: usp_User_Register was not created'

IF OBJECT_ID('dbo.usp_User_GetByEmail', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_GetByEmail'
ELSE
    PRINT '  ✗ ERROR: usp_User_GetByEmail was not created'

IF OBJECT_ID('dbo.usp_User_UpdateRefreshToken', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_UpdateRefreshToken'
ELSE
    PRINT '  ✗ ERROR: usp_User_UpdateRefreshToken was not created'

IF OBJECT_ID('dbo.usp_User_GetByRefreshToken', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_GetByRefreshToken'
ELSE
    PRINT '  ✗ ERROR: usp_User_GetByRefreshToken was not created'

IF OBJECT_ID('dbo.usp_User_UpdatePassword', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_UpdatePassword'
ELSE
    PRINT '  ✗ ERROR: usp_User_UpdatePassword was not created'

IF OBJECT_ID('dbo.usp_User_UpdateLastLogin', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_UpdateLastLogin'
ELSE
    PRINT '  ✗ ERROR: usp_User_UpdateLastLogin was not created'

IF OBJECT_ID('dbo.usp_User_GetRoles', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_GetRoles'
ELSE
    PRINT '  ✗ ERROR: usp_User_GetRoles was not created'

IF OBJECT_ID('dbo.usp_User_ConfirmEmail', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_ConfirmEmail'
ELSE
    PRINT '  ✗ ERROR: usp_User_ConfirmEmail was not created'

IF OBJECT_ID('dbo.usp_User_GetById', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_GetById'
ELSE
    PRINT '  ✗ ERROR: usp_User_GetById was not created'

IF OBJECT_ID('dbo.usp_User_AssignToTenant', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_AssignToTenant'
ELSE
    PRINT '  ✗ ERROR: usp_User_AssignToTenant was not created'

IF OBJECT_ID('dbo.usp_User_DevLogin', 'P') IS NOT NULL
    PRINT '  ✓ usp_User_DevLogin (DEVELOPMENT ONLY)'
ELSE
    PRINT '  ✗ ERROR: usp_User_DevLogin was not created'

PRINT ''
PRINT '============================================================================'
PRINT 'Authentication stored procedures created successfully!'
PRINT 'Total procedures created: 11'
PRINT '============================================================================'

GO
