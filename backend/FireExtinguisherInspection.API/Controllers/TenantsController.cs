using System.Security.Claims;
using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for tenant management
/// Supports tenant selection for SystemAdmin and multi-tenant users
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class TenantsController : ControllerBase
{
    private readonly ITenantService _tenantService;
    private readonly ILogger<TenantsController> _logger;
    private readonly IConfiguration _configuration;

    public TenantsController(
        ITenantService tenantService,
        ILogger<TenantsController> logger,
        IConfiguration configuration)
    {
        _tenantService = tenantService;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Retrieves all tenants (SystemAdmin only)
    /// </summary>
    /// <returns>List of all tenants</returns>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.SystemAdminOnly)]
    [ProducesResponseType(typeof(IEnumerable<TenantDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<TenantDto>>> GetAllTenants()
    {
        _logger.LogDebug("Fetching all tenants (SystemAdmin)");

        var tenants = await _tenantService.GetAllTenantsAsync();
        return Ok(tenants);
    }

    /// <summary>
    /// Retrieves tenants available to the current user
    /// - SystemAdmin: Returns all tenants
    /// - Multi-tenant users: Returns tenants they have access to
    /// - Single-tenant users: Returns their tenant
    /// </summary>
    /// <returns>List of available tenants</returns>
    [HttpGet("available")]
    [ProducesResponseType(typeof(IEnumerable<TenantDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IEnumerable<TenantDto>>> GetAvailableTenants()
    {
        // Check if user is SystemAdmin
        if (TenantResolver.IsSystemAdmin(User))
        {
            _logger.LogDebug("Fetching all tenants for SystemAdmin");
            var allTenants = await _tenantService.GetAllTenantsAsync();
            return Ok(allTenants);
        }

        // Get user ID from claims
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
        if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
        {
            _logger.LogWarning("User ID claim not found or invalid");
            return Unauthorized(new { message = "User ID not found in token" });
        }

        _logger.LogDebug("Fetching available tenants for user {UserId}", userId);
        var tenants = await _tenantService.GetAvailableTenantsForUserAsync(userId);
        return Ok(tenants);
    }

    /// <summary>
    /// Retrieves a specific tenant by ID
    /// </summary>
    /// <param name="id">Tenant ID</param>
    /// <returns>Tenant details</returns>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(TenantDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<TenantDto>> GetTenantById(Guid id)
    {
        _logger.LogDebug("Fetching tenant {TenantId}", id);

        // SystemAdmin can access any tenant
        if (!TenantResolver.IsSystemAdmin(User))
        {
            // For non-SystemAdmin, verify they have access to this tenant
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            if (userIdClaim != null && Guid.TryParse(userIdClaim.Value, out var userId))
            {
                var availableTenants = await _tenantService.GetAvailableTenantsForUserAsync(userId);
                if (!availableTenants.Any(t => t.TenantId == id))
                {
                    _logger.LogWarning("User {UserId} attempted to access tenant {TenantId} without permission", userId, id);
                    return Forbid();
                }
            }
            else
            {
                return Unauthorized(new { message = "User ID not found in token" });
            }
        }

        var tenant = await _tenantService.GetTenantByIdAsync(id);

        if (tenant == null)
        {
            return NotFound(new { message = $"Tenant {id} not found" });
        }

        return Ok(tenant);
    }

    /// <summary>
    /// Creates a new tenant (SystemAdmin only)
    /// </summary>
    /// <param name="request">Tenant creation request</param>
    /// <returns>Created tenant</returns>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.SystemAdminOnly)]
    [ProducesResponseType(typeof(TenantDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<TenantDto>> CreateTenant([FromBody] CreateTenantRequest request)
    {
        _logger.LogInformation("Creating tenant: {TenantCode}", request.TenantCode);

        try
        {
            var tenant = await _tenantService.CreateTenantAsync(request);

            return CreatedAtAction(
                nameof(GetTenantById),
                new { id = tenant.TenantId },
                tenant);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create tenant: {TenantCode}", request.TenantCode);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Updates an existing tenant (SystemAdmin only)
    /// </summary>
    /// <param name="id">Tenant ID</param>
    /// <param name="request">Tenant update request</param>
    /// <returns>Updated tenant</returns>
    [HttpPut("{id}")]
    [Authorize(Policy = AuthorizationPolicies.SystemAdminOnly)]
    [ProducesResponseType(typeof(TenantDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<TenantDto>> UpdateTenant(Guid id, [FromBody] UpdateTenantRequest request)
    {
        _logger.LogInformation("Updating tenant {TenantId}", id);

        try
        {
            var tenant = await _tenantService.UpdateTenantAsync(id, request);
            return Ok(tenant);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update tenant {TenantId}", id);
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Diagnostic endpoint to check tenant stored procedures (development only)
    /// </summary>
    /// <returns>Diagnostic information</returns>
    [HttpGet("diagnostic")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<ActionResult> DiagnosticCheck()
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("sub");
            var userId = userIdClaim != null && Guid.TryParse(userIdClaim.Value, out var id) ? id : Guid.Empty;
            var isSystemAdmin = TenantResolver.IsSystemAdmin(User);

            // Check if stored procedures exist
            var connString = _configuration.GetConnectionString("DefaultConnection");
            using var connection = new Microsoft.Data.SqlClient.SqlConnection(connString);
            await connection.OpenAsync();

            using var command = connection.CreateCommand();
            command.CommandText = @"
                SELECT name
                FROM sys.procedures
                WHERE name LIKE 'usp_Tenant%'
                ORDER BY name";

            var procedures = new List<string>();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                procedures.Add(reader.GetString(0));
            }

            return Ok(new
            {
                success = true,
                userId = userId,
                isAuthenticated = User.Identity?.IsAuthenticated ?? false,
                isSystemAdmin = isSystemAdmin,
                storedProcedures = procedures,
                procedureCount = procedures.Count,
                expectedProcedures = new[] {
                    "usp_Tenant_Create",
                    "usp_Tenant_GetAll",
                    "usp_Tenant_GetAvailableForUser",
                    "usp_Tenant_GetById",
                    "usp_Tenant_Update"
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Diagnostic check failed");
            return StatusCode(500, new
            {
                success = false,
                error = ex.Message,
                innerError = ex.InnerException?.Message,
                stackTrace = ex.StackTrace
            });
        }
    }
}
