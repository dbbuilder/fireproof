using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.IdentityModel.Tokens;

namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// JWT token generation and validation service
    /// </summary>
    public class JwtTokenService : IJwtTokenService
    {
        private readonly IConfiguration _configuration;
        private readonly string _secretKey;
        private readonly string _issuer;
        private readonly string _audience;
        private readonly int _accessTokenExpiryMinutes;
        private readonly int _refreshTokenExpiryDays;

        public JwtTokenService(IConfiguration configuration)
        {
            _configuration = configuration;
            _secretKey = configuration["Jwt:SecretKey"]
                ?? throw new InvalidOperationException("JWT SecretKey not configured");
            _issuer = configuration["Jwt:Issuer"] ?? "FireProofAPI";
            _audience = configuration["Jwt:Audience"] ?? "FireProofApp";
            _accessTokenExpiryMinutes = int.Parse(configuration["Jwt:AccessTokenExpiryMinutes"] ?? "60");
            _refreshTokenExpiryDays = int.Parse(configuration["Jwt:RefreshTokenExpiryDays"] ?? "7");
        }

        /// <summary>
        /// Generate JWT access token with user claims and roles
        /// </summary>
        public string GenerateAccessToken(UserDto user, List<RoleDto> roles)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.GivenName, user.FirstName),
                new Claim(ClaimTypes.Surname, user.LastName),
                new Claim("email_confirmed", user.EmailConfirmed.ToString()),
                new Claim("mfa_enabled", user.MfaEnabled.ToString())
            };

            // Add system roles
            var systemRoles = roles.Where(r => r.RoleType == "System").ToList();
            foreach (var role in systemRoles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role.RoleName));
                claims.Add(new Claim("system_role", role.RoleName));
            }

            // Add tenant roles
            var tenantRoles = roles.Where(r => r.RoleType == "Tenant").ToList();
            foreach (var role in tenantRoles)
            {
                if (role.TenantId.HasValue)
                {
                    claims.Add(new Claim("tenant_role", $"{role.TenantId}:{role.RoleName}"));
                    claims.Add(new Claim("tenant_id", role.TenantId.ToString()!));
                }
            }

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _issuer,
                audience: _audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_accessTokenExpiryMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        /// <summary>
        /// Generate secure random refresh token
        /// </summary>
        public string GenerateRefreshToken()
        {
            var randomBytes = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomBytes);
            return Convert.ToBase64String(randomBytes);
        }

        /// <summary>
        /// Validate JWT token and extract claims principal
        /// </summary>
        public ClaimsPrincipal? ValidateToken(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes(_secretKey);

                var validationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = _issuer,
                    ValidateAudience = true,
                    ValidAudience = _audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero // No tolerance for expiry
                };

                var principal = tokenHandler.ValidateToken(token, validationParameters, out var validatedToken);
                return principal;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Extract user ID from JWT token
        /// </summary>
        public Guid? GetUserIdFromToken(string token)
        {
            var principal = ValidateToken(token);
            if (principal == null)
                return null;

            var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (Guid.TryParse(userIdClaim, out var userId))
                return userId;

            return null;
        }

        /// <summary>
        /// Get token expiry time
        /// </summary>
        public DateTime GetTokenExpiry()
        {
            return DateTime.UtcNow.AddMinutes(_accessTokenExpiryMinutes);
        }

        /// <summary>
        /// Get refresh token expiry time
        /// </summary>
        public DateTime GetRefreshTokenExpiry()
        {
            return DateTime.UtcNow.AddDays(_refreshTokenExpiryDays);
        }
    }
}
