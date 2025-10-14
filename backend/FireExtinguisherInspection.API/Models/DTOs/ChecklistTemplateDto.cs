namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Checklist template for different inspection types (Monthly, Annual, etc.)
/// </summary>
public class ChecklistTemplateDto
{
    public Guid TemplateId { get; set; }
    public Guid? TenantId { get; set; }
    public required string TemplateName { get; set; }
    public required string InspectionType { get; set; } // Monthly, Annual, SixYear, TwelveYear, Hydrostatic
    public required string Standard { get; set; } // NFPA10, Title19, ULC, OSHA
    public bool IsSystemTemplate { get; set; }
    public bool IsActive { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? ModifiedDate { get; set; }

    // Navigation properties
    public List<ChecklistItemDto>? Items { get; set; }
}

/// <summary>
/// Request to create a custom checklist template
/// </summary>
public class CreateChecklistTemplateRequest
{
    public required string TemplateName { get; set; }
    public required string InspectionType { get; set; }
    public required string Standard { get; set; }
    public string? Description { get; set; }
}

/// <summary>
/// Request to update a custom checklist template
/// </summary>
public class UpdateChecklistTemplateRequest
{
    public string? TemplateName { get; set; }
    public string? Description { get; set; }
    public bool? IsActive { get; set; }
}
