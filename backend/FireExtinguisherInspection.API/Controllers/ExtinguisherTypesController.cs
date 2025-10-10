using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for fire extinguisher type management
/// Requires tenant-level authorization (Manager or above)
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class ExtinguisherTypesController : ControllerBase
{
    private readonly IExtinguisherTypeService _extinguisherTypeService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<ExtinguisherTypesController> _logger;

    public ExtinguisherTypesController(
        IExtinguisherTypeService extinguisherTypeService,
        TenantContext tenantContext,
        ILogger<ExtinguisherTypesController> logger)
    {
        _extinguisherTypeService = extinguisherTypeService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Creates a new extinguisher type
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherTypeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherTypeDto>> CreateExtinguisherType([FromBody] CreateExtinguisherTypeRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Creating extinguisher type for tenant {TenantId}", _tenantContext.TenantId);

        var extinguisherType = await _extinguisherTypeService.CreateExtinguisherTypeAsync(_tenantContext.TenantId, request);

        return CreatedAtAction(
            nameof(GetExtinguisherTypeById),
            new { id = extinguisherType.ExtinguisherTypeId },
            extinguisherType);
    }

    /// <summary>
    /// Retrieves all extinguisher types for the current tenant
    /// </summary>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ExtinguisherTypeDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<ExtinguisherTypeDto>>> GetAllExtinguisherTypes([FromQuery] bool? isActive = null)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogDebug("Fetching extinguisher types for tenant {TenantId}", _tenantContext.TenantId);

        var types = await _extinguisherTypeService.GetAllExtinguisherTypesAsync(_tenantContext.TenantId, isActive);

        return Ok(types);
    }

    /// <summary>
    /// Retrieves a specific extinguisher type by ID
    /// </summary>
    [HttpGet("{id}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherTypeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherTypeDto>> GetExtinguisherTypeById(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogDebug("Fetching extinguisher type {ExtinguisherTypeId} for tenant {TenantId}", id, _tenantContext.TenantId);

        var extinguisherType = await _extinguisherTypeService.GetExtinguisherTypeByIdAsync(_tenantContext.TenantId, id);

        if (extinguisherType == null)
        {
            return NotFound(new { message = $"Extinguisher type {id} not found" });
        }

        return Ok(extinguisherType);
    }

    /// <summary>
    /// Updates an existing extinguisher type
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(ExtinguisherTypeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ExtinguisherTypeDto>> UpdateExtinguisherType(Guid id, [FromBody] UpdateExtinguisherTypeRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Updating extinguisher type {ExtinguisherTypeId} for tenant {TenantId}", id, _tenantContext.TenantId);

        try
        {
            var extinguisherType = await _extinguisherTypeService.UpdateExtinguisherTypeAsync(_tenantContext.TenantId, id, request);
            return Ok(extinguisherType);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes (soft delete) an extinguisher type
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteExtinguisherType(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Deleting extinguisher type {ExtinguisherTypeId} for tenant {TenantId}", id, _tenantContext.TenantId);

        var success = await _extinguisherTypeService.DeleteExtinguisherTypeAsync(_tenantContext.TenantId, id);

        if (!success)
        {
            return NotFound(new { message = $"Extinguisher type {id} not found" });
        }

        return NoContent();
    }
}
