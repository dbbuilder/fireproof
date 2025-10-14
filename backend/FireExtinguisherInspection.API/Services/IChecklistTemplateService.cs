using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for checklist template management operations
/// </summary>
public interface IChecklistTemplateService
{
    /// <summary>
    /// Retrieves all system templates (NFPA, Title19, ULC standards)
    /// </summary>
    Task<IEnumerable<ChecklistTemplateDto>> GetSystemTemplatesAsync();

    /// <summary>
    /// Retrieves all templates available to a tenant (system + custom)
    /// </summary>
    Task<IEnumerable<ChecklistTemplateDto>> GetTenantTemplatesAsync(Guid tenantId, bool activeOnly = true);

    /// <summary>
    /// Retrieves a specific template by ID with all checklist items
    /// </summary>
    Task<ChecklistTemplateDto?> GetTemplateByIdAsync(Guid templateId);

    /// <summary>
    /// Retrieves templates by inspection type (Monthly, Annual, SixYear, etc.)
    /// </summary>
    Task<IEnumerable<ChecklistTemplateDto>> GetTemplatesByTypeAsync(Guid tenantId, string inspectionType);

    /// <summary>
    /// Creates a custom checklist template for a tenant
    /// </summary>
    Task<ChecklistTemplateDto> CreateCustomTemplateAsync(Guid tenantId, CreateChecklistTemplateRequest request);

    /// <summary>
    /// Adds checklist items to a template
    /// </summary>
    Task<IEnumerable<ChecklistItemDto>> AddTemplateItemsAsync(Guid templateId, CreateChecklistItemsRequest request);

    /// <summary>
    /// Updates a custom template (cannot modify system templates)
    /// </summary>
    Task<ChecklistTemplateDto> UpdateTemplateAsync(Guid tenantId, Guid templateId, UpdateChecklistTemplateRequest request);

    /// <summary>
    /// Deactivates a custom template (cannot delete system templates)
    /// </summary>
    Task<bool> DeactivateTemplateAsync(Guid tenantId, Guid templateId);
}
