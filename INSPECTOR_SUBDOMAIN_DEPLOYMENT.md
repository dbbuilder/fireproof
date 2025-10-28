# Inspector Subdomain Deployment Guide

**Subdomain:** https://inspect.fireproofapp.net
**Purpose:** Inspector-only mobile app for fire extinguisher inspections
**Last Updated:** October 23, 2025

---

## Overview

The FireProof Inspector app is deployed as a separate subdomain (`inspect.fireproofapp.net`) for:
- **Focused UX**: Inspector-only features, no admin clutter
- **Mobile-first**: Optimized for field inspectors on mobile devices
- **PWA Installation**: Installable as standalone app
- **Smaller bundle**: Faster load times (no admin code)
- **Independent scaling**: Can deploy and scale separately

---

## Prerequisites

- Azure subscription with Static Web Apps or App Service
- Domain ownership of `fireproofapp.net`
- Access to DNS provider (e.g., Azure DNS, Cloudflare, Name.com)
- Node.js 18+ and npm installed

---

## Option 1: Azure Static Web Apps (Recommended)

### Step 1: Create Azure Static Web App

```bash
# Using Azure CLI
az login

# Create resource group (if not exists)
az group create \
  --name rg-fireproof-inspector \
  --location eastus

# Create Static Web App
az staticwebapp create \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --source https://github.com/dbbuilder/fireproof \
  --branch main \
  --app-location "/frontend/fire-extinguisher-web" \
  --output-location "dist-inspector" \
  --build-command "npm run build:inspector" \
  --location eastus
```

### Step 2: Configure Custom Domain

```bash
# Add custom domain
az staticwebapp hostname set \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --hostname inspect.fireproofapp.net
```

Azure will provide validation records (CNAME or TXT). Add these to your DNS provider.

### Step 3: Configure DNS

**DNS Provider Configuration:**

```dns
# CNAME record
inspect.fireproofapp.net  →  CNAME  →  <your-static-web-app>.azurestaticapps.net

# Example:
inspect.fireproofapp.net  →  CNAME  →  nice-smoke-08dbc500f.2.azurestaticapps.net
```

**Using Azure DNS:**

```bash
# Create DNS record
az network dns record-set cname set-record \
  --resource-group rg-fireproof-dns \
  --zone-name fireproofapp.net \
  --record-set-name inspect \
  --cname <your-static-web-app>.azurestaticapps.net
```

**Using Name.com (via API):**

```bash
# Add CNAME record
curl -u "USERNAME:API_TOKEN" \
  -X POST https://api.name.com/v4/domains/fireproofapp.net/records \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CNAME",
    "host": "inspect",
    "answer": "<your-static-web-app>.azurestaticapps.net",
    "ttl": 300
  }'
```

### Step 4: Verify SSL Certificate

Azure Static Web Apps automatically provisions SSL certificates for custom domains. Verify:

```bash
# Check SSL certificate
curl -I https://inspect.fireproofapp.net

# Should return:
# HTTP/2 200
# SSL: Valid (Let's Encrypt or Azure managed certificate)
```

---

## Option 2: Azure App Service

### Step 1: Create App Service

```bash
# Create App Service Plan
az appservice plan create \
  --name asp-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name app-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --plan asp-fireproof-inspector \
  --runtime "NODE:18-lts"
```

### Step 2: Configure Custom Domain

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name app-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --hostname inspect.fireproofapp.net
```

### Step 3: Enable HTTPS

```bash
# Bind SSL certificate (Azure managed certificate)
az webapp config ssl bind \
  --name app-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --certificate-thumbprint auto \
  --ssl-type SNI
```

---

## Build Configuration

### package.json Scripts

Add inspector-specific build script:

```json
{
  "scripts": {
    "dev": "vite --port 5600",
    "dev:inspector": "vite --config vite.config.inspector.js --port 5600",
    "build": "vite build",
    "build:inspector": "vite build --config vite.config.inspector.js",
    "preview": "vite preview",
    "preview:inspector": "vite preview --outDir dist-inspector"
  }
}
```

### GitHub Actions Workflow

Create `.github/workflows/deploy-inspector.yml`:

```yaml
name: Deploy Inspector App

on:
  push:
    branches:
      - main
    paths:
      - 'frontend/fire-extinguisher-web/**'
      - '.github/workflows/deploy-inspector.yml'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    name: Build and Deploy Inspector App
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/fire-extinguisher-web/package-lock.json

      - name: Install dependencies
        run: |
          cd frontend/fire-extinguisher-web
          npm ci

      - name: Build inspector app
        run: |
          cd frontend/fire-extinguisher-web
          npm run build:inspector
        env:
          VITE_API_BASE_URL: ${{ secrets.VITE_API_BASE_URL }}
          VITE_APP_MODE: inspector

      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_INSPECTOR }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "frontend/fire-extinguisher-web"
          output_location: "dist-inspector"
          skip_app_build: true # Already built
```

---

## Environment Variables

### Development (.env.development)

```bash
VITE_API_BASE_URL=http://localhost:7001
VITE_APP_MODE=inspector
VITE_APP_NAME=FireProof Inspector
```

### Production (.env.production)

```bash
VITE_API_BASE_URL=https://api.fireproofapp.net
VITE_APP_MODE=inspector
VITE_APP_NAME=FireProof Inspector
```

### Azure App Settings

Configure in Azure Portal or via CLI:

```bash
# Set app settings
az staticwebapp appsettings set \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --setting-names \
    VITE_API_BASE_URL=https://api.fireproofapp.net \
    VITE_APP_MODE=inspector
```

---

## Testing After Deployment

### 1. DNS Propagation

```bash
# Check DNS resolution
nslookup inspect.fireproofapp.net

# Should return:
# Name: inspect.fireproofapp.net
# Address: <Azure Static Web App IP>
```

### 2. HTTPS Certificate

```bash
# Verify SSL
openssl s_client -connect inspect.fireproofapp.net:443 -servername inspect.fireproofapp.net

# Should show valid certificate
```

### 3. PWA Installation

**iOS (Safari):**
1. Navigate to https://inspect.fireproofapp.net
2. Tap Share button
3. Tap "Add to Home Screen"
4. Verify app icon appears on home screen

**Android (Chrome):**
1. Navigate to https://inspect.fireproofapp.net
2. Tap menu (3 dots)
3. Tap "Install app" or "Add to Home Screen"
4. Verify app installs

### 4. Offline Mode

1. Open inspector app
2. Enable Airplane Mode
3. Navigate to /inspector/dashboard
4. Verify app loads from cache
5. Test barcode scanner (should show offline indicator)

### 5. API Connectivity

```bash
# Test API endpoint
curl https://inspect.fireproofapp.net/api/authentication/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"inspector@test.com","password":"password"}'

# Should proxy to backend API
```

---

## Monitoring & Troubleshooting

### Azure Application Insights

```bash
# Enable Application Insights
az monitor app-insights component create \
  --app fireproof-inspector \
  --location eastus \
  --resource-group rg-fireproof-inspector \
  --application-type web

# Link to Static Web App
az staticwebapp appsettings set \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --setting-names \
    APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>
```

### Common Issues

**Issue: DNS not resolving**
```bash
# Solution: Wait for DNS propagation (can take 24-48 hours)
# Check propagation status
dig inspect.fireproofapp.net +trace
```

**Issue: SSL certificate error**
```bash
# Solution: Azure provisions certificate automatically after DNS validation
# Check certificate status
az staticwebapp hostname show \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --hostname inspect.fireproofapp.net
```

**Issue: 404 errors on refresh**
```bash
# Solution: Ensure staticwebapp.inspector.config.json is in place
# Verify navigationFallback is configured
```

**Issue: API calls failing (CORS)**
```bash
# Solution: Update backend CORS configuration to include inspect.fireproofapp.net

# Backend: Program.cs
options.AddPolicy("AllowFrontend", policy =>
{
    policy.WithOrigins(
        "https://fireproofapp.net",
        "https://inspect.fireproofapp.net",  // Add this
        "http://localhost:5600"
    )
});
```

---

## Rollback Procedure

### Revert to Previous Deployment

**Azure Static Web Apps:**

```bash
# List deployments
az staticwebapp environment list \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector

# Promote previous environment to production
az staticwebapp environment activate \
  --name swa-fireproof-inspector \
  --resource-group rg-fireproof-inspector \
  --environment-name <environment-name>
```

**GitHub Actions:**

1. Go to Actions tab in GitHub
2. Find previous successful deployment
3. Click "Re-run jobs"

---

## Security Checklist

- [ ] HTTPS enabled (SSL certificate valid)
- [ ] Security headers configured (X-Frame-Options, CSP, etc.)
- [ ] JWT tokens stored securely (httpOnly cookies or localStorage)
- [ ] API endpoints require authentication
- [ ] CORS configured correctly
- [ ] No sensitive data in environment variables committed to git
- [ ] Rate limiting enabled on API
- [ ] Application Insights monitoring enabled

---

## Performance Optimization

### Bundle Size Analysis

```bash
# Analyze bundle
cd frontend/fire-extinguisher-web
npm run build:inspector -- --mode analyze

# Target: <500KB gzipped
```

### CDN Configuration

Azure Static Web Apps includes built-in CDN. No additional configuration needed.

### Caching Strategy

Configured in `staticwebapp.inspector.config.json`:
- Static assets: Cache for 1 year
- HTML: No cache (always fresh)
- API: NetworkFirst strategy (cache fallback)

---

## Maintenance

### Update Dependencies

```bash
# Check for updates
cd frontend/fire-extinguisher-web
npm outdated

# Update dependencies
npm update

# Test
npm run build:inspector
npm run preview:inspector
```

### Monitor Performance

```bash
# Check Application Insights for:
# - Page load times
# - API response times
# - Error rates
# - User engagement
```

---

## Support

**Documentation:** [`INSPECTOR_BARCODE_SCANNER_PLAN.md`](./INSPECTOR_BARCODE_SCANNER_PLAN.md)
**Issues:** https://github.com/dbbuilder/fireproof/issues
**Deployment Status:** https://portal.azure.com

---

**Last Updated:** October 23, 2025
**Version:** 1.0
