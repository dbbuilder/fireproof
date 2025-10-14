USE FireProofDB
GO

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @AnnualTemplateId UNIQUEIDENTIFIER = NEWID()

-- Delete existing
DELETE FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems 
WHERE TemplateId IN (
  SELECT TemplateId FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates 
  WHERE TemplateName = 'NFPA 10 Annual Inspection'
)

DELETE FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates 
WHERE TemplateName = 'NFPA 10 Annual Inspection'

-- Insert template
INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates (
    TemplateId, TenantId, TemplateName, InspectionType, Standard,
    IsSystemTemplate, IsActive, Description
)
VALUES (
    @AnnualTemplateId,
    NULL,
    'NFPA 10 Annual Inspection',
    'Annual',
    'NFPA10',
    1,
    1,
    'Comprehensive annual inspection per NFPA 10 Section 7.3'
)

-- Insert 18 items
INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems (TemplateId, ItemText, ItemDescription, [Order], Category, Required, RequiresPhoto, RequiresComment, PassFailNA)
VALUES
(@AnnualTemplateId, 'Extinguisher accessible and visible', 'Verify the extinguisher is not blocked', 1, 'Location', 1, 0, 0, 1),
(@AnnualTemplateId, 'Location clearly marked', 'Check that signage is present', 2, 'Location', 1, 0, 0, 1),
(@AnnualTemplateId, 'Pressure gauge in operable range', 'Verify needle is in green zone', 3, 'Pressure', 1, 1, 0, 0),
(@AnnualTemplateId, 'Safety seal intact', 'Ensure tamper seal is unbroken', 4, 'Seal', 1, 1, 0, 0),
(@AnnualTemplateId, 'No visible physical damage', 'Inspect for dents or rust', 5, 'PhysicalCondition', 1, 1, 1, 0),
(@AnnualTemplateId, 'Operating instructions legible', 'Confirm label is readable', 6, 'Label', 1, 0, 0, 1),
(@AnnualTemplateId, 'Service tag attached and current', 'Check tag is present', 7, 'Label', 1, 1, 0, 0),
(@AnnualTemplateId, 'Hose in good condition', 'Verify hose is not cracked', 8, 'Hose', 1, 1, 1, 0),
(@AnnualTemplateId, 'Mounting bracket secure', 'Ensure bracket is fastened', 9, 'Location', 1, 0, 0, 1),
(@AnnualTemplateId, 'No signs of discharge', 'Check for discharge indicators', 10, 'PhysicalCondition', 1, 0, 1, 1),
(@AnnualTemplateId, 'Mechanical parts examination', 'Inspect all mechanical parts', 11, 'PhysicalCondition', 1, 0, 1, 0),
(@AnnualTemplateId, 'Extinguishing agent examination', 'Check agent condition', 12, 'PhysicalCondition', 1, 0, 1, 1),
(@AnnualTemplateId, 'Expelling means examination', 'Verify propellant pressure', 13, 'Pressure', 1, 0, 1, 1),
(@AnnualTemplateId, 'Weight check (CO2 types)', 'Weigh CO2 extinguishers', 14, 'Pressure', 1, 0, 1, 1),
(@AnnualTemplateId, 'Examine for corrosion', 'Detailed corrosion inspection', 15, 'PhysicalCondition', 1, 1, 1, 0),
(@AnnualTemplateId, 'Nameplate legibility', 'Ensure nameplate is legible', 16, 'Label', 1, 0, 0, 1),
(@AnnualTemplateId, 'Verify proper type for hazard', 'Confirm class matches hazards', 17, 'Other', 1, 0, 1, 1),
(@AnnualTemplateId, 'Verify proper mounting height', 'Check mounting height compliance', 18, 'Location', 1, 0, 0, 1)

PRINT 'NFPA 10 Annual Inspection Template created with 18 items'

SELECT COUNT(*) as ItemCount 
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems 
WHERE TemplateId = @AnnualTemplateId
GO
