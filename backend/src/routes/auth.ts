import { Router } from 'express';
import { register, login, resetPasswordRequest, resetPassword } from '../controllers/authController';
import { authLimiter } from '../middleware/rateLimiter';

const router = Router();

// Apply auth rate limiter to all auth routes
router.use(authLimiter);

router.post('/register', register);
router.post('/login', login);
router.post('/reset-password-request', resetPasswordRequest);
router.post('/reset-password', resetPassword);

export default router;
