<template>
  <div class="inspector-login">
    <div class="login-container">
      <!-- Logo/Branding -->
      <div class="branding">
        <div class="logo-icon">
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
          >
            <path d="M9 3v18M15 3v18M3 9h18M3 15h18" />
          </svg>
        </div>
        <h1
          class="app-title"
          data-testid="app-title"
        >
          FireProof Inspector
        </h1>
        <p class="app-subtitle">
          Fire Extinguisher Inspections
        </p>
      </div>

      <!-- Login Form -->
      <form
        class="login-form"
        data-testid="login-form"
        @submit.prevent="handleLogin"
      >
        <!-- Error Alert -->
        <div
          v-if="error"
          class="alert-error"
          role="alert"
          data-testid="error-alert"
        >
          <svg
            class="alert-icon"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
          >
            <circle
              cx="12"
              cy="12"
              r="10"
            />
            <line
              x1="15"
              y1="9"
              x2="9"
              y2="15"
            />
            <line
              x1="9"
              y1="9"
              x2="15"
              y2="15"
            />
          </svg>
          <span>{{ error }}</span>
        </div>

        <!-- Email Field -->
        <div class="form-group">
          <label
            for="email"
            class="form-label"
          >Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            autocomplete="email"
            required
            class="form-input"
            data-testid="email-input"
            placeholder="inspector@example.com"
            :disabled="isLoading"
          >
        </div>

        <!-- Password Field -->
        <div class="form-group">
          <label
            for="password"
            class="form-label"
          >Password</label>
          <input
            id="password"
            v-model="password"
            type="password"
            autocomplete="current-password"
            required
            class="form-input"
            data-testid="password-input"
            placeholder="Enter your password"
            :disabled="isLoading"
          >
        </div>

        <!-- Submit Button -->
        <button
          type="submit"
          class="btn-primary"
          data-testid="login-button"
          :disabled="isLoading || !email || !password"
        >
          <span v-if="!isLoading">Sign In</span>
          <span
            v-else
            class="loading-text"
          >
            <svg
              class="loading-spinner"
              viewBox="0 0 24 24"
            >
              <circle
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
                fill="none"
                stroke-dasharray="32"
                stroke-dashoffset="32"
              />
            </svg>
            Signing in...
          </span>
        </button>
      </form>

      <!-- Footer Info -->
      <div class="login-footer">
        <p class="footer-text">
          Inspector access only
        </p>
        <p class="footer-text footer-version">
          Version 1.0
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useInspectorStore } from '@/stores/useInspectorStore'

const router = useRouter()
const inspectorStore = useInspectorStore()

// Form state
const email = ref('')
const password = ref('')
const error = ref('')
const isLoading = ref(false)

/**
 * Handle login form submission
 */
const handleLogin = async () => {
  error.value = ''
  isLoading.value = true

  try {
    await inspectorStore.login(email.value, password.value)

    // Success - redirect to dashboard
    router.push('/inspector/dashboard')
  } catch (err) {
    error.value = err.response?.data?.message || err.message || 'Login failed. Please check your credentials.'
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
/* Container */
.inspector-login {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f9fafb;
  padding: 1rem;
}

.login-container {
  width: 100%;
  max-width: 400px;
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 2rem;
}

/* Branding */
.branding {
  text-align: center;
  margin-bottom: 2rem;
}

.logo-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto 1rem;
  background: #3b82f6;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.logo-icon svg {
  width: 40px;
  height: 40px;
}

.app-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 0.5rem 0;
}

.app-subtitle {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

/* Form */
.login-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: #374151;
}

.form-input {
  padding: 0.75rem 1rem;
  font-size: 1rem;
  border: 2px solid #e5e7eb;
  border-radius: 0.375rem;
  transition: all 0.2s;
  background: white;
}

.form-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-input:disabled {
  background: #f3f4f6;
  cursor: not-allowed;
}

.form-input::placeholder {
  color: #9ca3af;
}

/* Alert */
.alert-error {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 0.375rem;
  color: #dc2626;
  font-size: 0.875rem;
}

.alert-icon {
  width: 20px;
  height: 20px;
  flex-shrink: 0;
  stroke-width: 2;
}

/* Button */
.btn-primary {
  padding: 0.875rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  color: white;
  background: #3b82f6;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  min-height: 48px; /* Touch target */
}

.btn-primary:hover:not(:disabled) {
  background: #2563eb;
}

.btn-primary:active:not(:disabled) {
  background: #1d4ed8;
  transform: scale(0.98);
}

.btn-primary:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}

.loading-text {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.loading-spinner {
  width: 20px;
  height: 20px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
    stroke-dashoffset: 32;
  }
  to {
    transform: rotate(360deg);
    stroke-dashoffset: 0;
  }
}

/* Footer */
.login-footer {
  margin-top: 2rem;
  text-align: center;
}

.footer-text {
  font-size: 0.75rem;
  color: #9ca3af;
  margin: 0.25rem 0;
}

.footer-version {
  font-weight: 600;
}

/* Mobile Optimization */
@media (max-width: 640px) {
  .login-container {
    padding: 1.5rem;
  }

  .app-title {
    font-size: 1.25rem;
  }

  .form-input,
  .btn-primary {
    font-size: 16px; /* Prevent iOS zoom */
  }

  /* Ensure touch targets are large enough */
  .btn-primary {
    min-height: 44px; /* Apple HIG minimum */
  }
}

/* Focus visible for accessibility */
*:focus-visible {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}
</style>
