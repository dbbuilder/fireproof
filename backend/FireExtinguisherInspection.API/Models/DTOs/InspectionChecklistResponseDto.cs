namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Response to a single checklist item during inspection
/// </summary>
public class InspectionChecklistResponseDto
{
    public Guid ResponseId { get; set; }
    public Guid InspectionId { get; set; }
    public Guid ChecklistItemId { get; set; }
    public required string Response { get; set; } // Pass, Fail, NA
    public string? Comment { get; set; }
    public Guid? PhotoId { get; set; }
    public DateTime CreatedDate { get; set; }

    // Navigation properties
    public string? ItemText { get; set; }
    public string? Category { get; set; }
    public int? Order { get; set; }
}

/// <summary>
/// Request to save checklist responses (batch)
/// </summary>
public class SaveChecklistResponsesRequest
{
    public Guid InspectionId { get; set; }
    public required List<ChecklistResponseItem> Responses { get; set; }
}

public class ChecklistResponseItem
{
    public Guid ChecklistItemId { get; set; }
    public required string Response { get; set; } // Pass, Fail, NA
    public string? Comment { get; set; }
    public Guid? PhotoId { get; set; }
}
