namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Inspection record DTO with tamper-proof hash
/// </summary>
public class InspectionDto
{
    public Guid InspectionId { get; set; }
    public Guid TenantId { get; set; }
    public Guid ExtinguisherId { get; set; }
    public Guid InspectorUserId { get; set; }

    public DateTime InspectionDate { get; set; }
    public string InspectionType { get; set; } = string.Empty; // Monthly, Annual, 5-Year, 12-Year

    // Location verification
    public decimal? GpsLatitude { get; set; }
    public decimal? GpsLongitude { get; set; }
    public int? GpsAccuracyMeters { get; set; }
    public bool LocationVerified { get; set; }

    // Physical condition checks
    public bool IsAccessible { get; set; }
    public bool HasObstructions { get; set; }
    public bool SignageVisible { get; set; }
    public bool SealIntact { get; set; }
    public bool PinInPlace { get; set; }
    public bool NozzleClear { get; set; }
    public bool HoseConditionGood { get; set; }
    public bool GaugeInGreenZone { get; set; }
    public decimal? GaugePressurePsi { get; set; }
    public bool PhysicalDamagePresent { get; set; }
    public string? DamageDescription { get; set; }

    // Weight check (for certain types)
    public decimal? WeightPounds { get; set; }
    public bool WeightWithinSpec { get; set; }

    // Tag and documentation
    public bool InspectionTagAttached { get; set; }
    public string? PreviousInspectionDate { get; set; }
    public string? Notes { get; set; }

    // Pass/fail and actions
    public bool Passed { get; set; }
    public bool RequiresService { get; set; }
    public bool RequiresReplacement { get; set; }
    public string? FailureReason { get; set; }
    public string? CorrectiveAction { get; set; }

    // Photo evidence
    public List<string>? PhotoUrls { get; set; }

    // Tamper-proofing
    public string DataHash { get; set; } = string.Empty;
    public string InspectorSignature { get; set; } = string.Empty; // Digital signature
    public DateTime SignedDate { get; set; }
    public bool IsVerified { get; set; }

    // Timestamps
    public DateTime CreatedDate { get; set; }
    public DateTime ModifiedDate { get; set; }

    // Navigation properties
    public string? ExtinguisherCode { get; set; }
    public string? InspectorName { get; set; }
    public string? LocationName { get; set; }
}

/// <summary>
/// Request to create a new inspection
/// </summary>
public class CreateInspectionRequest
{
    public Guid ExtinguisherId { get; set; }
    public Guid InspectorUserId { get; set; }
    public DateTime InspectionDate { get; set; }
    public string InspectionType { get; set; } = string.Empty;

    // Location verification
    public decimal? GpsLatitude { get; set; }
    public decimal? GpsLongitude { get; set; }
    public int? GpsAccuracyMeters { get; set; }

    // Physical condition checks
    public bool IsAccessible { get; set; }
    public bool HasObstructions { get; set; }
    public bool SignageVisible { get; set; }
    public bool SealIntact { get; set; }
    public bool PinInPlace { get; set; }
    public bool NozzleClear { get; set; }
    public bool HoseConditionGood { get; set; }
    public bool GaugeInGreenZone { get; set; }
    public decimal? GaugePressurePsi { get; set; }
    public bool PhysicalDamagePresent { get; set; }
    public string? DamageDescription { get; set; }

    // Weight check
    public decimal? WeightPounds { get; set; }

    // Tag and documentation
    public bool InspectionTagAttached { get; set; }
    public string? PreviousInspectionDate { get; set; }
    public string? Notes { get; set; }

    // Actions
    public bool RequiresService { get; set; }
    public bool RequiresReplacement { get; set; }
    public string? FailureReason { get; set; }
    public string? CorrectiveAction { get; set; }

    // Photo evidence
    public List<string>? PhotoUrls { get; set; }
}

/// <summary>
/// Request to verify an inspection's integrity
/// </summary>
public class VerifyInspectionRequest
{
    public Guid InspectionId { get; set; }
}

/// <summary>
/// Response for inspection verification
/// </summary>
public class InspectionVerificationResponse
{
    public Guid InspectionId { get; set; }
    public bool IsValid { get; set; }
    public string? ValidationMessage { get; set; }
    public string OriginalHash { get; set; } = string.Empty;
    public string ComputedHash { get; set; } = string.Empty;
    public bool HashMatch { get; set; }
    public DateTime VerifiedDate { get; set; }
}

/// <summary>
/// Inspection statistics
/// </summary>
public class InspectionStatsDto
{
    public int TotalInspections { get; set; }
    public int PassedInspections { get; set; }
    public int FailedInspections { get; set; }
    public int RequiringService { get; set; }
    public int RequiringReplacement { get; set; }
    public double PassRate { get; set; }
    public DateTime? LastInspectionDate { get; set; }
    public int InspectionsThisMonth { get; set; }
    public int InspectionsThisYear { get; set; }
}
