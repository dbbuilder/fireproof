using System.Security.Cryptography;
using FireExtinguisherInspection.API.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace FireExtinguisherInspection.API.Services.Email;

public class PasswordResetService : IPasswordResetService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly IEmailService _emailService;
    private readonly PasswordResetSettings _settings;
    private readonly ILogger<PasswordResetService> _logger;

    public PasswordResetService(
        IDbConnectionFactory connectionFactory,
        IEmailService emailService,
        IOptions<PasswordResetSettings> settings,
        ILogger<PasswordResetService> logger)
    {
        _connectionFactory = connectionFactory;
        _emailService = emailService;
        _settings = settings.Value;
        _logger = logger;
    }

    public Task<string> GenerateResetTokenAsync()
    {
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64))
            .Replace("+", "-")
            .Replace("/", "_")
            .Replace("=", "");
        return Task.FromResult(token);
    }

    public async Task<bool> SendPasswordResetEmailAsync(string email)
    {
        try
        {
            var token = await GenerateResetTokenAsync();
            var expiresAt = DateTime.UtcNow.AddMinutes(_settings.TokenExpiryMinutes);

            using var connection = (SqlConnection)await _connectionFactory.CreateConnectionAsync();

            using var command = new SqlCommand("dbo.usp_PasswordResetToken_Create", connection);
            command.CommandType = System.Data.CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@Email", email);
            command.Parameters.AddWithValue("@Token", token);
            command.Parameters.AddWithValue("@ExpiresAt", expiresAt);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                var userExists = reader.GetInt32(reader.GetOrdinal("UserExists"));
                if (userExists == 1)
                {
                    var toName = $"{reader.GetString(reader.GetOrdinal("FirstName"))} {reader.GetString(reader.GetOrdinal("LastName"))}";
                    await _emailService.SendPasswordResetEmailAsync(email, toName, token, _settings.ResetUrl);
                    _logger.LogInformation("Password reset email sent to {Email}", email);
                }
                else
                {
                    _logger.LogInformation("Password reset requested for non-existent email: {Email}", email);
                }
            }

            // Always return true to prevent email enumeration
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending password reset email to {Email}", email);
            throw;
        }
    }

    public async Task<bool> ResetPasswordAsync(string token, string newPassword)
    {
        try
        {
            // Generate BCrypt hash
            var salt = BCrypt.Net.BCrypt.GenerateSalt(12);
            var hash = BCrypt.Net.BCrypt.HashPassword(newPassword, salt);

            using var connection = (SqlConnection)await _connectionFactory.CreateConnectionAsync();

            using var command = new SqlCommand("dbo.usp_PasswordResetToken_ResetPassword", connection);
            command.CommandType = System.Data.CommandType.StoredProcedure;
            command.Parameters.AddWithValue("@Token", token);
            command.Parameters.AddWithValue("@NewPasswordHash", hash);
            command.Parameters.AddWithValue("@NewPasswordSalt", salt);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                var email = reader.GetString(reader.GetOrdinal("Email"));
                _logger.LogInformation("Password reset successful for {Email}", email);
                return true;
            }

            return false;
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "SQL error during password reset with token {Token}", token);
            throw new InvalidOperationException(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resetting password with token {Token}", token);
            throw;
        }
    }

    public async Task ValidateTokenAsync(string token)
    {
        using var connection = (SqlConnection)await _connectionFactory.CreateConnectionAsync();

        using var command = new SqlCommand("dbo.usp_PasswordResetToken_Validate", connection);
        command.CommandType = System.Data.CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@Token", token);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var tokenStatus = reader.GetString(reader.GetOrdinal("TokenStatus"));
            if (tokenStatus != "Valid")
            {
                throw new InvalidOperationException($"Token is {tokenStatus}");
            }
        }
        else
        {
            throw new InvalidOperationException("Token not found");
        }
    }
}
