-- Fix usp_Extinguisher_GetAll stored procedure to match C# code parameters
--
-- ISSUE: The stored procedure had only 3 parameters (@TenantId, @LocationId, @IsActive)
--        but the C# code (ExtinguisherService.cs) was passing 5 parameters
--
-- SOLUTION: Add missing parameters (@ExtinguisherTypeId, @IsOutOfService)
--           and fix column aliases to match C# expectations:
--           - ExtinguisherCode: Alias ISNULL(AssetTag, BarcodeData) AS ExtinguisherCode
--           - LastHydroTestDate: Alias LastHydrostaticTestDate AS LastHydroTestDate
--
-- Run this for each tenant schema

USE FireProofDB
GO

-- Fix for tenant_634F2B52-D32A-46DD-A045-D158E793ADCB (Demo Company Inc)
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB')
BEGIN
    PRINT 'Fixing stored procedure for tenant_634F2B52-D32A-46DD-A045-D158E793ADCB...'

    EXEC('
    CREATE OR ALTER PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].usp_Extinguisher_GetAll
        @TenantId UNIQUEIDENTIFIER,
        @LocationId UNIQUEIDENTIFIER = NULL,
        @ExtinguisherTypeId UNIQUEIDENTIFIER = NULL,
        @IsActive BIT = NULL,
        @IsOutOfService BIT = NULL
    AS
    BEGIN
        SET NOCOUNT ON

        SELECT
            e.ExtinguisherId,
            e.TenantId,
            e.LocationId,
            e.ExtinguisherTypeId,
            ISNULL(e.AssetTag, e.BarcodeData) AS ExtinguisherCode,
            e.SerialNumber,
            e.AssetTag,
            e.Manufacturer,
            e.ManufactureDate,
            e.InstallDate,
            e.LastServiceDate,
            e.NextServiceDueDate,
            e.LastHydrostaticTestDate AS LastHydroTestDate,
            e.NextHydroTestDueDate,
            e.LocationDescription,
            e.FloorLevel,
            e.Notes,
            e.BarcodeData,
            e.QrCodeData,
            e.IsActive,
            e.IsOutOfService,
            e.OutOfServiceReason,
            e.CreatedDate,
            e.ModifiedDate,
            l.LocationName,
            l.LocationCode,
            et.TypeName,
            et.TypeCode
        FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
        INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l ON e.LocationId = l.LocationId
        INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
        WHERE e.TenantId = @TenantId
        AND (@LocationId IS NULL OR e.LocationId = @LocationId)
        AND (@ExtinguisherTypeId IS NULL OR e.ExtinguisherTypeId = @ExtinguisherTypeId)
        AND (@IsActive IS NULL OR e.IsActive = @IsActive)
        AND (@IsOutOfService IS NULL OR e.IsOutOfService = @IsOutOfService)
        ORDER BY l.LocationName, ISNULL(e.AssetTag, e.BarcodeData)
    END
    ')

    PRINT 'Fixed: tenant_634F2B52-D32A-46DD-A045-D158E793ADCB.usp_Extinguisher_GetAll'
END
ELSE
BEGIN
    PRINT 'Schema tenant_634F2B52-D32A-46DD-A045-D158E793ADCB does not exist'
END
GO

-- Generic fix for any other tenant schemas (can be run multiple times)
-- You can copy this block and replace the schema name for other tenants

PRINT ''
PRINT 'Stored procedure fix completed!'
PRINT ''
PRINT 'To fix additional tenant schemas, run:'
PRINT '  CREATE OR ALTER PROCEDURE [schema_name].usp_Extinguisher_GetAll ...'
PRINT '  (Replace schema_name with your tenant schema)'
GO
