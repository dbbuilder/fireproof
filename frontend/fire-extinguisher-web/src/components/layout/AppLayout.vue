<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <AppHeader
      :sidebar-open="sidebarOpen"
      @toggle-sidebar="toggleSidebar"
    />

    <!-- Main Container -->
    <div class="flex h-[calc(100vh-60px)]">
      <!-- Sidebar -->
      <AppSidebar
        :is-open="sidebarOpen"
        @close="closeSidebar"
      />

      <!-- Main Content Area -->
      <main
        class="flex-1 overflow-y-auto transition-all duration-300"
        :class="{ 'lg:ml-0': !sidebarOpen }"
      >
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <!-- Page content slot -->
          <slot />
        </div>
      </main>
    </div>

    <!-- Toast Notifications Container -->
    <div
      class="fixed bottom-0 right-0 z-50 p-6 space-y-4 pointer-events-none"
      aria-live="polite"
      aria-atomic="true"
    >
      <transition-group
        name="slide-up"
        tag="div"
        class="space-y-4"
      >
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="pointer-events-auto max-w-sm w-full animate-slide-up"
        >
          <div
            class="rounded-lg shadow-lg overflow-hidden"
            :class="{
              'bg-white border border-gray-200': toast.type === 'info',
              'bg-secondary-50 border border-secondary-200': toast.type === 'success',
              'bg-red-50 border border-red-200': toast.type === 'error',
              'bg-accent-50 border border-accent-200': toast.type === 'warning'
            }"
          >
            <div class="p-4">
              <div class="flex items-start">
                <div class="flex-shrink-0">
                  <component
                    :is="getToastIcon(toast.type)"
                    class="h-5 w-5"
                    :class="{
                      'text-gray-400': toast.type === 'info',
                      'text-secondary-600': toast.type === 'success',
                      'text-red-600': toast.type === 'error',
                      'text-accent-600': toast.type === 'warning'
                    }"
                  />
                </div>
                <div class="ml-3 flex-1">
                  <p
                    class="text-sm font-medium"
                    :class="{
                      'text-gray-900': toast.type === 'info',
                      'text-secondary-900': toast.type === 'success',
                      'text-red-900': toast.type === 'error',
                      'text-accent-900': toast.type === 'warning'
                    }"
                  >
                    {{ toast.message }}
                  </p>
                </div>
                <div class="ml-4 flex-shrink-0 flex">
                  <button
                    type="button"
                    class="inline-flex rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                    :class="{
                      'text-gray-400 hover:text-gray-500': toast.type === 'info',
                      'text-secondary-400 hover:text-secondary-500': toast.type === 'success',
                      'text-red-400 hover:text-red-500': toast.type === 'error',
                      'text-accent-400 hover:text-accent-500': toast.type === 'warning'
                    }"
                    @click="removeToast(toast.id)"
                  >
                    <span class="sr-only">Close</span>
                    <XMarkIcon class="h-5 w-5" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useToastStore } from '@/stores/toast'
import { storeToRefs } from 'pinia'
import AppHeader from './AppHeader.vue'
import AppSidebar from './AppSidebar.vue'
import {
  XMarkIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  XCircleIcon,
  InformationCircleIcon
} from '@heroicons/vue/24/outline'

// Sidebar state
const sidebarOpen = ref(true)

const toggleSidebar = () => {
  sidebarOpen.value = !sidebarOpen.value
}

const closeSidebar = () => {
  sidebarOpen.value = false
}

// Toast notifications
const toastStore = useToastStore()
const { toasts } = storeToRefs(toastStore)
const { removeToast } = toastStore

const getToastIcon = (type) => {
  switch (type) {
    case 'success':
      return CheckCircleIcon
    case 'error':
      return XCircleIcon
    case 'warning':
      return ExclamationTriangleIcon
    default:
      return InformationCircleIcon
  }
}
</script>

<style scoped>
/* Transition for toast notifications */
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s ease;
}

.slide-up-enter-from {
  transform: translateY(20px);
  opacity: 0;
}

.slide-up-leave-to {
  transform: translateX(100px);
  opacity: 0;
}
</style>
