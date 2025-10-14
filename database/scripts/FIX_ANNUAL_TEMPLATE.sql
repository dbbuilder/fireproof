/*============================================================================
  File:     FIX_ANNUAL_TEMPLATE.sql
  Purpose:  Fix NFPA 10 Annual Inspection Template (SQL quoting issue)
  Date:     October 14, 2025
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

DECLARE @Schema NVARCHAR(128) = (SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001')
DECLARE @AnnualTemplateId UNIQUEIDENTIFIER = NEWID()

PRINT 'Creating NFPA 10 Annual Inspection Template (Fixed)'
PRINT 'Schema: ' + @Schema

-- Delete existing if any
EXEC('DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId IN (SELECT TemplateId FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateName = ''NFPA 10 Annual Inspection'')')
EXEC('DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateName = ''NFPA 10 Annual Inspection''')

-- Insert template
DECLARE @Sql NVARCHAR(MAX) = '
INSERT INTO [' + @Schema + '].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    ''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Annual Inspection'',
    ''Annual'',
    ''NFPA10'',
    1,
    1,
    ''Comprehensive annual inspection per NFPA 10 Section 7.3. Includes all monthly checks plus detailed examination of mechanical parts, extinguishing agent, and expelling means.''
)'

EXEC sp_executesql @Sql

-- Insert items (properly escaping quotes)
SET @Sql = '
INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
-- All monthly items (1-10)
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Extinguisher accessible and visible'', ''Verify the extinguisher is not blocked by storage or equipment.'', 1, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Location clearly marked'', ''Check that location signage is present and visible.'', 2, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Pressure gauge in operable range'', ''Verify the pressure indicator needle is in the green zone.'', 3, ''Pressure'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Safety seal intact'', ''Ensure the tamper seal or indicator pin is present and unbroken.'', 4, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''No visible physical damage'', ''Inspect for dents, rust, leakage, or other damage.'', 5, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Operating instructions legible'', ''Confirm the instruction label is readable and facing the front.'', 6, ''Label'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Service tag attached and current'', ''Check that the service tag is attached and the last inspection date is current.'', 7, ''Label'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Hose and nozzle in good condition'', ''Verify the hose is not cracked, blocked, or damaged.'', 8, ''Hose'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mounting bracket secure'', ''Ensure the wall bracket or stand is securely fastened.'', 9, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''No signs of discharge'', ''Check for any indication the extinguisher has been discharged.'', 10, ''PhysicalCondition'', 1, 0, 1, 1),
-- Additional annual items (11-18)
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mechanical parts examination'', ''Inspect all mechanical parts for proper operation and no damage.'', 11, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Extinguishing agent examination'', ''Check the agent for proper type, quantity, and condition.'', 12, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Expelling means examination'', ''Verify the propellant is at proper pressure and free from contamination.'', 13, ''Pressure'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Weight check (CO2 types)'', ''Weigh CO2 extinguishers to verify proper charge.'', 14, ''Pressure'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Examine for corrosion'', ''Detailed inspection for rust, corrosion, dents, or damage.'', 15, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Nameplate legibility'', ''Ensure the manufacturer nameplate is legible with model and serial number.'', 16, ''Label'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Verify proper type for hazard'', ''Confirm the extinguisher class matches the fire hazards present.'', 17, ''Other'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Verify proper mounting height'', ''Extinguisher top should be no more than 5 feet from floor.'', 18, ''Location'', 1, 0, 0, 1)
'

EXEC sp_executesql @Sql

PRINT 'Annual template created with 18 items'

-- Verify
EXEC('SELECT COUNT(*) as ItemCount FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + '''')

GO
