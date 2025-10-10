using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace FireExtinguisherInspection.API.Authorization;

/// <summary>
/// Authorization handler for role-based access control
/// Evaluates both system-level and tenant-level roles from JWT claims
/// </summary>
public class RoleAuthorizationHandler : AuthorizationHandler<RoleRequirement>
{
    private readonly ILogger<RoleAuthorizationHandler> _logger;

    public RoleAuthorizationHandler(ILogger<RoleAuthorizationHandler> logger)
    {
        _logger = logger;
    }

    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        RoleRequirement requirement)
    {
        var user = context.User;

        if (user?.Identity?.IsAuthenticated != true)
        {
            _logger.LogWarning("Authorization failed: User not authenticated");
            return Task.CompletedTask;
        }

        var userId = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        _logger.LogDebug("Evaluating authorization for user {UserId}", userId);

        bool hasSystemRole = false;
        bool hasTenantRole = false;

        // Check system roles
        if (requirement.RequireSystemRole && requirement.SystemRoles.Length > 0)
        {
            var userSystemRoles = user.FindAll("system_role")
                .Select(c => c.Value)
                .ToList();

            _logger.LogDebug("User system roles: {SystemRoles}", string.Join(", ", userSystemRoles));

            if (requirement.SystemRoles.Any(role => userSystemRoles.Contains(role, StringComparer.OrdinalIgnoreCase)))
            {
                hasSystemRole = true;
                _logger.LogDebug("User {UserId} has matching system role", userId);
            }
        }

        // Check tenant roles
        if (requirement.RequireTenantRole && requirement.TenantRoles.Length > 0)
        {
            var userTenantRoles = user.FindAll("tenant_role")
                .Select(c => c.Value)
                .ToList();

            _logger.LogDebug("User tenant roles: {TenantRoles}", string.Join(", ", userTenantRoles));

            // Tenant roles are in format "TenantId:RoleName"
            // Extract just the role names
            var roleNames = userTenantRoles
                .Select(r => r.Contains(':') ? r.Split(':')[1] : r)
                .ToList();

            if (requirement.TenantRoles.Any(role => roleNames.Contains(role, StringComparer.OrdinalIgnoreCase)))
            {
                hasTenantRole = true;
                _logger.LogDebug("User {UserId} has matching tenant role", userId);
            }
        }

        // For mixed requirements (system OR tenant), succeed if either is satisfied
        // For single type requirements, succeed if that type is satisfied
        bool authorized = false;
        if (requirement.RequireSystemRole && requirement.RequireTenantRole)
        {
            // Mixed requirement: system OR tenant role
            authorized = hasSystemRole || hasTenantRole;
        }
        else if (requirement.RequireSystemRole)
        {
            // System role only
            authorized = hasSystemRole;
        }
        else if (requirement.RequireTenantRole)
        {
            // Tenant role only
            authorized = hasTenantRole;
        }

        if (authorized)
        {
            _logger.LogInformation("Authorization succeeded: User {UserId} has required role", userId);
            context.Succeed(requirement);
        }
        else
        {
            _logger.LogWarning("Authorization failed: User {UserId} does not have required roles. Required system roles: {SystemRoles}, Required tenant roles: {TenantRoles}",
                userId,
                string.Join(", ", requirement.SystemRoles),
                string.Join(", ", requirement.TenantRoles));
        }

        return Task.CompletedTask;
    }
}
