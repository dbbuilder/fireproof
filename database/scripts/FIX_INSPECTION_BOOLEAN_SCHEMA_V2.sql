/*============================================================================
  File:     FIX_INSPECTION_BOOLEAN_SCHEMA_V2.sql
  Purpose:  Fix NULL values AND alter schema to prevent NULL booleans (smart version)
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
UPDATE dbo.Inspections SET WeightWithinSpec = 1 WHERE WeightWithinSpec IS NULL;
UPDATE dbo.Inspections SET InspectionTagAttached = 0 WHERE InspectionTagAttached IS NULL;
UPDATE dbo.Inspections SET Passed = 0 WHERE Passed IS NULL;
UPDATE dbo.Inspections SET RequiresService = 0 WHERE RequiresService IS NULL;
UPDATE dbo.Inspections SET RequiresReplacement = 0 WHERE RequiresReplacement IS NULL;
UPDATE dbo.Inspections SET IsVerified = 0 WHERE IsVerified IS NULL;

PRINT '✓ Updated all NULL boolean values to defaults';

PRINT ''
PRINT '============================================================================'
PRINT 'Step 2: Add Default Constraints (if not exists)'
PRINT '============================================================================'

-- Helper to add default constraint only if it doesn't exist
DECLARE @sql NVARCHAR(MAX);

-- LocationVerified
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'LocationVerified'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_LocationVerified DEFAULT 0 FOR LocationVerified;
    PRINT '✓ Added DEFAULT for LocationVerified';
END
ELSE PRINT '- LocationVerified already has DEFAULT';

-- IsAccessible
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'IsAccessible'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_IsAccessible DEFAULT 0 FOR IsAccessible;
    PRINT '✓ Added DEFAULT for IsAccessible';
END
ELSE PRINT '- IsAccessible already has DEFAULT';

-- HasObstructions
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'HasObstructions'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_HasObstructions DEFAULT 0 FOR HasObstructions;
    PRINT '✓ Added DEFAULT for HasObstructions';
END
ELSE PRINT '- HasObstructions already has DEFAULT';

-- SignageVisible
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'SignageVisible'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_SignageVisible DEFAULT 0 FOR SignageVisible;
    PRINT '✓ Added DEFAULT for SignageVisible';
END
ELSE PRINT '- SignageVisible already has DEFAULT';

-- SealIntact
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'SealIntact'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_SealIntact DEFAULT 0 FOR SealIntact;
    PRINT '✓ Added DEFAULT for SealIntact';
END
ELSE PRINT '- SealIntact already has DEFAULT';

-- PinInPlace
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'PinInPlace'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_PinInPlace DEFAULT 0 FOR PinInPlace;
    PRINT '✓ Added DEFAULT for PinInPlace';
END
ELSE PRINT '- PinInPlace already has DEFAULT';

-- NozzleClear
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'NozzleClear'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_NozzleClear DEFAULT 0 FOR NozzleClear;
    PRINT '✓ Added DEFAULT for NozzleClear';
END
ELSE PRINT '- NozzleClear already has DEFAULT';

-- HoseConditionGood
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'HoseConditionGood'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_HoseConditionGood DEFAULT 0 FOR HoseConditionGood;
    PRINT '✓ Added DEFAULT for HoseConditionGood';
END
ELSE PRINT '- HoseConditionGood already has DEFAULT';

-- GaugeInGreenZone
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'GaugeInGreenZone'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_GaugeInGreenZone DEFAULT 0 FOR GaugeInGreenZone;
    PRINT '✓ Added DEFAULT for GaugeInGreenZone';
END
ELSE PRINT '- GaugeInGreenZone already has DEFAULT';

-- PhysicalDamagePresent
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'PhysicalDamagePresent'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_PhysicalDamagePresent DEFAULT 0 FOR PhysicalDamagePresent;
    PRINT '✓ Added DEFAULT for PhysicalDamagePresent';
END
ELSE PRINT '- PhysicalDamagePresent already has DEFAULT';

-- WeightWithinSpec
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'WeightWithinSpec'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_WeightWithinSpec DEFAULT 1 FOR WeightWithinSpec;
    PRINT '✓ Added DEFAULT for WeightWithinSpec';
END
ELSE PRINT '- WeightWithinSpec already has DEFAULT';

-- InspectionTagAttached
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'InspectionTagAttached'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_InspectionTagAttached DEFAULT 0 FOR InspectionTagAttached;
    PRINT '✓ Added DEFAULT for InspectionTagAttached';
END
ELSE PRINT '- InspectionTagAttached already has DEFAULT';

-- Passed
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'Passed'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_Passed DEFAULT 0 FOR Passed;
    PRINT '✓ Added DEFAULT for Passed';
END
ELSE PRINT '- Passed already has DEFAULT';

-- RequiresService
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'RequiresService'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_RequiresService DEFAULT 0 FOR RequiresService;
    PRINT '✓ Added DEFAULT for RequiresService';
END
ELSE PRINT '- RequiresService already has DEFAULT';

-- RequiresReplacement
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'RequiresReplacement'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_RequiresReplacement DEFAULT 0 FOR RequiresReplacement;
    PRINT '✓ Added DEFAULT for RequiresReplacement';
END
ELSE PRINT '- RequiresReplacement already has DEFAULT';

-- IsVerified
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('dbo.Inspections') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inspections') AND name = 'IsVerified'))
BEGIN
    ALTER TABLE dbo.Inspections ADD CONSTRAINT DF_Inspections_IsVerified DEFAULT 0 FOR IsVerified;
    PRINT '✓ Added DEFAULT for IsVerified';
END
ELSE PRINT '- IsVerified already has DEFAULT';

PRINT ''
PRINT '============================================================================'
PRINT 'Step 3: Make Columns NOT NULL'
PRINT '============================================================================'

-- Alter columns to NOT NULL (only if they're currently nullable)
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'LocationVerified' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN LocationVerified BIT NOT NULL;
    PRINT '✓ LocationVerified: Changed to NOT NULL';
END
ELSE PRINT '- LocationVerified: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'IsAccessible' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN IsAccessible BIT NOT NULL;
    PRINT '✓ IsAccessible: Changed to NOT NULL';
END
ELSE PRINT '- IsAccessible: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'HasObstructions' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN HasObstructions BIT NOT NULL;
    PRINT '✓ HasObstructions: Changed to NOT NULL';
END
ELSE PRINT '- HasObstructions: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'SignageVisible' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN SignageVisible BIT NOT NULL;
    PRINT '✓ SignageVisible: Changed to NOT NULL';
END
ELSE PRINT '- SignageVisible: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'SealIntact' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN SealIntact BIT NOT NULL;
    PRINT '✓ SealIntact: Changed to NOT NULL';
END
ELSE PRINT '- SealIntact: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'PinInPlace' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN PinInPlace BIT NOT NULL;
    PRINT '✓ PinInPlace: Changed to NOT NULL';
END
ELSE PRINT '- PinInPlace: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'NozzleClear' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN NozzleClear BIT NOT NULL;
    PRINT '✓ NozzleClear: Changed to NOT NULL';
END
ELSE PRINT '- NozzleClear: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'HoseConditionGood' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN HoseConditionGood BIT NOT NULL;
    PRINT '✓ HoseConditionGood: Changed to NOT NULL';
END
ELSE PRINT '- HoseConditionGood: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'GaugeInGreenZone' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN GaugeInGreenZone BIT NOT NULL;
    PRINT '✓ GaugeInGreenZone: Changed to NOT NULL';
END
ELSE PRINT '- GaugeInGreenZone: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'PhysicalDamagePresent' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN PhysicalDamagePresent BIT NOT NULL;
    PRINT '✓ PhysicalDamagePresent: Changed to NOT NULL';
END
ELSE PRINT '- PhysicalDamagePresent: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'WeightWithinSpec' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN WeightWithinSpec BIT NOT NULL;
    PRINT '✓ WeightWithinSpec: Changed to NOT NULL';
END
ELSE PRINT '- WeightWithinSpec: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'InspectionTagAttached' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN InspectionTagAttached BIT NOT NULL;
    PRINT '✓ InspectionTagAttached: Changed to NOT NULL';
END
ELSE PRINT '- InspectionTagAttached: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'Passed' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN Passed BIT NOT NULL;
    PRINT '✓ Passed: Changed to NOT NULL';
END
ELSE PRINT '- Passed: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'RequiresService' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN RequiresService BIT NOT NULL;
    PRINT '✓ RequiresService: Changed to NOT NULL';
END
ELSE PRINT '- RequiresService: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'RequiresReplacement' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN RequiresReplacement BIT NOT NULL;
    PRINT '✓ RequiresReplacement: Changed to NOT NULL';
END
ELSE PRINT '- RequiresReplacement: Already NOT NULL';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Inspections' AND COLUMN_NAME = 'IsVerified' AND IS_NULLABLE = 'YES')
BEGIN
    ALTER TABLE dbo.Inspections ALTER COLUMN IsVerified BIT NOT NULL;
    PRINT '✓ IsVerified: Changed to NOT NULL';
END
ELSE PRINT '- IsVerified: Already NOT NULL';

PRINT ''
PRINT '============================================================================'
PRINT 'Boolean Schema Fix Complete!'
PRINT 'All boolean columns now have NOT NULL constraints with defaults'
PRINT '============================================================================'

-- Show updated schema
SELECT
    COLUMN_NAME,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Inspections'
AND DATA_TYPE = 'bit'
ORDER BY ORDINAL_POSITION;

GO
