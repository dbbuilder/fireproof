import api from './api'
import type {
  RegisterRequest,
  LoginRequest,
  DevLoginRequest,
  RefreshTokenRequest,
  AuthenticationResponse,
  UserDto,
  RoleDto,
  ResetPasswordRequest,
  ConfirmEmailRequest,
  AssignUserToTenantRequest
} from '@/types/api'

/**
 * Authentication service for user registration, login, and token management
 * Handles all authentication-related API calls with full TypeScript type safety
 */
const authService = {
  /**
   * Register a new user
   * @param data - Registration request data
   * @returns Promise resolving to authentication response with JWT tokens
   */
  async register(data: RegisterRequest): Promise<AuthenticationResponse> {
    const response = await api.post<AuthenticationResponse>('/authentication/register', data)
    return response.data
  },

  /**
   * Login with email and password
   * @param data - Login request data
   * @returns Promise resolving to authentication response with JWT tokens
   */
  async login(data: LoginRequest): Promise<AuthenticationResponse> {
    const response = await api.post<AuthenticationResponse>('/authentication/login', data)
    return response.data
  },

  /**
   * Development login (NO PASSWORD CHECK)
   * WARNING: Only works when dev mode is enabled on the server
   * @param data - Dev login request data
   * @returns Promise resolving to authentication response with JWT tokens
   */
  async devLogin(data: DevLoginRequest): Promise<AuthenticationResponse> {
    const response = await api.post<AuthenticationResponse>('/authentication/dev-login', data)
    return response.data
  },

  /**
   * Refresh access token using refresh token
   * @param data - Refresh token request
   * @returns Promise resolving to new authentication response with tokens
   */
  async refreshToken(data: RefreshTokenRequest): Promise<AuthenticationResponse> {
    const response = await api.post<AuthenticationResponse>('/authentication/refresh', data)
    return response.data
  },

  /**
   * Reset user password
   * @param data - Password reset request
   * @returns Promise resolving when password is reset
   */
  async resetPassword(data: ResetPasswordRequest): Promise<void> {
    await api.post('/authentication/reset-password', data)
  },

  /**
   * Confirm user email
   * @param data - Email confirmation request
   * @returns Promise resolving when email is confirmed
   */
  async confirmEmail(data: ConfirmEmailRequest): Promise<void> {
    await api.post('/authentication/confirm-email', data)
  },

  /**
   * Get current user profile
   * @returns Promise resolving to current user data
   */
  async getCurrentUser(): Promise<UserDto> {
    const response = await api.get<UserDto>('/authentication/me')
    return response.data
  },

  /**
   * Get current user roles
   * @returns Promise resolving to list of user roles
   */
  async getCurrentUserRoles(): Promise<RoleDto[]> {
    const response = await api.get<RoleDto[]>('/authentication/me/roles')
    return response.data
  },

  /**
   * Assign user to tenant (admin only)
   * @param data - Assignment request
   * @returns Promise resolving when assignment is complete
   */
  async assignUserToTenant(data: AssignUserToTenantRequest): Promise<void> {
    await api.post('/authentication/assign-tenant', data)
  }
}

export default authService
