using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for inspection type management
/// Requires tenant-level authorization (Manager or above)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class InspectionTypesController : ControllerBase
{
    private readonly IInspectionTypeService _inspectionTypeService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<InspectionTypesController> _logger;

    public InspectionTypesController(
        IInspectionTypeService inspectionTypeService,
        TenantContext tenantContext,
        ILogger<InspectionTypesController> logger)
    {
        _inspectionTypeService = inspectionTypeService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Creates a new inspection type
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(InspectionTypeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionTypeDto>> CreateInspectionType([FromBody] CreateInspectionTypeRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Creating inspection type for tenant {TenantId}", _tenantContext.TenantId);

        var inspectionType = await _inspectionTypeService.CreateInspectionTypeAsync(_tenantContext.TenantId, request);

        return CreatedAtAction(
            nameof(GetInspectionTypeById),
            new { id = inspectionType.InspectionTypeId },
            inspectionType);
    }

    /// <summary>
    /// Retrieves all inspection types for the current tenant
    /// SystemAdmin users can optionally specify a tenantId parameter to query a specific tenant
    /// </summary>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionTypeDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionTypeDto>>> GetAllInspectionTypes(
        [FromQuery] bool? isActive = null,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                // SystemAdmin without tenant parameter - return empty list
                _logger.LogDebug("SystemAdmin fetching inspection types without tenantId - returning empty list");
                return Ok(Array.Empty<InspectionTypeDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        _logger.LogDebug("Fetching inspection types for tenant {TenantId}", effectiveTenantId);
        var types = await _inspectionTypeService.GetAllInspectionTypesAsync(effectiveTenantId, isActive);
        return Ok(types);
    }

    /// <summary>
    /// Retrieves a specific inspection type by ID
    /// </summary>
    [HttpGet("{id}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionTypeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionTypeDto>> GetInspectionTypeById(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogDebug("Fetching inspection type {InspectionTypeId} for tenant {TenantId}", id, _tenantContext.TenantId);

        var inspectionType = await _inspectionTypeService.GetInspectionTypeByIdAsync(_tenantContext.TenantId, id);

        if (inspectionType == null)
        {
            return NotFound(new { message = $"Inspection type {id} not found" });
        }

        return Ok(inspectionType);
    }

    /// <summary>
    /// Updates an existing inspection type
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(InspectionTypeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionTypeDto>> UpdateInspectionType(Guid id, [FromBody] UpdateInspectionTypeRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Updating inspection type {InspectionTypeId} for tenant {TenantId}", id, _tenantContext.TenantId);

        try
        {
            var inspectionType = await _inspectionTypeService.UpdateInspectionTypeAsync(_tenantContext.TenantId, id, request);
            return Ok(inspectionType);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes (soft delete) an inspection type
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteInspectionType(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Deleting inspection type {InspectionTypeId} for tenant {TenantId}", id, _tenantContext.TenantId);

        var success = await _inspectionTypeService.DeleteInspectionTypeAsync(_tenantContext.TenantId, id);

        if (!success)
        {
            return NotFound(new { message = $"Inspection type {id} not found" });
        }

        return NoContent();
    }
}
