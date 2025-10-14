using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for inspection deficiency management
/// Tracks issues found during inspections and their resolution workflow
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class DeficienciesController : ControllerBase
{
    private readonly IDeficiencyService _deficiencyService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<DeficienciesController> _logger;

    public DeficienciesController(
        IDeficiencyService deficiencyService,
        TenantContext tenantContext,
        ILogger<DeficienciesController> logger)
    {
        _deficiencyService = deficiencyService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    // ==================== CORE CRUD OPERATIONS ====================

    /// <summary>
    /// Creates a new deficiency for an inspection
    /// Typically called during or after inspection when issues are found
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionDeficiencyDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionDeficiencyDto>> CreateDeficiency([FromBody] CreateDeficiencyRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            _logger.LogInformation("Creating deficiency for inspection {InspectionId}: {DeficiencyType} - {Severity}",
                request.InspectionId, request.DeficiencyType, request.Severity);

            var deficiency = await _deficiencyService.CreateDeficiencyAsync(_tenantContext.TenantId, request);

            return CreatedAtAction(
                nameof(GetDeficiencyById),
                new { id = deficiency.DeficiencyId },
                deficiency);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating deficiency for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to create deficiency", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets a specific deficiency by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionDeficiencyDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionDeficiencyDto>> GetDeficiencyById(Guid id, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning not found");
                return NotFound(new { message = $"Deficiency {id} not found" });
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var deficiency = await _deficiencyService.GetDeficiencyByIdAsync(effectiveTenantId, id);

            if (deficiency == null)
                return NotFound(new { message = $"Deficiency {id} not found" });

            return Ok(deficiency);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving deficiency {DeficiencyId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve deficiency", error = ex.Message });
        }
    }

    /// <summary>
    /// Updates a deficiency (status, assignment, due date, estimated cost, action required)
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(InspectionDeficiencyDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionDeficiencyDto>> UpdateDeficiency(
        Guid id,
        [FromBody] UpdateDeficiencyRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var deficiency = await _deficiencyService.UpdateDeficiencyAsync(_tenantContext.TenantId, id, request);
            return Ok(deficiency);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Deficiency {id} not found" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating deficiency {DeficiencyId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to update deficiency", error = ex.Message });
        }
    }

    /// <summary>
    /// Deletes a deficiency (soft delete, preserves audit trail)
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteDeficiency(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var success = await _deficiencyService.DeleteDeficiencyAsync(_tenantContext.TenantId, id);

            if (!success)
                return NotFound(new { message = $"Deficiency {id} not found" });

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting deficiency {DeficiencyId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to delete deficiency", error = ex.Message });
        }
    }

    // ==================== WORKFLOW OPERATIONS ====================

    /// <summary>
    /// Resolves a deficiency (marks as Resolved with resolution notes and resolved by user)
    /// </summary>
    [HttpPut("{id:guid}/resolve")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(InspectionDeficiencyDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionDeficiencyDto>> ResolveDeficiency(
        Guid id,
        [FromBody] ResolveDeficiencyRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            _logger.LogInformation("Resolving deficiency {DeficiencyId} by user {ResolvedByUserId}",
                id, request.ResolvedByUserId);

            var deficiency = await _deficiencyService.ResolveDeficiencyAsync(_tenantContext.TenantId, id, request);
            return Ok(deficiency);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Deficiency {id} not found" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resolving deficiency {DeficiencyId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to resolve deficiency", error = ex.Message });
        }
    }

    // ==================== QUERY OPERATIONS ====================

    /// <summary>
    /// Gets all deficiencies for a specific inspection
    /// </summary>
    [HttpGet("inspection/{inspectionId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDeficiencyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDeficiencyDto>>> GetDeficienciesByInspection(
        Guid inspectionId,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDeficiencyDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var deficiencies = await _deficiencyService.GetDeficienciesByInspectionAsync(effectiveTenantId, inspectionId);
            return Ok(deficiencies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving deficiencies for inspection {InspectionId} for tenant {TenantId}",
                inspectionId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve deficiencies", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets all open deficiencies (Status = Open or InProgress)
    /// Critical for maintenance workflow - shows what needs to be addressed
    /// </summary>
    [HttpGet("open")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDeficiencyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDeficiencyDto>>> GetOpenDeficiencies(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDeficiencyDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var deficiencies = await _deficiencyService.GetOpenDeficienciesAsync(effectiveTenantId, startDate, endDate);
            return Ok(deficiencies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving open deficiencies for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve open deficiencies", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets deficiencies by severity level (Low, Medium, High, Critical)
    /// </summary>
    [HttpGet("severity/{severity}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDeficiencyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDeficiencyDto>>> GetDeficienciesBySeverity(
        string severity,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDeficiencyDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        // Validate severity parameter
        var validSeverities = new[] { "Low", "Medium", "High", "Critical" };
        if (!validSeverities.Contains(severity, StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = $"Invalid severity. Must be one of: {string.Join(", ", validSeverities)}" });
        }

        try
        {
            var deficiencies = await _deficiencyService.GetDeficienciesBySeverityAsync(
                effectiveTenantId,
                severity,
                startDate,
                endDate);
            return Ok(deficiencies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving {Severity} deficiencies for tenant {TenantId}",
                severity, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve deficiencies", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets deficiencies assigned to a specific user
    /// </summary>
    [HttpGet("assigned/{userId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDeficiencyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDeficiencyDto>>> GetDeficienciesByAssignee(
        Guid userId,
        [FromQuery] bool openOnly = true,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDeficiencyDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var deficiencies = await _deficiencyService.GetDeficienciesByAssigneeAsync(
                effectiveTenantId,
                userId,
                openOnly);
            return Ok(deficiencies);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving deficiencies assigned to user {UserId} for tenant {TenantId}",
                userId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve assigned deficiencies", error = ex.Message });
        }
    }
}
