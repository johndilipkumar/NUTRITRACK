import multer from 'multer';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import { env } from '../config/env';

// Ensure uploads directory exists
const uploadDir = path.resolve(env.UPLOAD_DIR);
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer storage — saves files to local uploads/ directory
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadDir);
  },
  filename: (_req, file, cb) => {
    // Generate unique filename to prevent collisions
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueName = `${uuidv4()}${ext}`;
    cb(null, uniqueName);
  },
});

// Allowed MIME types for food images
const ALLOWED_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
];

const fileFilter = (
  _req: Express.Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback
) => {
  if (ALLOWED_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG, WebP, and HEIC images are allowed.'));
  }
};

/**
 * Multer upload middleware configured for food images.
 * - Max file size: 10MB (configurable via MAX_FILE_SIZE env var)
 * - Allowed types: JPEG, PNG, WebP, HEIC
 * - Storage: Local filesystem in uploads/ directory
 */
export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: parseInt(env.MAX_FILE_SIZE, 10),
  },
});
