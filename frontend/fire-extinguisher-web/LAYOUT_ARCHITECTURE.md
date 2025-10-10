# FireProof UI Layout Architecture

## Design Principles

### 1. Intuitive Navigation
- Clear visual hierarchy
- Consistent placement of elements
- Breadcrumbs for context
- Active state indicators

### 2. Professional Appearance
- Clean, modern interface
- Consistent spacing (8px grid system)
- Subtle animations (200ms transitions)
- Professional color palette

### 3. Responsive Design
- Desktop: Full sidebar + content area
- Tablet: Collapsible sidebar
- Mobile: Bottom navigation + hamburger menu

### 4. User-Centric
- Most common actions easily accessible
- Clear feedback on all interactions
- Loading states for all async operations
- Error handling with helpful messages

---

## Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│ AppHeader (60px fixed height)                               │
│ ┌─────┐ FireProof    [Search]    🔔 👤 UserName ▾          │
│ └─────┘                                                      │
├─────────────────────────────────────────────────────────────┤
│         │                                                    │
│ Sidebar │ Main Content Area                                 │
│ (240px) │                                                    │
│         │ ┌────────────────────────────────────────────┐    │
│ 📊 Dash │ │ Page Header                                 │    │
│ 📍 Loca │ │ ├─ Breadcrumbs                              │    │
│ 🧯 Exti │ │ ├─ Page Title                               │    │
│ ✓ Inspe │ │ └─ Action Buttons                           │    │
│ 📄 Repo │ ├────────────────────────────────────────────┤    │
│ ⚙ Setti │ │                                             │    │
│         │ │ Page Content                                │    │
│         │ │                                             │    │
│         │ │                                             │    │
│         │ └────────────────────────────────────────────┘    │
│         │                                                    │
└─────────┴────────────────────────────────────────────────────┘
```

---

## Component Hierarchy

### AppLayout.vue (Root Layout)
```vue
<template>
  <div class="min-h-screen bg-gray-50">
    <AppHeader @toggle-sidebar="toggleSidebar" />
    <div class="flex h-[calc(100vh-60px)]">
      <AppSidebar :is-open="sidebarOpen" @close="closeSidebar" />
      <main class="flex-1 overflow-y-auto">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <slot />
        </div>
      </main>
    </div>
  </div>
</template>
```

**Responsibilities**:
- Overall page structure
- Sidebar state management (open/closed)
- Responsive behavior coordination
- Scrolling container for main content

**State**:
- `sidebarOpen` (boolean) - Controls sidebar visibility on mobile

---

### AppHeader.vue (Top Navigation)

**Layout** (60px height):
```
┌──────────────────────────────────────────────────────────┐
│ [☰] Logo  FireProof    [Search Box]     🔔  👤 Name ▾   │
└──────────────────────────────────────────────────────────┘
```

**Components**:
1. **Hamburger Menu** (mobile only)
   - Icon: Bars3Icon
   - Action: Toggle sidebar
   - Visible: < 1024px

2. **Logo + Brand**
   - Icon: Fire emoji or custom logo
   - Text: "FireProof"
   - Link: /dashboard
   - Font: Lexend, font-semibold

3. **Search Bar** (desktop only)
   - Placeholder: "Search extinguishers, locations..."
   - Icon: MagnifyingGlassIcon
   - Action: Global search
   - Width: 320px max
   - Visible: >= 1024px

4. **Notifications** (future feature)
   - Icon: BellIcon
   - Badge: Count of unread notifications
   - Dropdown: Recent notifications

5. **User Menu**
   - Avatar: User initials or photo
   - Name: First name + Last name
   - Dropdown:
     - Profile
     - Settings
     - Help & Support
     - Sign Out

**Functionality**:
- Fixed position at top
- z-index: 40 (above content, below modals)
- Background: white with border-b
- Shadow on scroll

---

### AppSidebar.vue (Navigation Menu)

**Desktop Layout** (240px width):
```
┌──────────────────┐
│ 📊 Dashboard     │ ← Active state: bg-primary-50
│ 📍 Locations     │
│ 🧯 Extinguishers │
│ ✓ Inspections    │
│ 📄 Reports       │
│ ───────────────  │
│ ⚙ Settings       │
└──────────────────┘
```

**Navigation Items**:
1. **Dashboard**
   - Icon: ChartBarIcon
   - Route: /dashboard
   - Description: "Overview and metrics"

2. **Locations**
   - Icon: MapPinIcon
   - Route: /locations
   - Description: "Manage facilities"

3. **Extinguishers**
   - Icon: Fire icon (custom or ShieldCheckIcon)
   - Route: /extinguishers
   - Description: "Manage equipment"
   - Badge: Count of due inspections

4. **Inspections**
   - Icon: ClipboardDocumentCheckIcon
   - Route: /inspections
   - Description: "Perform inspections"
   - Badge: Count of overdue

5. **Reports**
   - Icon: DocumentTextIcon
   - Route: /reports
   - Description: "Compliance reports"

6. **Settings** (bottom of sidebar)
   - Icon: Cog6ToothIcon
   - Route: /settings
   - Description: "Account settings"

**States**:
- **Active**: bg-primary-50, text-primary-700, font-medium
- **Inactive**: text-gray-600, hover:bg-gray-50
- **Disabled**: opacity-50, cursor-not-allowed

**Mobile Behavior**:
- Overlay sidebar (fixed position)
- Backdrop with click-to-close
- Slide-in animation from left
- Close button in top-right

**Responsive Breakpoints**:
- Desktop (>= 1024px): Always visible, 240px width
- Tablet (768px - 1023px): Overlay, full height
- Mobile (< 768px): Overlay, 80% width max

---

## Page Structure Template

Every page follows this structure:

```vue
<template>
  <div>
    <!-- Breadcrumbs -->
    <nav class="mb-4">
      <ol class="flex items-center space-x-2 text-sm">
        <li><a href="/dashboard">Dashboard</a></li>
        <li class="text-gray-400">/</li>
        <li class="text-gray-600">Locations</li>
      </ol>
    </nav>

    <!-- Page Header -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-3xl font-display font-semibold text-gray-900">
          Locations
        </h1>
        <p class="mt-1 text-sm text-gray-500">
          Manage your facility locations
        </p>
      </div>
      <div class="flex gap-3">
        <button class="btn-outline">
          Export
        </button>
        <button class="btn-primary">
          Add Location
        </button>
      </div>
    </div>

    <!-- Page Content -->
    <div class="space-y-6">
      <!-- Content cards, tables, etc -->
    </div>
  </div>
</template>
```

**Elements**:
1. **Breadcrumbs** (optional for top-level pages)
   - Shows navigation path
   - Each item clickable except current page
   - Separator: "/" or ChevronRightIcon

2. **Page Header**
   - Left: Title + description
   - Right: Primary actions
   - Spacing: mb-8

3. **Page Content**
   - Cards with shadow-soft
   - Consistent spacing (space-y-6)
   - Max width: max-w-7xl

---

## Common UI Patterns

### 1. List/Table View Pattern
```vue
<div class="card">
  <!-- Header with search and filters -->
  <div class="card-header flex items-center justify-between">
    <div class="flex-1">
      <input type="text" placeholder="Search..." class="form-input" />
    </div>
    <div class="flex gap-2">
      <select class="form-input">
        <option>All Statuses</option>
      </select>
    </div>
  </div>

  <!-- Table -->
  <div class="table-container">
    <table class="table">
      <thead>
        <tr>
          <th>Column 1</th>
          <th>Column 2</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <!-- Rows -->
      </tbody>
    </table>
  </div>

  <!-- Pagination -->
  <div class="card-footer">
    <!-- Pagination component -->
  </div>
</div>
```

### 2. Form Pattern
```vue
<form class="space-y-6">
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <div>
      <label class="form-label">Field Name</label>
      <input type="text" class="form-input" />
      <p class="form-helper">Helper text</p>
    </div>
  </div>

  <div class="flex justify-end gap-3">
    <button type="button" class="btn-outline">Cancel</button>
    <button type="submit" class="btn-primary">Save</button>
  </div>
</form>
```

### 3. Empty State Pattern
```vue
<div class="card">
  <div class="card-body text-center py-12">
    <Icon class="h-12 w-12 mx-auto text-gray-400" />
    <h3 class="mt-4 text-lg font-medium text-gray-900">
      No items found
    </h3>
    <p class="mt-2 text-sm text-gray-500">
      Get started by creating a new item
    </p>
    <button class="btn-primary mt-6">
      Create Item
    </button>
  </div>
</div>
```

### 4. Loading State Pattern
```vue
<div class="flex items-center justify-center py-12">
  <div class="text-center">
    <div class="spinner-lg text-primary-600 mx-auto"></div>
    <p class="mt-4 text-sm text-gray-500">Loading...</p>
  </div>
</div>
```

---

## Interaction Patterns

### 1. Button Actions
- **Primary Action**: btn-primary (one per page)
- **Secondary Actions**: btn-outline
- **Destructive Actions**: btn-danger
- **Loading State**: Show spinner + disable
- **Success**: Brief toast notification

### 2. Form Validation
- **Real-time**: Validate on blur
- **Submit**: Validate all fields
- **Error Display**: Red border + error message below field
- **Success**: Green checkmark icon

### 3. Async Operations
- **Before**: Show loading spinner
- **During**: Disable relevant buttons
- **Success**: Toast notification + update UI
- **Error**: Alert with retry option

### 4. Modals
- **Open**: Scale-in animation
- **Backdrop**: Click to close (with confirmation if dirty)
- **Close Button**: X in top-right
- **Actions**: Cancel (left) + Primary (right)

---

## Accessibility Checklist

- [ ] All interactive elements keyboard accessible
- [ ] Focus visible on all focusable elements
- [ ] ARIA labels for icon-only buttons
- [ ] Skip to main content link
- [ ] Semantic HTML (nav, main, aside, section)
- [ ] Alt text for all images
- [ ] Color contrast ratio >= 4.5:1
- [ ] Form labels associated with inputs
- [ ] Error messages announced to screen readers

---

## Performance Considerations

1. **Code Splitting**: Each route lazy-loaded
2. **Image Optimization**: WebP format, lazy loading
3. **Bundle Size**: Track and minimize
4. **Caching**: Service worker for offline support
5. **API Calls**: Debounce search, cache results

---

## Next Steps

1. Create AppLayout.vue ✓ (planned)
2. Create AppHeader.vue ✓ (planned)
3. Create AppSidebar.vue ✓ (planned)
4. Create common components (Button, Input, Card)
5. Build authentication views
6. Build each feature module
