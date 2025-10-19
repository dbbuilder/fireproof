# Password Reset Deployment Guide

This guide explains how to deploy the password reset functionality for the FireProof API.

## Overview

The password reset feature allows users to reset their passwords via email using SendGrid. It includes:

- Password reset request via email
- Secure token-based password reset
- Email templates with professional HTML formatting
- Configurable token expiry (default: 60 minutes)
- Email enumeration prevention for security

## Prerequisites

1. **SendGrid Account**: You need a SendGrid account with an API key
   - Sign up at https://sendgrid.com/
   - Create an API key with "Mail Send" permissions
   - Configure sender authentication (Domain or Single Sender Verification)

2. **Database Access**: Access to the SQL Server database to run migration scripts

3. **Azure Environment** (for production deployment):
   - Azure App Service for hosting the API
   - Azure Key Vault for storing secrets (recommended)

## Deployment Steps

### 1. Database Setup

Run the following SQL scripts in order on your database:

```bash
# 1. Create super admin stored procedure
sqlcmd -S <server> -U <username> -P <password> -C -d <database> \
  -i database/scripts/CREATE_USP_CREATE_SUPER_ADMIN.sql

# 2. Create demo super admin user
sqlcmd -S <server> -U <username> -P <password> -C -d <database> \
  -i database/scripts/CREATE_SUPER_ADMIN_USERS.sql

# 3. Create password reset schema (tables, indexes, stored procedures)
sqlcmd -S <server> -U <username> -P <password> -C -d <database> \
  -i database/scripts/CREATE_PASSWORD_RESET_SCHEMA.sql
```

**What this creates:**
- `dbo.PasswordResetTokens` table for storing reset tokens
- `usp_PasswordResetToken_Create` - Creates and emails a reset token
- `usp_PasswordResetToken_Validate` - Validates a token
- `usp_PasswordResetToken_ResetPassword` - Resets password with token
- `usp_PasswordResetToken_CleanupExpired` - Background cleanup job

### 2. SendGrid Configuration

#### Get your SendGrid API Key:

1. Log in to your SendGrid account
2. Navigate to **Settings** > **API Keys**
3. Click **Create API Key**
4. Name it (e.g., "FireProof-Production")
5. Select **Restricted Access** and grant **Mail Send** permission
6. Copy the API key (you won't be able to see it again)

#### Verify your sender email:

SendGrid requires sender verification. Choose one:

**Option A: Domain Authentication** (Recommended for production)
1. In SendGrid, go to **Settings** > **Sender Authentication**
2. Choose **Domain Authentication**
3. Add DNS records to your domain
4. Use any email on your verified domain (e.g., `info@servicevision.net`)

**Option B: Single Sender Verification** (For testing)
1. In SendGrid, go to **Settings** > **Sender Authentication**
2. Choose **Single Sender Verification**
3. Add the email address you want to send from
4. Verify via the email sent to that address

### 3. Application Configuration

#### Local Development (appsettings.json)

The `appsettings.json` file already has the structure. Update these values:

```json
{
  "Email": {
    "FromEmail": "info@servicevision.net",
    "FromName": "FireProof Support",
    "SendGridApiKey": ""  // Leave empty - use environment variable
  },
  "PasswordReset": {
    "TokenExpiryMinutes": 60,
    "ResetUrl": "https://fireproofapp.net/reset-password"
  }
}
```

**Note**: Never commit the actual API key to source control!

#### Environment Variables

Set the `SENDGRID_API_KEY` environment variable:

**Windows PowerShell:**
```powershell
$env:SENDGRID_API_KEY = "SG.YOUR_ACTUAL_API_KEY_HERE"
```

**Linux/macOS:**
```bash
export SENDGRID_API_KEY="SG.YOUR_ACTUAL_API_KEY_HERE"
```

**Docker:**
```dockerfile
ENV SENDGRID_API_KEY=SG.YOUR_ACTUAL_API_KEY_HERE
```

### 4. Azure Deployment

#### Option A: Using Azure Key Vault (Recommended)

1. **Create Key Vault secret:**
```bash
az keyvault secret set \
  --vault-name <your-vault-name> \
  --name SENDGRID-API-KEY \
  --value "SG.YOUR_ACTUAL_API_KEY_HERE"
```

2. **Configure App Service to use Key Vault:**
```bash
# Enable system-assigned managed identity
az webapp identity assign \
  --name <app-name> \
  --resource-group <resource-group>

# Grant the App Service access to Key Vault
az keyvault set-policy \
  --name <vault-name> \
  --object-id <identity-principal-id> \
  --secret-permissions get list
```

3. **Reference in App Service settings:**
```bash
az webapp config appsettings set \
  --name <app-name> \
  --resource-group <resource-group> \
  --settings SENDGRID_API_KEY="@Microsoft.KeyVault(SecretUri=https://<vault-name>.vault.azure.net/secrets/SENDGRID-API-KEY/)"
```

#### Option B: Direct App Service Settings

```bash
az webapp config appsettings set \
  --name <app-name> \
  --resource-group <resource-group> \
  --settings SENDGRID_API_KEY="SG.YOUR_ACTUAL_API_KEY_HERE"
```

### 5. Update Application Configuration

Update the `ResetUrl` in production:

```bash
az webapp config appsettings set \
  --name <app-name> \
  --resource-group <resource-group> \
  --settings PasswordReset__ResetUrl="https://fireproofapp.net/reset-password"
```

**Note**: Double underscore `__` is used for nested configuration in environment variables.

### 6. Deploy Application

Deploy the updated application to Azure:

```bash
# Build and publish
cd backend/FireExtinguisherInspection.API
dotnet publish -c Release -o ./publish

# Deploy to Azure (example using zip deploy)
cd publish
zip -r ../app.zip .
az webapp deployment source config-zip \
  --name <app-name> \
  --resource-group <resource-group> \
  --src ../app.zip
```

### 7. Verify Deployment

#### Test the API endpoints:

**1. Request password reset:**
```bash
curl -X POST https://api.fireproofapp.net/api/authentication/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@fireproofapp.net"}'
```

Expected response:
```json
{
  "message": "If your email exists in our system, you will receive a password reset link shortly."
}
```

**2. Check email:**
- Check the inbox for `demo@fireproofapp.net`
- Click the reset link or copy the token from the URL

**3. Reset password:**
```bash
curl -X POST https://api.fireproofapp.net/api/authentication/reset-password-with-token \
  -H "Content-Type: application/json" \
  -d '{
    "token": "TOKEN_FROM_EMAIL",
    "newPassword": "NewPassword123!",
    "confirmPassword": "NewPassword123!"
  }'
```

Expected response:
```json
{
  "message": "Password reset successfully. You can now login with your new password."
}
```

**4. Test login with new password:**
```bash
curl -X POST https://api.fireproofapp.net/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@fireproofapp.net",
    "password": "NewPassword123!"
  }'
```

## Configuration Reference

### Email Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `Email:FromEmail` | Email address to send from | `info@servicevision.net` | Yes |
| `Email:FromName` | Display name for sender | `FireProof Support` | Yes |
| `Email:SendGridApiKey` | SendGrid API key (prefer env var) | Empty | No (use env var) |

### Password Reset Settings

| Setting | Description | Default | Required |
|---------|-------------|---------|----------|
| `PasswordReset:TokenExpiryMinutes` | Token validity duration | `60` | No |
| `PasswordReset:ResetUrl` | URL for reset page in frontend | `https://fireproofapp.net/reset-password` | Yes |

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SENDGRID_API_KEY` | SendGrid API key | Yes |

**Priority**: Environment variable > appsettings.json

## Security Considerations

1. **Never commit API keys**: Always use environment variables or Key Vault
2. **Use HTTPS**: All password reset links use HTTPS
3. **Token expiry**: Default 60 minutes (configurable)
4. **Single-use tokens**: Tokens are marked as used after reset
5. **Email enumeration prevention**: API always returns success regardless of email existence
6. **BCrypt hashing**: Passwords are hashed with WorkFactor 12
7. **RAISERROR compatibility**: SQL Server error handling uses RAISERROR for compatibility

## Troubleshooting

### Email not sending

**Check 1: Verify API key**
```bash
# Test API key directly
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "personalizations": [{"to": [{"email": "test@example.com"}]}],
    "from": {"email": "info@servicevision.net"},
    "subject": "Test",
    "content": [{"type": "text/plain", "value": "Test"}]
  }'
```

**Check 2: Verify sender authentication**
- Ensure sender email is verified in SendGrid
- Check SendGrid Activity Feed for errors

**Check 3: Check application logs**
```bash
az webapp log tail --name <app-name> --resource-group <resource-group>
```

### Token validation fails

**Possible causes:**
- Token expired (check `TokenExpiryMinutes` setting)
- Token already used (check `IsUsed` flag in database)
- Token not found (user may have requested multiple resets)

**Debug query:**
```sql
SELECT TOP 10 *
FROM dbo.PasswordResetTokens
WHERE Email = 'demo@fireproofapp.net'
ORDER BY CreatedDate DESC
```

### Password reset fails

**Check:**
1. Token is valid (not expired, not used)
2. Password meets requirements (min 8 characters)
3. Database connection is working
4. SQL Server error logs for stored procedure errors

## Demo User Credentials

The deployment creates a demo super admin user:

| Field | Value |
|-------|-------|
| Email | demo@fireproofapp.net |
| Password | FireProofIt! |
| Roles | SystemAdmin, TenantAdmin (Demo Company Inc) |

## Support

For issues or questions:
1. Check application logs
2. Check SendGrid Activity Feed
3. Review SQL Server error logs
4. Contact support at support@fireproofapp.net
