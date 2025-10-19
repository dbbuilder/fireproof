namespace FireExtinguisherInspection.API.Services.Email;

public interface IPasswordResetService
{
    Task<string> GenerateResetTokenAsync();
    Task<bool> SendPasswordResetEmailAsync(string email);
    Task<bool> ResetPasswordAsync(string token, string newPassword);
    Task ValidateTokenAsync(string token);
}
