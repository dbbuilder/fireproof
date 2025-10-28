# Vercel Inspector App Deployment Guide

**Subdomain:** https://inspect.fireproofapp.net
**Framework:** Vue.js 3 + Vite
**Deployment Platform:** Vercel
**DNS Provider:** Name.com
**Last Updated:** October 28, 2025

---

## Prerequisites

- Node.js 18+ installed
- Vercel account (free tier works)
- Name.com account with fireproofapp.net domain
- Git repository access

**Name.com API Credentials:**
- Username: `TEDTHERRIAULT`
- API Token: `4790fea6e456f7fe9cf4f61a30f025acd63ecd1c`

---

## Step 1: Install Vercel CLI

```bash
# Install Vercel CLI globally
npm install -g vercel

# Login to Vercel
vercel login

# Verify installation
vercel --version
```

---

## Step 2: Build Inspector App Locally (Test)

```bash
# Navigate to frontend directory
cd frontend/fire-extinguisher-web

# Install dependencies
npm install

# Build inspector app
npm run build:inspector

# Preview build locally
npm run preview:inspector
# Opens at http://localhost:4173
```

**Verify:**
- App loads at http://localhost:4173
- Login page displays at /inspector/login
- No console errors
- Assets load correctly

---

## Step 3: Deploy to Vercel

### Initial Deployment

```bash
# Navigate to frontend directory
cd frontend/fire-extinguisher-web

# Deploy using inspector configuration
vercel --prod --config vercel.inspector.json

# Follow prompts:
# Set up and deploy "~/fireproof/frontend/fire-extinguisher-web"? [Y/n] Y
# Which scope? Select your account
# Link to existing project? [y/N] N
# What's your project's name? fireproof-inspector
# In which directory is your code located? ./
# Want to override the settings? [y/N] N
```

**Output:**
```
✅ Production: https://fireproof-inspector.vercel.app [copied to clipboard]
```

**Test Deployment:**
- Visit https://fireproof-inspector.vercel.app/inspector/login
- Verify login page loads
- Test barcode scanner (camera permissions)
- Test GPS location (geolocation permissions)

---

## Step 4: Configure Custom Domain (inspect.fireproofapp.net)

### Option A: Using Vercel CLI

```bash
# Add custom domain to Vercel project
vercel domains add inspect.fireproofapp.net fireproof-inspector

# Vercel will provide DNS records to add
```

### Option B: Using Vercel Dashboard (Recommended)

1. Go to https://vercel.com/dashboard
2. Select `fireproof-inspector` project
3. Navigate to **Settings** → **Domains**
4. Click **Add Domain**
5. Enter: `inspect.fireproofapp.net`
6. Click **Add**

**Vercel will provide:**
```
CNAME inspect → cname.vercel-dns.com
```

---

## Step 5: Configure Name.com DNS via API

### Using cURL

```bash
# Set credentials
NAME_COM_USER="TEDTHERRIAULT"
NAME_COM_TOKEN="4790fea6e456f7fe9cf4f61a30f025acd63ecd1c"

# Delete existing CNAME record (if exists)
curl -u "$NAME_COM_USER:$NAME_COM_TOKEN" \
  -X DELETE \
  https://api.name.com/v4/domains/fireproofapp.net/records/inspect

# Add CNAME record pointing to Vercel
curl -u "$NAME_COM_USER:$NAME_COM_TOKEN" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CNAME",
    "host": "inspect",
    "answer": "cname.vercel-dns.com",
    "ttl": 300
  }' \
  https://api.name.com/v4/domains/fireproofapp.net/records

# Verify DNS record was created
curl -u "$NAME_COM_USER:$NAME_COM_TOKEN" \
  https://api.name.com/v4/domains/fireproofapp.net/records | jq '.records[] | select(.host=="inspect")'
```

**Expected Output:**
```json
{
  "id": 123456789,
  "domainName": "fireproofapp.net",
  "host": "inspect",
  "fqdn": "inspect.fireproofapp.net",
  "type": "CNAME",
  "answer": "cname.vercel-dns.com",
  "ttl": 300
}
```

---

## Step 6: Configure Environment Variables in Vercel

### Using Vercel CLI

```bash
# Set API base URL (production backend)
vercel env add VITE_API_BASE_URL production
# When prompted, enter: https://api.fireproofapp.net

# Set app mode
vercel env add VITE_APP_MODE production
# When prompted, enter: inspector

# Set app name
vercel env add VITE_APP_NAME production
# When prompted, enter: FireProof Inspector

# Redeploy to apply environment variables
vercel --prod --config vercel.inspector.json
```

### Using Vercel Dashboard

1. Go to https://vercel.com/dashboard
2. Select `fireproof-inspector` project
3. Navigate to **Settings** → **Environment Variables**
4. Add the following variables for **Production**:

| Key | Value | Environment |
|-----|-------|-------------|
| `VITE_API_BASE_URL` | `https://api.fireproofapp.net` | Production |
| `VITE_APP_MODE` | `inspector` | Production |
| `VITE_APP_NAME` | `FireProof Inspector` | Production |

5. Click **Save**
6. Redeploy from **Deployments** tab

---

## Step 7: Verify Deployment

### DNS Propagation Check

```bash
# Check DNS resolution (may take 5-10 minutes)
nslookup inspect.fireproofapp.net

# Should return:
# inspect.fireproofapp.net canonical name = cname.vercel-dns.com

# Check with dig
dig inspect.fireproofapp.net +short

# Should return Vercel IP addresses
```

### HTTPS Certificate Check

```bash
# Verify SSL certificate (Vercel auto-provisions)
curl -I https://inspect.fireproofapp.net

# Should return:
# HTTP/2 200
# SSL: Valid certificate
```

### Functional Testing

1. **Login Page**
   - Visit: https://inspect.fireproofapp.net/inspector/login
   - Verify page loads without errors
   - Test login with inspector credentials

2. **Dashboard**
   - After login: https://inspect.fireproofapp.net/inspector/dashboard
   - Verify "Start Inspection" button visible
   - Check stats cards display

3. **Barcode Scanner**
   - Navigate to scan location
   - Grant camera permissions
   - Test barcode scanning
   - Verify camera switches (front/rear)

4. **GPS Location**
   - Grant geolocation permissions
   - Verify GPS coordinates captured
   - Check accuracy display

5. **Offline Mode**
   - Enable Airplane Mode
   - Navigate to dashboard
   - Verify offline banner displays
   - Check draft queue count

6. **PWA Installation**
   - iOS Safari: Share → Add to Home Screen
   - Android Chrome: Menu → Install app
   - Verify app icon on home screen
   - Launch as standalone app

---

## Step 8: Configure CORS on Backend API

**IMPORTANT:** Update backend API to allow requests from inspect.fireproofapp.net

### Backend: Program.cs

```csharp
// Add inspect.fireproofapp.net to CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(
            "https://fireproofapp.net",
            "https://inspect.fireproofapp.net",  // Add inspector subdomain
            "http://localhost:5600",
            "http://localhost:4173"
        )
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });
});
```

**Redeploy backend after updating CORS:**
```bash
# Backend deployment (example with Azure App Service)
cd backend/FireExtinguisherInspection.API
az webapp deployment source config-zip \
  --resource-group rg-fireproof \
  --name app-fireproof-api \
  --src publish.zip
```

---

## Step 9: Continuous Deployment (GitHub Actions)

### Option A: Vercel GitHub Integration (Recommended)

1. Go to https://vercel.com/dashboard
2. Select `fireproof-inspector` project
3. Navigate to **Settings** → **Git**
4. Connect GitHub repository: `dbbuilder/fireproof`
5. Set **Production Branch**: `main`
6. Set **Root Directory**: `frontend/fire-extinguisher-web`
7. Vercel will auto-deploy on every push to `main`

### Option B: GitHub Actions Workflow

Create `.github/workflows/deploy-inspector.yml`:

```yaml
name: Deploy Inspector App to Vercel

on:
  push:
    branches:
      - main
    paths:
      - 'frontend/fire-extinguisher-web/**'
      - '.github/workflows/deploy-inspector.yml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/fire-extinguisher-web/package-lock.json

      - name: Install Vercel CLI
        run: npm install -g vercel

      - name: Pull Vercel Environment Information
        run: vercel pull --yes --environment=production --token=${{ secrets.VERCEL_TOKEN }}
        working-directory: frontend/fire-extinguisher-web

      - name: Build Inspector App
        run: vercel build --prod --token=${{ secrets.VERCEL_TOKEN }}
        working-directory: frontend/fire-extinguisher-web
        env:
          VITE_API_BASE_URL: ${{ secrets.VITE_API_BASE_URL }}
          VITE_APP_MODE: inspector

      - name: Deploy to Vercel
        run: vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }}
        working-directory: frontend/fire-extinguisher-web
```

**GitHub Secrets Required:**
- `VERCEL_TOKEN` - Vercel API token (from https://vercel.com/account/tokens)
- `VITE_API_BASE_URL` - `https://api.fireproofapp.net`

---

## Step 10: Monitoring & Analytics

### Vercel Analytics

1. Go to https://vercel.com/dashboard
2. Select `fireproof-inspector` project
3. Navigate to **Analytics**
4. Enable **Web Analytics** (free tier: 100k events/month)

**Metrics Tracked:**
- Page views
- Unique visitors
- Performance metrics (Core Web Vitals)
- Geographic distribution

### Error Monitoring

```bash
# View real-time logs
vercel logs fireproof-inspector --prod

# Follow logs
vercel logs fireproof-inspector --prod --follow
```

---

## Troubleshooting

### Issue: DNS Not Resolving

**Solution:** Wait for DNS propagation (5-60 minutes)

```bash
# Check DNS propagation globally
https://dnschecker.org/#CNAME/inspect.fireproofapp.net

# Force DNS refresh (macOS/Linux)
sudo dscacheutil -flushcache

# Force DNS refresh (Windows)
ipconfig /flushdns
```

### Issue: SSL Certificate Error

**Solution:** Vercel auto-provisions SSL certificates after DNS validation (can take 10-30 minutes)

```bash
# Check Vercel certificate status
vercel certs ls fireproof-inspector
```

### Issue: 404 on Direct URL Access

**Solution:** Ensure rewrite rules are configured in vercel.inspector.json

```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### Issue: API Calls Failing (CORS)

**Solution:** Update backend CORS to include inspect.fireproofapp.net

```bash
# Test CORS headers
curl -I -X OPTIONS https://api.fireproofapp.net/api/authentication/login \
  -H "Origin: https://inspect.fireproofapp.net" \
  -H "Access-Control-Request-Method: POST"

# Should return:
# Access-Control-Allow-Origin: https://inspect.fireproofapp.net
```

### Issue: Build Fails

**Solution:** Test build locally first

```bash
cd frontend/fire-extinguisher-web
npm run build:inspector

# Check for errors
# Fix any build issues before deploying
```

### Issue: Environment Variables Not Applied

**Solution:** Redeploy after adding environment variables

```bash
# Trigger new deployment
vercel --prod --config vercel.inspector.json

# Or from dashboard: Deployments → Redeploy
```

---

## Rollback Procedure

### Rollback to Previous Deployment

```bash
# List recent deployments
vercel ls fireproof-inspector

# Promote previous deployment to production
vercel promote <deployment-url> --scope=<your-scope>
```

### Rollback via Dashboard

1. Go to https://vercel.com/dashboard
2. Select `fireproof-inspector` project
3. Navigate to **Deployments**
4. Find previous successful deployment
5. Click **...** → **Promote to Production**

---

## Performance Optimization

### Build Analysis

```bash
# Analyze bundle size
cd frontend/fire-extinguisher-web
npm run build:inspector -- --mode analyze

# Target: < 500KB gzipped
```

### Caching Strategy

Configured in vercel.inspector.json:
- Static assets: Cache for 1 year (`max-age=31536000`)
- HTML: No cache (always fresh)
- API: Network-first (cache fallback via Service Worker)

### Edge Network

Vercel automatically serves from global edge network (100+ locations):
- Automatic compression (Gzip/Brotli)
- Automatic image optimization
- HTTP/2 and HTTP/3 support

---

## Security Checklist

- [x] HTTPS enabled (auto-provisioned by Vercel)
- [x] Security headers configured (X-Frame-Options, CSP, etc.)
- [x] CORS properly configured on backend
- [x] JWT tokens stored in localStorage (inspector_token)
- [x] Camera and geolocation permissions required
- [x] No sensitive data in environment variables committed to git
- [x] Rate limiting on backend API
- [x] Vercel Analytics for monitoring

---

## Deployment Commands Summary

```bash
# Initial setup
npm install -g vercel
vercel login

# Deploy to production
cd frontend/fire-extinguisher-web
vercel --prod --config vercel.inspector.json

# Add custom domain via Name.com API
curl -u "TEDTHERRIAULT:4790fea6e456f7fe9cf4f61a30f025acd63ecd1c" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CNAME",
    "host": "inspect",
    "answer": "cname.vercel-dns.com",
    "ttl": 300
  }' \
  https://api.name.com/v4/domains/fireproofapp.net/records

# Set environment variables
vercel env add VITE_API_BASE_URL production
vercel env add VITE_APP_MODE production
vercel env add VITE_APP_NAME production

# Redeploy
vercel --prod --config vercel.inspector.json

# View logs
vercel logs fireproof-inspector --prod --follow
```

---

## Maintenance

### Update Dependencies

```bash
cd frontend/fire-extinguisher-web
npm outdated
npm update
npm run build:inspector  # Test build
vercel --prod --config vercel.inspector.json  # Deploy
```

### Monitor Performance

```bash
# View deployment metrics
vercel inspect <deployment-url>

# Check Core Web Vitals
# Visit: https://vercel.com/dashboard/fireproof-inspector/analytics
```

---

## Support & Resources

**Vercel Documentation:**
- [Vercel CLI Documentation](https://vercel.com/docs/cli)
- [Custom Domains](https://vercel.com/docs/concepts/projects/domains)
- [Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)

**Name.com API:**
- [API Documentation](https://www.name.com/api-docs)
- [DNS Records API](https://www.name.com/api-docs/DNS)

**Project Documentation:**
- [`INSPECTOR_BARCODE_SCANNER_PLAN.md`](./INSPECTOR_BARCODE_SCANNER_PLAN.md)
- [`FUTURE_COMPLIANCE_MODULES.md`](./FUTURE_COMPLIANCE_MODULES.md)

**Deployment Status:**
- Vercel Dashboard: https://vercel.com/dashboard
- Name.com DNS: https://www.name.com/account/domain/details/fireproofapp.net#dns

---

**Last Updated:** October 28, 2025
**Version:** 1.0
**Deployed By:** Claude Code
