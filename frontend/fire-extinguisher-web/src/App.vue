<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <!-- Global Sync Status Banner -->
    <SyncStatusBanner />

    <!-- Main App Content -->
    <router-view />
  </div>
</template>

<script setup>
import SyncStatusBanner from '@/components/SyncStatusBanner.vue'
</script>

<style>
#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
