/*============================================================================
  File:     SEED_BASE_DATA.sql
  Purpose:  Base/Foundation seed data for FireProof system
  Date:     October 14, 2025

  Description:
    This script populates essential baseline data needed for the system
    to function. This includes NFPA compliance templates and common
    extinguisher types that can be used across all tenants.

  Contents:
    1. System NFPA Compliance Templates (6 templates, 51 items)
    2. Common Extinguisher Type Definitions (reference data)

  Usage:
    Run once per tenant schema to initialize baseline data.
    Templates are marked as "system templates" and appear for all tenants.
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'FIREPROOF - BASE/FOUNDATION SEED DATA'
PRINT '============================================================================'
PRINT ''

-- This script can be applied to any tenant schema
-- For initial setup, we'll apply to DEMO001

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @TenantId UNIQUEIDENTIFIER = NULL -- System templates use NULL tenant

PRINT 'Target Schema: ' + @Schema
PRINT 'Creating system-wide templates...'
PRINT ''

-- ============================================================================
-- PART 1: NFPA COMPLIANCE TEMPLATES
-- ============================================================================

-- Template GUIDs (deterministic for consistency)
DECLARE @MonthlyTemplateId UNIQUEIDENTIFIER = '10000000-0000-0000-0000-000000000001'
DECLARE @AnnualTemplateId UNIQUEIDENTIFIER = '10000000-0000-0000-0000-000000000002'
DECLARE @SixYearTemplateId UNIQUEIDENTIFIER = '10000000-0000-0000-0000-000000000003'
DECLARE @TwelveYearTemplateId UNIQUEIDENTIFIER = '10000000-0000-0000-0000-000000000004'
DECLARE @Title19TemplateId UNIQUEIDENTIFIER = '10000000-0000-0000-0000-000000000005'
DECLARE @ULCTemplateId UNIQUEIDENTIFIER = '10000000-0000-0000-0000-000000000006'

-- Clear existing templates (for re-run safety)
EXEC('DELETE FROM [' + @Schema + '].ChecklistItems WHERE TemplateId IN (SELECT TemplateId FROM [' + @Schema + '].ChecklistTemplates WHERE IsSystemTemplate = 1)')
EXEC('DELETE FROM [' + @Schema + '].ChecklistTemplates WHERE IsSystemTemplate = 1')

-- ============================================================================
-- 1.1 NFPA 10 Monthly Inspection Template
-- ============================================================================
PRINT '1. Creating NFPA 10 Monthly Inspection Template...'

EXEC('
INSERT INTO [' + @Schema + '].ChecklistTemplates (TemplateId, TenantId, TemplateName, InspectionType, Standard, IsSystemTemplate, IsActive, Description)
VALUES (
    ''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Monthly Inspection'',
    ''Monthly'',
    ''NFPA10'',
    1,
    1,
    ''Standard monthly inspection per NFPA 10 Section 7.2. Visual verification that fire extinguishers are accessible, visible, and appear serviceable.''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Extinguisher accessible and visible'', ''Verify not blocked by storage or equipment'', 1, ''Location'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Location clearly marked'', ''Check signage is present and visible'', 2, ''Location'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Pressure gauge in operable range'', ''Verify needle is in green zone'', 3, ''Pressure'', 1, 1, 0, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Safety seal intact'', ''Ensure tamper seal is unbroken'', 4, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''No visible physical damage'', ''Inspect for dents, rust, leakage'', 5, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Operating instructions legible'', ''Confirm label is readable'', 6, ''Label'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Service tag attached and current'', ''Check tag is present and dated'', 7, ''Label'', 1, 1, 0, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Hose in good condition'', ''Verify not cracked or blocked'', 8, ''Hose'', 1, 1, 1, 0),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Mounting bracket secure'', ''Ensure bracket is fastened'', 9, ''Location'', 1, 0, 0, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''No signs of discharge'', ''Check for discharge indicators'', 10, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@MonthlyTemplateId AS NVARCHAR(50)) + ''', ''Inspection date documented'', ''Record date on tag'', 11, ''Label'', 1, 0, 0, 0)
')

PRINT '   ✓ NFPA 10 Monthly (11 items)'

-- ============================================================================
-- 1.2 NFPA 10 Annual Inspection Template
-- ============================================================================
PRINT '2. Creating NFPA 10 Annual Inspection Template...'

EXEC('
INSERT INTO [' + @Schema + '].ChecklistTemplates (TemplateId, TenantId, TemplateName, InspectionType, Standard, IsSystemTemplate, IsActive, Description)
VALUES (
    ''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Annual Inspection'',
    ''Annual'',
    ''NFPA10'',
    1,
    1,
    ''Comprehensive annual inspection per NFPA 10 Section 7.3''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''All monthly items verified'', ''Complete all standard monthly checks'', 1, ''Other'', 1, 0, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Extinguisher accessible'', ''Not blocked by storage'', 2, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Location marked'', ''Signage present'', 3, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Pressure gauge operable'', ''Needle in green zone'', 4, ''Pressure'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Safety seal intact'', ''Tamper seal unbroken'', 5, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''No physical damage'', ''No dents or rust'', 6, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Instructions legible'', ''Label readable'', 7, ''Label'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Service tag current'', ''Tag present and dated'', 8, ''Label'', 1, 1, 0, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Hose condition good'', ''Not cracked or blocked'', 9, ''Hose'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mounting secure'', ''Bracket fastened'', 10, ''Location'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mechanical parts exam'', ''All parts operable'', 11, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Agent examination'', ''Agent proper type and quantity'', 12, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Expelling means exam'', ''Propellant at proper pressure'', 13, ''Pressure'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Weight check'', ''CO2 units weighed'', 14, ''Pressure'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Corrosion inspection'', ''Detailed rust/corrosion check'', 15, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Nameplate legible'', ''Model and serial readable'', 16, ''Label'', 1, 0, 0, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Proper type for hazard'', ''Class matches hazards'', 17, ''Other'', 1, 0, 1, 1),
(''' + CAST(@AnnualTemplateId AS NVARCHAR(50)) + ''', ''Mounting height correct'', ''Top no more than 5ft from floor'', 18, ''Location'', 1, 0, 0, 1)
')

PRINT '   ✓ NFPA 10 Annual (18 items)'

-- ============================================================================
-- 1.3 Six-Year Maintenance Template
-- ============================================================================
PRINT '3. Creating Six-Year Maintenance Template...'

EXEC('
INSERT INTO [' + @Schema + '].ChecklistTemplates (TemplateId, TenantId, TemplateName, InspectionType, Standard, IsSystemTemplate, IsActive, Description)
VALUES (
    ''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Six-Year Maintenance'',
    ''SixYear'',
    ''NFPA10'',
    1,
    1,
    ''Internal examination and maintenance per NFPA 10 Section 7.3.1''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Internal examination'', ''Per manufacturer instructions'', 1, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Complete disassembly'', ''Disassemble all components'', 2, ''PhysicalCondition'', 1, 0, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Component inspection'', ''All parts checked for damage'', 3, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Parts replaced'', ''Worn parts replaced'', 4, ''Other'', 1, 0, 1, 1),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Refill/recharge'', ''Proper agent and pressure'', 5, ''Pressure'', 1, 0, 1, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''New tamper seal'', ''Fresh seal installed'', 6, ''Seal'', 1, 1, 0, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Service tag updated'', ''6-year maintenance recorded'', 7, ''Label'', 1, 1, 0, 0),
(''' + CAST(@SixYearTemplateId AS NVARCHAR(50)) + ''', ''Photo documentation'', ''Internal condition documented'', 8, ''Other'', 1, 1, 1, 0)
')

PRINT '   ✓ Six-Year Maintenance (8 items)'

-- ============================================================================
-- 1.4 Twelve-Year Hydrostatic Test Template
-- ============================================================================
PRINT '4. Creating Twelve-Year Hydrostatic Test Template...'

EXEC('
INSERT INTO [' + @Schema + '].ChecklistTemplates (TemplateId, TenantId, TemplateName, InspectionType, Standard, IsSystemTemplate, IsActive, Description)
VALUES (
    ''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''NFPA 10 Twelve-Year Hydrostatic Test'',
    ''TwelveYear'',
    ''NFPA10'',
    1,
    1,
    ''Hydrostatic pressure test per NFPA 10 Section 8.3''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Visual internal exam'', ''Internal cylinder inspection'', 1, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Hydrostatic test'', ''Pressure test performed'', 2, ''Pressure'', 1, 0, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Test results documented'', ''Pass/fail recorded'', 3, ''Other'', 1, 0, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Thread inspection'', ''Hose threads checked'', 4, ''Hose'', 1, 0, 1, 1),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Valve inspection'', ''Valve integrity verified'', 5, ''PhysicalCondition'', 1, 0, 1, 1),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Cylinder damage check'', ''External surface inspected'', 6, ''PhysicalCondition'', 1, 1, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Recharge after test'', ''Unit refilled and recharged'', 7, ''Pressure'', 1, 0, 1, 0),
(''' + CAST(@TwelveYearTemplateId AS NVARCHAR(50)) + ''', ''Test date on tag'', ''Hydro test date recorded'', 8, ''Label'', 1, 1, 0, 0)
')

PRINT '   ✓ Twelve-Year Hydrostatic (8 items)'

-- ============================================================================
-- 1.5 California Title 19 Template
-- ============================================================================
PRINT '5. Creating California Title 19 Template...'

EXEC('
INSERT INTO [' + @Schema + '].ChecklistTemplates (TemplateId, TenantId, TemplateName, InspectionType, Standard, IsSystemTemplate, IsActive, Description)
VALUES (
    ''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''California Title 19 Inspection'',
    ''Annual'',
    ''Title19'',
    1,
    1,
    ''California-specific requirements per Title 19''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''', ''State certification verified'', ''CA Fire Marshal cert present'', 1, ''Other'', 1, 0, 1, 1),
(''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''', ''NFPA 10 items complete'', ''All standard items checked'', 2, ''Other'', 1, 0, 0, 0),
(''' + CAST(@Title19TemplateId AS NVARCHAR(50)) + ''', ''CA documentation complete'', ''State forms completed'', 3, ''Other'', 1, 0, 1, 1)
')

PRINT '   ✓ California Title 19 (3 items)'

-- ============================================================================
-- 1.6 ULC Template
-- ============================================================================
PRINT '6. Creating ULC (Canadian) Template...'

EXEC('
INSERT INTO [' + @Schema + '].ChecklistTemplates (TemplateId, TenantId, TemplateName, InspectionType, Standard, IsSystemTemplate, IsActive, Description)
VALUES (
    ''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''',
    NULL,
    ''ULC Inspection (Canadian Standards)'',
    ''Annual'',
    ''ULC'',
    1,
    1,
    ''Canadian standards per ULC requirements''
)

INSERT INTO [' + @Schema + '].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''', ''ULC certification present'', ''ULC label verified'', 1, ''Label'', 1, 1, 0, 0),
(''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''', ''Monthly items complete'', ''All standard checks done'', 2, ''Other'', 1, 0, 0, 0),
(''' + CAST(@ULCTemplateId AS NVARCHAR(50)) + ''', ''Canadian compliance'', ''Local requirements met'', 3, ''Other'', 1, 0, 1, 1)
')

PRINT '   ✓ ULC Canadian (3 items)'

PRINT ''
PRINT '============================================================================'
PRINT 'BASE SEED DATA COMPLETE'
PRINT '============================================================================'
PRINT ''
PRINT 'Created:'
PRINT '  - 6 NFPA compliance templates'
PRINT '  - 51 checklist items total'
PRINT '  - All marked as system templates (available to all tenants)'
PRINT ''
PRINT 'Templates can now be used for inspections across any tenant.'
PRINT ''

GO
