<template>
  <div class="banded-grid" data-testid="banded-grid">
    <!-- Header Row -->
    <div
      class="grid-header"
      data-testid="grid-header"
      :style="{ gridTemplateColumns: gridTemplateColumns }"
    >
      <div
        v-for="column in columns"
        :key="column.key"
        :class="['header-cell', column.sortable && 'sortable']"
        @click="column.sortable && handleSort(column.key)"
        :data-testid="`header-${column.key}`"
      >
        <span>{{ column.label }}</span>
        <span v-if="column.sortable && sortBy === column.key" class="sort-indicator">
          {{ sortDirection === 'asc' ? '↑' : '↓' }}
        </span>
      </div>
      <div v-if="expandable" class="header-cell" style="width: 50px"></div>
    </div>

    <!-- Data Rows -->
    <div class="grid-body" data-testid="grid-body">
      <template v-if="paginatedData.length > 0">
        <div
          v-for="(row, index) in paginatedData"
          :key="getRowKey(row, index)"
          :class="['grid-row-group', { 'expanded': expandedRows.has(getRowKey(row, index)) }]"
          :data-testid="`row-${index}`"
        >
          <!-- Main Row -->
          <div
            :class="[
              'grid-row',
              index % 2 === 0 ? 'row-even' : 'row-odd',
              rowClass && rowClass(row),
              swipedRow === getRowKey(row, index) && 'swiped'
            ]"
            :style="{
              gridTemplateColumns: gridTemplateColumns,
              transform: swipedRow === getRowKey(row, index) ? 'translateX(-80px)' : 'translateX(0)'
            }"
            @click="expandable && toggleRow(row, index)"
            @touchstart="handleSwipeStart($event, row, index)"
            @touchmove="handleSwipeMove"
            @touchend="handleSwipeEnd"
          >
            <div
              v-for="column in columns"
              :key="column.key"
              :class="['grid-cell', column.align && `text-${column.align}`]"
              :data-testid="`cell-${column.key}-${index}`"
            >
              <slot :name="`cell-${column.key}`" :row="row" :value="row[column.key]">
                {{ column.format ? column.format(row[column.key], row) : row[column.key] }}
              </slot>
            </div>

            <!-- Expand Button -->
            <div v-if="expandable" class="grid-cell expand-cell" style="width: 50px">
              <button
                class="expand-btn"
                @click.stop="toggleRow(row, index)"
                :data-testid="`expand-btn-${index}`"
                :aria-label="expandedRows.has(getRowKey(row, index)) ? 'Collapse' : 'Expand'"
              >
                <svg
                  :class="['expand-icon', { 'rotated': expandedRows.has(getRowKey(row, index)) }]"
                  width="16"
                  height="16"
                  viewBox="0 0 16 16"
                  fill="currentColor"
                >
                  <path d="M4 6l4 4 4-4z" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Expanded Content (Desktop: inline, Mobile: bottom sheet) -->
          <transition name="expand">
            <div
              v-if="expandable && expandedRows.has(getRowKey(row, index))"
              :class="['expanded-content', isMobile && 'md:relative']"
              :data-testid="`expanded-${index}`"
            >
              <slot name="expanded-content" :row="row" :index="index">
                <div class="p-4 text-gray-600">
                  No expanded content defined
                </div>
              </slot>
            </div>
          </transition>
        </div>
      </template>

      <!-- Mobile Bottom Sheet Overlay -->
      <teleport to="body">
        <transition name="fade">
          <div
            v-if="expandedRows.size > 0 && isMobile"
            class="fixed inset-0 bg-black bg-opacity-50 z-40 md:hidden"
            @click="collapseAll"
            data-testid="bottom-sheet-overlay"
          ></div>
        </transition>
      </teleport>

      <!-- Empty State -->
      <div v-else class="empty-state" data-testid="grid-empty-state">
        <slot name="empty">
          <p class="text-gray-500 text-center py-8">{{ emptyMessage }}</p>
        </slot>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="paginated && totalPages > 1" class="grid-footer" data-testid="grid-pagination">
      <div class="pagination-info">
        Showing {{ startIndex + 1 }} to {{ endIndex }} of {{ totalRows }} items
      </div>
      <div class="pagination-controls">
        <button
          class="pagination-btn"
          :disabled="currentPage === 1"
          @click="goToPage(1)"
          data-testid="pagination-first"
        >
          First
        </button>
        <button
          class="pagination-btn"
          :disabled="currentPage === 1"
          @click="goToPage(currentPage - 1)"
          data-testid="pagination-prev"
        >
          Previous
        </button>

        <div class="page-numbers">
          <button
            v-for="page in visiblePages"
            :key="page"
            :class="['page-btn', { 'active': page === currentPage }]"
            @click="goToPage(page)"
            :data-testid="`pagination-page-${page}`"
          >
            {{ page }}
          </button>
        </div>

        <button
          class="pagination-btn"
          :disabled="currentPage === totalPages"
          @click="goToPage(currentPage + 1)"
          data-testid="pagination-next"
        >
          Next
        </button>
        <button
          class="pagination-btn"
          :disabled="currentPage === totalPages"
          @click="goToPage(totalPages)"
          data-testid="pagination-last"
        >
          Last
        </button>
      </div>

      <div class="per-page-selector">
        <label for="per-page">Per page:</label>
        <select
          id="per-page"
          v-model="itemsPerPageValue"
          class="per-page-select"
          data-testid="pagination-per-page"
        >
          <option :value="10">10</option>
          <option :value="25">25</option>
          <option :value="50">50</option>
          <option :value="100">100</option>
        </select>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

interface Column {
  key: string
  label: string
  width?: string
  sortable?: boolean
  align?: 'left' | 'center' | 'right'
  format?: (value: any, row: any) => string
}

interface Props {
  data: any[]
  columns: Column[]
  expandable?: boolean
  paginated?: boolean
  itemsPerPage?: number
  emptyMessage?: string
  rowKey?: string
  rowClass?: (row: any) => string
}

const props = withDefaults(defineProps<Props>(), {
  expandable: false,
  paginated: true,
  itemsPerPage: 25,
  emptyMessage: 'No data available',
  rowKey: 'id'
})

const emit = defineEmits<{
  (e: 'row-click', row: any): void
  (e: 'sort-change', sortBy: string, direction: 'asc' | 'desc'): void
}>()

// Sorting
const sortBy = ref<string>('')
const sortDirection = ref<'asc' | 'desc'>('asc')

// Pagination
const currentPage = ref(1)
const itemsPerPageValue = ref(props.itemsPerPage)

// Expandable rows
const expandedRows = ref<Set<string | number>>(new Set())

// Swipe gesture state
const swipedRow = ref<string | number | null>(null)
const swipeStartX = ref(0)
const swipeStartY = ref(0)
const swipeCurrentX = ref(0)
const swipeCurrentRow = ref<any>(null)
const swipeCurrentIndex = ref<number | null>(null)

// Mobile detection
const isMobile = ref(window.innerWidth < 768)

// Computed
const gridTemplateColumns = computed(() => {
  const widths = props.columns.map(col => col.width || 'minmax(100px, 1fr)')
  if (props.expandable) {
    widths.push('50px') // Expand button column
  }
  return widths.join(' ')
})

const sortedData = computed(() => {
  if (!sortBy.value) return props.data

  return [...props.data].sort((a, b) => {
    const aVal = a[sortBy.value]
    const bVal = b[sortBy.value]

    if (aVal === bVal) return 0

    const comparison = aVal < bVal ? -1 : 1
    return sortDirection.value === 'asc' ? comparison : -comparison
  })
})

const totalRows = computed(() => sortedData.value.length)

const totalPages = computed(() => {
  if (!props.paginated) return 1
  return Math.ceil(totalRows.value / itemsPerPageValue.value)
})

const startIndex = computed(() => {
  if (!props.paginated) return 0
  return (currentPage.value - 1) * itemsPerPageValue.value
})

const endIndex = computed(() => {
  if (!props.paginated) return totalRows.value
  return Math.min(startIndex.value + itemsPerPageValue.value, totalRows.value)
})

const paginatedData = computed(() => {
  if (!props.paginated) return sortedData.value
  return sortedData.value.slice(startIndex.value, endIndex.value)
})

const visiblePages = computed(() => {
  const pages: number[] = []
  const maxVisible = 5
  let start = Math.max(1, currentPage.value - Math.floor(maxVisible / 2))
  let end = Math.min(totalPages.value, start + maxVisible - 1)

  if (end - start < maxVisible - 1) {
    start = Math.max(1, end - maxVisible + 1)
  }

  for (let i = start; i <= end; i++) {
    pages.push(i)
  }

  return pages
})

// Methods
function handleSort(key: string) {
  if (sortBy.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortBy.value = key
    sortDirection.value = 'asc'
  }

  emit('sort-change', sortBy.value, sortDirection.value)
}

function toggleRow(row: any, index: number) {
  const key = getRowKey(row, index)
  if (expandedRows.value.has(key)) {
    expandedRows.value.delete(key)
  } else {
    expandedRows.value.add(key)
  }

  emit('row-click', row)
}

function getRowKey(row: any, index: number): string | number {
  return row[props.rowKey] ?? index
}

function goToPage(page: number) {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page
  }
}

// Watch for items per page changes
watch(itemsPerPageValue, () => {
  currentPage.value = 1
})

// Watch for data changes
watch(() => props.data, () => {
  currentPage.value = 1
  expandedRows.value.clear()
  swipedRow.value = null
})

// Swipe gesture functions
function handleSwipeStart(event: TouchEvent, row: any, index: number) {
  if (!isMobile.value) return

  swipeStartX.value = event.touches[0].clientX
  swipeStartY.value = event.touches[0].clientY
  swipeCurrentRow.value = row
  swipeCurrentIndex.value = index
}

function handleSwipeMove(event: TouchEvent) {
  if (!isMobile.value || swipeCurrentRow.value === null) return

  swipeCurrentX.value = event.touches[0].clientX
  const deltaX = swipeCurrentX.value - swipeStartX.value
  const deltaY = event.touches[0].clientY - swipeStartY.value

  // Only process horizontal swipes (not vertical scrolling)
  if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 10) {
    event.preventDefault()
  }
}

function handleSwipeEnd() {
  if (!isMobile.value || swipeCurrentRow.value === null) return

  const deltaX = swipeCurrentX.value - swipeStartX.value
  const rowKey = getRowKey(swipeCurrentRow.value, swipeCurrentIndex.value!)

  // Swipe left to reveal actions (threshold: 50px)
  if (deltaX < -50) {
    swipedRow.value = rowKey
  } else {
    swipedRow.value = null
  }

  // Reset
  swipeCurrentRow.value = null
  swipeCurrentIndex.value = null
  swipeStartX.value = 0
  swipeCurrentX.value = 0
}

// Handle window resize for mobile detection
const handleResize = () => {
  isMobile.value = window.innerWidth < 768
  if (!isMobile.value) {
    swipedRow.value = null
  }
}

// Expose methods for parent components
defineExpose({
  goToPage,
  collapseAll: () => {
    expandedRows.value.clear()
    swipedRow.value = null
  },
  expandAll: () => {
    props.data.forEach((row, index) => {
      expandedRows.value.add(getRowKey(row, index))
    })
  }
})

// Lifecycle hooks
onMounted(() => {
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.banded-grid {
  @apply w-full bg-white rounded-lg shadow overflow-hidden;
}

/* Mobile optimizations */
@media (max-width: 768px) {
  .banded-grid {
    @apply overflow-x-auto;
  }

  .grid-header,
  .grid-row {
    min-width: 800px; /* Ensure minimum width for horizontal scroll */
  }

  .grid-cell {
    @apply px-2 py-2 text-sm; /* Reduce padding on mobile */
  }

  .header-cell {
    @apply px-2 py-2 text-xs; /* Smaller header text */
  }
}

.grid-header {
  @apply grid gap-0 bg-gray-100 border-b-2 border-gray-300 font-semibold text-sm text-gray-700;
  position: sticky;
  top: 0;
  z-index: 10;
}

.header-cell {
  @apply px-4 py-3 flex items-center gap-2 border-r border-gray-200 last:border-r-0;
}

.header-cell.sortable {
  @apply cursor-pointer hover:bg-gray-200 transition-colors select-none;
}

.sort-indicator {
  @apply text-blue-600 font-bold;
}

.grid-body {
  @apply divide-y divide-gray-200;
}

.grid-row-group {
  @apply transition-all duration-200;
}

.grid-row {
  @apply grid gap-0 cursor-pointer hover:bg-gray-50 transition-colors;
  transition: transform 0.3s ease-out;
}

.grid-row.swiped {
  @apply shadow-lg;
}

.row-even {
  @apply bg-white;
}

.row-odd {
  @apply bg-gray-50;
}

.grid-cell {
  @apply px-4 py-3 border-r border-gray-200 last:border-r-0 flex items-center;
}

.expand-cell {
  @apply justify-center;
}

.expand-btn {
  @apply p-1 rounded hover:bg-gray-200 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500;
}

/* Mobile: Larger touch targets */
@media (max-width: 768px) {
  .expand-btn {
    @apply p-3; /* Larger touch area */
  }
}

.expand-icon {
  @apply transition-transform duration-200;
}

.expand-icon.rotated {
  @apply rotate-180;
}

.expanded-content {
  @apply bg-gray-50 border-t border-gray-200;
}

/* Mobile Bottom Sheet */
@media (max-width: 768px) {
  .expanded-content {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 50;
    max-height: 70vh;
    overflow-y: auto;
    @apply bg-white rounded-t-2xl shadow-2xl border-t-0;
  }
}

/* Transition for expand/collapse */
.expand-enter-active,
.expand-leave-active {
  @apply transition-all duration-300 overflow-hidden;
}

.expand-enter-from,
.expand-leave-to {
  @apply max-h-0 opacity-0;
}

.expand-enter-to,
.expand-leave-from {
  @apply max-h-[1000px] opacity-100;
}

.empty-state {
  @apply py-12 text-center;
}

.grid-footer {
  @apply flex items-center justify-between px-4 py-3 bg-gray-50 border-t border-gray-200 flex-wrap gap-4;
}

.pagination-info {
  @apply text-sm text-gray-700;
}

.pagination-controls {
  @apply flex items-center gap-2;
}

.pagination-btn,
.page-btn {
  @apply px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors;
}

/* Mobile: Larger pagination buttons */
@media (max-width: 768px) {
  .pagination-btn,
  .page-btn {
    @apply px-4 py-2 min-w-[44px] min-h-[44px] flex items-center justify-center; /* Apple HIG minimum touch target */
  }

  .grid-footer {
    @apply flex-col items-stretch gap-3;
  }

  .pagination-controls {
    @apply flex-wrap justify-center;
  }
}

.page-btn.active {
  @apply bg-blue-600 text-white border-blue-600 hover:bg-blue-700;
}

.page-numbers {
  @apply flex gap-1;
}

.per-page-selector {
  @apply flex items-center gap-2 text-sm;
}

.per-page-select {
  @apply border border-gray-300 rounded px-2 py-1 focus:outline-none focus:ring-2 focus:ring-blue-500;
}

/* Fade transition for overlay */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
