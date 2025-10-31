<template>
  <!-- Sidebar for desktop -->
  <aside
    class="hidden lg:flex lg:flex-shrink-0 lg:w-64 bg-white border-r border-gray-200 overflow-y-auto"
    :class="{ 'lg:hidden': !isOpen }"
  >
    <div class="flex flex-col w-full py-6">
      <nav class="flex-1 px-4 space-y-1">
        <router-link
          v-for="item in navigationItems"
          :key="item.name"
          :to="item.to"
          class="nav-link group"
          :class="isActive(item.to) ? 'nav-link-active' : 'nav-link-inactive'"
          :data-testid="`sidebar-nav-${item.name.toLowerCase().replace(/\s+/g, '-')}`"
        >
          <component
            :is="item.icon"
            class="h-5 w-5 flex-shrink-0 transition-colors"
            :class="isActive(item.to) ? 'text-primary-600' : 'text-gray-400 group-hover:text-gray-600'"
          />
          <span class="flex-1">{{ item.name }}</span>
          <span
            v-if="item.badge && item.badge > 0"
            class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium transition-colors"
            :class="isActive(item.to) ? 'bg-primary-100 text-primary-700' : 'bg-gray-100 text-gray-600 group-hover:bg-gray-200'"
          >
            {{ item.badge > 99 ? '99+' : item.badge }}
          </span>
        </router-link>
      </nav>

      <!-- Bottom Section -->
      <div class="mt-auto pt-6 px-4 border-t border-gray-200">
        <router-link
          to="/settings"
          class="nav-link group"
          :class="isActive('/settings') ? 'nav-link-active' : 'nav-link-inactive'"
          data-testid="sidebar-nav-settings"
        >
          <Cog6ToothIcon
            class="h-5 w-5 flex-shrink-0 transition-colors"
            :class="isActive('/settings') ? 'text-primary-600' : 'text-gray-400 group-hover:text-gray-600'"
          />
          <span>Settings</span>
        </router-link>
      </div>
    </div>
  </aside>

  <!-- Mobile sidebar overlay -->
  <transition
    enter-active-class="transition-opacity ease-linear duration-300"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition-opacity ease-linear duration-300"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div
      v-if="isOpen"
      class="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden"
      aria-hidden="true"
      @click="$emit('close')"
    />
  </transition>

  <!-- Mobile sidebar -->
  <transition
    enter-active-class="transition ease-in-out duration-300 transform"
    enter-from-class="-translate-x-full"
    enter-to-class="translate-x-0"
    leave-active-class="transition ease-in-out duration-300 transform"
    leave-from-class="translate-x-0"
    leave-to-class="-translate-x-full"
  >
    <aside
      v-if="isOpen"
      class="fixed inset-y-0 left-0 z-50 w-64 bg-white lg:hidden shadow-xl"
    >
      <div class="flex flex-col h-full">
        <!-- Mobile header with close button -->
        <div class="flex items-center justify-between h-16 px-4 border-b border-gray-200">
          <div class="flex items-center space-x-3">
            <div class="flex items-center justify-center w-10 h-10 rounded-lg bg-gradient-to-br from-primary-500 to-primary-600 shadow-sm">
              <svg
                class="w-6 h-6 text-white"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                />
              </svg>
            </div>
            <div>
              <h2 class="text-lg font-display font-semibold text-gray-900">
                FireProof
              </h2>
            </div>
          </div>
          <button
            type="button"
            class="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-primary-500"
            aria-label="Close sidebar"
            data-testid="sidebar-close-button"
            @click="$emit('close')"
          >
            <XMarkIcon class="h-6 w-6" />
          </button>
        </div>

        <!-- Mobile navigation -->
        <nav class="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
          <router-link
            v-for="item in navigationItems"
            :key="item.name"
            :to="item.to"
            class="nav-link group"
            :class="isActive(item.to) ? 'nav-link-active' : 'nav-link-inactive'"
            :data-testid="`sidebar-nav-${item.name.toLowerCase().replace(/\s+/g, '-')}`"
            @click="$emit('close')"
          >
            <component
              :is="item.icon"
              class="h-5 w-5 flex-shrink-0 transition-colors"
              :class="isActive(item.to) ? 'text-primary-600' : 'text-gray-400 group-hover:text-gray-600'"
            />
            <span class="flex-1">{{ item.name }}</span>
            <span
              v-if="item.badge && item.badge > 0"
              class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium transition-colors"
              :class="isActive(item.to) ? 'bg-primary-100 text-primary-700' : 'bg-gray-100 text-gray-600 group-hover:bg-gray-200'"
            >
              {{ item.badge > 99 ? '99+' : item.badge }}
            </span>
          </router-link>
        </nav>

        <!-- Mobile bottom section -->
        <div class="p-4 border-t border-gray-200">
          <router-link
            to="/settings"
            class="nav-link group"
            :class="isActive('/settings') ? 'nav-link-active' : 'nav-link-inactive'"
            data-testid="sidebar-nav-settings"
            @click="$emit('close')"
          >
            <Cog6ToothIcon
              class="h-5 w-5 flex-shrink-0 transition-colors"
              :class="isActive('/settings') ? 'text-primary-600' : 'text-gray-400 group-hover:text-gray-600'"
            />
            <span>Settings</span>
          </router-link>
        </div>
      </div>
    </aside>
  </transition>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  HomeIcon,
  MapPinIcon,
  ShieldCheckIcon,
  ClipboardDocumentCheckIcon,
  DocumentTextIcon,
  Cog6ToothIcon,
  XMarkIcon,
  RectangleStackIcon,
  UserCircleIcon,
  ClipboardDocumentListIcon,
  ArrowUpTrayIcon
} from '@heroicons/vue/24/outline'

defineProps({
  isOpen: {
    type: Boolean,
    default: true
  }
})

defineEmits(['close'])

const route = useRoute()
const authStore = useAuthStore()

// Check if user has SystemAdmin role
const isSystemAdmin = computed(() => {
  return authStore.hasSystemRole('SystemAdmin')
})

// Navigation items configuration
const navigationItems = computed(() => {
  const items = [
    {
      name: 'Dashboard',
      to: '/dashboard',
      icon: HomeIcon,
      badge: 0
    },
    {
      name: 'Locations',
      to: '/locations',
      icon: MapPinIcon,
      badge: 0
    },
    {
      name: 'Extinguishers',
      to: '/extinguishers',
      icon: ShieldCheckIcon,
      badge: 0 // TODO: Get count of extinguishers due for inspection
    },
    {
      name: 'Types',
      to: '/extinguisher-types',
      icon: RectangleStackIcon,
      badge: 0
    },
    {
      name: 'Inspections',
      to: '/inspections',
      icon: ClipboardDocumentCheckIcon,
      badge: 0 // TODO: Get count of overdue inspections
    },
    {
      name: 'Templates',
      to: '/checklist-templates',
      icon: ClipboardDocumentListIcon,
      badge: 0
    },
    {
      name: 'Import Data',
      to: '/import-data',
      icon: ArrowUpTrayIcon,
      badge: 0
    },
    {
      name: 'Reports',
      to: '/reports',
      icon: DocumentTextIcon,
      badge: 0
    }
  ]

  // Add Users menu item only for SystemAdmin
  if (isSystemAdmin.value) {
    items.splice(6, 0, {
      name: 'Users',
      to: '/users',
      icon: UserCircleIcon,
      badge: 0
    })
  }

  return items
})

// Check if route is active
const isActive = (path) => {
  return route.path.startsWith(path)
}
</script>
