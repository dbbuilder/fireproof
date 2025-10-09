import { defineStore } from 'pinia'
import authService from '@/services/authService'
import type {
  RegisterRequest,
  LoginRequest,
  DevLoginRequest,
  RefreshTokenRequest,
  AuthenticationResponse,
  UserDto,
  RoleDto,
  ResetPasswordRequest
} from '@/types/api'
import api from '@/services/api'

interface AuthState {
  user: UserDto | null
  roles: RoleDto[]
  accessToken: string | null
  refreshToken: string | null
  tokenExpiresAt: Date | null
  isAuthenticated: boolean
  loading: boolean
  error: string | null
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    roles: [],
    accessToken: localStorage.getItem('accessToken'),
    refreshToken: localStorage.getItem('refreshToken'),
    tokenExpiresAt: null,
    isAuthenticated: false,
    loading: false,
    error: null
  }),

  getters: {
    /**
     * Check if user is authenticated
     */
    isLoggedIn: (state): boolean => {
      return state.isAuthenticated && state.user !== null && state.accessToken !== null
    },

    /**
     * Get user's full name
     */
    userFullName: (state): string => {
      if (!state.user) return ''
      return `${state.user.firstName} ${state.user.lastName}`
    },

    /**
     * Get system roles
     */
    systemRoles: (state): RoleDto[] => {
      return state.roles.filter(r => r.roleType === 'System')
    },

    /**
     * Get tenant roles
     */
    tenantRoles: (state): RoleDto[] => {
      return state.roles.filter(r => r.roleType === 'Tenant')
    },

    /**
     * Check if user has a specific role (system or tenant)
     */
    hasRole: (state) => (roleName: string): boolean => {
      return state.roles.some(r => r.roleName === roleName)
    },

    /**
     * Check if user has a specific system role
     */
    hasSystemRole: (state) => (roleName: string): boolean => {
      return state.roles.some(r => r.roleType === 'System' && r.roleName === roleName)
    },

    /**
     * Check if user has a specific tenant role
     */
    hasTenantRole: (state) => (roleName: string, tenantId?: string): boolean => {
      return state.roles.some(
        r =>
          r.roleType === 'Tenant' &&
          r.roleName === roleName &&
          (!tenantId || r.tenantId === tenantId)
      )
    },

    /**
     * Check if user is a system admin
     */
    isSystemAdmin: (state): boolean => {
      return state.roles.some(r => r.roleType === 'System' && r.roleName === 'SystemAdmin')
    },

    /**
     * Check if user is a tenant admin for any tenant
     */
    isTenantAdmin: (state): boolean => {
      return state.roles.some(r => r.roleType === 'Tenant' && r.roleName === 'TenantAdmin')
    },

    /**
     * Get tenant IDs user has access to
     */
    tenantIds: (state): string[] => {
      return state.roles
        .filter(r => r.roleType === 'Tenant' && r.tenantId)
        .map(r => r.tenantId!)
        .filter((id, index, self) => self.indexOf(id) === index) // unique
    }
  },

  actions: {
    /**
     * Register a new user
     */
    async register(data: RegisterRequest): Promise<void> {
      this.loading = true
      this.error = null

      try {
        const response = await authService.register(data)
        this.setAuthData(response)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Registration failed'
        console.error('Registration error:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Login with email and password
     */
    async login(data: LoginRequest): Promise<void> {
      this.loading = true
      this.error = null

      try {
        const response = await authService.login(data)
        this.setAuthData(response)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Login failed'
        console.error('Login error:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Development login (NO PASSWORD)
     */
    async devLogin(email: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        const response = await authService.devLogin({ email })
        this.setAuthData(response)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Dev login failed'
        console.error('Dev login error:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Refresh access token
     */
    async refreshAccessToken(): Promise<void> {
      if (!this.refreshToken) {
        throw new Error('No refresh token available')
      }

      try {
        const response = await authService.refreshToken({ refreshToken: this.refreshToken })
        this.setAuthData(response)
      } catch (error: any) {
        console.error('Token refresh error:', error)
        this.logout() // Force logout on refresh failure
        throw error
      }
    },

    /**
     * Logout
     */
    logout(): void {
      this.user = null
      this.roles = []
      this.accessToken = null
      this.refreshToken = null
      this.tokenExpiresAt = null
      this.isAuthenticated = false
      this.error = null

      // Clear from localStorage
      localStorage.removeItem('accessToken')
      localStorage.removeItem('refreshToken')

      // Clear auth header
      delete api.defaults.headers.common['Authorization']
    },

    /**
     * Reset password
     */
    async resetPassword(data: ResetPasswordRequest): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await authService.resetPassword(data)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Password reset failed'
        console.error('Password reset error:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Fetch current user profile
     */
    async fetchCurrentUser(): Promise<void> {
      if (!this.accessToken) return

      this.loading = true
      this.error = null

      try {
        this.user = await authService.getCurrentUser()
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch user profile'
        console.error('Fetch user error:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Fetch current user roles
     */
    async fetchCurrentUserRoles(): Promise<void> {
      if (!this.accessToken) return

      this.loading = true
      this.error = null

      try {
        this.roles = await authService.getCurrentUserRoles()
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch user roles'
        console.error('Fetch roles error:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Set authentication data from response
     */
    setAuthData(response: AuthenticationResponse): void {
      this.user = response.user
      this.roles = response.roles
      this.accessToken = response.accessToken
      this.refreshToken = response.refreshToken
      this.tokenExpiresAt = new Date(response.expiresAt)
      this.isAuthenticated = true

      // Store in localStorage
      localStorage.setItem('accessToken', response.accessToken)
      localStorage.setItem('refreshToken', response.refreshToken)

      // Set auth header for all requests
      api.defaults.headers.common['Authorization'] = `Bearer ${response.accessToken}`
    },

    /**
     * Initialize auth from localStorage on app load
     */
    async initializeAuth(): Promise<void> {
      const token = localStorage.getItem('accessToken')
      const refreshToken = localStorage.getItem('refreshToken')

      if (token && refreshToken) {
        this.accessToken = token
        this.refreshToken = refreshToken

        // Set auth header
        api.defaults.headers.common['Authorization'] = `Bearer ${token}`

        try {
          // Fetch user and roles
          await Promise.all([this.fetchCurrentUser(), this.fetchCurrentUserRoles()])
          this.isAuthenticated = true
        } catch (error) {
          // Token might be expired, try to refresh
          try {
            await this.refreshAccessToken()
          } catch (refreshError) {
            // Refresh failed, logout
            this.logout()
          }
        }
      }
    },

    /**
     * Clear error
     */
    clearError(): void {
      this.error = null
    }
  }
})
