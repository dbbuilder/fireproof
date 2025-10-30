/*============================================================================
  File:     CREATE_USER_MANAGEMENT_PROCEDURES.sql
  Summary:  Creates stored procedures for user management (admin features)
  Date:     2025-01-30

  Procedures:
    - usp_User_GetAll
    - usp_User_Update
    - usp_User_Delete (soft delete)
    - usp_User_AssignSystemRole
    - usp_User_RemoveSystemRole
    - usp_User_GetSystemRoles
    - usp_User_GetTenantRoles
============================================================================*/

USE FireProofDB
GO

-- Drop existing procedures if they exist
IF OBJECT_ID('dbo.usp_User_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetAll
GO

IF OBJECT_ID('dbo.usp_User_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_Update
GO

IF OBJECT_ID('dbo.usp_User_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_Delete
GO

IF OBJECT_ID('dbo.usp_User_AssignSystemRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_AssignSystemRole
GO

IF OBJECT_ID('dbo.usp_User_RemoveSystemRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_RemoveSystemRole
GO

IF OBJECT_ID('dbo.usp_User_GetSystemRoles', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetSystemRoles
GO

IF OBJECT_ID('dbo.usp_User_GetTenantRoles', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetTenantRoles
GO

PRINT 'Creating user management stored procedures...'
PRINT ''

/*============================================================================
  Procedure: usp_User_GetAll
  Description: Retrieves all users with optional filtering
  Parameters:
    @SearchTerm - Optional search term for email, first name, or last name
    @IsActive - Optional filter by active status (NULL = all users)
    @PageNumber - Page number for pagination (1-based)
    @PageSize - Number of records per page
============================================================================*/
CREATE PROCEDURE dbo.usp_User_GetAll
    @SearchTerm NVARCHAR(256) = NULL,
    @IsActive BIT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1
    IF @PageSize < 1 SET @PageSize = 50
    IF @PageSize > 100 SET @PageSize = 100

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize

    -- Get total count
    DECLARE @TotalCount INT
    SELECT @TotalCount = COUNT(*)
    FROM dbo.Users u
    WHERE (@IsActive IS NULL OR u.IsActive = @IsActive)
      AND (
          @SearchTerm IS NULL OR
          u.Email LIKE '%' + @SearchTerm + '%' OR
          u.FirstName LIKE '%' + @SearchTerm + '%' OR
          u.LastName LIKE '%' + @SearchTerm + '%'
      )

    -- Get paginated users with role counts
    SELECT
        u.UserId,
        u.Email,
        u.FirstName,
        u.LastName,
        u.PhoneNumber,
        u.EmailConfirmed,
        u.MfaEnabled,
        u.LastLoginDate,
        u.IsActive,
        u.CreatedDate,
        u.ModifiedDate,
        -- Add system role count
        (SELECT COUNT(*) FROM dbo.UserSystemRoles usr WHERE usr.UserId = u.UserId AND usr.IsActive = 1) AS SystemRoleCount,
        -- Add tenant role count
        (SELECT COUNT(*) FROM dbo.UserTenantRoles utr WHERE utr.UserId = u.UserId AND utr.IsActive = 1) AS TenantRoleCount,
        -- Add total count for pagination
        @TotalCount AS TotalCount
    FROM dbo.Users u
    WHERE (@IsActive IS NULL OR u.IsActive = @IsActive)
      AND (
          @SearchTerm IS NULL OR
          u.Email LIKE '%' + @SearchTerm + '%' OR
          u.FirstName LIKE '%' + @SearchTerm + '%' OR
          u.LastName LIKE '%' + @SearchTerm + '%'
      )
    ORDER BY u.CreatedDate DESC, u.LastName, u.FirstName
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY
END
GO

PRINT '  - usp_User_GetAll created'
PRINT ''

/*============================================================================
  Procedure: usp_User_Update
  Description: Updates user profile information
  Parameters:
    @UserId - User ID
    @FirstName - First name
    @LastName - Last name
    @PhoneNumber - Phone number
    @EmailConfirmed - Email confirmed status
    @MfaEnabled - MFA enabled status
    @IsActive - Active status
============================================================================*/
CREATE PROCEDURE dbo.usp_User_Update
    @UserId UNIQUEIDENTIFIER,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @PhoneNumber NVARCHAR(20) = NULL,
    @EmailConfirmed BIT = 0,
    @MfaEnabled BIT = 0,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserId = @UserId)
    BEGIN
        RAISERROR('User not found', 16, 1)
        RETURN
    END

    -- Update user
    UPDATE dbo.Users
    SET
        FirstName = @FirstName,
        LastName = @LastName,
        PhoneNumber = @PhoneNumber,
        EmailConfirmed = @EmailConfirmed,
        MfaEnabled = @MfaEnabled,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    -- Return updated user
    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        LastLoginDate,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE UserId = @UserId
END
GO

PRINT '  - usp_User_Update created'
PRINT ''

/*============================================================================
  Procedure: usp_User_Delete
  Description: Soft deletes a user (sets IsActive = 0)
  Parameters:
    @UserId - User ID to delete
============================================================================*/
CREATE PROCEDURE dbo.usp_User_Delete
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserId = @UserId)
    BEGIN
        RAISERROR('User not found', 16, 1)
        RETURN
    END

    -- Soft delete user
    UPDATE dbo.Users
    SET
        IsActive = 0,
        ModifiedDate = GETUTCDATE()
    WHERE UserId = @UserId

    -- Also deactivate all role assignments
    UPDATE dbo.UserSystemRoles
    SET IsActive = 0
    WHERE UserId = @UserId

    UPDATE dbo.UserTenantRoles
    SET IsActive = 0
    WHERE UserId = @UserId
END
GO

PRINT '  - usp_User_Delete created'
PRINT ''

/*============================================================================
  Procedure: usp_User_AssignSystemRole
  Description: Assigns a system role to a user
  Parameters:
    @UserId - User ID
    @SystemRoleId - System role ID
============================================================================*/
CREATE PROCEDURE dbo.usp_User_AssignSystemRole
    @UserId UNIQUEIDENTIFIER,
    @SystemRoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserId = @UserId)
    BEGIN
        RAISERROR('User not found', 16, 1)
        RETURN
    END

    -- Validate system role exists
    IF NOT EXISTS (SELECT 1 FROM dbo.SystemRoles WHERE SystemRoleId = @SystemRoleId AND IsActive = 1)
    BEGIN
        RAISERROR('System role not found or inactive', 16, 1)
        RETURN
    END

    -- Check if assignment already exists
    IF EXISTS (
        SELECT 1
        FROM dbo.UserSystemRoles
        WHERE UserId = @UserId AND SystemRoleId = @SystemRoleId
    )
    BEGIN
        -- Reactivate if it was deactivated
        UPDATE dbo.UserSystemRoles
        SET IsActive = 1
        WHERE UserId = @UserId AND SystemRoleId = @SystemRoleId
    END
    ELSE
    BEGIN
        -- Create new assignment
        INSERT INTO dbo.UserSystemRoles (UserId, SystemRoleId, IsActive, CreatedDate)
        VALUES (@UserId, @SystemRoleId, 1, GETUTCDATE())
    END

    -- Return updated role list
    SELECT
        sr.SystemRoleId,
        sr.RoleName,
        sr.Description,
        usr.IsActive,
        usr.CreatedDate
    FROM dbo.UserSystemRoles usr
    INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
    WHERE usr.UserId = @UserId AND usr.IsActive = 1
END
GO

PRINT '  - usp_User_AssignSystemRole created'
PRINT ''

/*============================================================================
  Procedure: usp_User_RemoveSystemRole
  Description: Removes a system role from a user
  Parameters:
    @UserId - User ID
    @SystemRoleId - System role ID
============================================================================*/
CREATE PROCEDURE dbo.usp_User_RemoveSystemRole
    @UserId UNIQUEIDENTIFIER,
    @SystemRoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Deactivate the role assignment
    UPDATE dbo.UserSystemRoles
    SET IsActive = 0
    WHERE UserId = @UserId AND SystemRoleId = @SystemRoleId

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('System role assignment not found', 16, 1)
        RETURN
    END
END
GO

PRINT '  - usp_User_RemoveSystemRole created'
PRINT ''

/*============================================================================
  Procedure: usp_User_GetSystemRoles
  Description: Gets all system roles assigned to a user
  Parameters:
    @UserId - User ID
============================================================================*/
CREATE PROCEDURE dbo.usp_User_GetSystemRoles
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sr.SystemRoleId,
        sr.RoleName,
        sr.Description,
        sr.IsActive AS RoleIsActive,
        usr.IsActive AS AssignmentIsActive,
        usr.CreatedDate AS AssignedDate
    FROM dbo.UserSystemRoles usr
    INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
    WHERE usr.UserId = @UserId AND usr.IsActive = 1
    ORDER BY sr.RoleName
END
GO

PRINT '  - usp_User_GetSystemRoles created'
PRINT ''

/*============================================================================
  Procedure: usp_User_GetTenantRoles
  Description: Gets all tenant roles assigned to a user
  Parameters:
    @UserId - User ID
============================================================================*/
CREATE PROCEDURE dbo.usp_User_GetTenantRoles
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        utr.UserTenantRoleId,
        utr.TenantId,
        t.TenantName,
        t.TenantCode,
        utr.RoleName,
        utr.IsActive,
        utr.CreatedDate
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId AND utr.IsActive = 1
    ORDER BY t.TenantName, utr.RoleName
END
GO

PRINT '  - usp_User_GetTenantRoles created'
PRINT ''

PRINT 'All user management stored procedures created successfully!'
GO
