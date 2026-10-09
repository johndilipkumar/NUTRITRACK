import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { requireAdmin } from '../middleware/adminAuth';
import {
  getPlans,
  createPlan,
  updatePlan,
  getUsers,
  getUserDetails,
  adjustCredits,
  assignPlan,
  toggleAiAccess,
  getAdminOverview,
  getUsageAnalytics,
  getAuditLogs,
  getGlobalConfig,
  updateGlobalConfig,
} from '../controllers/adminController';

const router = Router();

// All admin routes require authentication + admin role
router.use(authenticate);
router.use(requireAdmin);

// Plan management
router.get('/plans', getPlans);
router.post('/plans', createPlan);
router.put('/plans/:id', updatePlan);

// User management
router.get('/users', getUsers);
router.get('/users/:id', getUserDetails);

// Credit control
router.post('/credits', adjustCredits);

// Plan assignment
router.post('/assign-plan', assignPlan);

// AI access control
router.post('/toggle-ai-access', toggleAiAccess);

// Analytics
router.get('/analytics/overview', getAdminOverview);
router.get('/analytics/usage', getUsageAnalytics);

// Audit logs
router.get('/audit-logs', getAuditLogs);

// Global config / spending safeguards
router.get('/config', getGlobalConfig);
router.put('/config', updateGlobalConfig);

export default router;
