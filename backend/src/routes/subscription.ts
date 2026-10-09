import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
  getAvailablePlans,
  getSubscriptionStatus,
  getSubscriptionHistory,
  getUsageHistory,
  cancelSubscription,
} from '../controllers/subscriptionController';
import {
  createCheckout,
  verifyPayment,
} from '../controllers/paymentController';

const router = Router();

// Public: list available plans (still needs auth to personalize)
router.get('/plans', getAvailablePlans);

// All subscription routes require authentication
router.use(authenticate);

// Current subscription and usage
router.get('/status', getSubscriptionStatus);
router.get('/history', getSubscriptionHistory);
router.get('/usage-history', getUsageHistory);

// Subscription management
router.post('/cancel', cancelSubscription);

// Payment
router.post('/checkout', createCheckout);
router.post('/verify-payment', verifyPayment);

export default router;
