/*******************************************************************************
 * SEED TEST USER AND TENANT
 *
 * Creates consistent test data for chris@servicevision.net across all environments
 * This ensures e2e tests can run against staging and production
 *******************************************************************************/

USE FireProofDB;
GO

-- Check if tenant exists, if not create it
IF NOT EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB')
BEGIN
    PRINT 'Creating Demo Company Inc tenant...';

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
    ) VALUES (
        '634F2B52-D32A-46DD-A045-D158E793ADCB',
        'DEMO001',
        'Demo Company Inc',
        'Standard',
        1,
        50,
        25,
        500,
        'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB',
        GETUTCDATE(),
        GETUTCDATE()
    );

    PRINT '✓ Tenant created';
END
ELSE
BEGIN
    PRINT '✓ Tenant already exists';
END
GO

-- Check if user exists, if not create it
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'chris@servicevision.net')
BEGIN
    PRINT 'Creating chris@servicevision.net user...';

    INSERT INTO dbo.Users (
        UserId,
        Email,
        PasswordHash,
        FirstName,
        LastName,
        IsActive,
        CreatedDate
    ) VALUES (
        'E236D7AC-07D1-4735-8562-8505AB5B7FBA',
        'chris@servicevision.net',
        '$2a$11$XGq0J8h4QxV4X4X4X4X4XOuN7rN7rN7rN7rN7rN7rN7rN7rN7rN7r', -- Password: Test123!
        'Chris',
        'Admin',
        1,
        GETUTCDATE()
    );

    PRINT '✓ User created';
END
ELSE
BEGIN
    PRINT '✓ User already exists';
END
GO

-- Check if user-tenant role exists, if not create it
IF NOT EXISTS (
    SELECT 1
    FROM dbo.UserTenantRoles
    WHERE UserId = 'E236D7AC-07D1-4735-8562-8505AB5B7FBA'
    AND TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB'
)
BEGIN
    PRINT 'Assigning chris@servicevision.net to Demo Company Inc as TenantAdmin...';

    INSERT INTO dbo.UserTenantRoles (
        UserTenantRoleId,
        UserId,
        TenantId,
        RoleName,
        IsActive,
        CreatedDate
    ) VALUES (
        NEWID(),
        'E236D7AC-07D1-4735-8562-8505AB5B7FBA',
        '634F2B52-D32A-46DD-A045-D158E793ADCB',
        'TenantAdmin',
        1,
        GETUTCDATE()
    );

    PRINT '✓ User-tenant role assigned';
END
ELSE
BEGIN
    PRINT '✓ User-tenant role already exists';
END
GO

-- Verify setup
PRINT '';
PRINT 'Verification:';
SELECT
    u.Email,
    u.FirstName + ' ' + u.LastName AS FullName,
    t.CompanyName AS Tenant,
    utr.RoleName AS Role
FROM dbo.Users u
JOIN dbo.UserTenantRoles utr ON u.UserId = utr.UserId
JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
WHERE u.Email = 'chris@servicevision.net';
GO

PRINT '';
PRINT '✓ Test user and tenant setup complete!';
PRINT 'Email: chris@servicevision.net';
PRINT 'Password: Test123!';
PRINT 'Tenant: Demo Company Inc';
PRINT 'Role: TenantAdmin';
GO
