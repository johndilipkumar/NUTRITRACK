import fs from 'fs';
import path from 'path';
import { env } from '../config/env';

/**
 * Storage service abstraction for food images.
 * MVP uses local filesystem storage. Can be swapped for Cloudinary/Supabase later
 * by implementing the same interface.
 */

/**
 * Returns the public URL for an uploaded image.
 * For local storage, this creates a URL path served by Express static middleware.
 */
export function getImageUrl(filename: string): string {
  return `/uploads/${filename}`;
}

/**
 * Deletes an image file from storage.
 * @param imageUrl - The URL/path of the image to delete
 */
export function deleteImage(imageUrl: string): void {
  try {
    // Extract filename from URL path
    const filename = imageUrl.replace('/uploads/', '');
    const filePath = path.resolve(env.UPLOAD_DIR, filename);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  } catch (error) {
    // Log but don't throw — image deletion failure shouldn't break the main operation
    console.error('Failed to delete image:', error);
  }
}

/**
 * Gets the absolute filesystem path for an uploaded image.
 * Used internally for passing images to the Gemini service.
 */
export function getImagePath(filename: string): string {
  return path.resolve(env.UPLOAD_DIR, filename);
}
