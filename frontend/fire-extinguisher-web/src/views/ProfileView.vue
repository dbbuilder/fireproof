<template>
  <AppLayout>
    <div>
      <div class="mb-8">
        <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
          Your Profile
        </h1>
        <p class="text-gray-600">
          Manage your personal information and preferences
        </p>
      </div>

      <!-- Coming Soon Message -->
      <div class="card">
        <div class="p-12 text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary-100 mb-4">
            <svg class="w-8 h-8 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <h2 class="text-xl font-semibold text-gray-900 mb-2">
            Profile Management Coming Soon
          </h2>
          <p class="text-gray-600 mb-6 max-w-md mx-auto">
            This feature will allow you to update your profile information, change your password, and manage your account settings.
          </p>
          <div class="flex items-center justify-center space-x-4">
            <router-link to="/dashboard" class="btn-outline">
              Back to Dashboard
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import AppLayout from '@/components/layout/AppLayout.vue'
</script>
