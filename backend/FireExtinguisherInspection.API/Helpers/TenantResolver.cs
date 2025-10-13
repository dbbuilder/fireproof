using System.Security.Claims;
using FireExtinguisherInspection.API.Models;

namespace FireExtinguisherInspection.API.Helpers;

/// <summary>
/// Helper class for resolving tenant context with SystemAdmin support
/// </summary>
public static class TenantResolver
{
    /// <summary>
    /// Resolves the effective tenant ID for the current request
    /// SystemAdmin users can override tenant context via tenantId parameter
    /// </summary>
    /// <param name="user">Current ClaimsPrincipal</param>
    /// <param name="tenantContext">Current TenantContext</param>
    /// <param name="tenantIdOverride">Optional tenant ID override (SystemAdmin only)</param>
    /// <param name="effectiveTenantId">The resolved tenant ID</param>
    /// <param name="errorMessage">Error message if resolution fails</param>
    /// <returns>True if tenant ID was resolved successfully</returns>
    public static bool TryResolveTenantId(
        ClaimsPrincipal user,
        TenantContext tenantContext,
        Guid? tenantIdOverride,
        out Guid effectiveTenantId,
        out string? errorMessage)
    {
        effectiveTenantId = Guid.Empty;
        errorMessage = null;

        // Check if user is SystemAdmin
        var isSystemAdmin = user.FindAll("system_role")
            .Any(c => c.Value.Equals("SystemAdmin", StringComparison.OrdinalIgnoreCase));

        if (isSystemAdmin && tenantIdOverride.HasValue)
        {
            // SystemAdmin can operate in any tenant's context
            effectiveTenantId = tenantIdOverride.Value;
            return true;
        }
        else if (isSystemAdmin && !tenantIdOverride.HasValue)
        {
            // SystemAdmin without tenant parameter - this is valid but returns empty results
            // Caller should handle this case by returning empty array
            return false;
        }
        else if (tenantContext.TenantId != Guid.Empty)
        {
            // Normal user - use their tenant context
            effectiveTenantId = tenantContext.TenantId;
            return true;
        }
        else
        {
            // No tenant context and not SystemAdmin
            errorMessage = "Tenant context not found";
            return false;
        }
    }

    /// <summary>
    /// Checks if the current user is a SystemAdmin
    /// </summary>
    public static bool IsSystemAdmin(ClaimsPrincipal user)
    {
        return user.FindAll("system_role")
            .Any(c => c.Value.Equals("SystemAdmin", StringComparison.OrdinalIgnoreCase));
    }
}
