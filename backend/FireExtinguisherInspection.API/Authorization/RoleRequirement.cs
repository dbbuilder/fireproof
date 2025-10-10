using Microsoft.AspNetCore.Authorization;

namespace FireExtinguisherInspection.API.Authorization;

/// <summary>
/// Authorization requirement for role-based access control
/// Supports both system-level and tenant-level roles
/// </summary>
public class RoleRequirement : IAuthorizationRequirement
{
    public string[] SystemRoles { get; }
    public string[] TenantRoles { get; }
    public bool RequireSystemRole { get; }
    public bool RequireTenantRole { get; }

    /// <summary>
    /// Constructor for system role requirement
    /// </summary>
    public RoleRequirement(params string[] systemRoles)
    {
        SystemRoles = systemRoles ?? Array.Empty<string>();
        TenantRoles = Array.Empty<string>();
        RequireSystemRole = systemRoles?.Length > 0;
        RequireTenantRole = false;
    }

    /// <summary>
    /// Constructor for tenant role requirement
    /// </summary>
    public RoleRequirement(bool isTenantRole, params string[] tenantRoles)
    {
        SystemRoles = Array.Empty<string>();
        TenantRoles = tenantRoles ?? Array.Empty<string>();
        RequireSystemRole = false;
        RequireTenantRole = isTenantRole && tenantRoles?.Length > 0;
    }

    /// <summary>
    /// Constructor for mixed role requirement (system OR tenant)
    /// </summary>
    public RoleRequirement(string[] systemRoles, string[] tenantRoles)
    {
        SystemRoles = systemRoles ?? Array.Empty<string>();
        TenantRoles = tenantRoles ?? Array.Empty<string>();
        RequireSystemRole = systemRoles?.Length > 0;
        RequireTenantRole = tenantRoles?.Length > 0;
    }
}
