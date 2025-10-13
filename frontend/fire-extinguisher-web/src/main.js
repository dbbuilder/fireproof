import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/main.css'

// Version tracking for cache busting verification
const APP_VERSION = '1.1.2'
const BUILD_TIMESTAMP = new Date().toISOString()
console.log(`🔥 FireProof v${APP_VERSION}`)
console.log(`📦 Build: ${BUILD_TIMESTAMP}`)
console.log(`🔧 Environment: ${import.meta.env.MODE}`)

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')
