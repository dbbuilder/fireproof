using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for fire extinguisher inspection management
/// Requires tenant-level authorization (Inspector or above)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class InspectionsController : ControllerBase
{
    private readonly IInspectionService _inspectionService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<InspectionsController> _logger;

    public InspectionsController(
        IInspectionService inspectionService,
        TenantContext tenantContext,
        ILogger<InspectionsController> logger)
    {
        _inspectionService = inspectionService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Create a new tamper-proof inspection
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionDto>> CreateInspection([FromBody] CreateInspectionRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var inspection = await _inspectionService.CreateInspectionAsync(_tenantContext.TenantId, request);
            return CreatedAtAction(nameof(GetInspectionById), new { id = inspection.InspectionId }, inspection);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating inspection for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to create inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Get all inspections with optional filtering
    /// </summary>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetAllInspections(
        [FromQuery] Guid? extinguisherId = null,
        [FromQuery] Guid? inspectorUserId = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? inspectionType = null,
        [FromQuery] bool? passed = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetAllInspectionsAsync(
                effectiveTenantId,
                extinguisherId,
                inspectorUserId,
                startDate,
                endDate,
                inspectionType,
                passed);

            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspections for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspection by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionDto>> GetInspectionById(Guid id, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspection = await _inspectionService.GetInspectionByIdAsync(effectiveTenantId, id);

            if (inspection == null)
                return NotFound(new { message = $"Inspection {id} not found" });

            return Ok(inspection);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspection {InspectionId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspection history for a specific extinguisher
    /// </summary>
    [HttpGet("extinguisher/{extinguisherId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetExtinguisherInspectionHistory(Guid extinguisherId, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetExtinguisherInspectionHistoryAsync(effectiveTenantId, extinguisherId);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspection history for extinguisher {ExtinguisherId} for tenant {TenantId}",
                extinguisherId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection history", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspections performed by a specific inspector
    /// </summary>
    [HttpGet("inspector/{inspectorUserId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetInspectorInspections(
        Guid inspectorUserId,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetInspectorInspectionsAsync(
                effectiveTenantId,
                inspectorUserId,
                startDate,
                endDate);

            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspections for inspector {InspectorUserId} for tenant {TenantId}",
                inspectorUserId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspector inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Verify the tamper-proof integrity of an inspection
    /// </summary>
    [HttpPost("{id:guid}/verify")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionVerificationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionVerificationResponse>> VerifyInspectionIntegrity(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var verificationResult = await _inspectionService.VerifyInspectionIntegrityAsync(_tenantContext.TenantId, id);
            return Ok(verificationResult);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Inspection {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to verify inspection integrity", error = ex.Message });
        }
    }

    /// <summary>
    /// Get inspection statistics
    /// </summary>
    [HttpGet("stats")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(InspectionStatsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionStatsDto>> GetInspectionStats(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionStatsDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var stats = await _inspectionService.GetInspectionStatsAsync(effectiveTenantId, startDate, endDate);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inspection stats for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve inspection statistics", error = ex.Message });
        }
    }

    /// <summary>
    /// Get overdue inspections
    /// </summary>
    [HttpGet("overdue")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionDto>>> GetOverdueInspections(
        [FromQuery] string inspectionType = "Monthly",
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var inspections = await _inspectionService.GetOverdueInspectionsAsync(effectiveTenantId, inspectionType);
            return Ok(inspections);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving overdue inspections for tenant {TenantId}", effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve overdue inspections", error = ex.Message });
        }
    }

    /// <summary>
    /// Delete an inspection (admin only - inspections are tamper-proof)
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteInspection(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var success = await _inspectionService.DeleteInspectionAsync(_tenantContext.TenantId, id);

            if (!success)
                return NotFound(new { message = $"Inspection {id} not found" });

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting inspection {InspectionId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to delete inspection", error = ex.Message });
        }
    }
}
