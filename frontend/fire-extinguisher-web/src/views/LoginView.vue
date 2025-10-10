<template>
  <div class="min-h-screen bg-gray-50 flex items-center justify-center p-4">
    <div class="max-w-md w-full">
      <!-- Logo & Brand -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-primary-500 to-primary-600 shadow-glow mb-4">
          <svg class="w-10 h-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
          </svg>
        </div>
        <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
          Welcome Back
        </h1>
        <p class="text-gray-600">
          Sign in to your FireProof account
        </p>
      </div>

      <!-- Login Card -->
      <div class="card">
        <div class="p-8">
          <!-- Dev Mode Notice (Only shown in development) -->
          <div v-if="showDevMode" class="alert-info mb-6">
            <InformationCircleIcon class="h-5 w-5" />
            <div>
              <p class="text-sm font-medium">Development Mode</p>
              <p class="text-xs mt-1">You can use dev login (no password required) or register a test account</p>
            </div>
          </div>

          <!-- Error Alert -->
          <div v-if="error" class="alert-danger mb-6">
            <XCircleIcon class="h-5 w-5" />
            <div>
              <p class="text-sm font-medium">{{ error }}</p>
            </div>
            <button
              type="button"
              class="text-red-400 hover:text-red-600"
              @click="clearError"
            >
              <XMarkIcon class="h-5 w-5" />
            </button>
          </div>

          <!-- Login Form -->
          <form @submit.prevent="handleLogin" class="space-y-6">
            <!-- Email Field -->
            <div>
              <label for="email" class="form-label">
                Email Address
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <EnvelopeIcon class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="email"
                  v-model="form.email"
                  type="email"
                  required
                  autocomplete="email"
                  class="form-input pl-10"
                  :class="{ 'border-red-500 focus:ring-red-500': emailError }"
                  placeholder="you@example.com"
                  @blur="validateEmail"
                />
              </div>
              <p v-if="emailError" class="form-error">
                {{ emailError }}
              </p>
            </div>

            <!-- Password Field -->
            <div>
              <label for="password" class="form-label">
                Password
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <LockClosedIcon class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="password"
                  v-model="form.password"
                  :type="showPassword ? 'text' : 'password'"
                  required
                  autocomplete="current-password"
                  class="form-input pl-10 pr-10"
                  :class="{ 'border-red-500 focus:ring-red-500': passwordError }"
                  placeholder="••••••••"
                  @blur="validatePassword"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                  @click="showPassword = !showPassword"
                >
                  <EyeIcon v-if="!showPassword" class="h-5 w-5" />
                  <EyeSlashIcon v-else class="h-5 w-5" />
                </button>
              </div>
              <p v-if="passwordError" class="form-error">
                {{ passwordError }}
              </p>
            </div>

            <!-- Remember Me & Forgot Password -->
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <input
                  id="remember-me"
                  v-model="form.rememberMe"
                  type="checkbox"
                  class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                />
                <label for="remember-me" class="ml-2 block text-sm text-gray-700">
                  Remember me
                </label>
              </div>

              <div class="text-sm">
                <a href="#" class="font-medium text-primary-600 hover:text-primary-500" @click.prevent="handleForgotPassword">
                  Forgot password?
                </a>
              </div>
            </div>

            <!-- Submit Button -->
            <button
              type="submit"
              :disabled="loading"
              class="btn-primary w-full"
            >
              <span v-if="!loading">Sign In</span>
              <span v-else class="flex items-center justify-center">
                <div class="spinner mr-2"></div>
                Signing in...
              </span>
            </button>

            <!-- Dev Login Button (Development Only) -->
            <button
              v-if="showDevMode"
              type="button"
              @click="handleDevLogin"
              :disabled="loading"
              class="btn-outline w-full"
            >
              <span v-if="!loading">Dev Login (No Password)</span>
              <span v-else class="flex items-center justify-center">
                <div class="spinner mr-2"></div>
                Logging in...
              </span>
            </button>
          </form>

          <!-- Divider -->
          <div class="mt-6">
            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-gray-300"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-white text-gray-500">
                  Don't have an account?
                </span>
              </div>
            </div>
          </div>

          <!-- Register Link -->
          <div class="mt-6 text-center">
            <router-link
              to="/register"
              class="font-medium text-primary-600 hover:text-primary-500 transition-colors"
            >
              Create a new account
            </router-link>
          </div>
        </div>
      </div>

      <!-- Back to Home -->
      <div class="mt-6 text-center">
        <router-link
          to="/"
          class="inline-flex items-center text-sm text-gray-600 hover:text-gray-900 transition-colors"
        >
          <ArrowLeftIcon class="h-4 w-4 mr-2" />
          Back to Home
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import {
  EnvelopeIcon,
  LockClosedIcon,
  EyeIcon,
  EyeSlashIcon,
  ArrowLeftIcon,
  InformationCircleIcon,
  XCircleIcon,
  XMarkIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const toast = useToastStore()

// Form state
const form = ref({
  email: '',
  password: '',
  rememberMe: false
})

// UI state
const showPassword = ref(false)
const loading = ref(false)
const error = ref<string | null>(null)
const emailError = ref<string | null>(null)
const passwordError = ref<string | null>(null)

// Dev mode detection (check if running on localhost)
const showDevMode = computed(() => {
  return window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
})

// Validation
const validateEmail = () => {
  emailError.value = null
  if (!form.value.email) {
    emailError.value = 'Email is required'
    return false
  }
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(form.value.email)) {
    emailError.value = 'Please enter a valid email address'
    return false
  }
  return true
}

const validatePassword = () => {
  passwordError.value = null
  if (!form.value.password) {
    passwordError.value = 'Password is required'
    return false
  }
  if (form.value.password.length < 6) {
    passwordError.value = 'Password must be at least 6 characters'
    return false
  }
  return true
}

const validateForm = () => {
  const emailValid = validateEmail()
  const passwordValid = validatePassword()
  return emailValid && passwordValid
}

// Clear error
const clearError = () => {
  error.value = null
  authStore.clearError()
}

// Login handler
const handleLogin = async () => {
  clearError()

  if (!validateForm()) {
    return
  }

  loading.value = true

  try {
    await authStore.login({
      email: form.value.email,
      password: form.value.password
    })

    toast.success('Welcome back! Login successful.')

    // Redirect to intended page or dashboard
    const redirect = (route.query.redirect as string) || '/dashboard'
    router.push(redirect)
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Login failed. Please check your credentials.'
    console.error('Login error:', err)
  } finally {
    loading.value = false
  }
}

// Dev login handler (no password required)
const handleDevLogin = async () => {
  clearError()

  if (!form.value.email) {
    emailError.value = 'Email is required for dev login'
    return
  }

  loading.value = true

  try {
    await authStore.devLogin(form.value.email)

    toast.success('Dev login successful!')

    // Redirect to intended page or dashboard
    const redirect = (route.query.redirect as string) || '/dashboard'
    router.push(redirect)
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Dev login failed. Make sure dev mode is enabled on the server.'
    console.error('Dev login error:', err)
  } finally {
    loading.value = false
  }
}

// Forgot password handler
const handleForgotPassword = () => {
  toast.info('Password reset functionality coming soon!')
  // TODO: Navigate to password reset page when implemented
  // router.push('/forgot-password')
}
</script>
