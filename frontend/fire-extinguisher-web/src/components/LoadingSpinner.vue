<template>
  <div
    v-if="show"
    class="loading-spinner-container"
    :class="containerClass"
  >
    <div
      class="loading-spinner"
      :class="sizeClass"
    >
      <div class="spinner" />
      <p
        v-if="message"
        class="loading-message"
      >
        {{ message }}
      </p>
    </div>
  </div>
</template>

<script setup>
import { defineProps } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: true
  },
  message: {
    type: String,
    default: 'Please wait...'
  },
  size: {
    type: String,
    default: 'medium',
    validator: (value) => ['small', 'medium', 'large'].includes(value)
  },
  overlay: {
    type: Boolean,
    default: false
  }
})

const sizeClass = {
  'spinner-small': props.size === 'small',
  'spinner-medium': props.size === 'medium',
  'spinner-large': props.size === 'large'
}

const containerClass = {
  'overlay': props.overlay,
  'inline': !props.overlay
}
</script>

<style scoped>
.loading-spinner-container {
  display: flex;
  justify-content: center;
  align-items: center;
}

.loading-spinner-container.overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(255, 255, 255, 0.9);
  z-index: 9999;
}

.loading-spinner-container.inline {
  padding: 2rem;
}

.loading-spinner {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.spinner {
  border: 4px solid #f3f4f6;
  border-top: 4px solid #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.spinner-small .spinner {
  width: 24px;
  height: 24px;
  border-width: 3px;
}

.spinner-medium .spinner {
  width: 48px;
  height: 48px;
  border-width: 4px;
}

.spinner-large .spinner {
  width: 72px;
  height: 72px;
  border-width: 6px;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.loading-message {
  color: #6b7280;
  font-size: 0.875rem;
  font-weight: 500;
  text-align: center;
  margin: 0;
}

.spinner-large + .loading-message {
  font-size: 1rem;
}

.spinner-small + .loading-message {
  font-size: 0.75rem;
}
</style>
