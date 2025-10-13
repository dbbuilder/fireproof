import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
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
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('../views/NotFoundView.vue')
    }
  ]
})

// Navigation guard for authentication
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Initialize auth on first navigation if needed
  if (!authStore.isAuthenticated && authStore.accessToken) {
    try {
      await authStore.initializeAuth()
    } catch (error) {
      console.error('Failed to initialize auth:', error)
    }
  }

  const isAuthenticated = authStore.isLoggedIn

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
