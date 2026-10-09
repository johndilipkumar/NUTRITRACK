import { prisma } from '../config/database';
import { v4 as uuidv4 } from 'uuid';

/**
 * Subscription Service — handles plan assignment, quota checks, and credit operations.
 * All quota enforcement happens here via atomic database operations.
 */

// ─── Credit conversion config ───────────────────────────────────────────
// How many application credits one AI request costs (base + per-token).
// These are configurable; in production, move to GlobalConfig.
const CREDIT_COST = {
  BASE_PER_REQUEST: 100,        // Flat cost per request
  PER_INPUT_TOKEN: 1,           // 1 credit per input token
  PER_OUTPUT_TOKEN: 2,          // 2 credits per output token (generation is costlier)
};

// Estimated USD cost per token (for cost tracking, not billing)
const ESTIMATED_COST = {
  INPUT_PER_TOKEN_USD: 0.000001,   // ~$0.10 per 100K tokens (Gemini Flash pricing)
  OUTPUT_PER_TOKEN_USD: 0.000004,  // ~$0.40 per 100K tokens
};

/**
 * Calculate application credits from token usage.
 */
export function calculateCredits(inputTokens: number, outputTokens: number): number {
  return CREDIT_COST.BASE_PER_REQUEST +
    (inputTokens * CREDIT_COST.PER_INPUT_TOKEN) +
    (outputTokens * CREDIT_COST.PER_OUTPUT_TOKEN);
}

/**
 * Calculate estimated USD cost from token usage (for admin reporting).
 */
export function calculateEstimatedCost(inputTokens: number, outputTokens: number): number {
  return (inputTokens * ESTIMATED_COST.INPUT_PER_TOKEN_USD) +
    (outputTokens * ESTIMATED_COST.OUTPUT_PER_TOKEN_USD);
}

/**
 * Get or create the default free plan.
 * This ensures the free plan always exists in the database.
 */
export async function getOrCreateDefaultPlan() {
  let freePlan = await prisma.plan.findUnique({
    where: { slug: 'free' },
  });

  if (!freePlan) {
    freePlan = await prisma.plan.create({
      data: {
        name: 'Free',
        slug: 'free',
        description: 'Get started with AI food analysis. Perfect for trying out NutriTrack.',
        priceAmount: 0,
        currency: 'INR',
        billingInterval: 'monthly',
        monthlyCreditLimit: 100000,
        dailyCreditLimit: 5000,
        dailyRequestLimit: 20,
        maxInputTokens: 2048,
        maxOutputTokens: 500,
        allowedModels: ['gemini-2.0-flash'],
        features: { foodAnalysis: true, history: true, analytics: true },
        isDefault: true,
        isActive: true,
        sortOrder: 0,
      },
    });
  }

  return freePlan;
}

/**
 * Assign the default Free plan to a new user.
 * Creates a subscription record with a 30-day billing period.
 * Idempotent — won't create duplicate subscriptions.
 */
export async function assignFreePlanToUser(userId: string): Promise<void> {
  // Check if user already has an active subscription
  const existing = await prisma.userSubscription.findFirst({
    where: {
      userId,
      status: { in: ['active', 'trialing'] },
    },
  });

  if (existing) return; // Already has a subscription

  const freePlan = await getOrCreateDefaultPlan();

  const now = new Date();
  const periodEnd = new Date(now);
  periodEnd.setDate(periodEnd.getDate() + 30);

  await prisma.$transaction([
    // Create subscription
    prisma.userSubscription.create({
      data: {
        userId,
        planId: freePlan.id,
        status: 'active',
        billingPeriodStart: now,
        billingPeriodEnd: periodEnd,
        dailyResetDate: now,
      },
    }),
    // Record initial plan allowance in credit ledger
    prisma.creditLedger.create({
      data: {
        userId,
        creditType: 'plan_allowance',
        transactionType: 'credit',
        amount: freePlan.monthlyCreditLimit,
        reason: 'Free plan initial allowance',
        createdBy: 'system',
      },
    }),
  ]);
}

/**
 * Get the user's active subscription with plan details.
 * Returns null if no active subscription exists.
 */
export async function getActiveSubscription(userId: string) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const subscription = await prisma.userSubscription.findFirst({
    where: {
      userId,
      status: { in: ['active', 'trialing', 'past_due'] },
    },
    include: {
      plan: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!subscription) return null;

  // Auto-reset daily counters if the date has changed
  const resetDate = new Date(subscription.dailyResetDate);
  resetDate.setHours(0, 0, 0, 0);

  if (resetDate < today) {
    await prisma.userSubscription.update({
      where: { id: subscription.id },
      data: {
        dailyCreditsUsed: 0,
        dailyRequestsUsed: 0,
        dailyResetDate: today,
      },
    });
    subscription.dailyCreditsUsed = 0;
    subscription.dailyRequestsUsed = 0;
    subscription.dailyResetDate = today;
  }

  // Check if billing period has expired and auto-reset monthly counters
  if (subscription.billingPeriodEnd < new Date()) {
    if (subscription.cancelAtPeriodEnd) {
      // Subscription should be cancelled
      await prisma.userSubscription.update({
        where: { id: subscription.id },
        data: { status: 'expired' },
      });
      return null;
    }

    // Auto-renew for free plan
    if (subscription.plan.priceAmount === 0) {
      const newPeriodStart = new Date();
      const newPeriodEnd = new Date();
      newPeriodEnd.setDate(newPeriodEnd.getDate() + 30);

      await prisma.$transaction([
        prisma.userSubscription.update({
          where: { id: subscription.id },
          data: {
            billingPeriodStart: newPeriodStart,
            billingPeriodEnd: newPeriodEnd,
            monthlyCreditsUsed: 0,
            dailyCreditsUsed: 0,
            dailyRequestsUsed: 0,
            dailyResetDate: newPeriodStart,
          },
        }),
        prisma.creditLedger.create({
          data: {
            userId,
            creditType: 'plan_allowance',
            transactionType: 'credit',
            amount: subscription.plan.monthlyCreditLimit,
            reason: 'Monthly plan allowance renewal',
            createdBy: 'system',
          },
        }),
      ]);

      subscription.monthlyCreditsUsed = 0;
      subscription.dailyCreditsUsed = 0;
      subscription.dailyRequestsUsed = 0;
      subscription.billingPeriodStart = newPeriodStart;
      subscription.billingPeriodEnd = newPeriodEnd;
    }
  }

  return subscription;
}

/**
 * Get available bonus credits for a user (non-expired, with remaining amount).
 */
export async function getAvailableBonusCredits(userId: string): Promise<number> {
  const bonusCredits = await prisma.creditLedger.findMany({
    where: {
      userId,
      creditType: 'bonus',
      transactionType: 'credit',
      remainingAmount: { gt: 0 },
      OR: [
        { expiresAt: null },
        { expiresAt: { gt: new Date() } },
      ],
    },
  });

  return bonusCredits.reduce((total, entry) => total + (entry.remainingAmount || 0), 0);
}

/**
 * Check if user has sufficient quota for an AI request.
 * Returns quota status with detailed information.
 */
export async function checkQuota(userId: string): Promise<{
  allowed: boolean;
  reason?: string;
  subscription: any;
  remainingMonthlyCredits: number;
  remainingDailyRequests: number;
  bonusCredits: number;
}> {
  const subscription = await getActiveSubscription(userId);

  if (!subscription) {
    return {
      allowed: false,
      reason: 'No active subscription. Please subscribe to a plan.',
      subscription: null,
      remainingMonthlyCredits: 0,
      remainingDailyRequests: 0,
      bonusCredits: 0,
    };
  }

  const plan = subscription.plan;
  const bonusCredits = await getAvailableBonusCredits(userId);

  // Check daily request limit
  const remainingDailyRequests = plan.dailyRequestLimit - subscription.dailyRequestsUsed;
  if (remainingDailyRequests <= 0) {
    return {
      allowed: false,
      reason: `Daily request limit reached (${plan.dailyRequestLimit} per day). Resets at midnight.`,
      subscription,
      remainingMonthlyCredits: plan.monthlyCreditLimit - subscription.monthlyCreditsUsed,
      remainingDailyRequests: 0,
      bonusCredits,
    };
  }

  // Check monthly credit limit (plan credits + bonus credits)
  const remainingPlanCredits = plan.monthlyCreditLimit - subscription.monthlyCreditsUsed;
  const totalAvailable = remainingPlanCredits + bonusCredits;

  if (totalAvailable <= 0) {
    return {
      allowed: false,
      reason: 'Monthly credit limit reached. Upgrade your plan or wait for the next billing period.',
      subscription,
      remainingMonthlyCredits: remainingPlanCredits,
      remainingDailyRequests,
      bonusCredits,
    };
  }

  // Check daily credit limit if set
  if (plan.dailyCreditLimit) {
    const remainingDailyCredits = plan.dailyCreditLimit - subscription.dailyCreditsUsed;
    if (remainingDailyCredits <= 0) {
      return {
        allowed: false,
        reason: `Daily credit limit reached (${plan.dailyCreditLimit} credits per day). Resets at midnight.`,
        subscription,
        remainingMonthlyCredits: remainingPlanCredits,
        remainingDailyRequests,
        bonusCredits,
      };
    }
  }

  return {
    allowed: true,
    subscription,
    remainingMonthlyCredits: remainingPlanCredits,
    remainingDailyRequests,
    bonusCredits,
  };
}

/**
 * Reserve credits for an in-progress AI request.
 * Uses an atomic transaction to prevent concurrent overspending.
 * Returns the reservation ID or throws if insufficient credits.
 */
export async function reserveCredits(
  userId: string,
  subscriptionId: string,
  estimatedCredits: number
): Promise<{ reservationId: string; requestId: string }> {
  const requestId = uuidv4();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5-minute timeout

  // Atomic: increment usage counters + create reservation
  const [, reservation] = await prisma.$transaction([
    prisma.userSubscription.update({
      where: { id: subscriptionId },
      data: {
        monthlyCreditsUsed: { increment: estimatedCredits },
        dailyCreditsUsed: { increment: estimatedCredits },
        dailyRequestsUsed: { increment: 1 },
      },
    }),
    prisma.usageReservation.create({
      data: {
        userId,
        requestId,
        reservedCredits: estimatedCredits,
        status: 'reserved',
        expiresAt,
      },
    }),
  ]);

  return { reservationId: reservation.id, requestId };
}

/**
 * Reconcile a reservation after the AI call completes.
 * Adjusts the subscription counters based on actual usage vs reserved amount.
 */
export async function reconcileReservation(
  reservationId: string,
  actualCredits: number,
  subscriptionId: string,
  inputTokens: number,
  outputTokens: number,
  status: 'completed' | 'failed',
  errorMessage?: string,
  durationMs?: number
): Promise<void> {
  const reservation = await prisma.usageReservation.findUnique({
    where: { id: reservationId },
  });

  if (!reservation || reservation.status !== 'reserved') return;

  const creditDiff = reservation.reservedCredits - actualCredits;

  await prisma.$transaction([
    // Update reservation status
    prisma.usageReservation.update({
      where: { id: reservationId },
      data: {
        finalCredits: actualCredits,
        status: 'reconciled',
      },
    }),

    // Adjust subscription counters if there's a difference
    ...(creditDiff !== 0
      ? [
          prisma.userSubscription.update({
            where: { id: subscriptionId },
            data: {
              monthlyCreditsUsed: { decrement: creditDiff },
              dailyCreditsUsed: { decrement: creditDiff },
            },
          }),
        ]
      : []),

    // Record usage event
    prisma.usageEvent.create({
      data: {
        userId: reservation.userId,
        requestId: reservation.requestId,
        provider: 'google',
        model: 'gemini-2.0-flash',
        inputTokens,
        outputTokens,
        applicationCreditsCharged: actualCredits,
        estimatedCost: calculateEstimatedCost(inputTokens, outputTokens),
        status,
        errorMessage,
        durationMs,
      },
    }),

    // Record consumption in credit ledger
    ...(actualCredits > 0
      ? [
          prisma.creditLedger.create({
            data: {
              userId: reservation.userId,
              creditType: 'consumption',
              transactionType: 'debit',
              amount: actualCredits,
              sourceReference: reservation.requestId,
              reason: `AI analysis (${inputTokens} in / ${outputTokens} out tokens)`,
              createdBy: 'system',
            },
          }),
        ]
      : []),
  ]);
}

/**
 * Release a reservation without charging (e.g., on failure).
 */
export async function releaseReservation(
  reservationId: string,
  subscriptionId: string
): Promise<void> {
  const reservation = await prisma.usageReservation.findUnique({
    where: { id: reservationId },
  });

  if (!reservation || reservation.status !== 'reserved') return;

  await prisma.$transaction([
    prisma.usageReservation.update({
      where: { id: reservationId },
      data: {
        finalCredits: 0,
        status: 'released',
      },
    }),
    // Reverse the reserved credits
    prisma.userSubscription.update({
      where: { id: subscriptionId },
      data: {
        monthlyCreditsUsed: { decrement: reservation.reservedCredits },
        dailyCreditsUsed: { decrement: reservation.reservedCredits },
        dailyRequestsUsed: { decrement: 1 },
      },
    }),
  ]);
}

/**
 * Check global spending safeguards.
 * Returns whether AI requests are currently allowed globally.
 */
export async function checkGlobalSafeguards(): Promise<{
  allowed: boolean;
  reason?: string;
}> {
  // Check if AI is globally enabled
  const aiEnabledConfig = await prisma.globalConfig.findUnique({
    where: { key: 'ai_enabled' },
  });

  if (aiEnabledConfig && aiEnabledConfig.value === 'false') {
    return {
      allowed: false,
      reason: 'AI service is temporarily disabled. Please try again later.',
    };
  }

  // Check daily spending limit
  const dailyLimitConfig = await prisma.globalConfig.findUnique({
    where: { key: 'daily_spend_limit_usd' },
  });

  if (dailyLimitConfig) {
    const limit = parseFloat(dailyLimitConfig.value);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todaySpend = await prisma.usageEvent.aggregate({
      where: {
        createdAt: { gte: today },
        status: 'completed',
      },
      _sum: { estimatedCost: true },
    });

    if ((todaySpend._sum.estimatedCost || 0) >= limit) {
      return {
        allowed: false,
        reason: 'AI service daily budget reached. Please try again tomorrow.',
      };
    }
  }

  // Check monthly spending limit
  const monthlyLimitConfig = await prisma.globalConfig.findUnique({
    where: { key: 'monthly_spend_limit_usd' },
  });

  if (monthlyLimitConfig) {
    const limit = parseFloat(monthlyLimitConfig.value);
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);

    const monthSpend = await prisma.usageEvent.aggregate({
      where: {
        createdAt: { gte: monthStart },
        status: 'completed',
      },
      _sum: { estimatedCost: true },
    });

    if ((monthSpend._sum.estimatedCost || 0) >= limit) {
      return {
        allowed: false,
        reason: 'AI service monthly budget reached. Service will resume next month.',
      };
    }
  }

  return { allowed: true };
}
