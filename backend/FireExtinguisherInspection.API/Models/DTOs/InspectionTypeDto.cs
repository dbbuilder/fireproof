namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Data transfer object for inspection type
/// </summary>
public class InspectionTypeDto
{
    public Guid InspectionTypeId { get; set; }
    public Guid TenantId { get; set; }
    public string TypeName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool RequiresServiceTechnician { get; set; }
    public int FrequencyDays { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
}

/// <summary>
/// Request model for creating a new inspection type
/// </summary>
public class CreateInspectionTypeRequest
{
    public string TypeName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool RequiresServiceTechnician { get; set; }
    public int FrequencyDays { get; set; }
}

/// <summary>
/// Request model for updating an inspection type
/// </summary>
public class UpdateInspectionTypeRequest
{
    public string TypeName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool RequiresServiceTechnician { get; set; }
    public int FrequencyDays { get; set; }
    public bool IsActive { get; set; }
}
