/*============================================================================
  File:     POPULATE_NFPA_TEMPLATES.sql
  Purpose:  Create NFPA compliance checklist templates for Phase 1 MVP
  Date:     October 14, 2025

  Templates Created:
    1. NFPA 10 Monthly Inspection (11 items)
    2. NFPA 10 Annual Inspection (18 items)
    3. NFPA 10 Six-Year Maintenance (8 items)
    4. NFPA 10 Twelve-Year Hydrostatic Test (8 items)
    5. California Title 19 Inspection (optional)
    6. ULC Inspection (Canadian Standards - optional)

  Applied to: DEMO001 tenant schema (system templates)
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating NFPA Compliance Templates'
PRINT '============================================================================'
PRINT ''

-- Get DEMO001 schema (we'll create system templates here)
DECLARE @Schema NVARCHAR(128) = (SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001')
DECLARE @TenantId UNIQUEIDENTIFIER = (SELECT TenantId FROM dbo.Tenants WHERE TenantCode = 'DEMO001')

IF @Schema IS NULL
BEGIN
    PRINT 'ERROR: DEMO001 tenant not found!'
    RETURN
END

PRINT 'Schema: ' + @Schema
PRINT 'TenantId: ' + CAST(@TenantId AS NVARCHAR(50))
PRINT ''

-- Template IDs (consistent GUIDs for reference)
DECLARE @MonthlyTemplateId UNIQUEIDENTIFIER = NEWID()
DECLARE @AnnualTemplateId UNIQUEIDENTIFIER = NEWID()
DECLARE @SixYearTemplateId UNIQUEIDENTIFIER = NEWID()
DECLARE @TwelveYearTemplateId UNIQUEIDENTIFIER = NEWID()
DECLARE @Title19TemplateId UNIQUEIDENTIFIER = NEWID()
DECLARE @ULCTemplateId UNIQUEIDENTIFIER = NEWID()

DECLARE @Sql NVARCHAR(MAX)

-- 1. NFPA 10 Monthly Inspection Template (Section 7.2)
PRINT '============================================================================'
PRINT '1. Creating NFPA 10 Monthly Inspection Template'
PRINT '============================================================================'

SET @Sql = '
DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + '''
DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateId = ''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + '''

INSERT INTO [' + @Schema + '].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    ''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''',
    NULL, -- System template
    ''NFPA 10 Monthly Inspection'',
    ''Monthly'',
    ''NFPA10'',
    1,
    1,
    ''Standard monthly inspection checklist per NFPA 10 Section 7.2. Ensures fire extinguishers are accessible, visible, and appear serviceable.''
)

-- Monthly checklist items
INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Extinguisher accessible and visible'', ''Verify the extinguisher is not blocked by storage, equipment, or other objects. It should be easily seen and reached in an emergency.'', 1, ''Location'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Location clearly marked'', ''Check that location signage is present and visible. Signs should be mounted at least 3-4 feet above floor level.'', 2, ''Location'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Pressure gauge in operable range (green zone)'', ''Verify the pressure indicator needle is in the green (operable) zone. Red zones indicate overcharge or undercharge.'', 3, ''Pressure'', 1, 1, 0, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Safety seal/tamper indicator intact'', ''Ensure the tamper seal or indicator pin is present and has not been broken. This confirms the extinguisher has not been discharged.'', 4, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''No visible physical damage'', ''Inspect for dents, rust, leakage, or other damage to the cylinder, valve, hose, and nozzle.'', 5, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Operating instructions legible and facing outward'', ''Confirm the instruction label is readable and facing the front. The label should not be faded, torn, or covered.'', 6, ''Label'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Service tag attached and current'', ''Check that the service tag is attached and the last inspection date is current (within required timeframe).'', 7, ''Label'', 1, 1, 0, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Hose and nozzle unobstructed and in good condition'', ''Verify the hose is not cracked, blocked, or damaged. The nozzle should be clear and undamaged.'', 8, ''Hose'', 1, 1, 1, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Mounting bracket secure'', ''Ensure the wall bracket or stand is securely fastened and the extinguisher sits firmly in place.'', 9, ''Location'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''No signs of discharge'', ''Check for any indication the extinguisher has been partially or fully discharged (weight, pressure, residue).'', 10, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Inspection date documented on tag'', ''Record the inspection date on the service tag or inspection record as required.'', 11, ''Label'', 1, 0, 0, 0)
'
EXEC sp_executesql @Sql
PRINT '  ✓ NFPA 10 Monthly Inspection Template created (11 items)'
PRINT ''

-- 2. NFPA 10 Annual Inspection Template (Section 7.3)
PRINT '============================================================================'
PRINT '2. Creating NFPA 10 Annual Inspection Template'
PRINT '============================================================================'

SET @Sql = '
DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + '''
DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateId = ''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + '''

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
)

-- Annual checklist items (includes all monthly + additional)
INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
-- All monthly items
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Extinguisher accessible and visible'', ''Verify the extinguisher is not blocked by storage, equipment, or other objects.'', 1, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Location clearly marked'', ''Check that location signage is present and visible.'', 2, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Pressure gauge in operable range (green zone)'', ''Verify the pressure indicator needle is in the green zone.'', 3, ''Pressure'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Safety seal/tamper indicator intact'', ''Ensure the tamper seal or indicator pin is present and unbroken.'', 4, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''No visible physical damage'', ''Inspect for dents, rust, leakage, or other damage.'', 5, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Operating instructions legible and facing outward'', ''Confirm the instruction label is readable and facing the front.'', 6, ''Label'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Service tag attached and current'', ''Check that the service tag is attached and the last inspection date is current.'', 7, ''Label'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Hose and nozzle unobstructed and in good condition'', ''Verify the hose is not cracked, blocked, or damaged.'', 8, ''Hose'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mounting bracket secure'', ''Ensure the wall bracket or stand is securely fastened.'', 9, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''No signs of discharge'', ''Check for any indication the extinguisher has been discharged.'', 10, ''PhysicalCondition'', 1, 0, 1, 1),
-- Additional annual items
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mechanical parts examination'', ''Inspect all mechanical parts (handle, lever, nozzle, hose coupling, valve) for proper operation and no damage.'', 11, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Extinguishing agent examination'', ''Check the extinguishing agent for proper type, quantity, and condition. For dry chemical, verify powder is free-flowing.'', 12, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Expelling means examination'', ''Verify the propellant (CO2, nitrogen) is at proper pressure and free from contamination.'', 13, ''Pressure'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Weight check (CO2 and stored pressure types)'', ''Weigh CO2 extinguishers to verify proper charge. If weight is below minimum, recharge or replace.'', 14, ''Pressure'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Examine for obvious physical damage, corrosion'', ''Detailed inspection for rust, corrosion, dents, or damage to cylinder, valve, and hardware.'', 15, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Examine extinguisher nameplate legibility'', ''Ensure the manufacturer nameplate is legible with model, serial number, and instructions intact.'', 16, ''Label'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Verify proper extinguisher type for hazard location'', ''Confirm the extinguisher class (A, B, C, K) matches the fire hazards present at the location.'', 17, ''Other'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Verify proper mounting height and accessibility'', ''Extinguishers should be mounted so the top is no more than 5 feet (for under 40 lbs) or 3.5 feet (for over 40 lbs) from the floor.'', 18, ''Location'', 1, 0, 0, 1)
'
EXEC sp_executesql @Sql
PRINT '  ✓ NFPA 10 Annual Inspection Template created (18 items)'
PRINT ''

-- 3. NFPA 10 Six-Year Maintenance Template (Section 7.3.1)
PRINT '============================================================================'
PRINT '3. Creating NFPA 10 Six-Year Maintenance Template'
PRINT '============================================================================'

SET @Sql = '
DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + '''
DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateId = ''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + '''

INSERT INTO [' + @Schema + '].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    ''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Six-Year Maintenance'',
    ''SixYear'',
    ''NFPA10'',
    1,
    1,
    ''Six-year internal examination and maintenance per NFPA 10 Section 7.3.1. Requires complete disassembly, internal inspection, and refilling/recharging.''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Internal examination (applicable types)'', ''Perform internal examination of dry chemical, dry powder, and wet chemical extinguishers per manufacturer instructions.'', 1, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Complete disassembly'', ''Disassemble valve, siphon tube, hose, and other components. Inspect all parts for damage or wear.'', 2, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Examination of all components'', ''Inspect valve assembly, shell, hose, nozzle, and all hardware for corrosion, damage, or wear.'', 3, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Replacement of parts as needed'', ''Replace any damaged or worn parts (O-rings, seals, gaskets, valve components) with manufacturer-approved parts.'', 4, ''Other'', 1, 0, 1, 1),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Refill or recharge'', ''Refill with proper extinguishing agent and recharge to proper pressure per manufacturer specifications.'', 5, ''Pressure'', 1, 0, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''New tamper seal installed'', ''Install new tamper seal or indicator to show the unit has been serviced.'', 6, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Service tag updated with 6-year maintenance'', ''Update the service tag with the date of 6-year maintenance and technician information.'', 7, ''Label'', 1, 1, 0, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Photo documentation of internal condition'', ''Capture photos of internal cylinder condition, agent, and components before and after service.'', 8, ''Other'', 1, 1, 1, 0)
'
EXEC sp_executesql @Sql
PRINT '  ✓ NFPA 10 Six-Year Maintenance Template created (8 items)'
PRINT ''

-- 4. NFPA 10 Twelve-Year Hydrostatic Test Template (Section 8.3)
PRINT '============================================================================'
PRINT '4. Creating NFPA 10 Twelve-Year Hydrostatic Test Template'
PRINT '============================================================================'

SET @Sql = '
DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + '''
DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateId = ''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + '''

INSERT INTO [' + @Schema + '].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    ''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Twelve-Year Hydrostatic Test'',
    ''TwelveYear'',
    ''NFPA10'',
    1,
    1,
    ''Twelve-year hydrostatic pressure test per NFPA 10 Section 8.3. Tests the structural integrity of the cylinder under pressure. Requires specialized equipment and certified technician.''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Visual internal examination'', ''Perform thorough visual inspection of the internal cylinder for corrosion, pitting, or damage before testing.'', 1, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Hydrostatic pressure test performed'', ''Pressurize the cylinder to test pressure (per manufacturer specifications) and hold for required duration. Monitor for leaks or expansion.'', 2, ''Pressure'', 1, 0, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Test results documented'', ''Record test pressure, duration, test date, and pass/fail results. Document any failures or anomalies.'', 3, ''Other'', 1, 0, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Thread inspection (hose assemblies)'', ''Inspect hose coupling threads for damage, corrosion, or cross-threading. Replace if defective.'', 4, ''Hose'', 1, 0, 1, 1),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Valve inspection'', ''Inspect valve assembly for proper sealing, gasket condition, and operational integrity.'', 5, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Cylinder inspection for damage/corrosion'', ''Inspect external cylinder surface for dents, rust, corrosion, or damage. Fail units with significant damage.'', 6, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Recharge after test'', ''Refill and recharge the extinguisher to proper pressure with correct extinguishing agent.'', 7, ''Pressure'', 1, 0, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''New service tag with hydrostatic test date'', ''Affix new service tag showing hydrostatic test date, next test due date, and technician certification.'', 8, ''Label'', 1, 1, 0, 0)
'
EXEC sp_executesql @Sql
PRINT '  ✓ NFPA 10 Twelve-Year Hydrostatic Test Template created (8 items)'
PRINT ''

-- 5. California Title 19 Template (Optional - placeholder)
PRINT '============================================================================'
PRINT '5. Creating California Title 19 Inspection Template'
PRINT '============================================================================'

SET @Sql = '
DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + '''
DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateId = ''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + '''

INSERT INTO [' + @Schema + '].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    ''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''California Title 19 Inspection'',
    ''Annual'',
    ''Title19'',
    1,
    1,
    ''California-specific fire extinguisher inspection requirements per Title 19. Includes additional state-mandated documentation and reporting.''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''', ''State Fire Marshal certification verified'', ''Verify the extinguisher meets California State Fire Marshal certification requirements.'', 1, ''Other'', 1, 0, 1, 1),
(''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''', ''All NFPA 10 monthly items completed'', ''Complete all standard NFPA 10 monthly inspection items.'', 2, ''Other'', 1, 0, 0, 0),
(''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''', ''California-specific documentation completed'', ''Complete any additional documentation required by California regulations.'', 3, ''Other'', 1, 0, 1, 1)
'
EXEC sp_executesql @Sql
PRINT '  ✓ California Title 19 Inspection Template created (3 items)'
PRINT ''

-- 6. ULC Template (Canadian Standards - Optional - placeholder)
PRINT '============================================================================'
PRINT '6. Creating ULC Inspection Template (Canadian Standards)'
PRINT '============================================================================'

SET @Sql = '
DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId = ''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + '''
DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE TemplateId = ''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + '''

INSERT INTO [' + @Schema + '].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    ''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''ULC Inspection (Canadian Standards)'',
    ''Annual'',
    ''ULC'',
    1,
    1,
    ''Fire extinguisher inspection per ULC (Underwriters Laboratories of Canada) standards. Meets Canadian regulatory compliance requirements.''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''', ''ULC certification label present'', ''Verify the extinguisher has a valid ULC certification label.'', 1, ''Label'', 1, 1, 0, 0),
(''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''', ''All monthly inspection items completed'', ''Complete all standard monthly inspection checks.'', 2, ''Other'', 1, 0, 0, 0),
(''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''', ''Canadian regulatory compliance verified'', ''Verify compliance with Canadian fire safety regulations and local authority requirements.'', 3, ''Other'', 1, 0, 1, 1)
'
EXEC sp_executesql @Sql
PRINT '  ✓ ULC Inspection Template created (3 items)'
PRINT ''

PRINT '============================================================================'
PRINT 'NFPA Compliance Templates Created Successfully!'
PRINT '============================================================================'
PRINT ''
PRINT 'Templates Created:'
PRINT '  1. NFPA 10 Monthly Inspection (11 items)'
PRINT '  2. NFPA 10 Annual Inspection (18 items)'
PRINT '  3. NFPA 10 Six-Year Maintenance (8 items)'
PRINT '  4. NFPA 10 Twelve-Year Hydrostatic Test (8 items)'
PRINT '  5. California Title 19 Inspection (3 items)'
PRINT '  6. ULC Inspection - Canadian Standards (3 items)'
PRINT ''
PRINT 'Total: 6 templates, 51 checklist items'
PRINT ''

GO
