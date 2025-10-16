/*============================================================================
  FIX CHRIS TENANT ROLE

  Ensures chris@servicevision.net has TenantAdmin role for DEMO001 tenant
  This adds the tenant_id claim to the JWT token for proper authorization
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Fixing chris@servicevision.net tenant role'
PRINT '============================================================================'
PRINT ''

DECLARE @ChrisUserId UNIQUEIDENTIFIER
DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'

-- Get chris user ID
SELECT @ChrisUserId = UserId FROM dbo.Users WHERE Email = 'chris@servicevision.net'

IF @ChrisUserId IS NULL
BEGIN
    PRINT '❌ ERROR: chris@servicevision.net not found'
    RETURN
END

PRINT '✓ Found chris@servicevision.net'
PRINT '  UserId: ' + CAST(@ChrisUserId AS NVARCHAR(50))
PRINT ''

-- Check current roles
PRINT 'Current roles:'
SELECT
    CASE WHEN RoleType = 'System' THEN '  System: ' + RoleName
         ELSE '  Tenant: ' + RoleName + ' (TenantId: ' + CAST(TenantId AS NVARCHAR(50)) + ')'
    END AS Role
FROM (
    SELECT 'System' AS RoleType, NULL AS TenantId, sr.RoleName
    FROM dbo.UserSystemRoles usr
    INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
    WHERE usr.UserId = @ChrisUserId AND usr.IsActive = 1

    UNION ALL

    SELECT 'Tenant' AS RoleType, utr.TenantId, utr.RoleName
    FROM dbo.UserTenantRoles utr
    WHERE utr.UserId = @ChrisUserId AND utr.IsActive = 1
) roles

PRINT ''

-- Check if TenantAdmin role already exists for this tenant
IF EXISTS (
    SELECT 1 FROM dbo.UserTenantRoles
    WHERE UserId = @ChrisUserId
    AND TenantId = @TenantId
    AND RoleName = 'TenantAdmin'
    AND IsActive = 1
)
BEGIN
    PRINT '✓ chris@servicevision.net already has TenantAdmin role for DEMO001'
END
ELSE
BEGIN
    PRINT 'Adding TenantAdmin role for DEMO001...'

    -- Check if role exists but is inactive
    IF EXISTS (
        SELECT 1 FROM dbo.UserTenantRoles
        WHERE UserId = @ChrisUserId
        AND TenantId = @TenantId
        AND RoleName = 'TenantAdmin'
    )
    BEGIN
        -- Reactivate existing role
        UPDATE dbo.UserTenantRoles
        SET IsActive = 1
        WHERE UserId = @ChrisUserId
        AND TenantId = @TenantId
        AND RoleName = 'TenantAdmin'

        PRINT '  ✓ Reactivated existing TenantAdmin role'
    END
    ELSE
    BEGIN
        -- Insert new role
        INSERT INTO dbo.UserTenantRoles (
            UserId, TenantId, RoleName, IsActive, CreatedDate
        )
        VALUES (
            @ChrisUserId, @TenantId, 'TenantAdmin', 1, GETUTCDATE()
        )

        PRINT '  ✓ Added TenantAdmin role'
    END
END

PRINT ''
PRINT '============================================================================'
PRINT 'Updated roles:'
PRINT '============================================================================'

SELECT
    CASE WHEN RoleType = 'System' THEN '  System: ' + RoleName
         ELSE '  Tenant: ' + RoleName + ' (TenantId: ' + CAST(TenantId AS NVARCHAR(50)) + ')'
    END AS Role
FROM (
    SELECT 'System' AS RoleType, NULL AS TenantId, sr.RoleName
    FROM dbo.UserSystemRoles usr
    INNER JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
    WHERE usr.UserId = @ChrisUserId AND usr.IsActive = 1

    UNION ALL

    SELECT 'Tenant' AS RoleType, utr.TenantId, utr.RoleName
    FROM dbo.UserTenantRoles utr
    WHERE utr.UserId = @ChrisUserId AND utr.IsActive = 1
) roles

PRINT ''
PRINT '✓ Done! JWT tokens will now include tenant_id claim for DEMO001'
PRINT '============================================================================'
GO
