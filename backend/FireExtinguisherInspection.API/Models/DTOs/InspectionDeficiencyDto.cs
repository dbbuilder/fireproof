namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Deficiency found during inspection
/// </summary>
public class InspectionDeficiencyDto
{
    public Guid DeficiencyId { get; set; }
    public Guid InspectionId { get; set; }
    public required string DeficiencyType { get; set; } // Damage, Corrosion, Leakage, Pressure, Seal, Label, Hose, Location, Other
    public required string Severity { get; set; } // Low, Medium, High, Critical
    public required string Description { get; set; }
    public required string Status { get; set; } // Open, InProgress, Resolved, Deferred

    public string? ActionRequired { get; set; }
    public decimal? EstimatedCost { get; set; }

    public Guid? AssignedToUserId { get; set; }
    public DateTime? DueDate { get; set; }

    public string? ResolutionNotes { get; set; }
    public DateTime? ResolvedDate { get; set; }
    public Guid? ResolvedByUserId { get; set; }

    public List<Guid>? PhotoIds { get; set; } // Photo references

    public DateTime CreatedDate { get; set; }
    public DateTime? ModifiedDate { get; set; }

    // Navigation properties
    public string? ExtinguisherAssetTag { get; set; }
    public string? ExtinguisherBarcode { get; set; }
    public string? LocationName { get; set; }
    public string? AssignedToName { get; set; }
    public string? ResolvedByName { get; set; }
}

/// <summary>
/// Request to create a deficiency
/// </summary>
public class CreateDeficiencyRequest
{
    public Guid InspectionId { get; set; }
    public required string DeficiencyType { get; set; }
    public required string Severity { get; set; }
    public required string Description { get; set; }
    public string? ActionRequired { get; set; }
    public decimal? EstimatedCost { get; set; }
    public Guid? AssignedToUserId { get; set; }
    public DateTime? DueDate { get; set; }
    public List<Guid>? PhotoIds { get; set; }
}

/// <summary>
/// Request to update a deficiency
/// </summary>
public class UpdateDeficiencyRequest
{
    public string? Status { get; set; }
    public string? ActionRequired { get; set; }
    public decimal? EstimatedCost { get; set; }
    public Guid? AssignedToUserId { get; set; }
    public DateTime? DueDate { get; set; }
}

/// <summary>
/// Request to resolve a deficiency
/// </summary>
public class ResolveDeficiencyRequest
{
    public Guid ResolvedByUserId { get; set; }
    public required string ResolutionNotes { get; set; }
}
