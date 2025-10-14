namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Individual item in a checklist template
/// </summary>
public class ChecklistItemDto
{
    public Guid ChecklistItemId { get; set; }
    public Guid TemplateId { get; set; }
    public required string ItemText { get; set; }
    public string? ItemDescription { get; set; }
    public int Order { get; set; }
    public required string Category { get; set; } // Location, PhysicalCondition, Pressure, Seal, Hose, Label, Other
    public bool Required { get; set; }
    public bool RequiresPhoto { get; set; }
    public bool RequiresComment { get; set; }
    public bool PassFailNA { get; set; } // true = Pass/Fail/NA, false = Pass/Fail only
    public string? VisualAid { get; set; } // URL to diagram/photo
    public DateTime CreatedDate { get; set; }
}

/// <summary>
/// Request to add items to a template
/// </summary>
public class CreateChecklistItemsRequest
{
    public required List<ChecklistItemRequest> Items { get; set; }
}

public class ChecklistItemRequest
{
    public required string ItemText { get; set; }
    public string? ItemDescription { get; set; }
    public int Order { get; set; }
    public required string Category { get; set; }
    public bool Required { get; set; } = true;
    public bool RequiresPhoto { get; set; }
    public bool RequiresComment { get; set; }
    public bool PassFailNA { get; set; } = true;
    public string? VisualAid { get; set; }
}
