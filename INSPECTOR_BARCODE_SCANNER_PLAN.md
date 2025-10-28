# FireProof Inspector Barcode Scanner - Implementation Plan

**Last Updated:** October 23, 2025
**Version:** 1.0
**Status:** Ready for Implementation
**Deployment URL:** https://inspect.fireproofapp.net

---

## Executive Summary

The FireProof Inspector Barcode Scanner is a mobile-first web application designed specifically for field inspectors to perform fire extinguisher inspections quickly and efficiently. The app uses barcode/QR code scanning to identify equipment, captures GPS location for verification, guides inspectors through NFPA-compliant checklists, and generates tamper-proof inspection records.

**Key Features:**
- 📱 Mobile-first PWA (installable on iOS/Android)
- 📷 Universal barcode scanning (QR, Code 39, Code 128, EAN, UPC, etc.)
- 🔐 Secure role-gated authentication (Inspector role only)
- 📍 GPS location capture and validation
- ✅ Guided NFPA-compliant checklists
- 📸 Photo capture for deficiencies
- ✍️ Digital signature capture
- 🔒 Tamper-proof hash generation (HMAC-SHA256)
- 💾 Offline-first with IndexedDB queue
- ⚡ Fast workflow (target: <2 minutes per inspection)

**Timeline:** 2-3 weeks
**Technology Stack:** Vue 3, html5-qrcode, Pinia, Tailwind CSS, IndexedDB

---

## Table of Contents

1. [Deployment Architecture](#deployment-architecture)
2. [Barcode Format Support](#barcode-format-support)
3. [Inspector Workflow](#inspector-workflow)
4. [Implementation Schedule](#implementation-schedule)
5. [Component Architecture](#component-architecture)
6. [Backend API Integration](#backend-api-integration)
7. [Offline Support Strategy](#offline-support-strategy)
8. [Security & Authentication](#security--authentication)
9. [Testing Strategy](#testing-strategy)
10. [Success Metrics](#success-metrics)

---

## Deployment Architecture

### Subdomain Strategy: inspect.fireproofapp.net

**Why a dedicated subdomain:**
- ✅ **Purpose-specific URL** - Easy to remember and communicate to inspectors
- ✅ **Separate PWA manifest** - Install as standalone app on mobile
- ✅ **Isolated routing** - No admin/customer portal routes, only inspector features
- ✅ **Simplified UI** - Mobile-first, single-purpose interface
- ✅ **Performance** - Smaller bundle size (no admin code)
- ✅ **Future flexibility** - Can deploy separately, scale independently

### Deployment Configuration

**Primary App (fireproofapp.net):**
- Admin portal
- Customer portal
- Desktop-optimized
- Full feature set

**Inspector App (inspect.fireproofapp.net):**
- Inspector-only features
- Mobile-optimized
- Minimal UI
- Offline-first

### DNS Configuration

```dns
# Azure Static Web Apps (or Azure App Service)
inspect.fireproofapp.net  →  CNAME  →  nice-smoke-08dbc500f.2.azurestaticapps.net
```

### Build Configuration

```javascript
// vite.config.inspector.js
export default defineConfig({
  base: '/',
  build: {
    outDir: 'dist-inspector',
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'inspector.html')
      }
    }
  },
  define: {
    'import.meta.env.VITE_APP_MODE': JSON.stringify('inspector')
  }
})
```

### Azure Static Web Apps Configuration

```json
// staticwebapp.config.json (for inspect.fireproofapp.net)
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/images/*", "/assets/*"]
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["inspector"]
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html",
      "statusCode": 200
    }
  },
  "globalHeaders": {
    "Cache-Control": "no-cache, no-store, must-revalidate"
  }
}
```

---

## Barcode Format Support

### Supported Formats (13+)

The scanner supports **all major barcode formats** simultaneously using automatic detection:

#### Linear (1D) Barcodes
- ✅ **Code 39** (3 of 9) - Most common on older fire extinguishers
  - Format: `*ABC123*` (includes start/stop characters)
  - Usage: Legacy equipment, industrial applications
  - Auto-cleaned: Strips `*` characters

- ✅ **Code 128** - High-density, newer equipment
  - Format: Alphanumeric, high density
  - Usage: Modern equipment, shipping labels
  - Capacity: Up to 128 ASCII characters

- ✅ **EAN-13** / **EAN-8** - European retail
- ✅ **UPC-A** / **UPC-E** - North American retail
- ✅ **Codabar** - Medical/library
- ✅ **ITF** (Interleaved 2 of 5) - Warehouse

#### 2D Barcodes
- ✅ **QR Code** - Best for mobile scanning (recommended)
  - Format: Can encode JSON, URLs, text
  - Usage: New equipment labels, multi-field data
  - Capacity: Up to 4,296 alphanumeric characters
  - Error correction: 7-30% (works when partially damaged)

- ✅ **Data Matrix** - Small industrial codes
- ✅ **PDF417** - Driver's licenses, transport
- ✅ **Aztec** - Tickets, transport

### Barcode Format Detection

```javascript
// Automatic format detection
scanner.start(cameraConfig, scanConfig, (decodedText, decodedResult) => {
  console.log(`Code: ${decodedText}`)
  console.log(`Format: ${decodedResult.result.format}`) // "CODE_39", "CODE_128", "QR_CODE", etc.

  // Format-specific handling
  handleScan(decodedText, decodedResult.result.format)
})
```

### Format-Specific Handling

```javascript
function handleScan(barcode, format) {
  switch(format) {
    case 'CODE_39':
      // Code 39 often includes start/stop characters (*)
      // Clean: *ABC123* → ABC123
      const cleaned = barcode.replace(/\*/g, '').trim().toUpperCase()
      return lookupExtinguisher(cleaned)

    case 'CODE_128':
      // Code 128 is already clean, just normalize
      return lookupExtinguisher(barcode.trim().toUpperCase())

    case 'QR_CODE':
      // QR codes can contain JSON or plain text
      try {
        const data = JSON.parse(barcode)
        // Example: {"type":"extinguisher","id":"EXT-12345","tenant":"DEMO001"}
        return lookupExtinguisher(data.id)
      } catch {
        // Plain text QR code
        return lookupExtinguisher(barcode.trim().toUpperCase())
      }

    default:
      // All other formats (EAN, UPC, etc.)
      return lookupExtinguisher(barcode.trim().toUpperCase())
  }
}
```

### Backend Barcode Lookup

```csharp
// Backend: ExtinguishersController.cs
[HttpGet("barcode/{code}")]
public async Task<ActionResult<ExtinguisherDto>> GetByBarcode(string code)
{
    var tenantId = HttpContext.GetTenantId();

    // Clean and normalize barcode
    code = CleanBarcodeData(code);

    // Lookup in Extinguishers.QrCodeData column
    var extinguisher = await _extinguisherService.GetByBarcodeAsync(tenantId, code);

    if (extinguisher == null)
    {
        return NotFound(new {
            message = "Extinguisher not found",
            code,
            suggestion: "Check barcode and try again, or enter manually"
        });
    }

    return Ok(extinguisher);
}

private string CleanBarcodeData(string code)
{
    // Remove Code 39 start/stop characters
    code = code.Replace("*", "");

    // Remove common prefixes
    code = code.TrimStart('0'); // Leading zeros

    // Normalize
    code = code.Trim().ToUpper();

    return code;
}
```

### Manual Entry Fallback

For damaged barcodes or poor lighting:

```vue
<div class="manual-entry">
  <input
    v-model="manualCode"
    placeholder="Enter barcode manually"
    class="text-input"
    @keyup.enter="submitManualCode"
  />
  <select v-model="manualFormat" class="format-select">
    <option value="CODE_39">Code 39 (3 of 9)</option>
    <option value="CODE_128">Code 128</option>
    <option value="QR_CODE">QR Code</option>
    <option value="EAN_13">EAN-13</option>
    <option value="OTHER">Other</option>
  </select>
  <button @click="submitManualCode" class="btn-primary">
    Submit
  </button>
</div>
```

### QR Code Generation (Recommended for New Equipment)

**For new equipment labels, generate QR codes:**

```javascript
// Generate QR code with embedded metadata
import QRCode from 'qrcode'

const qrData = {
  type: 'extinguisher',
  id: 'EXT-12345',
  tenant: 'DEMO001',
  location: 'LOC-001',
  assetTag: 'FE-BLDG-A-101',
  v: '1.0'  // Schema version
}

const qrCodeDataURL = await QRCode.toDataURL(JSON.stringify(qrData), {
  errorCorrectionLevel: 'H',  // High error correction (30%)
  margin: 2,
  width: 200
})

// Print on label or display
```

**QR Code Advantages:**
- ✅ Faster scanning (omnidirectional)
- ✅ More data capacity (JSON metadata)
- ✅ Error correction (works when 30% damaged)
- ✅ Smaller print size
- ✅ Better mobile camera compatibility

---

## Inspector Workflow

### 5-Step Inspection Process

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 🔐 Inspector Login                                        │
│    • Role-gated (Inspector role only)                       │
│    • JWT token (8-hour expiry)                              │
│    • Simplified UI (no admin features)                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. 📍 Scan Location QR Code                                 │
│    • Validates location exists                              │
│    • Captures GPS coordinates                               │
│    • Verifies GPS vs expected (50m tolerance)               │
│    • Override option with reason if mismatch                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. 🧯 Scan Extinguisher QR/Barcode                          │
│    • Auto-detects format (QR, Code 39, Code 128, etc.)     │
│    • Retrieves extinguisher details from API                │
│    • Shows last inspection date                             │
│    • Loads NFPA checklist (monthly/annual)                  │
│    • Displays specifications (type, capacity, location)     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. ✅ Perform Inspection                                     │
│    • Guided NFPA checklist (one item at a time)            │
│    • Large Pass/Fail/NA buttons (44x44px)                  │
│    • Required photo for failed items                        │
│    • Optional notes per item                                │
│    • Progress: "5 of 12 complete"                          │
│    • Save draft (offline support)                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. ✍️ Sign & Submit                                          │
│    • Review summary (all responses, photos)                 │
│    • Digital signature capture                              │
│    • Auto-timestamp + GPS embed                             │
│    • Generate tamper-proof hash (HMAC-SHA256)              │
│    • Sync to server (or queue if offline)                   │
│    • Show confirmation + next due date                      │
└─────────────────────────────────────────────────────────────┘
```

### Target Performance
- **Inspection time:** <2 minutes per extinguisher
- **Scan time:** <1 second per barcode
- **Photo upload:** <3 seconds per photo (compressed)
- **Offline queue:** Unlimited inspections
- **Background sync:** Automatic when online

---

## Implementation Schedule

### Week 1: Authentication & Barcode Scanning

**Days 1-2: Project Setup & Infrastructure**
- [ ] Create inspector-specific build configuration (`vite.config.inspector.js`)
- [ ] Create inspector entry point (`inspector.html`)
- [ ] Set up routing with `/inspector` prefix
- [ ] Configure Azure Static Web Apps for `inspect.fireproofapp.net`
- [ ] Create inspector-specific CSS theme (mobile-first)

**Days 3-4: Authentication**
- [ ] Create `InspectorLoginView.vue`
  - Simplified login form (email/password)
  - "Inspector Login" branding
  - Role validation (Inspector role only)
  - JWT token storage (localStorage)
  - Auto-redirect to dashboard on success

- [ ] Create `InspectorLayoutView.vue`
  - Minimal header (logout button only)
  - No sidebar navigation
  - Mobile-optimized
  - Offline indicator banner

- [ ] Create `InspectorDashboardView.vue`
  - "Start Inspection" button (large, primary)
  - Today's completed inspections count
  - Offline queue count
  - Sync status indicator

- [ ] Create `useInspectorStore.js` (Pinia)
  - Current location context
  - Current extinguisher context
  - Current inspection draft
  - Offline queue
  - User profile (inspector name, role)

**Days 5-7: Barcode Scanning**
- [ ] Install/verify html5-qrcode dependency
- [ ] Create `BarcodeScannerComponent.vue`
  - Camera permission request
  - Rear camera selection (facingMode: "environment")
  - Scanner viewport (250x250px targeting box)
  - Format detection (CODE_39, CODE_128, QR_CODE, etc.)
  - Success feedback (haptic vibration + sound)
  - Error handling (camera denied, no barcode found)
  - Manual entry fallback
  - Format display badge

- [ ] Create `ScanLocationView.vue`
  - Large "Scan Location" heading
  - Barcode scanner component
  - Location details display (after scan)
  - GPS coordinate capture
  - GPS validation (distance from expected)
  - Override button (if GPS mismatch)
  - "Next: Scan Extinguisher" button

- [ ] Create `ScanExtinguisherView.vue`
  - Large "Scan Extinguisher" heading
  - Barcode scanner component
  - Extinguisher details display (after scan)
  - Last inspection date/status
  - Next due date
  - Checklist preview
  - "Start Inspection" button

### Week 2: Inspection Workflow & Photos

**Days 8-10: Guided Checklist**
- [ ] Create `InspectionChecklistView.vue`
  - Single checklist item per screen
  - Swipe gestures (left/right for prev/next)
  - Large item text (18px, readable at arm's length)
  - Help icon (shows detailed instructions)
  - Visual aid image (if available)
  - Pass/Fail/NA button group (44x44px each)
  - Notes textarea (expands on tap)
  - Photo indicator (required for fails)
  - Progress bar (top of screen)
  - "Save Draft" button (bottom)
  - "Next" / "Previous" navigation

- [ ] Create `InspectionProgressBar.vue`
  - Completed items count
  - Total items count
  - Visual progress bar (green fill)
  - Percentage display
  - Estimated time remaining

**Days 11-12: Photo Capture**
- [ ] Create `PhotoCaptureComponent.vue`
  - Native camera access (getUserMedia)
  - Camera preview (full screen)
  - Capture button (large, centered)
  - Photo preview (after capture)
  - Retake button
  - Confirm/Use button
  - GPS coordinate auto-attach
  - Timestamp auto-attach
  - Photo compression (max 2MB, JPEG 85% quality)

- [ ] Create `services/photoService.js`
  - Compress image (canvas resize)
  - Convert to base64
  - Attach metadata (GPS, timestamp)
  - Store temporarily (IndexedDB if offline)
  - Upload to server (POST /api/inspections/{id}/photos)

**Days 13-14: GPS Location**
- [ ] Create `services/gpsService.js`
  - Request geolocation permission
  - Capture coordinates (latitude, longitude)
  - Measure accuracy (meters)
  - Calculate distance (haversine formula)
  - Validate against expected location
  - Handle errors (permission denied, timeout)

- [ ] GPS validation logic
  - Compare current GPS to extinguisher's expected location
  - Tolerance: 50 meters
  - Warning if outside tolerance
  - Override with reason required
  - Log GPS accuracy in inspection record

### Week 3: Signature, Backend Integration & Offline

**Days 15-16: Digital Signature**
- [ ] Create `SignaturePadComponent.vue`
  - Canvas-based signature capture
  - Touch/mouse drawing support
  - Clear button (erase signature)
  - Redo button
  - Inspector name display (read-only)
  - Timestamp display (auto-generated)
  - Convert to base64 image (PNG)

- [ ] Create `InspectionSummaryView.vue`
  - Inspection overview card
  - Checklist responses list (Pass/Fail/NA badges)
  - Photo thumbnails gallery
  - GPS coordinates display
  - Overall Pass/Fail status
  - Deficiency count (failed items)
  - Edit button (navigate back to specific item)
  - "Sign & Submit" button (proceed to signature)

**Days 17-18: Backend API Integration**
- [ ] Create `services/inspectorService.js`
  - `POST /api/inspections` - Create inspection
  - `PUT /api/inspections/{id}` - Update inspection progress
  - `POST /api/inspections/{id}/photos` - Upload photo
  - `POST /api/inspections/{id}/complete` - Finalize with signature
  - `GET /api/locations/{id}` - Get location details
  - `GET /api/extinguishers/barcode/{code}` - Get extinguisher by barcode
  - `GET /api/checklist-templates/type/{inspectionType}` - Get NFPA checklist

- [ ] API error handling
  - Network errors (offline)
  - 401 Unauthorized (token expired)
  - 404 Not Found (barcode not found)
  - 500 Server Error
  - Retry logic (exponential backoff)

**Days 19-21: Offline Support & Testing**
- [ ] Create `services/offlineService.js`
  - IndexedDB database setup
  - Store draft inspections
  - Store offline photos (base64)
  - Queue API calls
  - Background sync when online
  - Conflict resolution (server wins)

- [ ] IndexedDB Schema
  ```javascript
  const dbSchema = {
    draftInspections: {
      keyPath: 'id',
      indexes: ['timestamp', 'status']
    },
    offlinePhotos: {
      keyPath: 'id',
      indexes: ['inspectionId', 'timestamp']
    },
    syncQueue: {
      keyPath: 'id',
      indexes: ['endpoint', 'timestamp', 'retryCount']
    }
  }
  ```

- [ ] Create `services/tamperProofingService.js`
  - Generate HMAC-SHA256 hash
  - Hash input: inspection data + GPS + timestamp + photos
  - Chain hash with previous inspection (blockchain-style)
  - Verify hash on server

- [ ] Offline indicator UI
  - Banner at top (yellow background)
  - "You're offline. Inspections will sync when online."
  - Sync progress indicator (when syncing)
  - "X inspections in queue" counter

---

## Component Architecture

### Routing Structure

```
inspect.fireproofapp.net/
├── /inspector/login           → InspectorLoginView
├── /inspector/dashboard       → InspectorDashboardView
├── /inspector/scan-location   → ScanLocationView
├── /inspector/scan-extinguisher → ScanExtinguisherView
├── /inspector/checklist       → InspectionChecklistView
├── /inspector/summary         → InspectionSummaryView
├── /inspector/signature       → SignaturePadComponent
└── /inspector/complete        → InspectionCompleteView
```

### Component Hierarchy

```
InspectorApp
├── InspectorLayoutView
│   ├── Header (logout only)
│   ├── OfflineBanner (conditional)
│   └── RouterView
│       ├── InspectorLoginView
│       ├── InspectorDashboardView
│       ├── ScanLocationView
│       │   └── BarcodeScannerComponent
│       ├── ScanExtinguisherView
│       │   └── BarcodeScannerComponent
│       ├── InspectionChecklistView
│       │   ├── InspectionProgressBar
│       │   ├── ChecklistItemComponent
│       │   └── PhotoCaptureComponent
│       ├── InspectionSummaryView
│       │   └── PhotoGalleryComponent
│       └── SignaturePadComponent
```

### Shared Components

```javascript
// components/BarcodeScannerComponent.vue
// - Reusable for location and extinguisher scanning
// - Props: scanType ('location' | 'extinguisher')
// - Emits: @scan-success, @scan-error

// components/PhotoCaptureComponent.vue
// - Camera access and photo compression
// - Props: required (boolean)
// - Emits: @photo-captured, @photo-cancelled

// components/InspectionProgressBar.vue
// - Shows X of Y items complete
// - Props: current, total
// - Visual progress bar

// components/SignaturePadComponent.vue
// - Canvas-based signature capture
// - Props: inspectorName, readonly
// - Emits: @signature-complete, @signature-clear

// components/OfflineBanner.vue
// - Displays when navigator.onLine = false
// - Shows sync queue count
// - Sync progress indicator
```

### Pinia Stores

```javascript
// stores/useInspectorStore.js
export const useInspectorStore = defineStore('inspector', {
  state: () => ({
    // Current inspection context
    currentLocation: null,
    currentExtinguisher: null,
    currentInspection: null,
    checklistTemplate: null,
    checklistResponses: [],
    inspectionPhotos: [],

    // Offline queue
    draftInspections: [],
    offlinePhotos: [],
    syncQueue: [],

    // User context
    inspector: null,
    isOnline: navigator.onLine
  }),

  actions: {
    async scanLocation(barcode, format) { },
    async scanExtinguisher(barcode, format) { },
    async startInspection() { },
    async saveChecklistResponse(itemId, response, notes, photo) { },
    async saveDraft() { },
    async completeInspection(signature) { },
    async syncOfflineQueue() { }
  }
})

// stores/useAuthStore.js
export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: localStorage.getItem('token'),
    user: null,
    isAuthenticated: false
  }),

  actions: {
    async login(email, password) { },
    async logout() { },
    async refreshToken() { },
    checkRole(role) { }
  }
})
```

---

## Backend API Integration

### Required Backend Endpoints

```csharp
// ExtinguishersController.cs
[HttpGet("barcode/{code}")]
public async Task<ActionResult<ExtinguisherDto>> GetByBarcode(string code)

// LocationsController.cs
[HttpGet("{id}")]
public async Task<ActionResult<LocationDto>> GetById(Guid id)

// InspectionsController.cs
[HttpPost]
public async Task<ActionResult<InspectionDto>> CreateInspection(CreateInspectionRequest request)

[HttpPut("{id}")]
public async Task<ActionResult> UpdateInspection(Guid id, UpdateInspectionRequest request)

[HttpPost("{id}/photos")]
public async Task<ActionResult<PhotoUploadResponse>> UploadPhoto(Guid id, IFormFile photo)

[HttpPost("{id}/complete")]
public async Task<ActionResult<InspectionDto>> CompleteInspection(
    Guid id,
    CompleteInspectionRequest request)

// ChecklistTemplatesController.cs
[HttpGet("type/{inspectionType}")]
public async Task<ActionResult<ChecklistTemplateDto>> GetTemplateByType(string inspectionType)
```

### Request/Response DTOs

```csharp
// CreateInspectionRequest.cs
public class CreateInspectionRequest
{
    public Guid ExtinguisherId { get; set; }
    public string InspectionType { get; set; } // "Monthly", "Annual"
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public decimal LocationAccuracy { get; set; }
    public bool LocationVerified { get; set; }
    public string? LocationOverrideReason { get; set; }
}

// CompleteInspectionRequest.cs
public class CompleteInspectionRequest
{
    public string InspectorSignature { get; set; } // base64 image
    public List<ChecklistResponseDto> ChecklistResponses { get; set; }
    public bool OverallPass { get; set; }
    public int DeficiencyCount { get; set; }
    public string InspectionHash { get; set; } // HMAC-SHA256
    public string? PreviousInspectionHash { get; set; }
}

// ChecklistResponseDto.cs
public class ChecklistResponseDto
{
    public Guid ChecklistItemId { get; set; }
    public string Response { get; set; } // "Pass", "Fail", "NA"
    public string? Comment { get; set; }
    public Guid? PhotoId { get; set; }
}
```

---

## Offline Support Strategy

### IndexedDB Schema

```javascript
// db.js
import { openDB } from 'idb'

const DB_NAME = 'fireproof-inspector'
const DB_VERSION = 1

export async function initDB() {
  return await openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      // Draft inspections (not yet submitted)
      if (!db.objectStoreNames.contains('draftInspections')) {
        const store = db.createObjectStore('draftInspections', { keyPath: 'id' })
        store.createIndex('timestamp', 'timestamp')
        store.createIndex('status', 'status')
      }

      // Offline photos (base64 encoded)
      if (!db.objectStoreNames.contains('offlinePhotos')) {
        const store = db.createObjectStore('offlinePhotos', { keyPath: 'id' })
        store.createIndex('inspectionId', 'inspectionId')
        store.createIndex('timestamp', 'timestamp')
      }

      // Sync queue (pending API calls)
      if (!db.objectStoreNames.contains('syncQueue')) {
        const store = db.createObjectStore('syncQueue', { keyPath: 'id' })
        store.createIndex('endpoint', 'endpoint')
        store.createIndex('timestamp', 'timestamp')
        store.createIndex('retryCount', 'retryCount')
      }
    }
  })
}
```

### Background Sync

```javascript
// services/offlineService.js
export class OfflineService {
  async saveDraft(inspection) {
    const db = await initDB()
    await db.put('draftInspections', {
      ...inspection,
      timestamp: Date.now(),
      status: 'draft'
    })
  }

  async queueAPICall(endpoint, method, data) {
    const db = await initDB()
    await db.add('syncQueue', {
      id: crypto.randomUUID(),
      endpoint,
      method,
      data,
      timestamp: Date.now(),
      retryCount: 0
    })
  }

  async syncWhenOnline() {
    if (!navigator.onLine) return

    const db = await initDB()
    const queue = await db.getAll('syncQueue')

    for (const item of queue) {
      try {
        await api[item.method.toLowerCase()](item.endpoint, item.data)
        await db.delete('syncQueue', item.id)
      } catch (error) {
        // Increment retry count
        item.retryCount++
        if (item.retryCount < 3) {
          await db.put('syncQueue', item)
        } else {
          // Max retries reached, log error
          console.error('Sync failed after 3 retries:', item)
        }
      }
    }
  }
}

// Listen for online event
window.addEventListener('online', () => {
  offlineService.syncWhenOnline()
})
```

---

## Security & Authentication

### Role-Based Access Control

```javascript
// Router guard
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.path.startsWith('/inspector')) {
    if (!authStore.isAuthenticated) {
      return next('/inspector/login')
    }

    // Verify Inspector role
    if (!authStore.user.roles.includes('Inspector')) {
      return next('/unauthorized')
    }
  }

  next()
})
```

### JWT Token Management

```javascript
// services/authService.js
export class AuthService {
  async login(email, password) {
    const response = await api.post('/api/authentication/login', {
      email,
      password
    })

    const { token, refreshToken, user } = response.data

    // Store tokens
    localStorage.setItem('token', token)
    localStorage.setItem('refreshToken', refreshToken)

    // Decode JWT to check expiry
    const decoded = jwtDecode(token)
    const expiresAt = decoded.exp * 1000

    // Set refresh timer (15 minutes before expiry)
    setTimeout(() => {
      this.refreshToken()
    }, expiresAt - Date.now() - (15 * 60 * 1000))

    return user
  }

  async refreshToken() {
    const refreshToken = localStorage.getItem('refreshToken')
    const response = await api.post('/api/authentication/refresh', {
      refreshToken
    })

    const { token: newToken } = response.data
    localStorage.setItem('token', newToken)
  }
}
```

### Tamper-Proof Hash Generation

```javascript
// services/tamperProofingService.js
import CryptoJS from 'crypto-js'

export class TamperProofingService {
  generateInspectionHash(inspection, photos, previousHash) {
    const data = {
      extinguisherId: inspection.extinguisherId,
      inspectionType: inspection.inspectionType,
      inspectionDate: inspection.inspectionDate,
      latitude: inspection.latitude,
      longitude: inspection.longitude,
      checklistResponses: inspection.checklistResponses,
      photoHashes: photos.map(p => this.hashPhoto(p)),
      previousHash: previousHash || null,
      timestamp: Date.now()
    }

    const dataString = JSON.stringify(data)
    const secretKey = import.meta.env.VITE_HASH_SECRET

    return CryptoJS.HmacSHA256(dataString, secretKey).toString()
  }

  hashPhoto(photoBase64) {
    return CryptoJS.SHA256(photoBase64).toString()
  }
}
```

---

## Testing Strategy

### Unit Tests (Vitest)

```javascript
// BarcodeScannerComponent.spec.js
describe('BarcodeScannerComponent', () => {
  it('should detect Code 39 format', async () => {
    const wrapper = mount(BarcodeScannerComponent)
    await wrapper.vm.handleScan('*ABC123*', { format: 'CODE_39' })
    expect(wrapper.emitted('scan-success')[0][0].code).toBe('ABC123')
  })

  it('should detect Code 128 format', async () => {
    const wrapper = mount(BarcodeScannerComponent)
    await wrapper.vm.handleScan('ABC123', { format: 'CODE_128' })
    expect(wrapper.emitted('scan-success')[0][0].code).toBe('ABC123')
  })

  it('should parse QR code JSON', async () => {
    const qrData = JSON.stringify({ type: 'extinguisher', id: 'EXT-123' })
    const wrapper = mount(BarcodeScannerComponent)
    await wrapper.vm.handleScan(qrData, { format: 'QR_CODE' })
    expect(wrapper.emitted('scan-success')[0][0].code).toBe('EXT-123')
  })
})
```

### Integration Tests (Playwright)

```javascript
// inspector-workflow.spec.js
test('complete inspection workflow', async ({ page }) => {
  // Login
  await page.goto('https://inspect.fireproofapp.net/inspector/login')
  await page.fill('[data-testid="email-input"]', 'inspector@test.com')
  await page.fill('[data-testid="password-input"]', 'password')
  await page.click('[data-testid="login-button"]')

  // Dashboard
  await expect(page.locator('[data-testid="start-inspection-button"]')).toBeVisible()
  await page.click('[data-testid="start-inspection-button"]')

  // Scan location (mock barcode scan)
  await page.evaluate(() => {
    window.mockBarcodeScan('LOC-001', 'QR_CODE')
  })
  await expect(page.locator('[data-testid="location-details"]')).toBeVisible()

  // Scan extinguisher (mock barcode scan)
  await page.click('[data-testid="next-button"]')
  await page.evaluate(() => {
    window.mockBarcodeScan('EXT-12345', 'CODE_128')
  })
  await expect(page.locator('[data-testid="extinguisher-details"]')).toBeVisible()

  // Complete checklist
  await page.click('[data-testid="start-inspection-button"]')
  for (let i = 0; i < 12; i++) {
    await page.click('[data-testid="pass-button"]')
    if (i < 11) await page.click('[data-testid="next-button"]')
  }

  // Sign
  await page.click('[data-testid="review-button"]')
  await page.click('[data-testid="sign-button"]')

  // Draw signature (mock)
  const canvas = await page.locator('[data-testid="signature-canvas"]')
  await canvas.evaluate(el => {
    const ctx = el.getContext('2d')
    ctx.moveTo(50, 50)
    ctx.lineTo(150, 150)
    ctx.stroke()
  })

  await page.click('[data-testid="submit-button"]')

  // Verify success
  await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
})
```

### Device Testing

**iOS Devices:**
- iPhone 12 (iOS 16+)
- iPhone 13 (iOS 17+)
- iPhone 14 (iOS 17+)
- iPhone 15 (iOS 18+)
- Safari browser + PWA installed

**Android Devices:**
- Samsung Galaxy S21/S22/S23
- Google Pixel 6/7/8
- OnePlus 9/10/11
- Chrome browser + PWA installed

**Testing Scenarios:**
- Bright outdoor lighting
- Dim indoor lighting
- Damaged/dirty barcodes
- Various barcode formats
- Offline mode (airplane mode)
- Poor connection (slow 3G)
- GPS accuracy in urban/rural
- Photo compression quality

---

## Success Metrics

### Phase 1A Success Criteria

- [ ] ✅ Inspector can login with Inspector role
- [ ] ✅ Inspector can scan location QR code (all formats)
- [ ] ✅ Inspector can scan extinguisher barcode (Code 39, Code 128, QR)
- [ ] ✅ Inspector can complete NFPA checklist
- [ ] ✅ Inspector can capture photos for deficiencies
- [ ] ✅ Inspector can capture digital signature
- [ ] ✅ Inspection syncs to server successfully
- [ ] ✅ Offline mode works (drafts persist, sync on reconnect)
- [ ] ✅ GPS location captured accurately (<50m accuracy)
- [ ] ✅ Tamper-proof hash generated and verified

### Performance Targets

- **Inspection time:** <2 minutes per extinguisher
- **Barcode scan:** <1 second per code
- **Photo upload:** <3 seconds per photo (compressed)
- **GPS capture:** <5 seconds to acquire
- **Offline sync:** <30 seconds for 10 inspections
- **App bundle size:** <500KB gzipped
- **Initial load:** <3 seconds on 3G

### Beta Testing Goals

- **3 inspectors** perform testing
- **30 total inspections** (10 each)
- **Zero critical bugs** in barcode scanning
- **90%+ success rate** on first scan attempt
- **Positive feedback** on UI/UX
- **<5% offline sync failures**

---

## Deployment Checklist

### Pre-Deployment

- [ ] Code review complete
- [ ] Unit tests passing (95%+ coverage)
- [ ] Integration tests passing
- [ ] Performance testing complete
- [ ] Security audit complete
- [ ] Accessibility testing (WCAG 2.1 AA)

### DNS & SSL

- [ ] Configure DNS for inspect.fireproofapp.net
- [ ] SSL certificate provisioned (Azure manages)
- [ ] Verify HTTPS redirect

### Azure Configuration

- [ ] Create Azure Static Web App (or App Service)
- [ ] Configure custom domain (inspect.fireproofapp.net)
- [ ] Set environment variables (VITE_API_BASE_URL, etc.)
- [ ] Configure staticwebapp.config.json
- [ ] Enable Application Insights

### Post-Deployment

- [ ] Smoke test on production URL
- [ ] Test PWA installation (iOS/Android)
- [ ] Verify offline mode
- [ ] Test barcode scanning on production
- [ ] Monitor Application Insights for errors
- [ ] Gather beta tester feedback

---

## Future Enhancements (Phase 2+)

### Phase 2: Advanced Features
- [ ] Voice commands ("Next item", "Pass", "Fail")
- [ ] Bulk inspection mode (scan multiple extinguishers in sequence)
- [ ] Augmented reality (AR) guidance (overlay checklist on camera view)
- [ ] Predictive text for notes (AI-powered suggestions)
- [ ] Barcode generation tool (for new equipment)

### Phase 3: React Native Native Apps
- [ ] iOS app (Swift/SwiftUI)
- [ ] Android app (Kotlin/Jetpack Compose)
- [ ] App Store submission
- [ ] Google Play submission
- [ ] Push notifications (inspection reminders)
- [ ] Better camera performance (native camera APIs)

---

**END OF DOCUMENT**

---

**Document Version:** 1.0
**Last Updated:** October 23, 2025
**Status:** Ready for Implementation
**Next Review:** Weekly during active development
