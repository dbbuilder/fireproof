using SendGrid;
using SendGrid.Helpers.Mail;
using Microsoft.Extensions.Options;

namespace FireExtinguisherInspection.API.Services.Email;

public class EmailSettings
{
    public string FromEmail { get; set; } = string.Empty;
    public string FromName { get; set; } = string.Empty;
    public string SendGridApiKey { get; set; } = string.Empty;
}

public class PasswordResetSettings
{
    public int TokenExpiryMinutes { get; set; } = 60;
    public string ResetUrl { get; set; } = string.Empty;
}

public class SendGridEmailService : IEmailService
{
    private readonly EmailSettings _emailSettings;
    private readonly PasswordResetSettings _passwordResetSettings;
    private readonly ILogger<SendGridEmailService> _logger;

    public SendGridEmailService(
        IOptions<EmailSettings> emailSettings,
        IOptions<PasswordResetSettings> passwordResetSettings,
        ILogger<SendGridEmailService> logger)
    {
        _emailSettings = emailSettings.Value;
        _passwordResetSettings = passwordResetSettings.Value;
        _logger = logger;
    }

    public async Task SendPasswordResetEmailAsync(string toEmail, string toName, string resetToken, string resetUrl)
    {
        var subject = "Reset Your FireProof Password";
        var resetLink = $"{resetUrl}?token={resetToken}";

        var htmlContent = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""utf-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Password Reset</title>
</head>
<body style=""font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;"">
    <div style=""background-color: #f8f9fa; border-radius: 5px; padding: 30px; margin-bottom: 20px;"">
        <h1 style=""color: #dc3545; margin-top: 0;"">Password Reset Request</h1>
        <p style=""font-size: 16px;"">Hello {toName},</p>
        <p style=""font-size: 16px;"">
            We received a request to reset your password for your FireProof account.
            If you didn't make this request, please ignore this email.
        </p>
        <p style=""font-size: 16px;"">
            To reset your password, click the button below:
        </p>
        <div style=""text-align: center; margin: 30px 0;"">
            <a href=""{resetLink}""
               style=""background-color: #dc3545; color: white; padding: 14px 28px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;"">
                Reset Password
            </a>
        </div>
        <p style=""font-size: 14px; color: #666;"">
            Or copy and paste this link into your browser:<br>
            <a href=""{resetLink}"" style=""color: #dc3545; word-break: break-all;"">{resetLink}</a>
        </p>
        <p style=""font-size: 14px; color: #666; margin-top: 30px;"">
            This link will expire in {_passwordResetSettings.TokenExpiryMinutes} minutes for security reasons.
        </p>
    </div>
    <div style=""text-align: center; font-size: 12px; color: #999;"">
        <p>This is an automated message from FireProof. Please do not reply to this email.</p>
        <p>&copy; 2025 FireProof. All rights reserved.</p>
    </div>
</body>
</html>";

        var plainTextContent = $@"
Password Reset Request

Hello {toName},

We received a request to reset your password for your FireProof account. If you didn't make this request, please ignore this email.

To reset your password, visit this link:
{resetLink}

This link will expire in {_passwordResetSettings.TokenExpiryMinutes} minutes for security reasons.

This is an automated message from FireProof. Please do not reply to this email.

© 2025 FireProof. All rights reserved.
";

        await SendEmailAsync(toEmail, subject, htmlContent, plainTextContent);
    }

    public async Task SendWelcomeEmailAsync(string toEmail, string toName, string tempPassword)
    {
        var subject = "Welcome to FireProof";

        var htmlContent = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""utf-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Welcome to FireProof</title>
</head>
<body style=""font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;"">
    <div style=""background-color: #f8f9fa; border-radius: 5px; padding: 30px; margin-bottom: 20px;"">
        <h1 style=""color: #dc3545; margin-top: 0;"">Welcome to FireProof!</h1>
        <p style=""font-size: 16px;"">Hello {toName},</p>
        <p style=""font-size: 16px;"">
            Your FireProof account has been created successfully. Here are your login credentials:
        </p>
        <div style=""background-color: white; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0;"">
            <p style=""margin: 5px 0;""><strong>Email:</strong> {toEmail}</p>
            <p style=""margin: 5px 0;""><strong>Temporary Password:</strong> {tempPassword}</p>
        </div>
        <p style=""font-size: 16px; color: #dc3545; font-weight: bold;"">
            ⚠️ Please change your password after your first login for security reasons.
        </p>
        <div style=""text-align: center; margin: 30px 0;"">
            <a href=""https://fireproofapp.net/login""
               style=""background-color: #dc3545; color: white; padding: 14px 28px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;"">
                Login Now
            </a>
        </div>
    </div>
    <div style=""text-align: center; font-size: 12px; color: #999;"">
        <p>This is an automated message from FireProof. Please do not reply to this email.</p>
        <p>&copy; 2025 FireProof. All rights reserved.</p>
    </div>
</body>
</html>";

        await SendEmailAsync(toEmail, subject, htmlContent, $"Welcome to FireProof! Your temporary password is: {tempPassword}");
    }

    public async Task SendTestEmailAsync(string toEmail, string subject, string htmlContent)
    {
        await SendEmailAsync(toEmail, subject, htmlContent, "Test email from FireProof");
    }

    private async Task SendEmailAsync(string toEmail, string subject, string htmlContent, string plainTextContent)
    {
        try
        {
            var apiKey = Environment.GetEnvironmentVariable("SENDGRID_API_KEY") ?? _emailSettings.SendGridApiKey;

            if (string.IsNullOrEmpty(apiKey))
            {
                _logger.LogError("SendGrid API key is not configured");
                throw new InvalidOperationException("SendGrid API key is not configured");
            }

            var client = new SendGridClient(apiKey);
            var from = new EmailAddress(_emailSettings.FromEmail, _emailSettings.FromName);
            var to = new EmailAddress(toEmail);
            var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

            var response = await client.SendEmailAsync(msg);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Email sent successfully to {Email}. Subject: {Subject}", toEmail, subject);
            }
            else
            {
                var body = await response.Body.ReadAsStringAsync();
                _logger.LogError("Failed to send email to {Email}. Status: {Status}. Response: {Response}",
                    toEmail, response.StatusCode, body);
                throw new Exception($"Failed to send email. Status: {response.StatusCode}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending email to {Email}", toEmail);
            throw;
        }
    }
}
