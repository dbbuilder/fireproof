/*============================================================================
  ADDITIONAL REQUIREMENTS: Inspection Scheduling and Mobile Features
  
  This document extends REQUIREMENTS.md with detailed specifications for:
  - Intelligent inspection scheduling
  - Route optimization and planning
  - GPS tracking and geofencing
  - Push notifications
  - Mobile-specific features
  - Compliance management
============================================================================*/

## BR-11: Intelligent Inspection Scheduling
**Priority:** Critical  
**Description:** Automated scheduling system that manages inspection cycles, assigns inspectors, and optimizes routes.

### Features:

#### Automatic Schedule Generation
- **Frequency-Based Scheduling:** 
  - Monthly inspections (every 30 days)
  - Annual inspections (every 365 days)
  - Hydrostatic testing (5, 12 years based on extinguisher type)
  - Custom inspection intervals per tenant
  
- **Smart Scheduling:**
  - Calculate next inspection date based on last completion
  - Factor in grace periods (7 days before/after due date)
  - Account for weekends and holidays
  - Batch scheduling for new extinguishers
  - Bulk rescheduling capabilities

#### Inspector Assignment
- **Automatic Assignment:**
  - Assign based on location proximity
  - Balance workload across inspectors
  - Consider inspector certifications/qualifications
  - Respect inspector availability calendars
  
- **Manual Override:**
  - Location managers can assign specific inspectors
  - Reassign inspections if inspector unavailable
  - Inspector can claim available inspections

#### Route Optimization
- **Daily Route Planning:**
  - Optimize inspection sequence to minimize travel time
  - Calculate driving distances between locations
  - Estimate time per inspection (5-10 min monthly, 30-45 min annual)
  - Suggest optimal start time and sequence
  - Account for traffic patterns (via integration)

- **Multi-Location Routes:**
  - Group inspections by geographic proximity
  - Suggest multi-site visits in single trip
  - Calculate total route time and distance
  - Export route to navigation apps (Google Maps, Apple Maps, Waze)

**Acceptance Criteria:**
- Inspections automatically scheduled based on last completion + frequency
- Overdue inspections flagged with days overdue count
- Inspectors see daily route with optimized sequence
- Route optimization reduces travel time by 30%+
- Push notifications sent 7 days before due date
- Email digest of upcoming inspections (daily/weekly)

---

## BR-12: GPS and Geofencing
**Priority:** Critical  
**Description:** Location-based features to verify inspector presence and streamline inspection workflow.

### Features:

#### GPS Tracking
- **Real-Time Location:**
  - Track inspector location during inspection shift (with consent)
  - Record GPS coordinates when inspection starts
  - Record GPS coordinates when inspection completes
  - Store GPS accuracy (meters) with each reading
  - Timestamp all GPS readings
  
- **Location Verification:**
  - Verify inspector is within 50 meters of location during inspection
  - Flag inspections conducted outside acceptable radius
  - Allow manual override with justification (indoor GPS issues)
  - Visual map showing inspector location vs. location address

#### Geofencing
- **Automatic Triggers:**
  - Push notification when inspector enters geofence: "You have 5 extinguishers to inspect at this location"
  - Auto-load location inspection list when entering geofence
  - Auto-suggest starting inspection when near extinguisher (5 meters)
  - Alert if inspector leaves location with incomplete inspections
  
- **Geofence Configuration:**
  - Set geofence radius per location (default 100 meters)
  - Larger radius for campuses, smaller for single buildings
  - Visual geofence editor on map
  - Test geofence with current location

#### Location Intelligence
- **Proximity Detection:**
  - Show nearby locations on map
  - "Inspect Next" suggestions based on current location
  - Distance and drive time to next location
  - Suggest opportunistic inspections (near current location, due soon)
  
- **Historical Tracking:**
  - Inspection heatmap (where inspections completed)
  - Inspector travel patterns
  - Time spent at each location
  - Compliance map (color-coded by status)

**Acceptance Criteria:**
- GPS coordinates captured with ±10 meter accuracy
- Geofence triggers work within 30 seconds of entry/exit
- Invalid GPS locations flagged for review
- Inspector location visible to location manager (real-time dashboard)
- Historical GPS data retained for 90 days
- Privacy controls: location tracked only during work hours with explicit consent

---

## BR-13: Push Notifications (Mobile)
**Priority:** High  
**Description:** Real-time notifications to keep inspectors informed and ensure timely inspections.

### Notification Types:

#### For Inspectors:
1. **Inspection Due Reminders:**
   - "You have 8 inspections due this week"
   - 7 days before: "5 inspections due next week"
   - On due date: "3 inspections due today"
   - Overdue: "2 inspections are now overdue"

2. **Geofence Notifications:**
   - Enter location: "3 extinguishers need inspection here"
   - Near extinguisher: "Extinguisher E-101 needs inspection (5m away)"
   - Exit with incomplete: "You have 1 incomplete inspection at this location"

3. **Assignment Notifications:**
   - "New inspection assigned: Main Office Building"
   - "Inspection reassigned from John Doe"
   - "Urgent: Annual inspection overdue by 15 days"

4. **Sync Notifications:**
   - "5 offline inspections synced successfully"
   - "Sync failed for 1 inspection - retry needed"
   - "Low storage: Clear old inspection photos"

5. **Schedule Changes:**
   - "Tomorrow's route optimized - 30 min saved"
   - "Weather alert: Plan indoor inspections"
   - "Location closed today - inspections rescheduled"

#### For Location Managers:
1. **Compliance Alerts:**
   - "5 extinguishers at Main Office overdue"
   - "Compliance dropped below 90% at Seattle locations"
   - "Monthly inspection cycle complete: 48/50 completed"

2. **Inspector Activity:**
   - "John completed 12 inspections today"
   - "Inspection failed: Extinguisher E-205 needs service"
   - "Inspector reported deficiency requiring attention"

3. **Approval Requests:**
   - "Review and approve 3 inspection reports"
   - "Service request submitted for approval"

#### For Tenant Admins:
1. **Reports Ready:**
   - "Monthly compliance report generated"
   - "Annual certification ready for download"

2. **System Alerts:**
   - "Approaching location limit (48/50)"
   - "Subscription renewal due in 30 days"

### Notification Delivery:
- **Push Notifications:** Mobile app (iOS/Android)
- **In-App Notifications:** Badge counts, notification center
- **Email Fallback:** If push disabled or not delivered
- **SMS Option:** For critical/urgent notifications (configurable)

### Notification Settings:
- **User Preferences:**
  - Enable/disable by category
  - Quiet hours (no notifications 10 PM - 7 AM)
  - Notification sound/vibration
  - Grouped vs. individual notifications
  
- **Admin Controls:**
  - Mandatory notifications (cannot be disabled)
  - Notification frequency caps
  - Emergency broadcast to all users

**Acceptance Criteria:**
- Push notifications delivered within 60 seconds
- 95% delivery success rate
- Users can customize notification preferences
- Critical notifications cannot be disabled
- Notification history viewable in app
- Deep links: tapping notification opens relevant screen

---

## BR-14: Mobile-Optimized Inspection Checklists
**Priority:** Critical  
**Description:** Streamlined, touch-friendly inspection checklists optimized for mobile use.

### Features:

#### Checklist Presentation:
- **One Item Per Screen:** 
  - Large touch targets (minimum 44x44pt)
  - Swipe to next/previous item
  - Progress indicator (Item 3 of 7)
  - Auto-advance after selection (configurable)
  
- **Quick Actions:**
  - Large Pass/Fail/NA buttons
  - Tap-and-hold for notes
  - Quick photo button (one tap to capture)
  - Voice-to-text for notes (hands-free)
  - Skip non-required items

#### Smart Checklists:
- **Contextual Items:**
  - Show only items relevant to extinguisher type
  - Skip items based on previous answers
  - Conditional logic (If pressure low, require photo)
  
- **Pre-filled Data:**
  - Remember common notes ("Pressure OK", "Located in hallway")
  - Quick-select common responses
  - Photo templates for recurring issues

#### Photo Capture:
- **Integrated Camera:**
  - One-tap photo capture
  - Auto-focus on gauge/pressure indicator
  - Photo required indicators
  - Multiple photos per item
  - Annotate photos (draw arrows, add text)
  
- **Photo Intelligence:**
  - Suggest retake if blurry
  - Warn if photo appears too dark
  - Compress photos automatically (reduce size 80%)
  - Offline queueing with progress indicator

#### Offline Mode:
- **Complete Offline Support:**
  - Download checklist templates
  - Download location/extinguisher data
  - Capture photos offline (stored locally)
  - Queue for upload when online
  - Conflict resolution if edited online
  
- **Offline Indicators:**
  - Clear "Offline Mode" banner
  - Queue count (3 inspections pending sync)
  - Storage space available
  - Estimated sync time when online

#### Voice Commands (Future):
- "Start inspection" - Begin new inspection
- "Pass" / "Fail" - Record checklist responses
- "Take photo" - Capture photo
- "Add note: [text]" - Dictate notes
- "Next" / "Previous" - Navigate items
- "Complete inspection" - Finalize and submit

**Acceptance Criteria:**
- Checklist completion time < 2 minutes for monthly inspection
- One-handed operation possible
- Works reliably offline
- Photos compress to < 500KB each
- Auto-save every 10 seconds
- Resume in-progress inspection from any device

---

## BR-15: Compliance Management and Reporting
**Priority:** High  
**Description:** Comprehensive compliance tracking with automated alerts and recommendations.

### Features:

#### Compliance Dashboard:
- **Real-Time Status:**
  - Overall compliance percentage (e.g., 94.2%)
  - Breakdown by location
  - Breakdown by extinguisher type
  - Trend over time (line chart)
  
- **Key Metrics:**
  - Inspections completed this month
  - Inspections due this week
  - Overdue inspections (with days overdue)
  - Average time to complete inspection
  - Inspector performance metrics

#### Predictive Compliance:
- **Risk Scoring:**
  - Locations at risk of non-compliance
  - Extinguishers with pattern of late inspections
  - Inspectors with incomplete work
  
- **Recommendations:**
  - "Add 2 more inspectors to maintain compliance"
  - "Schedule weekend catch-up for overdue inspections"
  - "Location X needs inspection every 25 days (short cycle)"
  
- **Forecasting:**
  - Projected compliance for next 30/60/90 days
  - Identify bottlenecks (inspector capacity, location access)
  - Budget forecasting for upcoming annual inspections

#### Automated Alerts:
- **Compliance Thresholds:**
  - Alert when compliance < 95%
  - Escalate when compliance < 90%
  - Critical alert when compliance < 80%
  
- **Proactive Warnings:**
  - "15 inspections due next week - schedule now"
  - "Location will be non-compliant in 5 days without action"
  - "Hydrostatic test due for 3 extinguishers this month"

#### Regulatory Reports:
- **Compliance Certificates:**
  - Auto-generate monthly compliance certificate
  - Include all inspection records
  - Digital signature with QR code verification
  - PDF suitable for regulatory submission
  
- **Audit Trail:**
  - Complete inspection history
  - All changes tracked (who, what, when)
  - Export audit log for external auditors
  - Tamper-proof with hash verification

**Acceptance Criteria:**
- Compliance percentage updated in real-time
- Alerts sent before locations become non-compliant
- Reports generated automatically by 5th of each month
- Audit trail passes external audit review
- Compliance certificates accepted by regulatory bodies

---

## BR-16: Location Management and Mapping
**Priority:** High  
**Description:** Comprehensive location management with GPS, indoor maps, and hierarchical structures.

### Features:

#### Location Hierarchy:
- **Multi-Level Structure:**
  - Campus > Building > Floor > Room
  - Custom levels (e.g., Warehouse > Section > Aisle)
  - Parent-child relationships
  - Inheritance of properties (contact info, access instructions)

#### GPS and Mapping:
- **Location Coordinates:**
  - Geocode address to coordinates
  - Manual pin placement on map
  - Verify coordinates before saving
  - Radius accuracy indicator
  
- **Map Views:**
  - List view: All locations with compliance status
  - Map view: Locations as pins (color-coded by status)
  - Cluster pins when zoomed out
  - Tap pin to see location details
  - Route from current location

#### Indoor Maps (Future):
- **Floor Plans:**
  - Upload building floor plans
  - Pin extinguishers on floor plan
  - Indoor navigation (ARKit/ARCore)
  - Print location maps for field use

#### Location Details:
- **Access Information:**
  - Building access hours
  - Security requirements
  - Contact person name/phone
  - Parking information
  - Special instructions
  
- **Inspection History:**
  - Last inspection date
  - Next due date
  - Compliance percentage
  - Extinguisher count
  - Failed inspections

**Acceptance Criteria:**
- GPS coordinates accurate within 10 meters
- Locations sortable by distance from current location
- Location hierarchy supports 5 levels deep
- Map view loads within 2 seconds
- Offline maps available for inspection areas

---

## BR-17: Inspector Efficiency Tools
**Priority:** High  
**Description:** Tools to maximize inspector productivity and minimize inspection time.

### Features:

#### Daily Route Planning:
- **Optimized Routes:**
  - Auto-generate daily route based on due inspections
  - Minimize total drive time
  - Account for location access hours
  - Suggest best start time
  
- **Route Export:**
  - One-tap export to navigation app
  - Multi-stop route support
  - Voice-guided navigation
  - Alternate route suggestions

#### Bulk Operations:
- **Batch Actions:**
  - Mark multiple extinguishers as "Inspected - Pass"
  - Bulk photo capture (scan location, take photos)
  - Copy notes to multiple inspections
  - Batch schedule changes
  
- **Quick Scan Mode:**
  - Scan barcode → Auto-load checklist → Rapid Pass/Fail
  - For monthly inspections with no issues
  - Complete inspection in < 30 seconds

#### Time Tracking:
- **Automatic Tracking:**
  - Start time when inspection begins
  - End time when completed
  - Calculate duration
  - Compare to estimated time
  
- **Analytics:**
  - Average time per inspection type
  - Time spent at each location
  - Travel time vs. inspection time
  - Productivity trends

#### Inspector Dashboard:
- **Today's Work:**
  - Inspections due today (sorted by route)
  - Completed count / Total count
  - Estimated completion time
  - Next location suggestion
  
- **Quick Stats:**
  - Inspections this week/month
  - Pass/fail rate
  - Performance vs. team average
  - Bonus/incentive tracking (optional)

**Acceptance Criteria:**
- Route optimization reduces travel time 30%+
- Bulk scan mode allows 20+ inspections per hour
- Time tracking accurate to the minute
- Inspector can complete daily work with < 5 taps

---

## Mobile-Specific Technical Requirements

### MR-1: Offline-First Architecture
**Priority:** Critical

**Requirements:**
- All critical features work without internet
- Local database with sync engine
- Queue for photos/inspections (unlimited size)
- Automatic sync when connectivity restored
- Clear sync status indicators

**Acceptance Criteria:**
- 100% of inspection workflow available offline
- Sync completes in < 2 minutes for daily work
- Conflict resolution for concurrent edits
- No data loss even if app crashes

---

### MR-2: Background Operations
**Priority:** High

**Requirements:**
- Background sync (iOS Background Fetch, Android WorkManager)
- Location tracking in background (opt-in)
- Push notifications while app closed
- Background upload of photos

**Acceptance Criteria:**
- Background sync runs every 15 minutes
- Battery drain < 5% per hour
- Background operations comply with OS guidelines
- User can disable background features

---

### MR-3: Camera Optimization
**Priority:** High

**Requirements:**
- Fast camera launch (< 1 second)
- Auto-focus and exposure
- Flash control
- Photo compression (80% reduction)
- EXIF data preservation

**Acceptance Criteria:**
- Photos captured in < 2 seconds
- Photos compressed without quality loss
- EXIF metadata includes GPS and timestamp
- Works in low-light conditions

---

### MR-4: Battery Optimization
**Priority:** Medium

**Requirements:**
- GPS only when inspecting (not constant)
- Aggressive photo compression
- Batch network requests
- Low-power mode support

**Acceptance Criteria:**
- Full day use (8 hours) with 50%+ battery
- No significant drain vs. other apps
- Battery usage displayed in settings
- Warning when battery < 20%

---

### MR-5: Mobile Device Management (MDM) Support
**Priority:** Medium (Enterprise)

**Requirements:**
- Compatible with enterprise MDM solutions
- Support app configuration (via MDM)
- Certificate-based authentication
- Remote wipe capability

**Acceptance Criteria:**
- Works with Microsoft Intune, VMware Workspace ONE
- App config pushed via MDM
- Complies with enterprise security policies

---

## Scheduling Database Schema Additions

### New Tables Required:

```sql
-- Inspection Schedules
CREATE TABLE [tenant_schema].InspectionSchedules (
    ScheduleId UNIQUEIDENTIFIER PRIMARY KEY,
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    FrequencyDays INT NOT NULL,
    LastCompletedDate DATE NULL,
    NextDueDate DATE NOT NULL,
    AssignedInspectorUserId UNIQUEIDENTIFIER NULL,
    ScheduleStatus NVARCHAR(50) NOT NULL, -- Active, Paused, Completed
    CreatedDate DATETIME2 NOT NULL
)

-- Inspector Routes
CREATE TABLE [tenant_schema].InspectorRoutes (
    RouteId UNIQUEIDENTIFIER PRIMARY KEY,
    InspectorUserId UNIQUEIDENTIFIER NOT NULL,
    RouteDate DATE NOT NULL,
    OptimizedSequence NVARCHAR(MAX) NOT NULL, -- JSON array of location IDs
    TotalDistance DECIMAL(10,2) NULL, -- kilometers
    EstimatedDuration INT NULL, -- minutes
    Status NVARCHAR(50) NOT NULL, -- Planned, InProgress, Completed
    CreatedDate DATETIME2 NOT NULL
)

-- Geofences
CREATE TABLE [tenant_schema].LocationGeofences (
    GeofenceId UNIQUEIDENTIFIER PRIMARY KEY,
    LocationId UNIQUEIDENTIFIER NOT NULL,
    CenterLatitude DECIMAL(9,6) NOT NULL,
    CenterLongitude DECIMAL(9,6) NOT NULL,
    RadiusMeters INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL
)

-- Push Notification Subscriptions
CREATE TABLE dbo.PushNotificationSubscriptions (
    SubscriptionId UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    DeviceToken NVARCHAR(500) NOT NULL,
    Platform NVARCHAR(20) NOT NULL, -- iOS, Android
    IsActive BIT NOT NULL DEFAULT 1,
    LastUsed DATETIME2 NOT NULL,
    CreatedDate DATETIME2 NOT NULL
)

-- Notification Preferences
CREATE TABLE dbo.UserNotificationPreferences (
    PreferenceId UNIQUEIDENTIFIER PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    NotificationType NVARCHAR(100) NOT NULL,
    IsEnabled BIT NOT NULL DEFAULT 1,
    QuietHoursStart TIME NULL,
    QuietHoursEnd TIME NULL,
    CreatedDate DATETIME2 NOT NULL
)
```

---

This enhanced requirements document ensures the system will maximize inspector efficiency, maintain compliance, and provide a world-class mobile experience with GPS, geofencing, and intelligent scheduling.
