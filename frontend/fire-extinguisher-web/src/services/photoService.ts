import api from './api'
import type { InspectionPhotoDto, PhotoUploadResponse } from '@/types/api'

/**
 * Photo Service
 * Mobile-first photo management with EXIF extraction and thumbnail generation
 * Supports batch upload for offline queue sync
 */
const photoService = {
  /**
   * Upload a single photo with EXIF extraction
   * Supports JPEG, PNG, HEIC (iOS native format)
   * Max file size: 50 MB
   * @param inspectionId - Inspection UUID
   * @param photoType - Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other
   * @param file - Photo file from camera or file input
   * @param captureDate - Optional override for capture date
   * @returns Promise resolving to upload response with signed URLs
   */
  async uploadPhoto(
    inspectionId: string,
    photoType: string,
    file: File,
    captureDate?: string | null
  ): Promise<PhotoUploadResponse> {
    const formData = new FormData()
    formData.append('inspectionId', inspectionId)
    formData.append('photoType', photoType)
    formData.append('file', file)
    if (captureDate) {
      formData.append('captureDate', captureDate)
    }

    const response = await api.post<PhotoUploadResponse>('/photos', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    return response.data
  },

  /**
   * Upload multiple photos in batch (offline queue sync)
   * Max batch size: 50 photos, 500 MB total
   * @param photos - Array of photo upload requests
   * @returns Promise resolving to array of upload responses
   */
  async uploadPhotosBatch(
    photos: Array<{
      inspectionId: string
      photoType: string
      file: File
      captureDate?: string | null
    }>
  ): Promise<PhotoUploadResponse[]> {
    const formData = new FormData()

    // Append each photo with indexed field names for model binding
    photos.forEach((photo, index) => {
      formData.append(`[${index}].inspectionId`, photo.inspectionId)
      formData.append(`[${index}].photoType`, photo.photoType)
      formData.append(`[${index}].file`, photo.file)
      if (photo.captureDate) {
        formData.append(`[${index}].captureDate`, photo.captureDate)
      }
    })

    const response = await api.post<PhotoUploadResponse[]>('/photos/batch', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    return response.data
  },

  /**
   * Get a specific photo by ID
   * @param photoId - Photo UUID
   * @returns Promise resolving to photo details with EXIF data
   */
  async getById(photoId: string): Promise<InspectionPhotoDto> {
    const response = await api.get<InspectionPhotoDto>(`/photos/${photoId}`)
    return response.data
  },

  /**
   * Get all photos for an inspection
   * @param inspectionId - Inspection UUID
   * @returns Promise resolving to array of photos
   */
  async getByInspection(inspectionId: string): Promise<InspectionPhotoDto[]> {
    const response = await api.get<InspectionPhotoDto[]>(`/photos/inspection/${inspectionId}`)
    return response.data
  },

  /**
   * Get photos by type for an inspection
   * @param inspectionId - Inspection UUID
   * @param photoType - Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other
   * @returns Promise resolving to array of photos
   */
  async getByType(inspectionId: string, photoType: string): Promise<InspectionPhotoDto[]> {
    const response = await api.get<InspectionPhotoDto[]>(`/photos/inspection/${inspectionId}/type/${photoType}`)
    return response.data
  },

  /**
   * Get signed URL for photo access (time-limited)
   * @param photoId - Photo UUID
   * @param expirationMinutes - URL expiration (5-1440 minutes, default 60)
   * @returns Promise resolving to signed URL
   */
  async getPhotoUrl(photoId: string, expirationMinutes: number = 60): Promise<string> {
    const params = { expirationMinutes }
    const response = await api.get<{ url: string; expiresIn: number }>(`/photos/${photoId}/url`, { params })
    return response.data.url
  },

  /**
   * Get signed URL for thumbnail (mobile list optimization)
   * @param photoId - Photo UUID
   * @param expirationMinutes - URL expiration (5-1440 minutes, default 60)
   * @returns Promise resolving to signed thumbnail URL
   */
  async getThumbnailUrl(photoId: string, expirationMinutes: number = 60): Promise<string> {
    const params = { expirationMinutes }
    const response = await api.get<{ url: string; expiresIn: number }>(`/photos/${photoId}/thumbnail`, { params })
    return response.data.url
  },

  /**
   * Delete a photo from Azure Blob Storage and database
   * @param photoId - Photo UUID
   * @returns Promise resolving when delete is complete
   */
  async delete(photoId: string): Promise<void> {
    await api.delete(`/photos/${photoId}`)
  },

  /**
   * Get camera constraints for mobile photo capture
   * Optimized for NFPA inspection photos
   * @returns Camera constraints object for getUserMedia
   */
  getCameraConstraints(): MediaStreamConstraints {
    return {
      video: {
        facingMode: { ideal: 'environment' }, // Prefer rear camera
        width: { ideal: 1920 },
        height: { ideal: 1080 },
        aspectRatio: { ideal: 16 / 9 }
      },
      audio: false
    }
  },

  /**
   * Convert canvas to Blob for upload
   * @param canvas - Canvas element with captured photo
   * @param quality - JPEG quality (0-1, default 0.9)
   * @returns Promise resolving to photo Blob
   */
  async canvasToBlob(canvas: HTMLCanvasElement, quality: number = 0.9): Promise<Blob> {
    return new Promise((resolve, reject) => {
      canvas.toBlob(
        (blob) => {
          if (blob) {
            resolve(blob)
          } else {
            reject(new Error('Canvas to Blob conversion failed'))
          }
        },
        'image/jpeg',
        quality
      )
    })
  }
}

export default photoService
