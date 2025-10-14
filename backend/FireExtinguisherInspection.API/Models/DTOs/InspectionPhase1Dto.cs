namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Phase 1 Inspection DTO with checklist-based approach
/// Uses ChecklistTemplates and separate tables for responses, photos, and deficiencies
/// </summary>
public class InspectionPhase1Dto
{
    public Guid InspectionId { get; set; }
    public Guid TenantId { get; set; }
    public Guid ExtinguisherId { get; set; }
    public Guid InspectorUserId { get; set; }
    public Guid TemplateId { get; set; }

    public required string InspectionType { get; set; } // Monthly, Annual, SixYear, TwelveYear, Hydrostatic
    public required string Status { get; set; } // Scheduled, InProgress, Completed, Failed

    // Scheduling and timing
    public DateTime? ScheduledDate { get; set; }
    public DateTime? StartTime { get; set; }
    public DateTime? CompletedTime { get; set; }

    // GPS Verification
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public decimal? LocationAccuracy { get; set; }

    // Tamper-Proofing (Blockchain-style hash chaining)
    public string? InspectionHash { get; set; }
    public string? PreviousInspectionHash { get; set; }
    public bool? HashVerified { get; set; }

    // Inspector Signature
    public string? InspectorSignature { get; set; }
    public DateTime? SignedDate { get; set; }

    // Overall Result
    public string? OverallResult { get; set; } // Pass, Fail, ConditionalPass

    public string? Notes { get; set; }

    public DateTime CreatedDate { get; set; }
    public DateTime? ModifiedDate { get; set; }

    // Navigation properties
    public string? ExtinguisherCode { get; set; }
    public string? InspectorName { get; set; }
    public string? LocationName { get; set; }
    public string? TemplateName { get; set; }

    // Related data (populated separately)
    public List<InspectionChecklistResponseDto>? ChecklistResponses { get; set; }
    public List<InspectionPhotoDto>? Photos { get; set; }
    public List<InspectionDeficiencyDto>? Deficiencies { get; set; }
}

/// <summary>
/// Request to create a new Phase 1 inspection
/// </summary>
public class CreateInspectionPhase1Request
{
    public Guid ExtinguisherId { get; set; }
    public Guid InspectorUserId { get; set; }
    public Guid TemplateId { get; set; }
    public required string InspectionType { get; set; } // Monthly, Annual, SixYear, TwelveYear, Hydrostatic
    public DateTime? ScheduledDate { get; set; }

    // GPS coordinates (captured at start)
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public decimal? LocationAccuracy { get; set; }
}

/// <summary>
/// Request to update an in-progress inspection
/// </summary>
public class UpdateInspectionPhase1Request
{
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public decimal? LocationAccuracy { get; set; }
    public string? Notes { get; set; }
}

/// <summary>
/// Request to complete an inspection (compute hash, sign, mark complete)
/// </summary>
public class CompleteInspectionRequest
{
    public required string OverallResult { get; set; } // Pass, Fail, ConditionalPass
    public string? Notes { get; set; }
    public string? InspectorSignature { get; set; } // Digital signature or base64 image
}

/// <summary>
/// Response for inspection verification (Phase 1 - blockchain style)
/// </summary>
public class InspectionPhase1VerificationResponse
{
    public Guid InspectionId { get; set; }
    public bool IsValid { get; set; }
    public string? ValidationMessage { get; set; }
    public string? InspectionHash { get; set; }
    public string? PreviousInspectionHash { get; set; }
    public bool HashChainVerified { get; set; }
    public bool SignatureVerified { get; set; }
    public bool LocationVerified { get; set; }
    public DateTime VerifiedDate { get; set; }
}

/// <summary>
/// Inspection statistics for Phase 1
/// </summary>
public class InspectionPhase1StatsDto
{
    public int TotalInspections { get; set; }
    public int CompletedInspections { get; set; }
    public int InProgressInspections { get; set; }
    public int FailedInspections { get; set; }
    public int PassedInspections { get; set; }
    public int ConditionalPassInspections { get; set; }
    public int TotalDeficiencies { get; set; }
    public int CriticalDeficiencies { get; set; }
    public double PassRate { get; set; }
    public DateTime? LastInspectionDate { get; set; }
    public int InspectionsThisMonth { get; set; }
    public int InspectionsThisYear { get; set; }
}
