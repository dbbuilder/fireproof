/*============================================================================
  File:     ADD_ISOUTOFSERVICE_RLS.sql
  Purpose:  Add IsOutOfService column to dbo.Extinguishers table (RLS model)
  Date:     October 18, 2025
  Issue:    ExtinguisherService expects IsOutOfService column but it doesn't exist
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Adding IsOutOfService Column to dbo.Extinguishers'
PRINT '============================================================================'

-- Check and add IsOutOfService
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Extinguishers'
    AND COLUMN_NAME = 'IsOutOfService'
)
BEGIN
    ALTER TABLE dbo.Extinguishers
    ADD IsOutOfService BIT NOT NULL DEFAULT 0;

    PRINT '✓ Added IsOutOfService column';
END
ELSE
BEGIN
    PRINT '- IsOutOfService column already exists';
END

-- Check and add OutOfServiceReason
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Extinguishers'
    AND COLUMN_NAME = 'OutOfServiceReason'
)
BEGIN
    ALTER TABLE dbo.Extinguishers
    ADD OutOfServiceReason NVARCHAR(500) NULL;

    PRINT '✓ Added OutOfServiceReason column';
END
ELSE
BEGIN
    PRINT '- OutOfServiceReason column already exists';
END

PRINT ''
PRINT '============================================================================'
PRINT 'Column Addition Complete!'
PRINT '============================================================================'

GO
