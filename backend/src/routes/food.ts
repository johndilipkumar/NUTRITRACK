import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { upload } from '../middleware/upload';
import { analysisLimiter } from '../middleware/rateLimiter';
import {
  analyzeFoodImage,
  saveFood,
  saveManualFood,
  getFoodHistory,
  getFoodById,
  deleteFood,
} from '../controllers/foodController';

const router = Router();

// All food routes require authentication
router.use(authenticate);

// AI analysis — with stricter rate limit
router.post('/analyze', analysisLimiter, upload.single('image'), analyzeFoodImage);

// CRUD operations
router.post('/save', saveFood);
router.post('/manual', saveManualFood);
router.get('/history', getFoodHistory);
router.get('/:id', getFoodById);
router.delete('/:id', deleteFood);

export default router;
