<template>
  <AppLayout>
    <div>
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-display font-semibold text-gray-900 mb-2">
          Settings
        </h1>
        <p class="text-gray-600">
          Manage your account and application preferences
        </p>
      </div>

      <!-- Tabs -->
      <div class="mb-6">
        <div class="border-b border-gray-200">
          <nav class="-mb-px flex space-x-8">
            <button
              v-for="tab in tabs"
              :key="tab.id"
              class="py-4 px-1 border-b-2 font-medium text-sm transition-colors"
              :class="[
                activeTab === tab.id
                  ? 'border-primary-500 text-primary-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              ]"
              @click="activeTab = tab.id"
            >
              <component
                :is="tab.icon"
                class="h-5 w-5 inline-block mr-2"
              />
              {{ tab.name }}
            </button>
          </nav>
        </div>
      </div>

      <!-- Profile Tab -->
      <div
        v-if="activeTab === 'profile'"
        class="space-y-6"
      >
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">
              Profile Information
            </h2>
          </div>
          <div class="card-body">
            <form
              class="space-y-5"
              @submit.prevent="saveProfile"
            >
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label
                    for="firstName"
                    class="form-label"
                  >First Name *</label>
                  <input
                    id="firstName"
                    v-model="profileForm.firstName"
                    type="text"
                    required
                    class="form-input"
                  >
                </div>

                <div>
                  <label
                    for="lastName"
                    class="form-label"
                  >Last Name *</label>
                  <input
                    id="lastName"
                    v-model="profileForm.lastName"
                    type="text"
                    required
                    class="form-input"
                  >
                </div>
              </div>

              <div>
                <label
                  for="email"
                  class="form-label"
                >Email Address</label>
                <input
                  id="email"
                  v-model="profileForm.email"
                  type="email"
                  disabled
                  class="form-input bg-gray-50"
                >
                <p class="form-helper">
                  Email address cannot be changed. Contact support if you need to update it.
                </p>
              </div>

              <div>
                <label
                  for="phoneNumber"
                  class="form-label"
                >Phone Number</label>
                <input
                  id="phoneNumber"
                  v-model="profileForm.phoneNumber"
                  type="tel"
                  class="form-input"
                  placeholder="+1 (555) 123-4567"
                >
              </div>

              <div class="flex items-center justify-between pt-4 border-t border-gray-200">
                <div class="text-sm text-gray-500">
                  Last updated: {{ formatDate(authStore.user?.modifiedDate) }}
                </div>
                <button
                  type="submit"
                  :disabled="savingProfile"
                  class="btn-primary"
                >
                  <span v-if="!savingProfile">Save Changes</span>
                  <span
                    v-else
                    class="flex items-center"
                  >
                    <div class="spinner mr-2" />
                    Saving...
                  </span>
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <!-- Security Tab -->
      <div
        v-if="activeTab === 'security'"
        class="space-y-6"
      >
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">
              Change Password
            </h2>
          </div>
          <div class="card-body">
            <form
              class="space-y-5"
              @submit.prevent="changePassword"
            >
              <div>
                <label
                  for="currentPassword"
                  class="form-label"
                >Current Password *</label>
                <div class="relative">
                  <input
                    id="currentPassword"
                    v-model="passwordForm.currentPassword"
                    :type="showCurrentPassword ? 'text' : 'password'"
                    required
                    class="form-input pr-10"
                  >
                  <button
                    type="button"
                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                    @click="showCurrentPassword = !showCurrentPassword"
                  >
                    <EyeIcon
                      v-if="!showCurrentPassword"
                      class="h-5 w-5"
                    />
                    <EyeSlashIcon
                      v-else
                      class="h-5 w-5"
                    />
                  </button>
                </div>
              </div>

              <div>
                <label
                  for="newPassword"
                  class="form-label"
                >New Password *</label>
                <div class="relative">
                  <input
                    id="newPassword"
                    v-model="passwordForm.newPassword"
                    :type="showNewPassword ? 'text' : 'password'"
                    required
                    class="form-input pr-10"
                    @input="checkPasswordStrength"
                  >
                  <button
                    type="button"
                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                    @click="showNewPassword = !showNewPassword"
                  >
                    <EyeIcon
                      v-if="!showNewPassword"
                      class="h-5 w-5"
                    />
                    <EyeSlashIcon
                      v-else
                      class="h-5 w-5"
                    />
                  </button>
                </div>

                <!-- Password Strength Indicator -->
                <div
                  v-if="passwordForm.newPassword"
                  class="mt-2"
                >
                  <div class="flex items-center space-x-2">
                    <div class="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                      <div
                        class="h-full transition-all duration-300"
                        :class="[
                          passwordStrength === 'weak' ? 'bg-red-500 w-1/3' :
                          passwordStrength === 'medium' ? 'bg-amber-500 w-2/3' :
                          'bg-green-500 w-full'
                        ]"
                      />
                    </div>
                    <span
                      class="text-xs font-medium capitalize"
                      :class="[
                        passwordStrength === 'weak' ? 'text-red-600' :
                        passwordStrength === 'medium' ? 'text-amber-600' :
                        'text-green-600'
                      ]"
                    >
                      {{ passwordStrength }}
                    </span>
                  </div>
                  <p class="text-xs text-gray-500 mt-1">
                    Use at least 8 characters with a mix of letters, numbers, and symbols
                  </p>
                </div>
              </div>

              <div>
                <label
                  for="confirmPassword"
                  class="form-label"
                >Confirm New Password *</label>
                <div class="relative">
                  <input
                    id="confirmPassword"
                    v-model="passwordForm.confirmPassword"
                    :type="showConfirmPassword ? 'text' : 'password'"
                    required
                    class="form-input pr-10"
                  >
                  <button
                    type="button"
                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                    @click="showConfirmPassword = !showConfirmPassword"
                  >
                    <EyeIcon
                      v-if="!showConfirmPassword"
                      class="h-5 w-5"
                    />
                    <EyeSlashIcon
                      v-else
                      class="h-5 w-5"
                    />
                  </button>
                </div>
                <p
                  v-if="passwordForm.confirmPassword && passwordForm.newPassword !== passwordForm.confirmPassword"
                  class="text-sm text-red-600 mt-1"
                >
                  Passwords do not match
                </p>
              </div>

              <div class="flex items-center justify-end pt-4 border-t border-gray-200">
                <button
                  type="submit"
                  :disabled="changingPassword || !passwordsMatch"
                  class="btn-primary"
                >
                  <span v-if="!changingPassword">Change Password</span>
                  <span
                    v-else
                    class="flex items-center"
                  >
                    <div class="spinner mr-2" />
                    Changing...
                  </span>
                </button>
              </div>
            </form>
          </div>
        </div>

        <!-- Two-Factor Authentication -->
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">
              Two-Factor Authentication
            </h2>
          </div>
          <div class="card-body">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <h3 class="font-medium text-gray-900 mb-1">
                  {{ authStore.user?.mfaEnabled ? 'Enabled' : 'Disabled' }}
                </h3>
                <p class="text-sm text-gray-600">
                  Add an extra layer of security to your account by requiring a verification code when signing in.
                </p>
              </div>
              <button
                class="ml-4 btn-outline"
                :disabled="toggling2FA"
                @click="toggle2FA"
              >
                {{ authStore.user?.mfaEnabled ? 'Disable' : 'Enable' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Notifications Tab -->
      <div
        v-if="activeTab === 'notifications'"
        class="space-y-6"
      >
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">
              Email Notifications
            </h2>
          </div>
          <div class="card-body space-y-4">
            <div class="flex items-start justify-between py-3">
              <div class="flex-1">
                <h3 class="font-medium text-gray-900 mb-1">
                  Inspection Reminders
                </h3>
                <p class="text-sm text-gray-600">
                  Receive email reminders when inspections are due
                </p>
              </div>
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  v-model="notificationSettings.inspectionReminders"
                  type="checkbox"
                  class="sr-only peer"
                  @change="saveNotificationSettings"
                >
                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600" />
              </label>
            </div>

            <div class="flex items-start justify-between py-3 border-t border-gray-200">
              <div class="flex-1">
                <h3 class="font-medium text-gray-900 mb-1">
                  Failed Inspection Alerts
                </h3>
                <p class="text-sm text-gray-600">
                  Get notified when an extinguisher fails inspection
                </p>
              </div>
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  v-model="notificationSettings.failedInspectionAlerts"
                  type="checkbox"
                  class="sr-only peer"
                  @change="saveNotificationSettings"
                >
                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600" />
              </label>
            </div>

            <div class="flex items-start justify-between py-3 border-t border-gray-200">
              <div class="flex-1">
                <h3 class="font-medium text-gray-900 mb-1">
                  Weekly Reports
                </h3>
                <p class="text-sm text-gray-600">
                  Receive a weekly summary of inspection activity
                </p>
              </div>
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  v-model="notificationSettings.weeklyReports"
                  type="checkbox"
                  class="sr-only peer"
                  @change="saveNotificationSettings"
                >
                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600" />
              </label>
            </div>

            <div class="flex items-start justify-between py-3 border-t border-gray-200">
              <div class="flex-1">
                <h3 class="font-medium text-gray-900 mb-1">
                  System Updates
                </h3>
                <p class="text-sm text-gray-600">
                  Stay informed about new features and updates
                </p>
              </div>
              <label class="relative inline-flex items-center cursor-pointer">
                <input
                  v-model="notificationSettings.systemUpdates"
                  type="checkbox"
                  class="sr-only peer"
                  @change="saveNotificationSettings"
                >
                <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600" />
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- Preferences Tab -->
      <div
        v-if="activeTab === 'preferences'"
        class="space-y-6"
      >
        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">
              Display Preferences
            </h2>
          </div>
          <div class="card-body space-y-4">
            <div>
              <label
                for="dateFormat"
                class="form-label"
              >Date Format</label>
              <select
                id="dateFormat"
                v-model="preferences.dateFormat"
                class="form-input"
                @change="savePreferences"
              >
                <option value="MM/DD/YYYY">
                  MM/DD/YYYY (US)
                </option>
                <option value="DD/MM/YYYY">
                  DD/MM/YYYY (UK)
                </option>
                <option value="YYYY-MM-DD">
                  YYYY-MM-DD (ISO)
                </option>
              </select>
            </div>

            <div>
              <label
                for="timeFormat"
                class="form-label"
              >Time Format</label>
              <select
                id="timeFormat"
                v-model="preferences.timeFormat"
                class="form-input"
                @change="savePreferences"
              >
                <option value="12">
                  12-hour (AM/PM)
                </option>
                <option value="24">
                  24-hour
                </option>
              </select>
            </div>

            <div>
              <label
                for="itemsPerPage"
                class="form-label"
              >Items Per Page</label>
              <select
                id="itemsPerPage"
                v-model.number="preferences.itemsPerPage"
                class="form-input"
                @change="savePreferences"
              >
                <option :value="10">
                  10
                </option>
                <option :value="25">
                  25
                </option>
                <option :value="50">
                  50
                </option>
                <option :value="100">
                  100
                </option>
              </select>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h2 class="text-lg font-semibold text-gray-900">
              Data Management
            </h2>
          </div>
          <div class="card-body space-y-4">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <h3 class="font-medium text-gray-900 mb-1">
                  Export All Data
                </h3>
                <p class="text-sm text-gray-600">
                  Download a complete backup of your data in CSV format
                </p>
              </div>
              <button
                class="ml-4 btn-outline"
                :disabled="exporting"
                @click="exportData"
              >
                {{ exporting ? 'Exporting...' : 'Export' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import AppLayout from '@/components/layout/AppLayout.vue'
import {
  UserIcon,
  LockClosedIcon,
  BellIcon,
  Cog6ToothIcon,
  EyeIcon,
  EyeSlashIcon
} from '@heroicons/vue/24/outline'

const authStore = useAuthStore()
const toast = useToastStore()

const activeTab = ref('profile')
const savingProfile = ref(false)
const changingPassword = ref(false)
const toggling2FA = ref(false)
const exporting = ref(false)

const showCurrentPassword = ref(false)
const showNewPassword = ref(false)
const showConfirmPassword = ref(false)
const passwordStrength = ref('weak')

const tabs = [
  { id: 'profile', name: 'Profile', icon: UserIcon },
  { id: 'security', name: 'Security', icon: LockClosedIcon },
  { id: 'notifications', name: 'Notifications', icon: BellIcon },
  { id: 'preferences', name: 'Preferences', icon: Cog6ToothIcon }
]

const profileForm = ref({
  firstName: '',
  lastName: '',
  email: '',
  phoneNumber: ''
})

const passwordForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const notificationSettings = ref({
  inspectionReminders: true,
  failedInspectionAlerts: true,
  weeklyReports: false,
  systemUpdates: true
})

const preferences = ref({
  dateFormat: 'MM/DD/YYYY',
  timeFormat: '12',
  itemsPerPage: 25
})

const passwordsMatch = computed(() => {
  return passwordForm.value.newPassword === passwordForm.value.confirmPassword
})

onMounted(() => {
  if (authStore.user) {
    profileForm.value = {
      firstName: authStore.user.firstName || '',
      lastName: authStore.user.lastName || '',
      email: authStore.user.email || '',
      phoneNumber: authStore.user.phoneNumber || ''
    }
  }

  // Load saved preferences from localStorage
  const savedNotifications = localStorage.getItem('notificationSettings')
  if (savedNotifications) {
    notificationSettings.value = JSON.parse(savedNotifications)
  }

  const savedPreferences = localStorage.getItem('preferences')
  if (savedPreferences) {
    preferences.value = JSON.parse(savedPreferences)
  }
})

const saveProfile = async () => {
  savingProfile.value = true

  try {
    // In a real implementation, this would call an API endpoint
    await new Promise(resolve => setTimeout(resolve, 1000))

    // Update the auth store user
    if (authStore.user) {
      authStore.user.firstName = profileForm.value.firstName
      authStore.user.lastName = profileForm.value.lastName
      authStore.user.phoneNumber = profileForm.value.phoneNumber
    }

    toast.success('Profile updated successfully')
  } catch (error) {
    console.error('Failed to save profile:', error)
    toast.error('Failed to save profile')
  } finally {
    savingProfile.value = false
  }
}

const checkPasswordStrength = () => {
  const password = passwordForm.value.newPassword
  if (!password) {
    passwordStrength.value = 'weak'
    return
  }

  let strength = 0
  if (password.length >= 8) strength++
  if (password.length >= 12) strength++
  if (/[a-z]/.test(password)) strength++
  if (/[A-Z]/.test(password)) strength++
  if (/[0-9]/.test(password)) strength++
  if (/[^a-zA-Z0-9]/.test(password)) strength++

  if (strength <= 2) passwordStrength.value = 'weak'
  else if (strength <= 4) passwordStrength.value = 'medium'
  else passwordStrength.value = 'strong'
}

const changePassword = async () => {
  if (!passwordsMatch.value) {
    toast.error('Passwords do not match')
    return
  }

  if (passwordStrength.value === 'weak') {
    toast.error('Please choose a stronger password')
    return
  }

  changingPassword.value = true

  try {
    // In a real implementation, this would call an API endpoint
    await new Promise(resolve => setTimeout(resolve, 1000))

    toast.success('Password changed successfully')

    // Reset form
    passwordForm.value = {
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    }
  } catch (error) {
    console.error('Failed to change password:', error)
    toast.error('Failed to change password')
  } finally {
    changingPassword.value = false
  }
}

const toggle2FA = async () => {
  toggling2FA.value = true

  try {
    // In a real implementation, this would call an API endpoint
    await new Promise(resolve => setTimeout(resolve, 1000))

    const newStatus = !authStore.user?.mfaEnabled
    if (authStore.user) {
      authStore.user.mfaEnabled = newStatus
    }

    toast.success(`Two-factor authentication ${newStatus ? 'enabled' : 'disabled'}`)
  } catch (error) {
    console.error('Failed to toggle 2FA:', error)
    toast.error('Failed to update two-factor authentication')
  } finally {
    toggling2FA.value = false
  }
}

const saveNotificationSettings = () => {
  localStorage.setItem('notificationSettings', JSON.stringify(notificationSettings.value))
  toast.success('Notification settings saved')
}

const savePreferences = () => {
  localStorage.setItem('preferences', JSON.stringify(preferences.value))
  toast.success('Preferences saved')
}

const exportData = async () => {
  exporting.value = true

  try {
    toast.info('Preparing data export...')

    // Simulate export
    await new Promise(resolve => setTimeout(resolve, 2000))

    toast.success('Data exported successfully')
  } catch (error) {
    console.error('Failed to export data:', error)
    toast.error('Failed to export data')
  } finally {
    exporting.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return 'Never'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}
</script>
