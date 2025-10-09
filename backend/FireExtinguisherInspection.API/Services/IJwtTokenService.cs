using System;
using System.Collections.Generic;
using System.Security.Claims;
using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// Service for JWT token generation and validation
    /// </summary>
    public interface IJwtTokenService
    {
        /// <summary>
        /// Generate JWT access token from user data and roles
        /// </summary>
        /// <param name="user">User information</param>
        /// <param name="roles">User roles (system and tenant)</param>
        /// <returns>JWT access token string</returns>
        string GenerateAccessToken(UserDto user, List<RoleDto> roles);

        /// <summary>
        /// Generate refresh token
        /// </summary>
        /// <returns>Secure random refresh token</returns>
        string GenerateRefreshToken();

        /// <summary>
        /// Validate JWT token and extract claims
        /// </summary>
        /// <param name="token">JWT token to validate</param>
        /// <returns>Claims principal if valid, null otherwise</returns>
        ClaimsPrincipal? ValidateToken(string token);

        /// <summary>
        /// Get user ID from token
        /// </summary>
        /// <param name="token">JWT token</param>
        /// <returns>User ID if valid, null otherwise</returns>
        Guid? GetUserIdFromToken(string token);

        /// <summary>
        /// Get token expiry time
        /// </summary>
        /// <returns>Token expiry DateTime</returns>
        DateTime GetTokenExpiry();
    }
}
