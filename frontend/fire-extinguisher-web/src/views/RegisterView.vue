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
          Create Account
        </h1>
        <p class="text-gray-600">
          Join FireProof to manage fire safety inspections
        </p>
      </div>

      <!-- Register Card -->
      <div class="card">
        <div class="p-8">
          <!-- Error Alert -->
          <div v-if="error" class="alert-danger mb-6" data-testid="register-error">
            <XCircleIcon class="h-5 w-5" />
            <div>
              <p class="text-sm font-medium">{{ error }}</p>
            </div>
            <button
              type="button"
              class="text-red-400 hover:text-red-600"
              @click="clearError"
              data-testid="close-error"
            >
              <XMarkIcon class="h-5 w-5" />
            </button>
          </div>

          <!-- Success Message -->
          <div v-if="registrationSuccess" class="alert-success mb-6" data-testid="register-success">
            <CheckCircleIcon class="h-5 w-5" />
            <div>
              <p class="text-sm font-medium">Account created successfully!</p>
              <p class="text-xs mt-1">Redirecting to dashboard...</p>
            </div>
          </div>

          <!-- Registration Form -->
          <form v-if="!registrationSuccess" @submit.prevent="handleRegister" class="space-y-5">
            <!-- First Name -->
            <div>
              <label for="firstName" class="form-label">
                First Name
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <UserIcon class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="firstName"
                  v-model="form.firstName"
                  type="text"
                  required
                  autocomplete="given-name"
                  class="form-input pl-10"
                  :class="{ 'border-red-500 focus:ring-red-500': firstNameError }"
                  placeholder="John"
                  data-testid="firstname-input"
                  @blur="validateFirstName"
                />
              </div>
              <p v-if="firstNameError" class="form-error">
                {{ firstNameError }}
              </p>
            </div>

            <!-- Last Name -->
            <div>
              <label for="lastName" class="form-label">
                Last Name
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <UserIcon class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="lastName"
                  v-model="form.lastName"
                  type="text"
                  required
                  autocomplete="family-name"
                  class="form-input pl-10"
                  :class="{ 'border-red-500 focus:ring-red-500': lastNameError }"
                  placeholder="Doe"
                  data-testid="lastname-input"
                  @blur="validateLastName"
                />
              </div>
              <p v-if="lastNameError" class="form-error">
                {{ lastNameError }}
              </p>
            </div>

            <!-- Email -->
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
                  placeholder="john@example.com"
                  data-testid="register-email-input"
                  @blur="validateEmail"
                />
              </div>
              <p v-if="emailError" class="form-error">
                {{ emailError }}
              </p>
            </div>

            <!-- Password -->
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
                  autocomplete="new-password"
                  class="form-input pl-10 pr-10"
                  :class="{ 'border-red-500 focus:ring-red-500': passwordError }"
                  placeholder="••••••••"
                  data-testid="register-password-input"
                  @input="checkPasswordStrength"
                  @blur="validatePassword"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                  data-testid="toggle-register-password-visibility"
                  @click="showPassword = !showPassword"
                >
                  <EyeIcon v-if="!showPassword" class="h-5 w-5" />
                  <EyeSlashIcon v-else class="h-5 w-5" />
                </button>
              </div>

              <!-- Password Strength Indicator -->
              <div v-if="form.password" class="mt-2">
                <div class="flex items-center justify-between text-xs mb-1">
                  <span class="text-gray-600">Password strength:</span>
                  <span
                    :class="{
                      'text-red-600': passwordStrength === 'weak',
                      'text-accent-600': passwordStrength === 'medium',
                      'text-secondary-600': passwordStrength === 'strong'
                    }"
                  >
                    {{ passwordStrength.toUpperCase() }}
                  </span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-1.5">
                  <div
                    class="h-1.5 rounded-full transition-all duration-300"
                    :class="{
                      'bg-red-500 w-1/3': passwordStrength === 'weak',
                      'bg-accent-500 w-2/3': passwordStrength === 'medium',
                      'bg-secondary-500 w-full': passwordStrength === 'strong'
                    }"
                  ></div>
                </div>
              </div>

              <p v-if="passwordError" class="form-error">
                {{ passwordError }}
              </p>
              <p v-else class="form-helper">
                Must be at least 8 characters with uppercase, lowercase, and number
              </p>
            </div>

            <!-- Confirm Password -->
            <div>
              <label for="confirmPassword" class="form-label">
                Confirm Password
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <LockClosedIcon class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="confirmPassword"
                  v-model="form.confirmPassword"
                  :type="showConfirmPassword ? 'text' : 'password'"
                  required
                  autocomplete="new-password"
                  class="form-input pl-10 pr-10"
                  :class="{ 'border-red-500 focus:ring-red-500': confirmPasswordError }"
                  placeholder="••••••••"
                  data-testid="confirm-password-input"
                  @blur="validateConfirmPassword"
                />
                <button
                  type="button"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                  data-testid="toggle-confirm-password-visibility"
                  @click="showConfirmPassword = !showConfirmPassword"
                >
                  <EyeIcon v-if="!showConfirmPassword" class="h-5 w-5" />
                  <EyeSlashIcon v-else class="h-5 w-5" />
                </button>
              </div>
              <p v-if="confirmPasswordError" class="form-error">
                {{ confirmPasswordError }}
              </p>
            </div>

            <!-- Terms & Conditions -->
            <div>
              <div class="flex items-start">
                <input
                  id="terms"
                  v-model="form.acceptTerms"
                  type="checkbox"
                  class="h-4 w-4 mt-1 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  data-testid="accept-terms-checkbox"
                />
                <label for="terms" class="ml-2 block text-sm text-gray-700">
                  I agree to the
                  <a href="#" class="font-medium text-primary-600 hover:text-primary-500" data-testid="terms-link" @click.prevent="showTerms">
                    Terms of Service
                  </a>
                  and
                  <a href="#" class="font-medium text-primary-600 hover:text-primary-500" data-testid="privacy-link" @click.prevent="showPrivacy">
                    Privacy Policy
                  </a>
                </label>
              </div>
              <p v-if="termsError" class="form-error ml-6">
                {{ termsError }}
              </p>
            </div>

            <!-- Submit Button -->
            <button
              type="submit"
              :disabled="loading"
              class="btn-primary w-full"
              data-testid="register-submit-button"
            >
              <span v-if="!loading">Create Account</span>
              <span v-else class="flex items-center justify-center">
                <div class="spinner mr-2"></div>
                Creating account...
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
                  Already have an account?
                </span>
              </div>
            </div>
          </div>

          <!-- Login Link -->
          <div class="mt-6 text-center">
            <router-link
              to="/login"
              class="font-medium text-primary-600 hover:text-primary-500 transition-colors"
              data-testid="login-link"
            >
              Sign in to your account
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
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import {
  UserIcon,
  EnvelopeIcon,
  LockClosedIcon,
  EyeIcon,
  EyeSlashIcon,
  ArrowLeftIcon,
  XCircleIcon,
  XMarkIcon,
  CheckCircleIcon
} from '@heroicons/vue/24/outline'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToastStore()

// Form state
const form = ref({
  firstName: '',
  lastName: '',
  email: '',
  password: '',
  confirmPassword: '',
  acceptTerms: false
})

// UI state
const showPassword = ref(false)
const showConfirmPassword = ref(false)
const loading = ref(false)
const registrationSuccess = ref(false)
const error = ref<string | null>(null)
const passwordStrength = ref<'weak' | 'medium' | 'strong'>('weak')

// Validation errors
const firstNameError = ref<string | null>(null)
const lastNameError = ref<string | null>(null)
const emailError = ref<string | null>(null)
const passwordError = ref<string | null>(null)
const confirmPasswordError = ref<string | null>(null)
const termsError = ref<string | null>(null)

// Validation functions
const validateFirstName = () => {
  firstNameError.value = null
  if (!form.value.firstName) {
    firstNameError.value = 'First name is required'
    return false
  }
  if (form.value.firstName.length < 2) {
    firstNameError.value = 'First name must be at least 2 characters'
    return false
  }
  return true
}

const validateLastName = () => {
  lastNameError.value = null
  if (!form.value.lastName) {
    lastNameError.value = 'Last name is required'
    return false
  }
  if (form.value.lastName.length < 2) {
    lastNameError.value = 'Last name must be at least 2 characters'
    return false
  }
  return true
}

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

const checkPasswordStrength = () => {
  const password = form.value.password

  if (!password) {
    passwordStrength.value = 'weak'
    return
  }

  let strength = 0

  // Length check
  if (password.length >= 8) strength++
  if (password.length >= 12) strength++

  // Character variety checks
  if (/[a-z]/.test(password)) strength++
  if (/[A-Z]/.test(password)) strength++
  if (/[0-9]/.test(password)) strength++
  if (/[^a-zA-Z0-9]/.test(password)) strength++

  if (strength <= 2) {
    passwordStrength.value = 'weak'
  } else if (strength <= 4) {
    passwordStrength.value = 'medium'
  } else {
    passwordStrength.value = 'strong'
  }
}

const validatePassword = () => {
  passwordError.value = null
  if (!form.value.password) {
    passwordError.value = 'Password is required'
    return false
  }
  if (form.value.password.length < 8) {
    passwordError.value = 'Password must be at least 8 characters'
    return false
  }
  if (!/[a-z]/.test(form.value.password)) {
    passwordError.value = 'Password must contain at least one lowercase letter'
    return false
  }
  if (!/[A-Z]/.test(form.value.password)) {
    passwordError.value = 'Password must contain at least one uppercase letter'
    return false
  }
  if (!/[0-9]/.test(form.value.password)) {
    passwordError.value = 'Password must contain at least one number'
    return false
  }
  return true
}

const validateConfirmPassword = () => {
  confirmPasswordError.value = null
  if (!form.value.confirmPassword) {
    confirmPasswordError.value = 'Please confirm your password'
    return false
  }
  if (form.value.password !== form.value.confirmPassword) {
    confirmPasswordError.value = 'Passwords do not match'
    return false
  }
  return true
}

const validateTerms = () => {
  termsError.value = null
  if (!form.value.acceptTerms) {
    termsError.value = 'You must accept the terms and conditions'
    return false
  }
  return true
}

const validateForm = () => {
  const firstNameValid = validateFirstName()
  const lastNameValid = validateLastName()
  const emailValid = validateEmail()
  const passwordValid = validatePassword()
  const confirmPasswordValid = validateConfirmPassword()
  const termsValid = validateTerms()

  return firstNameValid && lastNameValid && emailValid &&
         passwordValid && confirmPasswordValid && termsValid
}

// Clear error
const clearError = () => {
  error.value = null
  authStore.clearError()
}

// Register handler
const handleRegister = async () => {
  clearError()

  if (!validateForm()) {
    return
  }

  loading.value = true

  try {
    await authStore.register({
      email: form.value.email,
      password: form.value.password,
      firstName: form.value.firstName,
      lastName: form.value.lastName
    })

    registrationSuccess.value = true
    toast.success('Account created successfully! Welcome to FireProof.')

    // Redirect to dashboard after a short delay
    setTimeout(() => {
      router.push('/dashboard')
    }, 2000)
  } catch (err: any) {
    error.value = err.response?.data?.message || 'Registration failed. Please try again.'
    console.error('Registration error:', err)
  } finally {
    loading.value = false
  }
}

// Show terms/privacy (placeholder)
const showTerms = () => {
  toast.info('Terms of Service - Coming soon')
  // TODO: Open terms modal or navigate to terms page
}

const showPrivacy = () => {
  toast.info('Privacy Policy - Coming soon')
  // TODO: Open privacy modal or navigate to privacy page
}
</script>
