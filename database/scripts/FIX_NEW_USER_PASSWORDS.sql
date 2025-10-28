/*============================================================================
  File:     FIX_NEW_USER_PASSWORDS.sql
  Purpose:  Update Jon and Charlotte passwords to match Chris's password
  Date:     October 18, 2025
  Password: Same as chris@servicevision.net
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '============================================================================'
PRINT 'Updating Passwords to Match Chris'
PRINT '============================================================================'

-- Update Jon Dunn's password
UPDATE dbo.Users
SET PasswordHash = '$2a$12$srgcbdtHATHsqqARPOMgD.laEA.X.5sFX9ag0acV9kTDaN6ubWNt.',
    PasswordSalt = '$2a$12$srgcbdtHATHsqqARPOMgD.'
WHERE Email = 'jdunn@2amarketing.com';

PRINT '✓ Updated password for jdunn@2amarketing.com';

-- Update Charlotte Payne's password
UPDATE dbo.Users
SET PasswordHash = '$2a$12$srgcbdtHATHsqqARPOMgD.laEA.X.5sFX9ag0acV9kTDaN6ubWNt.',
    PasswordSalt = '$2a$12$srgcbdtHATHsqqARPOMgD.'
WHERE Email = 'cpayne4@kumc.edu';

PRINT '✓ Updated password for cpayne4@kumc.edu';

PRINT ''
PRINT '============================================================================'
PRINT 'Password Update Complete!'
PRINT '============================================================================'
PRINT 'All three users now have the same password credentials'
PRINT ''

-- Verify the update
SELECT
    Email,
    CASE
        WHEN PasswordHash = '$2a$12$srgcbdtHATHsqqARPOMgD.laEA.X.5sFX9ag0acV9kTDaN6ubWNt.'
        THEN 'Matches Chris'
        ELSE 'Different'
    END AS PasswordStatus
FROM dbo.Users
WHERE Email IN ('chris@servicevision.net', 'jdunn@2amarketing.com', 'cpayne4@kumc.edu')
ORDER BY Email;

GO
