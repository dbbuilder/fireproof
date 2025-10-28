/*============================================================================
  File:     FIX_INSPECTION_BOOLEAN_SCHEMA.sql
  Purpose:  Fix NULL values AND alter schema to prevent NULL booleans
  Date:     October 18, 2025
  Issue:    Boolean columns allow NULL but service code doesn't check for NULL
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Step 1: Fix Existing NULL Boolean Values'
PRINT '============================================================================'

-- Fix NULL boolean columns with logical defaults
UPDATE dbo.Inspections SET LocationVerified = 0 WHERE LocationVerified IS NULL;
UPDATE dbo.Inspections SET IsAccessible = 0 WHERE IsAccessible IS NULL;
UPDATE dbo.Inspections SET HasObstructions = 0 WHERE HasObstructions IS NULL;
UPDATE dbo.Inspections SET SignageVisible = 0 WHERE SignageVisible IS NULL;
UPDATE dbo.Inspections SET SealIntact = 0 WHERE SealIntact IS NULL;
UPDATE dbo.Inspections SET PinInPlace = 0 WHERE PinInPlace IS NULL;
UPDATE dbo.Inspections SET NozzleClear = 0 WHERE NozzleClear IS NULL;
UPDATE dbo.Inspections SET HoseConditionGood = 0 WHERE HoseConditionGood IS NULL;
UPDATE dbo.Inspections SET GaugeInGreenZone = 0 WHERE GaugeInGreenZone IS NULL;
UPDATE dbo.Inspections SET PhysicalDamagePresent = 0 WHERE PhysicalDamagePresent IS NULL;
UPDATE dbo.Inspections SET WeightWithinSpec = 0 WHERE WeightWithinSpec IS NULL;
UPDATE dbo.Inspections SET InspectionTagAttached = 0 WHERE InspectionTagAttached IS NULL;
UPDATE dbo.Inspections SET Passed = 0 WHERE Passed IS NULL;
UPDATE dbo.Inspections SET RequiresService = 0 WHERE RequiresService IS NULL;
UPDATE dbo.Inspections SET RequiresReplacement = 0 WHERE RequiresReplacement IS NULL;
UPDATE dbo.Inspections SET IsVerified = 0 WHERE IsVerified IS NULL;

PRINT '✓ Updated all NULL boolean values to FALSE (0)';

PRINT ''
PRINT '============================================================================'
PRINT 'Step 2: Alter Columns to NOT NULL with Defaults'
PRINT '============================================================================'

-- Add default constraints and make columns NOT NULL
ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_LocationVerified DEFAULT 0 FOR LocationVerified;
ALTER TABLE dbo.Inspections ALTER COLUMN LocationVerified BIT NOT NULL;
PRINT '✓ LocationVerified: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_IsAccessible DEFAULT 0 FOR IsAccessible;
ALTER TABLE dbo.Inspections ALTER COLUMN IsAccessible BIT NOT NULL;
PRINT '✓ IsAccessible: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_HasObstructions DEFAULT 0 FOR HasObstructions;
ALTER TABLE dbo.Inspections ALTER COLUMN HasObstructions BIT NOT NULL;
PRINT '✓ HasObstructions: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_SignageVisible DEFAULT 0 FOR SignageVisible;
ALTER TABLE dbo.Inspections ALTER COLUMN SignageVisible BIT NOT NULL;
PRINT '✓ SignageVisible: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_SealIntact DEFAULT 0 FOR SealIntact;
ALTER TABLE dbo.Inspections ALTER COLUMN SealIntact BIT NOT NULL;
PRINT '✓ SealIntact: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_PinInPlace DEFAULT 0 FOR PinInPlace;
ALTER TABLE dbo.Inspections ALTER COLUMN PinInPlace BIT NOT NULL;
PRINT '✓ PinInPlace: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_NozzleClear DEFAULT 0 FOR NozzleClear;
ALTER TABLE dbo.Inspections ALTER COLUMN NozzleClear BIT NOT NULL;
PRINT '✓ NozzleClear: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_HoseConditionGood DEFAULT 0 FOR HoseConditionGood;
ALTER TABLE dbo.Inspections ALTER COLUMN HoseConditionGood BIT NOT NULL;
PRINT '✓ HoseConditionGood: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_GaugeInGreenZone DEFAULT 0 FOR GaugeInGreenZone;
ALTER TABLE dbo.Inspections ALTER COLUMN GaugeInGreenZone BIT NOT NULL;
PRINT '✓ GaugeInGreenZone: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_PhysicalDamagePresent DEFAULT 0 FOR PhysicalDamagePresent;
ALTER TABLE dbo.Inspections ALTER COLUMN PhysicalDamagePresent BIT NOT NULL;
PRINT '✓ PhysicalDamagePresent: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_WeightWithinSpec DEFAULT 1 FOR WeightWithinSpec;
ALTER TABLE dbo.Inspections ALTER COLUMN WeightWithinSpec BIT NOT NULL;
PRINT '✓ WeightWithinSpec: Added DEFAULT 1 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_InspectionTagAttached DEFAULT 0 FOR InspectionTagAttached;
ALTER TABLE dbo.Inspections ALTER COLUMN InspectionTagAttached BIT NOT NULL;
PRINT '✓ InspectionTagAttached: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_Passed DEFAULT 0 FOR Passed;
ALTER TABLE dbo.Inspections ALTER COLUMN Passed BIT NOT NULL;
PRINT '✓ Passed: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_RequiresService DEFAULT 0 FOR RequiresService;
ALTER TABLE dbo.Inspections ALTER COLUMN RequiresService BIT NOT NULL;
PRINT '✓ RequiresService: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_RequiresReplacement DEFAULT 0 FOR RequiresReplacement;
ALTER TABLE dbo.Inspections ALTER COLUMN RequiresReplacement BIT NOT NULL;
PRINT '✓ RequiresReplacement: Added DEFAULT 0 and NOT NULL constraint';

ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_IsVerified DEFAULT 0 FOR IsVerified;
ALTER TABLE dbo.Inspections ALTER COLUMN IsVerified BIT NOT NULL;
PRINT '✓ IsVerified: Added DEFAULT 0 and NOT NULL constraint';

PRINT ''
PRINT '============================================================================'
PRINT 'Boolean Schema Fix Complete!'
PRINT 'All boolean columns now have NOT NULL constraints with defaults'
PRINT '============================================================================'

-- Show updated schema
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Inspections'
AND DATA_TYPE = 'bit'
ORDER BY ORDINAL_POSITION;

GO
