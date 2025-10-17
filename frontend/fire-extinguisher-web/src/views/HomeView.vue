<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
    <div class="max-w-4xl w-full">
      <div class="text-center mb-12">
        <h1 class="text-6xl font-bold text-gray-900 mb-4">
          🔥 FireProof
        </h1>
        <p class="text-2xl text-gray-700 mb-8">
          Fire Extinguisher Inspection System
        </p>
        <p class="text-lg text-gray-600 max-w-2xl mx-auto mb-12">
          Professional multi-tenant SaaS platform for managing fire extinguisher
          inspections, compliance tracking, and regulatory reporting.
        </p>

        <div class="flex gap-4 justify-center">
          <router-link
            to="/login"
            class="px-8 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-lg"
          >
            Get Started
          </router-link>
          <router-link
            to="/dashboard"
            class="px-8 py-3 bg-white text-blue-600 font-semibold rounded-lg hover:bg-gray-50 transition-colors shadow-lg border-2 border-blue-600"
          >
            Dashboard
          </router-link>
        </div>
      </div>

      <div class="grid md:grid-cols-3 gap-6 mt-16">
        <div class="bg-white p-6 rounded-lg shadow-md">
          <div class="text-3xl mb-4">
            📱
          </div>
          <h3 class="text-lg font-semibold mb-2">
            Multi-Platform
          </h3>
          <p class="text-gray-600">
            Web and mobile apps with offline capability
          </p>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-md">
          <div class="text-3xl mb-4">
            🔒
          </div>
          <h3 class="text-lg font-semibold mb-2">
            Tamper-Proof
          </h3>
          <p class="text-gray-600">
            Cryptographic verification of all inspections
          </p>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-md">
          <div class="text-3xl mb-4">
            📊
          </div>
          <h3 class="text-lg font-semibold mb-2">
            Compliance Reports
          </h3>
          <p class="text-gray-600">
            Automated NFPA 10 compliant reporting
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Home view component
</script>
