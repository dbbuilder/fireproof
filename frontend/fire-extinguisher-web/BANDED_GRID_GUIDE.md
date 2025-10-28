# Banded Grid Component - High-Volume Data Solution

## Overview

The `BandedGrid` component is a scalable, reusable data grid designed to replace card-based layouts for high-volume locations (hospitals, large campuses, etc.). It provides:

- **Expandable rows** for detailed information
- **Client-side pagination** (10, 25, 50, 100 items per page)
- **Column sorting**
- **Location and status filtering**
- **Responsive banded design** (alternating row colors)
- **Custom cell templates** (badges, icons, formatted data)
- **Action buttons** (edit, delete, QR code generation)

## Problem Solved

The original card-based layout (`ExtinguishersView.vue`) displayed ALL extinguishers at once in a 3-column grid. For hospitals with 500+ extinguishers, this created:
- Long page load times
- Excessive scrolling
- No way to filter or search efficiently
- Poor performance on mobile devices

## Solution

The new `BandedGrid` component provides:
- **Pagination**: Display 25-100 items per page (configurable)
- **Filters**: Search, location, type, and status filters
- **Expandable rows**: Click to see full details without navigation
- **Column sorting**: Click headers to sort by any column
- **Responsive stats**: Stats update based on filters

## Component Location

- **Grid Component**: `/src/components/BandedGrid.vue`
- **Example Usage**: `/src/views/ExtinguishersViewGrid.vue`

## Basic Usage

```vue
<template>
  <BandedGrid
    :data="filteredData"
    :columns="gridColumns"
    :expandable="true"
    :paginated="true"
    :items-per-page="50"
    :row-key="'id'"
    @row-click="handleRowClick"
    @sort-change="handleSortChange"
  >
    <!-- Custom cell templates -->
    <template #cell-status="{ row }">
      <span class="badge-success">{{ row.status }}</span>
    </template>

    <!-- Expanded content -->
    <template #expanded-content="{ row }">
      <div class="p-4">
        <p>{{ row.detailedInfo }}</p>
      </div>
    </template>
  </BandedGrid>
</template>

<script setup>
const gridColumns = [
  { key: 'code', label: 'Code', width: '150px', sortable: true },
  { key: 'status', label: 'Status', width: '120px', sortable: false },
  { key: 'location', label: 'Location', width: '200px', sortable: true }
]
</script>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `data` | Array | **required** | Array of data objects to display |
| `columns` | Array | **required** | Column configuration (see Column Configuration) |
| `expandable` | Boolean | `false` | Enable expandable rows |
| `paginated` | Boolean | `true` | Enable pagination |
| `itemsPerPage` | Number | `25` | Items per page (10, 25, 50, 100) |
| `emptyMessage` | String | `'No data available'` | Message when no data |
| `rowKey` | String | `'id'` | Property to use as unique row key |
| `rowClass` | Function | `null` | Function to return custom row class |

## Column Configuration

```javascript
const columns = [
  {
    key: 'fieldName',           // Property name in data object
    label: 'Display Name',      // Column header text
    width: '150px',             // Column width (optional)
    sortable: true,             // Enable sorting (optional)
    align: 'left',              // Text alignment: 'left', 'center', 'right' (optional)
    format: (value, row) => {}  // Custom formatter function (optional)
  }
]
```

## Events

### `@row-click`
Emitted when a row is clicked (expandable rows).

```javascript
const handleRowClick = (row) => {
  console.log('Clicked row:', row)
}
```

### `@sort-change`
Emitted when column sort changes.

```javascript
const handleSortChange = (sortBy, direction) => {
  console.log('Sort by:', sortBy, direction) // direction: 'asc' or 'desc'
}
```

## Slot Templates

### Cell Templates

Customize individual column rendering:

```vue
<template #cell-columnKey="{ row, value }">
  <!-- Custom rendering for specific column -->
  <span class="font-bold">{{ value }}</span>
</template>
```

Example for status badges:

```vue
<template #cell-status="{ row }">
  <span
    v-if="row.isActive"
    class="badge-success text-xs"
  >
    Active
  </span>
  <span
    v-else
    class="badge-danger text-xs"
  >
    Inactive
  </span>
</template>
```

### Expanded Content Template

Define content shown when row is expanded:

```vue
<template #expanded-content="{ row, index }">
  <div class="p-6 bg-white">
    <div class="grid grid-cols-3 gap-6">
      <!-- Detailed information -->
      <div>
        <h4 class="font-semibold mb-3">Details</h4>
        <dl class="space-y-2 text-sm">
          <div>
            <dt class="text-gray-500">Manufacturer</dt>
            <dd class="text-gray-900">{{ row.manufacturer }}</dd>
          </div>
        </dl>
      </div>
    </div>
  </div>
</template>
```

### Empty State Template

Customize empty state display:

```vue
<template #empty>
  <div class="p-12 text-center">
    <p class="text-gray-500">No items found</p>
    <button class="btn-primary mt-4">Add First Item</button>
  </div>
</template>
```

## Row Styling

Use `rowClass` prop to conditionally style rows:

```javascript
const getRowClass = (row) => {
  if (row.isOutOfService) {
    return 'bg-red-50 border-l-4 border-red-500'
  }
  if (needsAttention(row)) {
    return 'bg-accent-50 border-l-4 border-accent-500'
  }
  return ''
}
```

```vue
<BandedGrid
  :data="data"
  :columns="columns"
  :row-class="getRowClass"
/>
```

## Filtering Pattern

Implement client-side filtering with computed property:

```javascript
const filters = ref({
  search: '',
  locationId: '',
  status: ''
})

const filteredData = computed(() => {
  let filtered = allData.value

  // Search filter
  if (filters.value.search) {
    const search = filters.value.search.toLowerCase()
    filtered = filtered.filter(item =>
      item.code?.toLowerCase().includes(search) ||
      item.name?.toLowerCase().includes(search)
    )
  }

  // Location filter
  if (filters.value.locationId) {
    filtered = filtered.filter(item =>
      item.locationId === filters.value.locationId
    )
  }

  // Status filter
  if (filters.value.status) {
    filtered = filtered.filter(item =>
      item.status === filters.value.status
    )
  }

  return filtered
})
```

## Performance Tips

### For 1000+ Items:

1. **Enable pagination**: Set `itemsPerPage` to 50-100
2. **Use server-side filtering**: Move filters to API calls
3. **Lazy load details**: Only fetch expanded content when needed
4. **Virtual scrolling**: For extreme cases (10,000+ items), consider `vue-virtual-scroller`

### For 100-1000 Items:

1. **Client-side filtering**: Filter in computed property (as shown above)
2. **Pagination**: 25-50 items per page
3. **Indexed data**: Use Maps for lookups instead of arrays

### For <100 Items:

1. **Disable pagination**: Set `:paginated="false"`
2. **Simple filtering**: Client-side is fine
3. **Load all data**: No lazy loading needed

## Exposed Methods

Parent components can call these methods:

```javascript
import { ref } from 'vue'

const gridRef = ref()

// Go to specific page
gridRef.value.goToPage(3)

// Collapse all expanded rows
gridRef.value.collapseAll()

// Expand all rows
gridRef.value.expandAll()
```

## Complete Example: Extinguishers View

See `/src/views/ExtinguishersViewGrid.vue` for a complete implementation including:

- **4 stat cards** with filtered counts
- **Search filter** (code, serial, manufacturer)
- **Location filter** (dropdown)
- **Type filter** (dropdown)
- **Status filter** (active, inactive, out-of-service, needs-attention)
- **Expandable rows** with service history, notes, and dates
- **Custom cell templates** for status badges, dates, icons
- **Action buttons** (edit, QR code, delete)
- **Row highlighting** (red for out-of-service, amber for needs attention)
- **Pagination** (50 items per page)
- **Column sorting** (code, type, location, next service date)

## Migration Path

### Step 1: Create New Grid View

Create a new file (e.g., `ExtinguishersViewGrid.vue`) alongside the existing view.

### Step 2: Test in Isolation

Test the new grid view with production data to ensure performance.

### Step 3: Feature Flag (Optional)

Add a feature flag to toggle between old and new views:

```javascript
const useGridView = ref(localStorage.getItem('useGridView') === 'true')
```

### Step 4: Replace Original

Once tested, replace the original view or update router to use the new view.

## Accessibility

The grid includes proper accessibility features:

- **ARIA labels** on expand buttons
- **Keyboard navigation** (Tab through rows, Enter to expand)
- **Screen reader support** (row counts, pagination info)
- **Test IDs** for automated testing

## Test IDs

All key elements include `data-testid` attributes:

- `banded-grid` - Grid container
- `grid-header` - Header row
- `header-{columnKey}` - Individual headers
- `grid-body` - Body container
- `row-{index}` - Data rows
- `cell-{columnKey}-{index}` - Individual cells
- `expand-btn-{index}` - Expand buttons
- `expanded-{index}` - Expanded content
- `grid-empty-state` - Empty state
- `grid-pagination` - Pagination controls
- `pagination-first/prev/next/last` - Navigation buttons
- `pagination-page-{page}` - Page numbers
- `pagination-per-page` - Items per page selector

## Styling

The component uses Tailwind CSS with custom classes:

- `.card` - Card container
- `.badge-*` - Status badges (success, danger, warning, secondary)
- `.btn-primary` - Primary button
- `.btn-outline` - Outline button
- `.form-input` - Input fields
- `.form-label` - Form labels

## Future Enhancements

Potential improvements:

1. **Server-side pagination** - For 10,000+ items
2. **Column resize** - Drag to resize columns
3. **Column reorder** - Drag to reorder columns
4. **Column visibility** - Show/hide columns
5. **Export to CSV** - Download filtered data
6. **Bulk actions** - Select multiple rows
7. **Inline editing** - Edit cells directly in grid
8. **Virtual scrolling** - For extreme performance needs

## Support

For questions or issues:
- Check `ExtinguishersViewGrid.vue` for complete example
- Review `BandedGrid.vue` component source
- Contact development team for customization needs
