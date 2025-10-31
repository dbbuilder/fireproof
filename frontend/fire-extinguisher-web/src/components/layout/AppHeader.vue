<template>
  <header class="bg-white border-b border-gray-200 h-16 fixed top-0 left-0 right-0 z-40">
    <div class="h-full px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-full">
        <!-- Left Section: Menu + Logo -->
        <div class="flex items-center space-x-4">
          <!-- Mobile Menu Button -->
          <button
            type="button"
            class="lg:hidden inline-flex items-center justify-center p-2 rounded-lg text-gray-600 hover:text-gray-900 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary-500 transition-colors"
            aria-label="Toggle sidebar"
            data-testid="header-menu-toggle"
            @click="$emit('toggle-sidebar')"
          >
            <Bars3Icon class="h-6 w-6" />
          </button>

          <!-- Logo + Brand -->
          <router-link
            to="/dashboard"
            class="flex items-center space-x-3 group"
            data-testid="header-logo"
          >
            <!-- Logo Icon - Flame with Checkmark -->
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 200 240"
              class="w-10 h-10"
            >
              <path
                fill="#e95f5f"
                d="M100 10 L85 35 L75 20 L65 50 L50 30 L35 70 L25 240 L175 240 L165 70 L150 30 L135 50 L125 20 L115 35 Z"
              />
              <path
                fill="white"
                stroke="white"
                stroke-width="8"
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M130 120 L90 160 L70 140 M90 160 L85 155"
              />
            </svg>

            <!-- Brand Name -->
            <div class="hidden sm:block">
              <h1 class="text-xl font-display font-semibold text-gray-900 group-hover:text-primary-600 transition-colors">
                FireProof
              </h1>
              <p class="text-xs text-gray-500 -mt-1">
                Inspection System
              </p>
            </div>
          </router-link>
        </div>

        <!-- Center Section: Tenant Display -->
        <div class="hidden md:flex flex-1 items-center justify-center mx-8">
          <div
            class="flex items-center space-x-3 px-6 py-2 bg-gradient-to-r from-primary-50 to-primary-100 border border-primary-200 rounded-lg"
            data-testid="header-tenant-display"
          >
            <BuildingOfficeIcon class="h-6 w-6 text-primary-600 flex-shrink-0" />
            <div class="text-center">
              <p class="text-xs font-medium text-primary-600 uppercase tracking-wide">
                Organization
              </p>
              <p class="text-sm font-semibold text-gray-900">
                {{ tenantName }}
              </p>
            </div>
          </div>
        </div>

        <!-- Right Section: Notifications + User Menu -->
        <div class="flex items-center space-x-2 sm:space-x-4">
          <!-- Notifications Button (Future Feature) -->
          <button
            type="button"
            class="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 transition-colors"
            aria-label="View notifications"
            data-testid="header-notifications-button"
          >
            <BellIcon class="h-6 w-6" />
            <!-- Notification Badge -->
            <span
              v-if="notificationCount > 0"
              class="absolute top-1 right-1 flex h-4 w-4 items-center justify-center rounded-full bg-primary-600 text-white text-xs font-medium"
            >
              {{ notificationCount > 9 ? '9+' : notificationCount }}
            </span>
          </button>

          <!-- User Menu Dropdown -->
          <div
            ref="userMenuRef"
            class="relative"
          >
            <button
              type="button"
              class="flex items-center space-x-3 p-2 rounded-lg hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-colors"
              aria-haspopup="true"
              :aria-expanded="userMenuOpen"
              data-testid="header-user-menu-button"
              @click="toggleUserMenu"
            >
              <!-- User Avatar -->
              <div class="flex items-center justify-center w-8 h-8 rounded-full bg-gradient-to-br from-primary-500 to-primary-600 text-white text-sm font-medium shadow-sm">
                {{ userInitials }}
              </div>

              <!-- User Name (Desktop Only) -->
              <div class="hidden md:block text-left">
                <p class="text-sm font-medium text-gray-900">
                  {{ user?.firstName }} {{ user?.lastName }}
                </p>
                <p class="text-xs text-gray-500">
                  {{ userRole }}
                </p>
              </div>

              <!-- Dropdown Icon -->
              <ChevronDownIcon
                class="h-4 w-4 text-gray-500 transition-transform"
                :class="{ 'rotate-180': userMenuOpen }"
              />
            </button>

            <!-- Dropdown Menu -->
            <transition
              enter-active-class="transition ease-out duration-100"
              enter-from-class="transform opacity-0 scale-95"
              enter-to-class="transform opacity-100 scale-100"
              leave-active-class="transition ease-in duration-75"
              leave-from-class="transform opacity-100 scale-100"
              leave-to-class="transform opacity-0 scale-95"
            >
              <div
                v-if="userMenuOpen"
                class="absolute right-0 mt-2 w-56 origin-top-right rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                role="menu"
                aria-orientation="vertical"
                data-testid="header-user-menu-dropdown"
              >
                <div class="p-4 border-b border-gray-100">
                  <p class="text-sm font-medium text-gray-900">
                    {{ user?.email }}
                  </p>
                  <p class="text-xs text-gray-500 mt-1">
                    {{ tenantName }}
                  </p>
                </div>

                <div class="py-1">
                  <router-link
                    to="/profile"
                    class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                    role="menuitem"
                    data-testid="header-user-menu-profile"
                    @click="userMenuOpen = false"
                  >
                    <UserCircleIcon class="h-5 w-5 mr-3 text-gray-400" />
                    Your Profile
                  </router-link>

                  <router-link
                    to="/settings"
                    class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                    role="menuitem"
                    data-testid="header-user-menu-settings"
                    @click="userMenuOpen = false"
                  >
                    <Cog6ToothIcon class="h-5 w-5 mr-3 text-gray-400" />
                    Settings
                  </router-link>

                  <a
                    href="#"
                    class="flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                    role="menuitem"
                    data-testid="header-user-menu-help"
                    @click.prevent="handleHelp"
                  >
                    <QuestionMarkCircleIcon class="h-5 w-5 mr-3 text-gray-400" />
                    Help & Support
                  </a>
                </div>

                <div
                  v-if="canSwitchTenant"
                  class="border-t border-gray-100 py-1"
                >
                  <button
                    type="button"
                    class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                    role="menuitem"
                    data-testid="header-user-menu-switch-tenant"
                    @click="handleSwitchTenant"
                  >
                    <BuildingOfficeIcon class="h-5 w-5 mr-3 text-gray-400" />
                    Switch Tenant
                  </button>
                </div>

                <div class="border-t border-gray-100 py-1">
                  <button
                    type="button"
                    class="flex items-center w-full px-4 py-2 text-sm text-red-700 hover:bg-red-50 transition-colors"
                    role="menuitem"
                    data-testid="header-user-menu-logout"
                    @click="handleSignOut"
                  >
                    <ArrowRightOnRectangleIcon class="h-5 w-5 mr-3 text-red-400" />
                    Sign Out
                  </button>
                </div>
              </div>
            </transition>
          </div>
        </div>
      </div>
    </div>
  </header>

  <!-- Spacer to prevent content from hiding under fixed header -->
  <div class="h-16" />
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  Bars3Icon,
  MagnifyingGlassIcon,
  BellIcon,
  ChevronDownIcon,
  UserCircleIcon,
  Cog6ToothIcon,
  QuestionMarkCircleIcon,
  ArrowRightOnRectangleIcon,
  BuildingOfficeIcon
} from '@heroicons/vue/24/outline'

defineProps({
  sidebarOpen: {
    type: Boolean,
    default: true
  }
})

defineEmits(['toggle-sidebar'])

const router = useRouter()
const authStore = useAuthStore()

// Search
const searchQuery = ref('')

const handleSearch = () => {
  if (searchQuery.value.trim()) {
    router.push({
      path: '/search',
      query: { q: searchQuery.value }
    })
  }
}

// Notifications (placeholder)
const notificationCount = ref(0)

// User Menu
const userMenuOpen = ref(false)
const userMenuRef = ref(null)

const user = computed(() => authStore.user)
const userRole = computed(() => authStore.user?.role || 'User')
const tenantName = computed(() => authStore.tenant?.name || 'Organization')

const userInitials = computed(() => {
  if (!user.value) return 'U'
  const first = user.value.firstName?.charAt(0) || ''
  const last = user.value.lastName?.charAt(0) || ''
  return (first + last).toUpperCase() || 'U'
})

const toggleUserMenu = () => {
  userMenuOpen.value = !userMenuOpen.value
}

const handleSignOut = async () => {
  userMenuOpen.value = false
  await authStore.logout()
  router.push('/login')
}

const handleHelp = () => {
  userMenuOpen.value = false
  // Open help documentation or support chat
  window.open('https://docs.fireproof.app', '_blank')
}

// Determine if user can switch tenants (SystemAdmin or multi-tenant user)
const canSwitchTenant = computed(() => {
  const isSystemAdmin = authStore.roles.some(
    r => r.roleType === 'System' && r.roleName === 'SystemAdmin'
  )

  const uniqueTenantIds = authStore.roles
    .filter(r => r.roleType === 'Tenant' && r.tenantId)
    .map(r => r.tenantId)
    .filter((id, index, self) => self.indexOf(id) === index)

  // Can switch if SystemAdmin or has multiple tenants
  return isSystemAdmin || uniqueTenantIds.length > 1
})

const handleSwitchTenant = () => {
  userMenuOpen.value = false
  // Clear current tenant selection
  authStore.setCurrentTenant(null)
  // Redirect to tenant selector
  router.push('/select-tenant')
}

// Close user menu when clicking outside
const handleClickOutside = (event) => {
  if (userMenuRef.value && !userMenuRef.value.contains(event.target)) {
    userMenuOpen.value = false
  }
}

// Close menu on route change
const closeMenuOnRouteChange = () => {
  userMenuOpen.value = false
}

router.beforeEach(() => {
  closeMenuOnRouteChange()
})

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
