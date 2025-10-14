using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service interface for inspection deficiency management
/// Tracks issues found during inspections and their resolution workflow
/// </summary>
public interface IDeficiencyService
{
    /// <summary>
    /// Creates a new deficiency for an inspection
    /// </summary>
    Task<InspectionDeficiencyDto> CreateDeficiencyAsync(Guid tenantId, CreateDeficiencyRequest request);

    /// <summary>
    /// Gets a specific deficiency by ID
    /// </summary>
    Task<InspectionDeficiencyDto?> GetDeficiencyByIdAsync(Guid tenantId, Guid deficiencyId);

    /// <summary>
    /// Gets all deficiencies for a specific inspection
    /// </summary>
    Task<IEnumerable<InspectionDeficiencyDto>> GetDeficienciesByInspectionAsync(Guid tenantId, Guid inspectionId);

    /// <summary>
    /// Gets all open deficiencies (Status = Open or InProgress)
    /// </summary>
    Task<IEnumerable<InspectionDeficiencyDto>> GetOpenDeficienciesAsync(
        Guid tenantId,
        DateTime? startDate = null,
        DateTime? endDate = null);

    /// <summary>
    /// Gets deficiencies by severity level (Low, Medium, High, Critical)
    /// </summary>
    Task<IEnumerable<InspectionDeficiencyDto>> GetDeficienciesBySeverityAsync(
        Guid tenantId,
        string severity,
        DateTime? startDate = null,
        DateTime? endDate = null);

    /// <summary>
    /// Gets deficiencies assigned to a specific user
    /// </summary>
    Task<IEnumerable<InspectionDeficiencyDto>> GetDeficienciesByAssigneeAsync(
        Guid tenantId,
        Guid assignedToUserId,
        bool openOnly = true);

    /// <summary>
    /// Updates a deficiency (status, assignment, due date, etc.)
    /// </summary>
    Task<InspectionDeficiencyDto> UpdateDeficiencyAsync(
        Guid tenantId,
        Guid deficiencyId,
        UpdateDeficiencyRequest request);

    /// <summary>
    /// Resolves a deficiency (marks as Resolved with resolution notes)
    /// </summary>
    Task<InspectionDeficiencyDto> ResolveDeficiencyAsync(
        Guid tenantId,
        Guid deficiencyId,
        ResolveDeficiencyRequest request);

    /// <summary>
    /// Deletes a deficiency (soft delete, preserves audit trail)
    /// </summary>
    Task<bool> DeleteDeficiencyAsync(Guid tenantId, Guid deficiencyId);
}
