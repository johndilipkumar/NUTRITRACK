import { Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import {
  createPlanSchema,
  updatePlanSchema,
  creditAdjustmentSchema,
  assignPlanSchema,
  toggleAiAccessSchema,
  updateGlobalConfigSchema,
} from '../validators/adminValidators';

// ═══════════════════════════════════════════════════════════════════════════
// PLAN CRUD
// ═══════════════════════════════════════════════════════════════════════════

/**
 * GET /api/admin/plans
 * List all plans (including inactive ones for admin).
 */
export const getPlans = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const plans = await prisma.plan.findMany({
      orderBy: { sortOrder: 'asc' },
      include: {
        _count: { select: { subscriptions: true } },
      },
    });

    res.json({ success: true, data: plans });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/plans
 * Create a new subscription plan.
 */
export const createPlan = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = createPlanSchema.parse(req.body);

    // If this plan is set as default, unset any existing default
    if (input.isDefault) {
      await prisma.plan.updateMany({
        where: { isDefault: true },
        data: { isDefault: false },
      });
    }

    const plan = await prisma.plan.create({ data: input });

    // Audit log
    await prisma.adminAuditLog.create({
      data: {
        adminUserId: req.userId!,
        action: 'plan_created',
        reason: `Created plan: ${plan.name}`,
        details: { plan },
      },
    });

    res.status(201).json({ success: true, data: plan });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/plans/:id
 * Update an existing plan.
 */
export const updatePlan = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { id } = req.params;
    const input = updatePlanSchema.parse(req.body);

    const existingPlan = await prisma.plan.findUnique({ where: { id } });
    if (!existingPlan) {
      throw new AppError(404, 'Plan not found.');
    }

    // If setting as default, unset others
    if (input.isDefault) {
      await prisma.plan.updateMany({
        where: { isDefault: true, id: { not: id } },
        data: { isDefault: false },
      });
    }

    const updatedPlan = await prisma.plan.update({
      where: { id },
      data: input,
    });

    // Audit log
    await prisma.adminAuditLog.create({
      data: {
        adminUserId: req.userId!,
        action: 'plan_updated',
        reason: `Updated plan: ${updatedPlan.name}`,
        details: { before: existingPlan, after: updatedPlan },
      },
    });

    res.json({ success: true, data: updatedPlan });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

/**
 * GET /api/admin/users
 * List users with pagination, search, and filter.
 */
export const getUsers = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const search = (req.query.search as string) || '';
    const planFilter = req.query.plan as string;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { name: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          aiAccessEnabled: true,
          createdAt: true,
          updatedAt: true,
          subscriptions: {
            where: { status: { in: ['active', 'trialing', 'past_due'] } },
            include: { plan: { select: { id: true, name: true, slug: true } } },
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
        },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.user.count({ where }),
    ]);

    // Enrich with usage data
    const enrichedUsers = await Promise.all(
      users.map(async (user) => {
        const subscription = user.subscriptions[0] || null;
        return {
          ...user,
          currentPlan: subscription?.plan || null,
          subscriptionStatus: subscription?.status || 'none',
          subscriptions: undefined, // Don't send raw subscriptions array
        };
      })
    );

    res.json({
      success: true,
      data: {
        users: enrichedUsers,
        pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/users/:id
 * Get detailed user information.
 */
export const getUserDetails = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        aiAccessEnabled: true,
        createdAt: true,
        updatedAt: true,
        subscriptions: {
          include: { plan: true },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!user) {
      throw new AppError(404, 'User not found.');
    }

    // Get usage stats
    const [usageStats, creditHistory, paymentHistory] = await Promise.all([
      prisma.usageEvent.aggregate({
        where: { userId: id },
        _count: true,
        _sum: {
          applicationCreditsCharged: true,
          inputTokens: true,
          outputTokens: true,
          estimatedCost: true,
        },
      }),
      prisma.creditLedger.findMany({
        where: { userId: id },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
      prisma.payment.findMany({
        where: { userId: id },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    ]);

    res.json({
      success: true,
      data: {
        user,
        usageStats: {
          totalRequests: usageStats._count,
          totalCreditsUsed: usageStats._sum.applicationCreditsCharged || 0,
          totalInputTokens: usageStats._sum.inputTokens || 0,
          totalOutputTokens: usageStats._sum.outputTokens || 0,
          totalEstimatedCost: usageStats._sum.estimatedCost || 0,
        },
        creditHistory,
        paymentHistory,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// CREDIT ADJUSTMENT
// ═══════════════════════════════════════════════════════════════════════════

/**
 * POST /api/admin/credits
 * Grant or revoke bonus credits for a user.
 */
export const adjustCredits = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = creditAdjustmentSchema.parse(req.body);
    const adminUserId = req.userId!;

    // Verify target user exists
    const targetUser = await prisma.user.findUnique({
      where: { id: input.userId },
      select: { id: true, email: true },
    });

    if (!targetUser) {
      throw new AppError(404, 'Target user not found.');
    }

    if (input.type === 'revoke') {
      // Check available bonus credits before revoking
      const availableBonus = await prisma.creditLedger.findMany({
        where: {
          userId: input.userId,
          creditType: 'bonus',
          transactionType: 'credit',
          remainingAmount: { gt: 0 },
        },
      });

      const totalAvailable = availableBonus.reduce(
        (sum, entry) => sum + (entry.remainingAmount || 0),
        0
      );

      if (totalAvailable < input.amount) {
        throw new AppError(400, `Cannot revoke ${input.amount} credits. Only ${totalAvailable} bonus credits available.`);
      }
    }

    const ledgerEntry = await prisma.creditLedger.create({
      data: {
        userId: input.userId,
        creditType: 'bonus',
        transactionType: input.type === 'grant' ? 'credit' : 'debit',
        amount: input.amount,
        remainingAmount: input.type === 'grant' ? input.amount : null,
        expiresAt: input.expiresAt ? new Date(input.expiresAt) : null,
        reason: input.reason,
        createdBy: adminUserId,
      },
    });

    // Audit log
    await prisma.adminAuditLog.create({
      data: {
        adminUserId,
        action: input.type === 'grant' ? 'credit_granted' : 'credit_revoked',
        targetUserId: input.userId,
        reason: input.reason,
        details: {
          amount: input.amount,
          type: input.type,
          expiresAt: input.expiresAt,
          ledgerEntryId: ledgerEntry.id,
        },
      },
    });

    res.status(201).json({
      success: true,
      message: `${input.amount} credits ${input.type === 'grant' ? 'granted to' : 'revoked from'} user.`,
      data: ledgerEntry,
    });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// PLAN ASSIGNMENT
// ═══════════════════════════════════════════════════════════════════════════

/**
 * POST /api/admin/assign-plan
 * Manually assign a plan to a user (admin override).
 */
export const assignPlan = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = assignPlanSchema.parse(req.body);
    const adminUserId = req.userId!;

    const [targetUser, plan] = await Promise.all([
      prisma.user.findUnique({ where: { id: input.userId } }),
      prisma.plan.findUnique({ where: { id: input.planId } }),
    ]);

    if (!targetUser) throw new AppError(404, 'User not found.');
    if (!plan) throw new AppError(404, 'Plan not found.');
    if (!plan.isActive) throw new AppError(400, 'Cannot assign an inactive plan.');

    const now = new Date();
    const periodEnd = new Date(now);
    periodEnd.setDate(periodEnd.getDate() + 30);

    // Expire existing active subscriptions
    await prisma.userSubscription.updateMany({
      where: {
        userId: input.userId,
        status: { in: ['active', 'trialing'] },
      },
      data: { status: 'expired' },
    });

    // Create new subscription
    const subscription = await prisma.userSubscription.create({
      data: {
        userId: input.userId,
        planId: input.planId,
        status: 'active',
        billingPeriodStart: now,
        billingPeriodEnd: periodEnd,
        dailyResetDate: now,
      },
      include: { plan: true },
    });

    // Record plan allowance in credit ledger
    await prisma.creditLedger.create({
      data: {
        userId: input.userId,
        creditType: 'plan_allowance',
        transactionType: 'credit',
        amount: plan.monthlyCreditLimit,
        reason: `Plan assigned by admin: ${plan.name}`,
        createdBy: adminUserId,
      },
    });

    // Audit log
    await prisma.adminAuditLog.create({
      data: {
        adminUserId,
        action: 'plan_assigned',
        targetUserId: input.userId,
        reason: input.reason,
        details: {
          planId: plan.id,
          planName: plan.name,
          subscriptionId: subscription.id,
        },
      },
    });

    res.status(201).json({
      success: true,
      message: `${plan.name} plan assigned to user.`,
      data: subscription,
    });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// AI ACCESS CONTROL
// ═══════════════════════════════════════════════════════════════════════════

/**
 * POST /api/admin/toggle-ai-access
 * Enable or disable AI access for a user.
 */
export const toggleAiAccess = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = toggleAiAccessSchema.parse(req.body);
    const adminUserId = req.userId!;

    const user = await prisma.user.update({
      where: { id: input.userId },
      data: { aiAccessEnabled: input.enabled },
      select: { id: true, email: true, aiAccessEnabled: true },
    });

    await prisma.adminAuditLog.create({
      data: {
        adminUserId,
        action: input.enabled ? 'user_ai_restored' : 'user_suspended',
        targetUserId: input.userId,
        reason: input.reason,
        details: { aiAccessEnabled: input.enabled },
      },
    });

    res.json({
      success: true,
      message: `AI access ${input.enabled ? 'enabled' : 'disabled'} for user.`,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// USAGE & COST ANALYTICS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * GET /api/admin/analytics/overview
 * Admin dashboard overview statistics.
 */
export const getAdminOverview = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const [
      totalUsers,
      activeSubscriptions,
      freeUsers,
      paidUsers,
      usageStats,
      failedRequests,
      recentUsage,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.userSubscription.count({
        where: { status: { in: ['active', 'trialing'] } },
      }),
      prisma.userSubscription.count({
        where: {
          status: 'active',
          plan: { priceAmount: 0 },
        },
      }),
      prisma.userSubscription.count({
        where: {
          status: 'active',
          plan: { priceAmount: { gt: 0 } },
        },
      }),
      prisma.usageEvent.aggregate({
        where: {
          createdAt: { gte: startDate },
          status: 'completed',
        },
        _count: true,
        _sum: {
          applicationCreditsCharged: true,
          inputTokens: true,
          outputTokens: true,
          estimatedCost: true,
        },
      }),
      prisma.usageEvent.count({
        where: {
          createdAt: { gte: startDate },
          status: 'failed',
        },
      }),
      // Daily usage for the period
      prisma.$queryRawUnsafe<Array<{ date: string; requests: number; credits: number; cost: number }>>(
        `SELECT DATE(created_at) as date,
                COUNT(*)::int as requests,
                COALESCE(SUM(application_credits_charged), 0)::int as credits,
                COALESCE(SUM(estimated_cost), 0)::float as cost
         FROM usage_events
         WHERE created_at >= $1 AND status = 'completed'
         GROUP BY DATE(created_at)
         ORDER BY date ASC`,
        startDate
      ),
    ]);

    res.json({
      success: true,
      data: {
        totalUsers,
        activeSubscriptions,
        freeUsers,
        paidUsers,
        period: { days, startDate: startDate.toISOString() },
        usage: {
          totalRequests: usageStats._count,
          totalCredits: usageStats._sum.applicationCreditsCharged || 0,
          totalInputTokens: usageStats._sum.inputTokens || 0,
          totalOutputTokens: usageStats._sum.outputTokens || 0,
          estimatedCostUsd: usageStats._sum.estimatedCost || 0,
          failedRequests,
        },
        dailyUsage: recentUsage,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/analytics/usage
 * Detailed usage analytics with filters.
 */
export const getUsageAnalytics = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const userId = req.query.userId as string;
    const model = req.query.model as string;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 50;
    const skip = (page - 1) * limit;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const where: any = { createdAt: { gte: startDate } };
    if (userId) where.userId = userId;
    if (model) where.model = model;

    const [events, total] = await Promise.all([
      prisma.usageEvent.findMany({
        where,
        include: {
          user: { select: { id: true, email: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.usageEvent.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        events,
        pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// AUDIT LOGS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * GET /api/admin/audit-logs
 * View admin audit logs.
 */
export const getAuditLogs = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 50;
    const action = req.query.action as string;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (action) where.action = action;

    const [logs, total] = await Promise.all([
      prisma.adminAuditLog.findMany({
        where,
        include: {
          adminUser: { select: { id: true, email: true, name: true } },
          targetUser: { select: { id: true, email: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.adminAuditLog.count({ where }),
    ]);

    res.json({
      success: true,
      data: {
        logs,
        pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL CONFIG / SPENDING SAFEGUARDS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * GET /api/admin/config
 * Get all global configuration values.
 */
export const getGlobalConfig = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const configs = await prisma.globalConfig.findMany({
      orderBy: { key: 'asc' },
    });

    res.json({ success: true, data: configs });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/admin/config
 * Update a global configuration value.
 */
export const updateGlobalConfig = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = updateGlobalConfigSchema.parse(req.body);
    const adminUserId = req.userId!;

    const existing = await prisma.globalConfig.findUnique({
      where: { key: input.key },
    });

    const config = await prisma.globalConfig.upsert({
      where: { key: input.key },
      create: {
        key: input.key,
        value: input.value,
        description: input.description,
        updatedBy: adminUserId,
      },
      update: {
        value: input.value,
        description: input.description,
        updatedBy: adminUserId,
      },
    });

    // Audit log
    await prisma.adminAuditLog.create({
      data: {
        adminUserId,
        action: 'config_updated',
        reason: `Updated config: ${input.key}`,
        details: {
          key: input.key,
          previousValue: existing?.value,
          newValue: input.value,
        },
      },
    });

    res.json({ success: true, data: config });
  } catch (error) {
    next(error);
  }
};
