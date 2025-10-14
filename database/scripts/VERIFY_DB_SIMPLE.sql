USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'FIREPROOF DATABASE VERIFICATION'
PRINT '============================================================================'
PRINT ''

-- TEST 1: Core Tables
PRINT '1. Core Tables (dbo):'
SELECT 'Tenants' as TableName, COUNT(*) as RowCount FROM dbo.Tenants
UNION ALL
SELECT 'Users', COUNT(*) FROM dbo.Users
UNION ALL
SELECT 'UserTenantRoles', COUNT(*) FROM dbo.UserTenantRoles
PRINT ''

-- TEST 2: DEMO001 Tables
PRINT '2. DEMO001 Tenant Tables:'
SELECT 'Locations' as TableName, COUNT(*) as RowCount 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
UNION ALL
SELECT 'ExtinguisherTypes', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes
UNION ALL
SELECT 'Extinguishers', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
UNION ALL
SELECT 'ChecklistTemplates', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates
UNION ALL
SELECT 'ChecklistItems', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems
UNION ALL
SELECT 'Inspections', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
UNION ALL
SELECT 'InspectionPhotos', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionPhotos
UNION ALL
SELECT 'InspectionDeficiencies', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies
UNION ALL
SELECT 'InspectionChecklistResponses', COUNT(*) 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionChecklistResponses
PRINT ''

-- TEST 3: Stored Procedures
PRINT '3. Stored Procedures Count:'
SELECT 
    CASE 
        WHEN name LIKE 'usp_Checklist%' THEN 'ChecklistTemplate'
        WHEN name LIKE 'usp_Inspection_%' THEN 'Inspection'
        WHEN name LIKE 'usp_InspectionPhoto%' THEN 'InspectionPhoto'
        WHEN name LIKE 'usp_InspectionDeficiency%' THEN 'InspectionDeficiency'
        WHEN name LIKE 'usp_Location%' THEN 'Location'
        WHEN name LIKE 'usp_Extinguisher%' THEN 'Extinguisher'
        ELSE 'Other'
    END as Category,
    COUNT(*) as ProcCount
FROM sys.procedures 
WHERE SCHEMA_NAME(schema_id) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
GROUP BY CASE 
    WHEN name LIKE 'usp_Checklist%' THEN 'ChecklistTemplate'
    WHEN name LIKE 'usp_Inspection_%' THEN 'Inspection'
    WHEN name LIKE 'usp_InspectionPhoto%' THEN 'InspectionPhoto'
    WHEN name LIKE 'usp_InspectionDeficiency%' THEN 'InspectionDeficiency'
    WHEN name LIKE 'usp_Location%' THEN 'Location'
    WHEN name LIKE 'usp_Extinguisher%' THEN 'Extinguisher'
    ELSE 'Other'
END
ORDER BY Category
PRINT ''

-- TEST 4: Template Details
PRINT '4. NFPA Templates:'
SELECT 
    t.TemplateName,
    t.InspectionType,
    COUNT(i.ChecklistItemId) as ItemCount
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates t
LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems i 
    ON t.TemplateId = i.TemplateId
GROUP BY t.TemplateName, t.InspectionType
ORDER BY t.InspectionType
PRINT ''

-- TEST 5: Critical Columns
PRINT '5. Critical Columns Check:'
SELECT 
    'Extinguishers.LastServiceDate' as ColumnCheck,
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END as Status
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
AND TABLE_NAME = 'Extinguishers' 
AND COLUMN_NAME = 'LastServiceDate'

UNION ALL

SELECT 
    'Extinguishers.NextServiceDueDate',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
AND TABLE_NAME = 'Extinguishers' 
AND COLUMN_NAME = 'NextServiceDueDate'

UNION ALL

SELECT 
    'Extinguishers.IsOutOfService',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
AND TABLE_NAME = 'Extinguishers' 
AND COLUMN_NAME = 'IsOutOfService'

UNION ALL

SELECT 
    'Inspections.InspectionHash',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
AND TABLE_NAME = 'Inspections' 
AND COLUMN_NAME = 'InspectionHash'

UNION ALL

SELECT 
    'Inspections.PreviousInspectionHash',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
AND TABLE_NAME = 'Inspections' 
AND COLUMN_NAME = 'PreviousInspectionHash'

UNION ALL

SELECT 
    'InspectionPhotos.EXIFData',
    CASE WHEN COUNT(*) > 0 THEN 'EXISTS' ELSE 'MISSING' END
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
AND TABLE_NAME = 'InspectionPhotos' 
AND COLUMN_NAME = 'EXIFData'

PRINT ''
PRINT '============================================================================'
PRINT 'VERIFICATION COMPLETE'
PRINT '============================================================================'

GO
