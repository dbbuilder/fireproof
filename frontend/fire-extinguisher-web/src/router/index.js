import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // ============================================
    // Root Redirect - Inspector Mode
    // ============================================
    {
      path: '/',
      redirect: () => {
        // If in inspector mode, redirect to inspector login
        if (import.meta.env.VITE_APP_MODE === 'inspector') {
          return '/inspector/login'
        }
        // Otherwise stay at home (admin app)
        return { name: 'home' }
      }
    },

    // ============================================
    // Inspector Routes (Subdomain: inspect.fireproofapp.net)
    // ============================================
    {
      path: '/inspector/login',
      name: 'inspector-login',
      component: () => import('../views/inspector/InspectorLoginView.vue'),
      meta: { requiresInspectorGuest: true }
    },
    {
      path: '/inspector',
      component: () => import('../views/inspector/InspectorLayoutView.vue'),
      meta: { requiresInspector: true },
      children: [
        {
          path: 'dashboard',
          name: 'inspector-dashboard',
          component: () => import('../views/inspector/InspectorDashboardView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'scan-location',
          name: 'inspector-scan-location',
          component: () => import('../views/inspector/ScanLocationView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'scan-extinguisher',
          name: 'inspector-scan-extinguisher',
          component: () => import('../views/inspector/ScanExtinguisherView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'inspection-checklist',
          name: 'inspector-inspection-checklist',
          component: () => import('../views/inspector/InspectionChecklistView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'inspection-photos',
          name: 'inspector-inspection-photos',
          component: () => import('../views/inspector/InspectionPhotosView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'inspection-signature',
          name: 'inspector-inspection-signature',
          component: () => import('../views/inspector/InspectionSignatureView.vue'),
          meta: { requiresInspector: true }
        },
        {
          path: 'inspection-success',
          name: 'inspector-inspection-success',
          component: () => import('../views/inspector/InspectionSuccessView.vue'),
          meta: { requiresInspector: true }
        }
      ]
    },

    // ============================================
    // Admin Routes (Main App)
    // ============================================
    {
      path: '/home',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/select-tenant',
      name: 'select-tenant',
      component: () => import('../views/TenantSelectorView.vue'),
      meta: { requiresAuth: true, skipTenantCheck: true }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/locations',
      name: 'locations',
      component: () => import('../views/LocationsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/extinguishers',
      name: 'extinguishers',
      component: () => import('../views/ExtinguishersViewGrid.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/extinguishers-cards',
      name: 'extinguishers-cards',
      component: () => import('../views/ExtinguishersView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/extinguisher-types',
      name: 'extinguisher-types',
      component: () => import('../views/ExtinguisherTypesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections',
      name: 'inspections',
      component: () => import('../views/InspectionsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/new',
      name: 'inspection-create',
      component: () => import('../views/InspectionPhase1CreateView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/:id',
      name: 'inspection-detail',
      component: () => import('../views/InspectionPhase1DetailView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/:id/checklist',
      name: 'inspection-checklist',
      component: () => import('../views/InspectionPhase1ChecklistView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inspections/:id/complete',
      name: 'inspection-complete',
      component: () => import('../views/InspectionPhase1CompleteView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports',
      name: 'reports',
      component: () => import('../views/ReportsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/profile',
      name: 'profile',
      component: () => import('../views/ProfileView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/users',
      name: 'users',
      component: () => import('../views/UsersView.vue'),
      meta: { requiresAuth: true, requiresSystemAdmin: true }
    },
    {
      path: '/checklist-templates',
      name: 'checklist-templates',
      component: () => import('../views/ChecklistTemplatesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/import-data',
      name: 'import-data',
      component: () => import('../views/ImportDataView.vue'),
      meta: { requiresAuth: true, requiresTenantAdmin: true }
    },
    {
      path: '/import-history',
      name: 'import-history',
      component: () => import('../views/ImportHistoryView.vue'),
      meta: { requiresAuth: true, requiresTenantAdmin: true }
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('../views/NotFoundView.vue')
    }
  ]
})

// Track if auth initialization has been attempted
let authInitStarted = false

// Navigation guard for authentication
router.beforeEach(async (to, from, next) => {
  // ============================================
  // Inspector Routes Guard
  // ============================================
  const isInspectorRoute = to.path.startsWith('/inspector')

  if (isInspectorRoute) {
    const inspectorStore = useInspectorStore()

    // Protect inspector routes that require authentication
    if (to.meta.requiresInspector && !inspectorStore.isAuthenticated) {
      next({
        name: 'inspector-login',
        query: { redirect: to.fullPath }
      })
      return
    }

    // Redirect authenticated inspectors away from login page
    if (to.meta.requiresInspectorGuest && inspectorStore.isAuthenticated) {
      next({ name: 'inspector-dashboard' })
      return
    }

    next()
    return
  }

  // ============================================
  // Admin Routes Guard
  // ============================================
  const authStore = useAuthStore()

  // Initialize auth on first navigation if needed
  if (!authInitStarted && !authStore.isAuthenticated && authStore.accessToken) {
    authInitStarted = true
    // Initialize in background - don't block navigation
    authStore.initializeAuth().catch(() => {
      // Silent failure - auth store handles cleanup
    })
  }

  // Check authentication status
  // In E2E test mode (Playwright), trust localStorage tokens even if store isn't hydrated yet
  // This prevents timing issues where router guard runs before Pinia store initialization completes
  const hasTokenInStorage = typeof localStorage !== 'undefined' &&
    localStorage.getItem('accessToken') &&
    localStorage.getItem('refreshToken')

  const isAuthenticated = authStore.isLoggedIn ||
    (typeof window !== 'undefined' && window.__PLAYWRIGHT_E2E__ && hasTokenInStorage)

  // Protect routes that require authentication
  if (to.meta.requiresAuth && !isAuthenticated) {
    next({
      name: 'login',
      query: { redirect: to.fullPath }
    })
    return
  }

  // Check if tenant selection is needed (SystemAdmin or multi-tenant users without tenant selected)
  if (
    isAuthenticated &&
    to.meta.requiresAuth &&
    !to.meta.skipTenantCheck &&
    authStore.needsTenantSelection
  ) {
    next({
      name: 'select-tenant',
      query: { redirect: to.fullPath }
    })
    return
  }

  // Redirect authenticated users away from guest-only pages (login, register)
  if (to.meta.requiresGuest && isAuthenticated) {
    // Check if they need to select a tenant first
    if (authStore.needsTenantSelection) {
      next({ name: 'select-tenant' })
    } else {
      next({ name: 'dashboard' })
    }
    return
  }

  next()
})

export default router
