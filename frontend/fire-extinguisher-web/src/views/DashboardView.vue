<template>
  <div class="min-h-screen bg-gray-50">
    <nav class="bg-white shadow-sm border-b">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <h1 class="text-xl font-bold text-gray-900">FireProof Dashboard</h1>
          </div>
          <div class="flex items-center space-x-4">
            <button
              @click="handleLogout"
              class="px-4 py-2 text-sm text-gray-700 hover:text-gray-900"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="px-4 py-6 sm:px-0">
        <div class="bg-white rounded-lg shadow p-6 mb-6">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Welcome to FireProof</h2>
          <p class="text-gray-600 mb-4">
            This is the dashboard placeholder. Features will be implemented in subsequent phases:
          </p>
          <ul class="list-disc list-inside space-y-2 text-gray-700">
            <li>Location management</li>
            <li>Extinguisher inventory</li>
            <li>Inspection workflow</li>
            <li>Compliance reports</li>
            <li>Analytics and insights</li>
          </ul>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Total Locations</h3>
            <p class="text-3xl font-bold text-blue-600">0</p>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Fire Extinguishers</h3>
            <p class="text-3xl font-bold text-green-600">0</p>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Inspections This Month</h3>
            <p class="text-3xl font-bold text-purple-600">0</p>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const handleLogout = () => {
  localStorage.removeItem('auth_token')
  router.push('/login')
}
</script>
