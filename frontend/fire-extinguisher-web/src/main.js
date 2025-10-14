import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/main.css'

// Initialize offline sync manager
import { offlineSync } from './utils/offlineSync'
import { db } from './utils/indexedDB'

// Version tracking for cache busting verification
const APP_VERSION = '1.1.2'
const BUILD_TIMESTAMP = new Date().toISOString()
console.log(`🔥 FireProof v${APP_VERSION}`)
console.log(`📦 Build: ${BUILD_TIMESTAMP}`)
console.log(`🔧 Environment: ${import.meta.env.MODE}`)
console.log(`📡 Online: ${navigator.onLine}`)

const app = createApp(App)

app.use(createPinia())
app.use(router)

// Initialize IndexedDB and Offline Sync
;(async () => {
  try {
    // Initialize IndexedDB
    await db.init()
    console.log('✓ IndexedDB initialized')

    // Initialize offline sync manager
    offlineSync.init()
    console.log('✓ Offline sync initialized')

    // Add sync status logging in development
    if (import.meta.env.DEV) {
      offlineSync.on((event) => {
        console.log('🔄 Sync event:', event.type, event)
      })
    }

    // Get initial sync status
    const status = await offlineSync.getStatus()
    if (status.pendingOperations > 0 || status.pendingPhotos > 0) {
      console.log(`⏳ Pending sync: ${status.pendingOperations} operations, ${status.pendingPhotos} photos`)
    }
  } catch (error) {
    console.error('❌ Error initializing offline features:', error)
  }
})()

app.mount('#app')
