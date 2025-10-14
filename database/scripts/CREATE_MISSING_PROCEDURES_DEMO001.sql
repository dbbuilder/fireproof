/*============================================================================
  File:     CREATE_MISSING_PROCEDURES_DEMO001.sql
  Purpose:  Create missing stored procedures for DEMO001 tenant
  Date:     October 14, 2025
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating Missing Stored Procedures for DEMO001'
PRINT '============================================================================'
PRINT ''

-- Get DEMO001 schema name
DECLARE @SchemaName NVARCHAR(128)
SELECT @SchemaName = DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001'

IF @SchemaName IS NULL
BEGIN
    PRINT 'ERROR: DEMO001 tenant not found!'
    RETURN
END

PRINT 'Tenant Schema: ' + @SchemaName
PRINT ''

-- Create usp_Extinguisher_GetById
DECLARE @CreateGetByIdSql NVARCHAR(MAX) = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''usp_Extinguisher_GetById'' AND SCHEMA_NAME(schema_id) = ''' + @SchemaName + ''')
    DROP PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetById
'
EXEC sp_executesql @CreateGetByIdSql

SET @CreateGetByIdSql = '
CREATE PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetById
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.ExtinguisherId,
        e.TenantId,
        e.LocationId,
        e.ExtinguisherTypeId,
        e.AssetTag,
        e.BarcodeData,
        e.Manufacturer,
        e.Model,
        e.SerialNumber,
        e.ManufactureDate,
        e.InstallDate,
        e.LastHydrostaticTestDate,
        e.Capacity,
        e.LocationDescription,
        e.IsActive,
        e.CreatedDate,
        e.ModifiedDate,
        -- Additional columns
        ISNULL(e.AssetTag, e.BarcodeData) AS ExtinguisherCode,
        e.LastServiceDate,
        e.NextServiceDueDate,
        e.NextHydroTestDueDate,
        e.FloorLevel,
        e.Notes,
        e.QrCodeData,
        e.IsOutOfService,
        e.OutOfServiceReason,
        -- Navigation properties
        l.LocationName,
        t.TypeName,
        t.TypeCode
    FROM [' + @SchemaName + '].Extinguishers e
    LEFT JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    LEFT JOIN [' + @SchemaName + '].ExtinguisherTypes t ON e.ExtinguisherTypeId = t.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
        AND e.ExtinguisherId = @ExtinguisherId
        AND e.IsActive = 1
END
'
EXEC sp_executesql @CreateGetByIdSql
PRINT '  ✓ Created usp_Extinguisher_GetById'

-- Create usp_ExtinguisherType_GetAll
DECLARE @CreateTypeGetAllSql NVARCHAR(MAX) = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''usp_ExtinguisherType_GetAll'' AND SCHEMA_NAME(schema_id) = ''' + @SchemaName + ''')
    DROP PROCEDURE [' + @SchemaName + '].usp_ExtinguisherType_GetAll
'
EXEC sp_executesql @CreateTypeGetAllSql

SET @CreateTypeGetAllSql = '
CREATE PROCEDURE [' + @SchemaName + '].usp_ExtinguisherType_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ExtinguisherTypeId,
        TenantId,
        TypeCode,
        TypeName,
        Description,
        MonthlyInspectionRequired,
        AnnualInspectionRequired,
        HydrostaticTestYears,
        IsActive,
        CreatedDate,
        -- Additional columns expected by service
        AgentType = NULL,
        Capacity = NULL,
        CapacityUnit = NULL,
        FireClassRating = NULL,
        ServiceLifeYears = NULL,
        HydroTestIntervalYears = HydrostaticTestYears,
        ModifiedDate = GETUTCDATE()
    FROM [' + @SchemaName + '].ExtinguisherTypes
    WHERE TenantId = @TenantId
        AND (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY TypeName
END
'
EXEC sp_executesql @CreateTypeGetAllSql
PRINT '  ✓ Created usp_ExtinguisherType_GetAll'

-- Create usp_ExtinguisherType_GetById
DECLARE @CreateTypeGetByIdSql NVARCHAR(MAX) = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''usp_ExtinguisherType_GetById'' AND SCHEMA_NAME(schema_id) = ''' + @SchemaName + ''')
    DROP PROCEDURE [' + @SchemaName + '].usp_ExtinguisherType_GetById
'
EXEC sp_executesql @CreateTypeGetByIdSql

SET @CreateTypeGetByIdSql = '
CREATE PROCEDURE [' + @SchemaName + '].usp_ExtinguisherType_GetById
    @ExtinguisherTypeId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ExtinguisherTypeId,
        TenantId,
        TypeCode,
        TypeName,
        Description,
        MonthlyInspectionRequired,
        AnnualInspectionRequired,
        HydrostaticTestYears,
        IsActive,
        CreatedDate,
        -- Additional columns expected by service
        AgentType = NULL,
        Capacity = NULL,
        CapacityUnit = NULL,
        FireClassRating = NULL,
        ServiceLifeYears = NULL,
        HydroTestIntervalYears = HydrostaticTestYears,
        ModifiedDate = GETUTCDATE()
    FROM [' + @SchemaName + '].ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId
END
'
EXEC sp_executesql @CreateTypeGetByIdSql
PRINT '  ✓ Created usp_ExtinguisherType_GetById'

-- Create usp_ExtinguisherType_Create
DECLARE @CreateTypeCreateSql NVARCHAR(MAX) = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''usp_ExtinguisherType_Create'' AND SCHEMA_NAME(schema_id) = ''' + @SchemaName + ''')
    DROP PROCEDURE [' + @SchemaName + '].usp_ExtinguisherType_Create
'
EXEC sp_executesql @CreateTypeCreateSql

SET @CreateTypeCreateSql = '
CREATE PROCEDURE [' + @SchemaName + '].usp_ExtinguisherType_Create
    @TenantId UNIQUEIDENTIFIER,
    @TypeCode NVARCHAR(50),
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(1000) = NULL,
    @AgentType NVARCHAR(100) = NULL,
    @Capacity DECIMAL(10,2) = NULL,
    @CapacityUnit NVARCHAR(20) = NULL,
    @FireClassRating NVARCHAR(50) = NULL,
    @ServiceLifeYears INT = NULL,
    @HydroTestIntervalYears INT = NULL,
    @ExtinguisherTypeId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @ExtinguisherTypeId = NEWID()

    INSERT INTO [' + @SchemaName + '].ExtinguisherTypes (
        ExtinguisherTypeId,
        TenantId,
        TypeCode,
        TypeName,
        Description,
        MonthlyInspectionRequired,
        AnnualInspectionRequired,
        HydrostaticTestYears,
        IsActive,
        CreatedDate
    )
    VALUES (
        @ExtinguisherTypeId,
        @TenantId,
        @TypeCode,
        @TypeName,
        @Description,
        1,
        1,
        @HydroTestIntervalYears,
        1,
        GETUTCDATE()
    )

    SELECT
        ExtinguisherTypeId,
        TenantId,
        TypeCode,
        TypeName,
        Description,
        MonthlyInspectionRequired,
        AnnualInspectionRequired,
        HydrostaticTestYears,
        IsActive,
        CreatedDate,
        AgentType = @AgentType,
        Capacity = @Capacity,
        CapacityUnit = @CapacityUnit,
        FireClassRating = @FireClassRating,
        ServiceLifeYears = @ServiceLifeYears,
        HydroTestIntervalYears = HydrostaticTestYears,
        ModifiedDate = GETUTCDATE()
    FROM [' + @SchemaName + '].ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId
END
'
EXEC sp_executesql @CreateTypeCreateSql
PRINT '  ✓ Created usp_ExtinguisherType_Create'

PRINT ''
PRINT '============================================================================'
PRINT 'Missing Stored Procedures Created Successfully!'
PRINT '============================================================================'
PRINT ''
PRINT 'Created Procedures:'
PRINT '  - usp_Extinguisher_GetById'
PRINT '  - usp_ExtinguisherType_GetAll'
PRINT '  - usp_ExtinguisherType_GetById'
PRINT '  - usp_ExtinguisherType_Create'
PRINT ''

GO
