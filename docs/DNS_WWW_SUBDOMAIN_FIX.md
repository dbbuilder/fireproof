# Fix www.fireproofapp.net DNS Issue

## Problem
The apex domain `fireproofapp.net` works correctly, but `www.fireproofapp.net` returns an SSL certificate error:
```
curl: (60) SSL: no alternative certificate subject name matches target host name 'www.fireproofapp.net'
```

## Root Cause
While the DNS CNAME record for `www.fireproofapp.net` is correctly configured to point to `nice-smoke-08dbc500f.2.azurestaticapps.net`, Azure Static Web Apps has not provisioned an SSL certificate for the www subdomain because it hasn't been added as a custom domain.

## Current DNS Configuration (Correct)
```json
{
    "host": "www",
    "fqdn": "www.fireproofapp.net.",
    "type": "CNAME",
    "answer": "nice-smoke-08dbc500f.2.azurestaticapps.net",
    "ttl": 300
}
```

## Solution
Add `www.fireproofapp.net` as a custom domain in Azure Static Web Apps:

### Steps:
1. **Navigate to Azure Portal**
   - Go to https://portal.azure.com
   - Search for "Static Web Apps"
   - Select the app with hostname `nice-smoke-08dbc500f.2.azurestaticapps.net`

2. **Add Custom Domain**
   - In the left sidebar, click "Custom domains"
   - Click "+ Add" button
   - Enter domain name: `www.fireproofapp.net`
   - Domain provider: "Other DNS provider"
   - Click "Next"

3. **Validate Domain**
   - Azure will validate the existing CNAME record
   - The CNAME already points to `nice-smoke-08dbc500f.2.azurestaticapps.net` ✅
   - Click "Add"

4. **SSL Certificate Provisioning**
   - Azure will automatically provision a free SSL certificate
   - This process takes 5-10 minutes
   - Certificate will auto-renew

## Verification
After the custom domain is added and the certificate is provisioned:

```bash
# Should return 200 OK with valid SSL
curl -I https://www.fireproofapp.net/

# Both should work identically
curl -I https://fireproofapp.net/
curl -I https://www.fireproofapp.net/
```

## Alternative: Use Azure CLI (if resource group is known)
```bash
# List custom domains
az staticwebapp hostname list \
  --name <app-name> \
  --resource-group <resource-group>

# Add custom domain
az staticwebapp hostname set \
  --name <app-name> \
  --resource-group <resource-group> \
  --hostname www.fireproofapp.net
```

## Status
- ❌ DNS CNAME configured (already done)
- ⏳ **ACTION REQUIRED**: Add custom domain in Azure Portal
- ⏳ Awaiting SSL certificate provisioning

## Created
October 31, 2025
