using System.Security.Claims;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace FireExtinguisherInspection.Tests.Services
{
    public class JwtTokenServiceTests
    {
        private readonly IJwtTokenService _jwtTokenService;
        private readonly IConfiguration _configuration;

        public JwtTokenServiceTests()
        {
            var configData = new Dictionary<string, string>
            {
                { "Jwt:SecretKey", "ThisIsAVerySecretKeyForTestingPurposesOnly123456789" },
                { "Jwt:Issuer", "FireProofTestAPI" },
                { "Jwt:Audience", "FireProofTestApp" },
                { "Jwt:AccessTokenExpiryMinutes", "60" },
                { "Jwt:RefreshTokenExpiryDays", "7" }
            };

            _configuration = new ConfigurationBuilder()
                .AddInMemoryCollection(configData!)
                .Build();

            _jwtTokenService = new JwtTokenService(_configuration);
        }

        [Fact]
        public void GenerateAccessToken_WithValidUser_ReturnsValidToken()
        {
            // Arrange
            var user = new UserDto
            {
                UserId = Guid.NewGuid(),
                Email = "test@example.com",
                FirstName = "Test",
                LastName = "User",
                EmailConfirmed = true,
                MfaEnabled = false,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            var roles = new List<RoleDto>
            {
                new RoleDto { RoleType = "System", RoleName = "SystemAdmin", IsActive = true }
            };

            // Act
            var token = _jwtTokenService.GenerateAccessToken(user, roles);

            // Assert
            token.Should().NotBeNullOrEmpty();
            token.Split('.').Should().HaveCount(3); // JWT has 3 parts
        }

        [Fact]
        public void GenerateAccessToken_IncludesUserClaims()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var user = new UserDto
            {
                UserId = userId,
                Email = "test@example.com",
                FirstName = "Test",
                LastName = "User",
                EmailConfirmed = true,
                MfaEnabled = false,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            var roles = new List<RoleDto>();

            // Act
            var token = _jwtTokenService.GenerateAccessToken(user, roles);
            var principal = _jwtTokenService.ValidateToken(token);

            // Assert
            principal.Should().NotBeNull();
            principal!.FindFirst(ClaimTypes.NameIdentifier)?.Value.Should().Be(userId.ToString());
            principal.FindFirst(ClaimTypes.Email)?.Value.Should().Be("test@example.com");
            principal.FindFirst(ClaimTypes.GivenName)?.Value.Should().Be("Test");
            principal.FindFirst(ClaimTypes.Surname)?.Value.Should().Be("User");
        }

        [Fact]
        public void GenerateAccessToken_IncludesSystemRoles()
        {
            // Arrange
            var user = new UserDto
            {
                UserId = Guid.NewGuid(),
                Email = "admin@example.com",
                FirstName = "Admin",
                LastName = "User",
                EmailConfirmed = true,
                MfaEnabled = false,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            var roles = new List<RoleDto>
            {
                new RoleDto { RoleType = "System", RoleName = "SystemAdmin", IsActive = true }
            };

            // Act
            var token = _jwtTokenService.GenerateAccessToken(user, roles);
            var principal = _jwtTokenService.ValidateToken(token);

            // Assert
            principal.Should().NotBeNull();
            principal!.FindFirst(ClaimTypes.Role)?.Value.Should().Be("SystemAdmin");
            principal.FindFirst("system_role")?.Value.Should().Be("SystemAdmin");
        }

        [Fact]
        public void GenerateAccessToken_IncludesTenantRoles()
        {
            // Arrange
            var tenantId = Guid.NewGuid();
            var user = new UserDto
            {
                UserId = Guid.NewGuid(),
                Email = "inspector@example.com",
                FirstName = "Inspector",
                LastName = "User",
                EmailConfirmed = true,
                MfaEnabled = false,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            var roles = new List<RoleDto>
            {
                new RoleDto
                {
                    RoleType = "Tenant",
                    TenantId = tenantId,
                    RoleName = "Inspector",
                    IsActive = true
                }
            };

            // Act
            var token = _jwtTokenService.GenerateAccessToken(user, roles);
            var principal = _jwtTokenService.ValidateToken(token);

            // Assert
            principal.Should().NotBeNull();
            principal!.FindFirst("tenant_role")?.Value.Should().Be($"{tenantId}:Inspector");
            principal.FindFirst("tenant_id")?.Value.Should().Be(tenantId.ToString());
        }

        [Fact]
        public void GenerateRefreshToken_ReturnsUniqueTokens()
        {
            // Act
            var token1 = _jwtTokenService.GenerateRefreshToken();
            var token2 = _jwtTokenService.GenerateRefreshToken();

            // Assert
            token1.Should().NotBeNullOrEmpty();
            token2.Should().NotBeNullOrEmpty();
            token1.Should().NotBe(token2);
        }

        [Fact]
        public void ValidateToken_WithValidToken_ReturnsClaimsPrincipal()
        {
            // Arrange
            var user = new UserDto
            {
                UserId = Guid.NewGuid(),
                Email = "test@example.com",
                FirstName = "Test",
                LastName = "User",
                EmailConfirmed = true,
                MfaEnabled = false,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            var token = _jwtTokenService.GenerateAccessToken(user, new List<RoleDto>());

            // Act
            var principal = _jwtTokenService.ValidateToken(token);

            // Assert
            principal.Should().NotBeNull();
            principal.Should().BeOfType<ClaimsPrincipal>();
        }

        [Fact]
        public void ValidateToken_WithInvalidToken_ReturnsNull()
        {
            // Arrange
            var invalidToken = "invalid.token.here";

            // Act
            var principal = _jwtTokenService.ValidateToken(invalidToken);

            // Assert
            principal.Should().BeNull();
        }

        [Fact]
        public void GetUserIdFromToken_WithValidToken_ReturnsUserId()
        {
            // Arrange
            var userId = Guid.NewGuid();
            var user = new UserDto
            {
                UserId = userId,
                Email = "test@example.com",
                FirstName = "Test",
                LastName = "User",
                EmailConfirmed = true,
                MfaEnabled = false,
                IsActive = true,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            var token = _jwtTokenService.GenerateAccessToken(user, new List<RoleDto>());

            // Act
            var extractedUserId = _jwtTokenService.GetUserIdFromToken(token);

            // Assert
            extractedUserId.Should().Be(userId);
        }

        [Fact]
        public void GetUserIdFromToken_WithInvalidToken_ReturnsNull()
        {
            // Arrange
            var invalidToken = "invalid.token.here";

            // Act
            var userId = _jwtTokenService.GetUserIdFromToken(invalidToken);

            // Assert
            userId.Should().BeNull();
        }

        [Fact]
        public void GetTokenExpiry_ReturnsCorrectExpiryTime()
        {
            // Arrange
            var beforeExpiry = DateTime.UtcNow;

            // Act
            var expiry = _jwtTokenService.GetTokenExpiry();
            var afterExpiry = DateTime.UtcNow;

            // Assert
            expiry.Should().BeAfter(beforeExpiry.AddMinutes(59));
            expiry.Should().BeBefore(afterExpiry.AddMinutes(61));
        }
    }
}
