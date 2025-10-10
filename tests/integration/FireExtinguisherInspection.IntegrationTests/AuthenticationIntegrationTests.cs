using System.Data;
using Dapper;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace FireExtinguisherInspection.IntegrationTests
{
    /// <summary>
    /// Integration tests for authentication flow against real database
    /// </summary>
    public class AuthenticationIntegrationTests : IAsyncLifetime
    {
        private readonly string _connectionString;
        private readonly IDbConnectionFactory _connectionFactory;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IJwtTokenService _jwtTokenService;
        private readonly IAuthenticationService _authService;
        private readonly Mock<ILogger<AuthenticationService>> _mockLogger;

        public AuthenticationIntegrationTests()
        {
            var configuration = new ConfigurationBuilder()
                .AddJsonFile("appsettings.test.json", optional: false)
                .Build();

            _connectionString = configuration.GetConnectionString("DefaultConnection")!;

            var memoryCache = new MemoryCache(new MemoryCacheOptions());
            var mockDbLogger = new Mock<ILogger<DbConnectionFactory>>();

            _connectionFactory = new DbConnectionFactory(configuration, memoryCache, mockDbLogger.Object);
            _passwordHasher = new PasswordHasher();
            _jwtTokenService = new JwtTokenService(configuration);
            _mockLogger = new Mock<ILogger<AuthenticationService>>();

            _authService = new AuthenticationService(
                _connectionFactory,
                _passwordHasher,
                _jwtTokenService,
                _mockLogger.Object
            );
        }

        public async Task InitializeAsync()
        {
            // Cleanup any test users that might exist
            await CleanupTestDataAsync();
        }

        public async Task DisposeAsync()
        {
            // Cleanup after tests
            await CleanupTestDataAsync();
        }

        private async Task CleanupTestDataAsync()
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            // Delete test users
            await connection.ExecuteAsync(@"
                DELETE FROM dbo.Users
                WHERE Email LIKE '%integrationtest.com'
            ");
        }

        [Fact]
        public async Task RegisterUser_WithValidData_CreatesUserSuccessfully()
        {
            // Arrange
            var request = new RegisterRequest
            {
                Email = "newuser@integrationtest.com",
                Password = "SecurePassword123!",
                FirstName = "Integration",
                LastName = "Test",
                PhoneNumber = "555-1234"
            };

            // Act
            var response = await _authService.RegisterAsync(request);

            // Assert
            response.Should().NotBeNull();
            response.AccessToken.Should().NotBeNullOrEmpty();
            response.RefreshToken.Should().NotBeNullOrEmpty();
            response.User.Email.Should().Be(request.Email);
            response.User.FirstName.Should().Be(request.FirstName);
            response.User.LastName.Should().Be(request.LastName);
            response.User.PhoneNumber.Should().Be(request.PhoneNumber);
            response.User.EmailConfirmed.Should().BeFalse();
            response.User.UserId.Should().NotBeEmpty();

            // Verify user exists in database
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            var dbUser = await connection.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT UserId, Email, FirstName, LastName FROM dbo.Users WHERE Email = @Email",
                new { Email = request.Email }
            );

            Assert.NotNull(dbUser);
        }

        [Fact]
        public async Task RegisterUser_WithDuplicateEmail_ThrowsException()
        {
            // Arrange
            var request1 = new RegisterRequest
            {
                Email = "duplicate@integrationtest.com",
                Password = "Password123!",
                FirstName = "First",
                LastName = "User"
            };

            var request2 = new RegisterRequest
            {
                Email = "duplicate@integrationtest.com",
                Password = "Password123!",
                FirstName = "Second",
                LastName = "User"
            };

            // Act
            await _authService.RegisterAsync(request1);
            Func<Task> act = async () => await _authService.RegisterAsync(request2);

            // Assert
            await act.Should().ThrowAsync<Exception>()
                .WithMessage("*already exists*");
        }

        [Fact]
        public async Task Login_WithValidCredentials_ReturnsTokens()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Email = "logintest@integrationtest.com",
                Password = "TestPassword123!",
                FirstName = "Login",
                LastName = "Test"
            };

            await _authService.RegisterAsync(registerRequest);

            var loginRequest = new LoginRequest
            {
                Email = "logintest@integrationtest.com",
                Password = "TestPassword123!"
            };

            // Act
            var response = await _authService.LoginAsync(loginRequest);

            // Assert
            response.Should().NotBeNull();
            response.AccessToken.Should().NotBeNullOrEmpty();
            response.RefreshToken.Should().NotBeNullOrEmpty();
            response.User.Email.Should().Be(loginRequest.Email);

            // Verify LastLoginDate was updated
            using var connection = new SqlConnection(_connectionString);
            var dbUser = await connection.QueryFirstOrDefaultAsync<dynamic>(
                "SELECT LastLoginDate FROM dbo.Users WHERE Email = @Email",
                new { Email = loginRequest.Email }
            );

            ((DateTime?)dbUser.LastLoginDate).Should().NotBeNull();
        }

        [Fact]
        public async Task Login_WithInvalidPassword_ThrowsUnauthorizedException()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Email = "invalidpass@integrationtest.com",
                Password = "CorrectPassword123!",
                FirstName = "Test",
                LastName = "User"
            };

            await _authService.RegisterAsync(registerRequest);

            var loginRequest = new LoginRequest
            {
                Email = "invalidpass@integrationtest.com",
                Password = "WrongPassword123!"
            };

            // Act
            Func<Task> act = async () => await _authService.LoginAsync(loginRequest);

            // Assert
            await act.Should().ThrowAsync<UnauthorizedAccessException>()
                .WithMessage("*Invalid email or password*");
        }

        [Fact]
        public async Task Login_WithNonexistentUser_ThrowsUnauthorizedException()
        {
            // Arrange
            var loginRequest = new LoginRequest
            {
                Email = "nonexistent@integrationtest.com",
                Password = "Password123!"
            };

            // Act
            Func<Task> act = async () => await _authService.LoginAsync(loginRequest);

            // Assert
            await act.Should().ThrowAsync<UnauthorizedAccessException>()
                .WithMessage("*Invalid email or password*");
        }

        [Fact]
        public async Task RefreshToken_WithValidRefreshToken_ReturnsNewTokens()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Email = "refreshtest@integrationtest.com",
                Password = "Password123!",
                FirstName = "Refresh",
                LastName = "Test"
            };

            var registerResponse = await _authService.RegisterAsync(registerRequest);
            var refreshRequest = new RefreshTokenRequest
            {
                RefreshToken = registerResponse.RefreshToken
            };

            // Act
            var response = await _authService.RefreshTokenAsync(refreshRequest);

            // Assert
            response.Should().NotBeNull();
            response.AccessToken.Should().NotBeNullOrEmpty();
            response.RefreshToken.Should().NotBeNullOrEmpty();
            response.AccessToken.Should().NotBe(registerResponse.AccessToken);
            response.RefreshToken.Should().NotBe(registerResponse.RefreshToken);
        }

        [Fact]
        public async Task RefreshToken_WithInvalidRefreshToken_ThrowsUnauthorizedException()
        {
            // Arrange
            var refreshRequest = new RefreshTokenRequest
            {
                RefreshToken = "invalid.refresh.token.here"
            };

            // Act
            Func<Task> act = async () => await _authService.RefreshTokenAsync(refreshRequest);

            // Assert
            await act.Should().ThrowAsync<UnauthorizedAccessException>()
                .WithMessage("*Invalid or expired refresh token*");
        }

        [Fact]
        public async Task ResetPassword_WithValidCurrentPassword_UpdatesPassword()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Email = "resetpass@integrationtest.com",
                Password = "OldPassword123!",
                FirstName = "Reset",
                LastName = "Test"
            };

            var registerResponse = await _authService.RegisterAsync(registerRequest);

            var resetRequest = new ResetPasswordRequest
            {
                UserId = registerResponse.User.UserId,
                CurrentPassword = "OldPassword123!",
                NewPassword = "NewPassword123!"
            };

            // Act
            var result = await _authService.ResetPasswordAsync(resetRequest);

            // Assert
            result.Should().BeTrue();

            // Verify can login with new password
            var loginRequest = new LoginRequest
            {
                Email = "resetpass@integrationtest.com",
                Password = "NewPassword123!"
            };

            var loginResponse = await _authService.LoginAsync(loginRequest);
            loginResponse.Should().NotBeNull();
        }

        [Fact]
        public async Task ResetPassword_WithIncorrectCurrentPassword_ThrowsUnauthorizedException()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Email = "wrongcurrent@integrationtest.com",
                Password = "CorrectPassword123!",
                FirstName = "Test",
                LastName = "User"
            };

            var registerResponse = await _authService.RegisterAsync(registerRequest);

            var resetRequest = new ResetPasswordRequest
            {
                UserId = registerResponse.User.UserId,
                CurrentPassword = "WrongPassword123!",
                NewPassword = "NewPassword123!"
            };

            // Act
            Func<Task> act = async () => await _authService.ResetPasswordAsync(resetRequest);

            // Assert
            await act.Should().ThrowAsync<UnauthorizedAccessException>()
                .WithMessage("*Current password is incorrect*");
        }

        [Fact]
        public async Task DevLogin_WithExistingDevUser_ReturnsTokens()
        {
            // Arrange
            var devLoginRequest = new DevLoginRequest
            {
                Email = "dev@fireproof.local"
            };

            // Act
            var response = await _authService.DevLoginAsync(devLoginRequest);

            // Assert
            response.Should().NotBeNull();
            response.AccessToken.Should().NotBeNullOrEmpty();
            response.RefreshToken.Should().NotBeNullOrEmpty();
            response.User.Email.Should().Be("dev@fireproof.local");
            response.Roles.Should().NotBeEmpty();
        }

        [Fact]
        public async Task GetUserRoles_ForDevUser_ReturnsExpectedRoles()
        {
            // Arrange
            var devLoginResponse = await _authService.DevLoginAsync(new DevLoginRequest
            {
                Email = "dev@fireproof.local"
            });

            // Act
            var roles = await _authService.GetUserRolesAsync(devLoginResponse.User.UserId);

            // Assert
            roles.Should().NotBeEmpty();
            roles.Should().Contain(r => r.RoleType == "Tenant" && r.RoleName == "TenantAdmin");
        }

        [Fact]
        public async Task PasswordHashing_IsBCryptCompliant()
        {
            // Arrange
            var password = "TestPassword123!";

            // Act
            var hash = _passwordHasher.HashPassword(password, out var salt);

            // Assert
            hash.Should().StartWith("$2"); // BCrypt hashes start with $2a, $2b, or $2y
            _passwordHasher.VerifyPassword(password, hash, salt).Should().BeTrue();
        }

        [Fact]
        public async Task JwtToken_ContainsExpectedClaims()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Email = "claims@integrationtest.com",
                Password = "Password123!",
                FirstName = "Claims",
                LastName = "Test"
            };

            var response = await _authService.RegisterAsync(registerRequest);

            // Act
            var principal = _jwtTokenService.ValidateToken(response.AccessToken);

            // Assert
            principal.Should().NotBeNull();
            principal!.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                .Should().Be(response.User.UserId.ToString());
            principal.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value
                .Should().Be("claims@integrationtest.com");
            principal.FindFirst(System.Security.Claims.ClaimTypes.GivenName)?.Value
                .Should().Be("Claims");
            principal.FindFirst(System.Security.Claims.ClaimTypes.Surname)?.Value
                .Should().Be("Test");
        }
    }
}
