<template>
  <div class="min-h-screen bg-gray-50 flex items-center justify-center p-4">
    <div class="max-w-md w-full text-center">
      <div class="mb-8">
        <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-primary-100 mb-4">
          <svg class="w-12 h-12 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h1 class="text-6xl font-display font-bold text-gray-900 mb-4">
          404
        </h1>
        <h2 class="text-2xl font-semibold text-gray-900 mb-2">
          Page Not Found
        </h2>
        <p class="text-gray-600 mb-8">
          Sorry, we couldn't find the page you're looking for. It might have been moved or deleted.
        </p>
      </div>

      <div class="flex items-center justify-center space-x-4">
        <router-link to="/dashboard" class="btn-primary">
          Go to Dashboard
        </router-link>
        <button @click="$router.back()" class="btn-outline">
          Go Back
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
const router = useRouter()
</script>
