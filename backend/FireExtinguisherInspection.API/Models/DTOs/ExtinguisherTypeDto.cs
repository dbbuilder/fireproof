namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Data transfer object for fire extinguisher type
/// </summary>
public class ExtinguisherTypeDto
{
    public Guid ExtinguisherTypeId { get; set; }
    public Guid TenantId { get; set; }
    public string TypeCode { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? AgentType { get; set; }
    public decimal? Capacity { get; set; }
    public string? CapacityUnit { get; set; }
    public string? FireClassRating { get; set; }
    public int? ServiceLifeYears { get; set; }
    public int? HydroTestIntervalYears { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime ModifiedDate { get; set; }
}

/// <summary>
/// Request model for creating a new extinguisher type
/// </summary>
public class CreateExtinguisherTypeRequest
{
    public string TypeCode { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? AgentType { get; set; }
    public decimal? Capacity { get; set; }
    public string? CapacityUnit { get; set; }
    public string? FireClassRating { get; set; }
    public int? ServiceLifeYears { get; set; }
    public int? HydroTestIntervalYears { get; set; }
}

/// <summary>
/// Request model for updating an extinguisher type
/// </summary>
public class UpdateExtinguisherTypeRequest
{
    public string TypeName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? AgentType { get; set; }
    public decimal? Capacity { get; set; }
    public string? CapacityUnit { get; set; }
    public string? FireClassRating { get; set; }
    public int? ServiceLifeYears { get; set; }
    public int? HydroTestIntervalYears { get; set; }
    public bool IsActive { get; set; }
}
