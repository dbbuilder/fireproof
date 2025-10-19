namespace FireExtinguisherInspection.API.Services.Email;

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(string toEmail, string toName, string resetToken, string resetUrl);
    Task SendWelcomeEmailAsync(string toEmail, string toName, string tempPassword);
    Task SendTestEmailAsync(string toEmail, string subject, string htmlContent);
}
