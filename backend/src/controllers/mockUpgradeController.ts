import { Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

/**
 * POST /api/subscription/mock-upgrade
 * Simulates a plan upgrade without real payment processing.
 * Only works in development/demo mode or for test accounts.
 * In production, this endpoint rejects all requests.
 */
export const mockUpgrade = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const { planId, simulateFailure } = req.body;

    // Block in production unless explicitly allowed via global config
    const env = process.env.NODE_ENV || 'development';
    if (env === 'production') {
      const mockAllowed = await prisma.globalConfig.findUnique({
        where: { key: 'mock_upgrades_enabled' },
      });
      if (!mockAllowed || mockAllowed.value !== 'true') {
        throw new AppError(403, 'Mock upgrades are disabled in production.');
      }
    }

    if (!planId) {
      throw new AppError(400, 'planId is required.');
    }

    // Simulate failure path
    if (simulateFailure === true) {
      res.status(402).json({
        success: false,
        message: 'Demo: Payment simulation failed. Your plan has not been changed.',
        simulated: true,
      });
      return;
    }

    // Find the target plan
    const plan = await prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) throw new AppError(404, 'Plan not found.');
    if (!plan.isActive) throw new AppError(400, 'This plan is not currently available.');

    // Expire existing active subscriptions
    await prisma.userSubscription.updateMany({
      where: {
        userId,
        status: { in: ['active', 'trialing'] },
      },
      data: { status: 'expired' },
    });

    // Create new subscription
    const now = new Date();
    const periodEnd = new Date(now);
    periodEnd.setDate(periodEnd.getDate() + 30);

    const subscription = await prisma.userSubscription.create({
      data: {
        userId,
        planId: plan.id,
        status: 'active',
        billingPeriodStart: now,
        billingPeriodEnd: periodEnd,
        dailyResetDate: now,
        isMockSubscription: true,
        monthlyCreditsUsed: 0,
        dailyCreditsUsed: 0,
        dailyRequestsUsed: 0,
      },
      include: { plan: true },
    });

    // Record plan allowance in credit ledger
    await prisma.creditLedger.create({
      data: {
        userId,
        creditType: 'plan_allowance',
        transactionType: 'credit',
        amount: plan.monthlyCreditLimit,
        reason: `Mock upgrade to ${plan.name}`,
        createdBy: 'system',
      },
    });

    res.json({
      success: true,
      message: `Demo: Successfully simulated upgrade to ${plan.name}. This is not a real payment.`,
      simulated: true,
      data: {
        subscriptionId: subscription.id,
        plan: {
          id: plan.id,
          name: plan.name,
          slug: plan.slug,
          priceAmount: plan.priceAmount,
          generationLimit: plan.generationLimit,
          billingInterval: plan.billingInterval,
        },
        billingPeriodStart: subscription.billingPeriodStart,
        billingPeriodEnd: subscription.billingPeriodEnd,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/subscription/generation-status
 * Returns how many generations the user has used vs their limit in the current billing period.
 * This is the authoritative generation count for the UI.
 */
export const getGenerationStatus = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    // Get active subscription
    const subscription = await prisma.userSubscription.findFirst({
      where: {
        userId,
        status: { in: ['active', 'trialing', 'past_due'] },
      },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!subscription) {
      res.json({
        success: true,
        data: {
          hasSubscription: false,
          generationsUsed: 0,
          generationLimit: 0,
          generationsRemaining: 0,
          planName: null,
          billingPeriodEnd: null,
        },
      });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true, unlimitedGenerations: true },
    });

    const isUnlimited = user?.unlimitedGenerations === true || user?.role === 'admin';

    // Count successful generations (completed usage events) in the current billing period
    const generationsUsed = await prisma.usageEvent.count({
      where: {
        userId,
        status: 'completed',
        ...(subscription
          ? {
              createdAt: {
                gte: subscription.billingPeriodStart,
                lte: subscription.billingPeriodEnd,
              },
            }
          : {}),
      },
    });

    if (isUnlimited) {
      res.json({
        success: true,
        data: {
          hasSubscription: true,
          isUnlimited: true,
          generationsUsed,
          generationLimit: -1,
          generationsRemaining: -1,
          percentUsed: 0,
          planName: subscription ? `${subscription.plan.name} (Unlimited)` : 'VIP Unlimited',
          planSlug: subscription?.plan.slug || 'unlimited',
          priceAmount: subscription?.plan.priceAmount || 0,
          billingPeriodStart: subscription?.billingPeriodStart || new Date(),
          billingPeriodEnd: subscription?.billingPeriodEnd || new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          billingInterval: subscription?.plan.billingInterval || 'monthly',
          isMock: subscription?.isMockSubscription || false,
          status: 'active',
          cancelAtPeriodEnd: false,
        },
      });
      return;
    }

    const generationLimit = subscription.plan.generationLimit;
    const remaining = Math.max(0, generationLimit - generationsUsed);

    res.json({
      success: true,
      data: {
        hasSubscription: true,
        isUnlimited: false,
        generationsUsed,
        generationLimit,
        generationsRemaining: remaining,
        percentUsed: generationLimit > 0 ? Math.round((generationsUsed / generationLimit) * 100) : 0,
        planName: subscription.plan.name,
        planSlug: subscription.plan.slug,
        priceAmount: subscription.plan.priceAmount,
        billingPeriodStart: subscription.billingPeriodStart,
        billingPeriodEnd: subscription.billingPeriodEnd,
        billingInterval: subscription.plan.billingInterval,
        isMock: subscription.isMockSubscription,
        status: subscription.status,
        cancelAtPeriodEnd: subscription.cancelAtPeriodEnd,
      },
    });
  } catch (error) {
    next(error);
  }
};
