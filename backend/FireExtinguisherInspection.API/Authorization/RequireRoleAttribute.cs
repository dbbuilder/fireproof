using Microsoft.AspNetCore.Authorization;

namespace FireExtinguisherInspection.API.Authorization;

/// <summary>
/// Attribute to require system-level roles for endpoint access
/// Usage: [RequireRole(RoleNames.SystemAdmin)]
/// </summary>
public class RequireRoleAttribute : AuthorizeAttribute
{
    public RequireRoleAttribute(params string[] roles)
    {
        // Set the policy name based on the first role
        // The actual authorization logic is handled by RoleAuthorizationHandler
        Policy = roles.Length > 0 ? roles[0] : string.Empty;
    }
}

/// <summary>
/// Attribute to require tenant-level roles for endpoint access
/// Usage: [RequireTenantRole(RoleNames.TenantAdmin, RoleNames.TenantManager)]
/// </summary>
public class RequireTenantRoleAttribute : AuthorizeAttribute
{
    public RequireTenantRoleAttribute(params string[] roles)
    {
        // Set the policy name based on the first role
        // The actual authorization logic is handled by RoleAuthorizationHandler
        Policy = roles.Length > 0 ? roles[0] : string.Empty;
    }
}
