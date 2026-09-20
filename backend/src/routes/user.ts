import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { getProfile, updateProfile, deleteAccount } from '../controllers/userController';

const router = Router();

// All user routes require authentication
router.use(authenticate);

router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.delete('/account', deleteAccount);

export default router;
