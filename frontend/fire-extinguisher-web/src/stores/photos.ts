import { defineStore } from 'pinia'
import photoService from '@/services/photoService'
import type { InspectionPhotoDto, PhotoUploadResponse } from '@/types/api'

interface PhotoState {
  photos: InspectionPhotoDto[]
  currentPhoto: InspectionPhotoDto | null
  uploadQueue: Array<{
    inspectionId: string
    photoType: string
    file: File
    captureDate?: string | null
    localId: string // Temporary ID for tracking
    status: 'pending' | 'uploading' | 'uploaded' | 'failed'
    uploadedPhotoId?: string | null
    error?: string | null
  }>
  cameraActive: boolean
  loading: boolean
  error: string | null
}

export const usePhotoStore = defineStore('photos', {
  state: (): PhotoState => ({
    photos: [],
    currentPhoto: null,
    uploadQueue: [],
    cameraActive: false,
    loading: false,
    error: null
  }),

  getters: {
    photoCount: (state): number => state.photos.length,

    getPhotoById: (state) => (id: string): InspectionPhotoDto | undefined => {
      return state.photos.find(photo => photo.photoId === id)
    },

    /**
     * Get photos by inspection
     */
    getPhotosByInspection: (state) => (inspectionId: string): InspectionPhotoDto[] => {
      return state.photos.filter(photo => photo.inspectionId === inspectionId)
    },

    /**
     * Get photos by type
     */
    getPhotosByType: (state) => (photoType: string): InspectionPhotoDto[] => {
      return state.photos.filter(photo => photo.photoType === photoType)
    },

    /**
     * Get pending uploads count
     */
    pendingUploadsCount: (state): number => {
      return state.uploadQueue.filter(item => item.status === 'pending').length
    },

    /**
     * Get failed uploads count
     */
    failedUploadsCount: (state): number => {
      return state.uploadQueue.filter(item => item.status === 'failed').length
    },

    /**
     * Check if upload queue has items
     */
    hasQueuedUploads: (state): boolean => {
      return state.uploadQueue.length > 0
    },

    /**
     * Check if any uploads are in progress
     */
    isUploading: (state): boolean => {
      return state.uploadQueue.some(item => item.status === 'uploading')
    }
  },

  actions: {
    async uploadPhoto(
      inspectionId: string,
      photoType: string,
      file: File,
      captureDate?: string | null
    ): Promise<PhotoUploadResponse> {
      this.loading = true
      this.error = null

      try {
        const response = await photoService.uploadPhoto(inspectionId, photoType, file, captureDate)
        return response
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to upload photo'
        console.error('Error uploading photo:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async uploadPhotosBatch(
      photos: Array<{
        inspectionId: string
        photoType: string
        file: File
        captureDate?: string | null
      }>
    ): Promise<PhotoUploadResponse[]> {
      this.loading = true
      this.error = null

      try {
        const responses = await photoService.uploadPhotosBatch(photos)
        return responses
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to upload photos'
        console.error('Error uploading photos batch:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Add photo to upload queue (offline support)
     */
    queuePhotoUpload(inspectionId: string, photoType: string, file: File, captureDate?: string | null): string {
      const localId = `local-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

      this.uploadQueue.push({
        inspectionId,
        photoType,
        file,
        captureDate,
        localId,
        status: 'pending'
      })

      return localId
    },

    /**
     * Process upload queue (sync queued photos when online)
     */
    async processUploadQueue(): Promise<void> {
      if (!navigator.onLine) {
        console.log('Offline - upload queue processing deferred')
        return
      }

      const pendingItems = this.uploadQueue.filter(item => item.status === 'pending')

      for (const item of pendingItems) {
        // Mark as uploading
        item.status = 'uploading'

        try {
          const response = await photoService.uploadPhoto(
            item.inspectionId,
            item.photoType,
            item.file,
            item.captureDate
          )

          // Mark as uploaded
          item.status = 'uploaded'
          item.uploadedPhotoId = response.photoId

          // Remove from queue after successful upload
          this.uploadQueue = this.uploadQueue.filter(i => i.localId !== item.localId)
        } catch (error: any) {
          // Mark as failed
          item.status = 'failed'
          item.error = error.response?.data?.message || 'Upload failed'
          console.error('Error uploading queued photo:', error)
        }
      }
    },

    /**
     * Retry failed uploads
     */
    async retryFailedUploads(): Promise<void> {
      const failedItems = this.uploadQueue.filter(item => item.status === 'failed')

      failedItems.forEach(item => {
        item.status = 'pending'
        item.error = null
      })

      await this.processUploadQueue()
    },

    /**
     * Clear uploaded items from queue
     */
    clearUploadedFromQueue(): void {
      this.uploadQueue = this.uploadQueue.filter(item => item.status !== 'uploaded')
    },

    /**
     * Remove item from queue
     */
    removeFromQueue(localId: string): void {
      this.uploadQueue = this.uploadQueue.filter(item => item.localId !== localId)
    },

    async fetchPhotoById(id: string): Promise<InspectionPhotoDto> {
      this.loading = true
      this.error = null

      try {
        this.currentPhoto = await photoService.getById(id)
        return this.currentPhoto
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch photo'
        console.error('Error fetching photo:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchPhotosByInspection(inspectionId: string): Promise<InspectionPhotoDto[]> {
      this.loading = true
      this.error = null

      try {
        const photos = await photoService.getByInspection(inspectionId)
        // Merge with existing photos (avoid duplicates)
        photos.forEach(photo => {
          const index = this.photos.findIndex(p => p.photoId === photo.photoId)
          if (index === -1) {
            this.photos.push(photo)
          } else {
            this.photos[index] = photo
          }
        })
        return photos
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch photos'
        console.error('Error fetching photos:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchPhotosByType(inspectionId: string, photoType: string): Promise<InspectionPhotoDto[]> {
      this.loading = true
      this.error = null

      try {
        const photos = await photoService.getByType(inspectionId, photoType)
        // Merge with existing photos (avoid duplicates)
        photos.forEach(photo => {
          const index = this.photos.findIndex(p => p.photoId === photo.photoId)
          if (index === -1) {
            this.photos.push(photo)
          } else {
            this.photos[index] = photo
          }
        })
        return photos
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to fetch photos by type'
        console.error('Error fetching photos by type:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async getPhotoUrl(photoId: string, expirationMinutes: number = 60): Promise<string> {
      this.error = null

      try {
        return await photoService.getPhotoUrl(photoId, expirationMinutes)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to get photo URL'
        console.error('Error getting photo URL:', error)
        throw error
      }
    },

    async getThumbnailUrl(photoId: string, expirationMinutes: number = 60): Promise<string> {
      this.error = null

      try {
        return await photoService.getThumbnailUrl(photoId, expirationMinutes)
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to get thumbnail URL'
        console.error('Error getting thumbnail URL:', error)
        throw error
      }
    },

    async deletePhoto(id: string): Promise<void> {
      this.loading = true
      this.error = null

      try {
        await photoService.delete(id)

        // Remove from local state
        this.photos = this.photos.filter(photo => photo.photoId !== id)

        if (this.currentPhoto?.photoId === id) {
          this.currentPhoto = null
        }
      } catch (error: any) {
        this.error = error.response?.data?.message || 'Failed to delete photo'
        console.error('Error deleting photo:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    /**
     * Initialize camera for photo capture
     */
    async initializeCamera(): Promise<MediaStream> {
      this.cameraActive = true
      this.error = null

      try {
        const constraints = photoService.getCameraConstraints()
        const stream = await navigator.mediaDevices.getUserMedia(constraints)
        return stream
      } catch (error: any) {
        this.error = 'Failed to access camera: ' + error.message
        this.cameraActive = false
        console.error('Error initializing camera:', error)
        throw error
      }
    },

    /**
     * Stop camera stream
     */
    stopCamera(stream: MediaStream): void {
      stream.getTracks().forEach(track => track.stop())
      this.cameraActive = false
    },

    clearError(): void {
      this.error = null
    }
  }
})
