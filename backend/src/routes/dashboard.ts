import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { getDashboard, getDailyAnalytics, getWeeklyAnalytics } from '../controllers/dashboardController';

const router = Router();

// All dashboard routes require authentication
router.use(authenticate);

router.get('/', getDashboard);
router.get('/analytics/daily', getDailyAnalytics);
router.get('/analytics/weekly', getWeeklyAnalytics);

export default router;
