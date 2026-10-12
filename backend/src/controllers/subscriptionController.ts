import { Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { getActiveSubscription, getAvailableBonusCredits } from '../services/subscriptionService';

/**
 * GET /api/plans
 * List all active plans (public, for pricing page).
 */
export const getAvailablePlans = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const plans = await prisma.plan.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        priceAmount: true,
        currency: true,
        billingInterval: true,
        monthlyCreditLimit: true,
        dailyCreditLimit: true,
        dailyRequestLimit: true,
        generationLimit: true,
        maxOutputTokens: true,
        allowedModels: true,
        features: true,
        isDefault: true,
        sortOrder: true,
      },
    });

    res.json({ success: true, data: plans });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/subscription/status
 * Get the current user's subscription and usage information.
 */
export const getSubscriptionStatus = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    const subscription = await getActiveSubscription(userId);
    const bonusCredits = await getAvailableBonusCredits(userId);

    if (!subscription) {
      res.json({
        success: true,
        data: {
          hasSubscription: false,
          plan: null,
          usage: null,
          bonusCredits: 0,
        },
      });
      return;
    }

    const plan = subscription.plan;

    res.json({
      success: true,
      data: {
        hasSubscription: true,
        subscriptionId: subscription.id,
        plan: {
          id: plan.id,
          name: plan.name,
          slug: plan.slug,
          description: plan.description,
          priceAmount: plan.priceAmount,
          currency: plan.currency,
          billingInterval: plan.billingInterval,
          monthlyCreditLimit: plan.monthlyCreditLimit,
          dailyCreditLimit: plan.dailyCreditLimit,
          dailyRequestLimit: plan.dailyRequestLimit,
          maxOutputTokens: plan.maxOutputTokens,
          features: plan.features,
        },
        status: subscription.status,
        billingPeriodStart: subscription.billingPeriodStart,
        billingPeriodEnd: subscription.billingPeriodEnd,
        cancelAtPeriodEnd: subscription.cancelAtPeriodEnd,
        usage: {
          monthlyCreditsUsed: subscription.monthlyCreditsUsed,
          monthlyCreditsRemaining: Math.max(0, plan.monthlyCreditLimit - subscription.monthlyCreditsUsed),
          dailyCreditsUsed: subscription.dailyCreditsUsed,
          dailyCreditsRemaining: plan.dailyCreditLimit
            ? Math.max(0, plan.dailyCreditLimit - subscription.dailyCreditsUsed)
            : null,
          dailyRequestsUsed: subscription.dailyRequestsUsed,
          dailyRequestsRemaining: plan.dailyRequestLimit - subscription.dailyRequestsUsed,
        },
        bonusCredits,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/subscription/history
 * Get the user's subscription history.
 */
export const getSubscriptionHistory = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    const [subscriptions, payments] = await Promise.all([
      prisma.userSubscription.findMany({
        where: { userId },
        include: { plan: { select: { id: true, name: true, slug: true, priceAmount: true, currency: true } } },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.payment.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
    ]);

    res.json({
      success: true,
      data: { subscriptions, payments },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/subscription/usage-history
 * Get the user's AI usage history.
 */
export const getUsageHistory = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const skip = (page - 1) * limit;

    const [events, total] = await Promise.all([
      prisma.usageEvent.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.usageEvent.count({ where: { userId } }),
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

/**
 * POST /api/subscription/cancel
 * Cancel the user's subscription at end of billing period.
 */
export const cancelSubscription = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    const subscription = await getActiveSubscription(userId);

    if (!subscription) {
      res.status(400).json({
        success: false,
        message: 'No active subscription to cancel.',
      });
      return;
    }

    // Free plans just downgrade to... free, so nothing changes
    if (subscription.plan.priceAmount === 0) {
      res.status(400).json({
        success: false,
        message: 'Free plan cannot be cancelled. You will always have access to the free tier.',
      });
      return;
    }

    await prisma.userSubscription.update({
      where: { id: subscription.id },
      data: {
        cancelAtPeriodEnd: true,
        cancelledAt: new Date(),
      },
    });

    res.json({
      success: true,
      message: `Subscription will end on ${subscription.billingPeriodEnd.toISOString().split('T')[0]}. You will retain access until then.`,
    });
  } catch (error) {
    next(error);
  }
};
