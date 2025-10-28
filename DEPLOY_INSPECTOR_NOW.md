# Deploy Inspector App - Quick Start

**Target URL:** https://inspect.fireproofapp.net
**Estimated Time:** 30 minutes
**Last Updated:** October 28, 2025

---

## Prerequisites Checklist

- [x] Backend CORS updated (committed)
- [x] Inspector build scripts added (committed)
- [x] Vercel configuration created (committed)
- [ ] Vercel CLI installed
- [ ] Backend deployed with new CORS
- [ ] Vercel account ready

---

## Step 1: Install Vercel CLI (2 minutes)

```bash
# Install globally
npm install -g vercel

# Login to Vercel
vercel login
# Opens browser to authenticate

# Verify
vercel --version
```

---

## Step 2: Deploy Backend with Updated CORS (5-10 minutes)

The backend now includes CORS for:
- `https://inspect.fireproofapp.net`
- `https://fireproof-inspector.vercel.app`
- `http://localhost:5600`

### Option A: Azure App Service (if already deployed)

```bash
cd backend/FireExtinguisherInspection.API

# Build and publish
dotnet publish -c Release -o ./publish

# Create zip
cd publish
zip -r ../publish.zip .
cd ..

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group rg-fireproof \
  --name <your-app-service-name> \
  --src publish.zip

# Or use Azure Portal: Deployment Center → Manual Deployment → ZIP Deploy
```

### Option B: Restart App Service (if already current)

```bash
# If code is already deployed via GitHub Actions
az webapp restart \
  --resource-group rg-fireproof \
  --name <your-app-service-name>
```

---

## Step 3: Test Backend CORS (2 minutes)

```bash
# Test CORS with inspector origin
curl -I -X OPTIONS https://api.fireproofapp.net/api/authentication/login \
  -H "Origin: https://inspect.fireproofapp.net" \
  -H "Access-Control-Request-Method: POST"

# Expected response should include:
# Access-Control-Allow-Origin: https://inspect.fireproofapp.net
# Access-Control-Allow-Methods: POST, ...
# Access-Control-Allow-Credentials: true
```

---

## Step 4: Build Inspector App Locally (Test) (3 minutes)

```bash
cd frontend/fire-extinguisher-web

# Install dependencies (if not already)
npm install

# Build inspector app
npm run build:inspector

# Should output: dist-inspector directory created
# Should see: ✓ built in Xs

# Preview locally
npm run preview:inspector
# Opens at http://localhost:4173
```

**Test Locally:**
1. Open http://localhost:4173/inspector/login
2. Verify page loads
3. Check browser console for errors
4. Press Ctrl+C to stop preview

---

## Step 5: Deploy to Vercel (5 minutes)

```bash
cd frontend/fire-extinguisher-web

# Deploy to production
vercel --prod --config vercel.inspector.json

# Follow prompts:
# ? Set up and deploy? [Y/n] Y
# ? Which scope? [Select your account]
# ? Link to existing project? [y/N] N
# ? What's your project's name? fireproof-inspector
# ? In which directory is your code located? ./
# ? Want to override the settings? [y/N] N

# Wait for deployment (1-2 minutes)
# Output: ✅ Production: https://fireproof-inspector.vercel.app
```

**Test Vercel Default Domain:**
```bash
# Visit the URL provided
open https://fireproof-inspector.vercel.app/inspector/login

# Verify:
# - Page loads
# - No console errors
# - Login form displays
```

---

## Step 6: Configure Custom Domain via Vercel Dashboard (3 minutes)

### Option A: Vercel Dashboard (Recommended)

1. Go to https://vercel.com/dashboard
2. Click on `fireproof-inspector` project
3. Navigate to **Settings** → **Domains**
4. Click **Add Domain**
5. Enter: `inspect.fireproofapp.net`
6. Click **Add**

**Vercel will display:**
```
Add the following record to your DNS provider:

Type: CNAME
Name: inspect
Value: cname.vercel-dns.com
```

### Option B: Vercel CLI

```bash
vercel domains add inspect.fireproofapp.net fireproof-inspector

# Will display DNS instructions
```

---

## Step 7: Configure Name.com DNS via API (2 minutes)

```bash
# Set credentials
NAME_COM_USER="TEDTHERRIAULT"
NAME_COM_TOKEN="4790fea6e456f7fe9cf4f61a30f025acd63ecd1c"

# Delete existing record (if any)
curl -u "$NAME_COM_USER:$NAME_COM_TOKEN" \
  -X DELETE \
  https://api.name.com/v4/domains/fireproofapp.net/records/inspect

# Add CNAME record
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

# Verify record created
curl -u "$NAME_COM_USER:$NAME_COM_TOKEN" \
  https://api.name.com/v4/domains/fireproofapp.net/records | \
  jq '.records[] | select(.host=="inspect")'
```

**Expected Output:**
```json
{
  "id": 123456789,
  "host": "inspect",
  "type": "CNAME",
  "answer": "cname.vercel-dns.com",
  "ttl": 300
}
```

---

## Step 8: Configure Environment Variables in Vercel (3 minutes)

### Option A: Vercel Dashboard

1. Go to https://vercel.com/dashboard
2. Select `fireproof-inspector` project
3. Navigate to **Settings** → **Environment Variables**
4. Add these variables for **Production**:

| Variable | Value |
|----------|-------|
| `VITE_API_BASE_URL` | `https://api.fireproofapp.net` |
| `VITE_APP_MODE` | `inspector` |
| `VITE_APP_NAME` | `FireProof Inspector` |

5. Click **Save**
6. Navigate to **Deployments** tab
7. Click **...** on latest deployment → **Redeploy**

### Option B: Vercel CLI

```bash
# Add environment variables
vercel env add VITE_API_BASE_URL production
# When prompted: https://api.fireproofapp.net

vercel env add VITE_APP_MODE production
# When prompted: inspector

vercel env add VITE_APP_NAME production
# When prompted: FireProof Inspector

# Redeploy to apply changes
cd frontend/fire-extinguisher-web
vercel --prod --config vercel.inspector.json
```

---

## Step 9: Wait for DNS Propagation (5-30 minutes)

```bash
# Check DNS resolution
nslookup inspect.fireproofapp.net

# Should return:
# inspect.fireproofapp.net canonical name = cname.vercel-dns.com

# Check globally
# Visit: https://dnschecker.org/#CNAME/inspect.fireproofapp.net
```

**Vercel SSL Certificate:**
- Auto-provisions after DNS validation
- Usually takes 10-30 minutes
- No action required

---

## Step 10: Test Production Deployment (5 minutes)

### 1. HTTPS & DNS

```bash
# Test HTTPS
curl -I https://inspect.fireproofapp.net

# Should return: HTTP/2 200
```

### 2. Login Page

```bash
# Visit in browser
open https://inspect.fireproofapp.net/inspector/login

# Verify:
# - HTTPS lock icon (SSL valid)
# - Page loads without errors
# - FireProof Inspector branding displays
```

### 3. Test Login

**Use existing inspector user or create one:**

```sql
-- Create inspector user (if needed)
INSERT INTO Users (UserId, Email, PasswordHash, PasswordSalt, FirstName, LastName, IsActive, CreatedDate)
VALUES (NEWID(), 'inspector@fireproofapp.net', '<hash>', '<salt>', 'Test', 'Inspector', 1, GETDATE());

-- Add Inspector role
INSERT INTO UserSystemRoles (UserSystemRoleId, UserId, SystemRoleId, AssignedDate)
SELECT NEWID(), u.UserId, sr.SystemRoleId, GETDATE()
FROM Users u, SystemRoles sr
WHERE u.Email = 'inspector@fireproofapp.net' AND sr.RoleName = 'Inspector';
```

**Test Login:**
1. Go to https://inspect.fireproofapp.net/inspector/login
2. Enter credentials
3. Click **Sign In**
4. Should redirect to `/inspector/dashboard`
5. Verify "Start Inspection" button displays

### 4. Test Barcode Scanner

1. Click **Start Inspection**
2. Should navigate to `/inspector/scan-location`
3. Grant camera permissions when prompted
4. Verify camera video stream displays
5. Test barcode scanning (use phone QR code or sample)

### 5. Test GPS

1. On scan location screen
2. Grant geolocation permissions when prompted
3. Verify GPS coordinates display
4. Check accuracy (should be ±10-50 meters)

### 6. Test Complete Workflow

1. Scan location → GPS capture
2. Scan extinguisher → Details display
3. Complete checklist → 10 items
4. Add photos → Camera capture
5. Sign inspection → Signature pad
6. Submit → Success screen

### 7. Test Offline Mode

1. Enable Airplane Mode
2. Navigate to dashboard
3. Verify offline banner displays
4. Check "X in queue" badge
5. Disable Airplane Mode
6. Verify "Syncing..." message

---

## Troubleshooting

### DNS not resolving

**Solution:** Wait 5-60 minutes for propagation

```bash
# Clear DNS cache
# macOS:
sudo dscacheutil -flushcache

# Windows:
ipconfig /flushdns

# Linux:
sudo systemd-resolve --flush-caches
```

### SSL Certificate Error

**Solution:** Wait 10-30 minutes for Vercel to provision certificate

```bash
# Check Vercel certificate status
vercel certs ls fireproof-inspector
```

### API Calls Fail (CORS)

**Solution:** Verify backend CORS is deployed

```bash
# Test CORS headers
curl -I -X OPTIONS https://api.fireproofapp.net/api/authentication/login \
  -H "Origin: https://inspect.fireproofapp.net" \
  -H "Access-Control-Request-Method: POST"

# Should include:
# Access-Control-Allow-Origin: https://inspect.fireproofapp.net
```

### Login Fails

**Solution:** Check backend logs, verify JWT token generation

```bash
# Check backend health
curl https://api.fireproofapp.net/health

# Test login endpoint
curl -X POST https://api.fireproofapp.net/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email":"inspector@test.com","password":"test123"}'
```

---

## Success Criteria

- [x] Backend deployed with CORS updates
- [ ] Inspector app deployed to Vercel
- [ ] DNS configured (inspect.fireproofapp.net → cname.vercel-dns.com)
- [ ] Environment variables set
- [ ] HTTPS certificate valid
- [ ] Login page loads
- [ ] Inspector can login successfully
- [ ] Barcode scanner works (camera permissions)
- [ ] GPS location works (geolocation permissions)
- [ ] Complete inspection workflow functional
- [ ] Offline mode works (offline banner + queue)
- [ ] PWA installable on iOS/Android

---

## Customer Preview URL

**Share this URL with customers:**

```
https://inspect.fireproofapp.net/inspector/login

Test Credentials (if created):
Email: inspector@fireproofapp.net
Password: <set during user creation>
```

---

## Rollback (if needed)

```bash
# List deployments
vercel ls fireproof-inspector

# Promote previous deployment
vercel promote <previous-deployment-url>
```

---

## Support

**Full Documentation:** [`VERCEL_INSPECTOR_DEPLOYMENT.md`](./VERCEL_INSPECTOR_DEPLOYMENT.md)

**Vercel Dashboard:** https://vercel.com/dashboard

**Name.com DNS:** https://www.name.com/account/domain/details/fireproofapp.net#dns

**Backend Logs:** Check Azure App Service logs or Vercel Functions logs

---

**Estimated Total Time:** 30 minutes
**Ready for Customer Preview:** Same day

🚀 **Let's deploy!**
