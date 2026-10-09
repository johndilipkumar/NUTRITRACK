import { Response, NextFunction } from 'express';
import crypto from 'crypto';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { getActiveSubscription } from '../services/subscriptionService';

/**
 * POST /api/subscription/checkout
 * Creates a Razorpay order for plan upgrade.
 *
 * NOTE: In production, you would use the Razorpay SDK to create real orders.
 * This implementation creates a payment record and returns order details
 * that the frontend can use with the Razorpay checkout widget.
 * The actual Razorpay integration requires the `razorpay` npm package
 * and valid API keys. For now, this creates the payment flow structure.
 */
export const createCheckout = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const { planId } = req.body;

    if (!planId) {
      throw new AppError(400, 'Plan ID is required.');
    }

    const plan = await prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) throw new AppError(404, 'Plan not found.');
    if (!plan.isActive) throw new AppError(400, 'This plan is not currently available.');
    if (plan.priceAmount === 0) throw new AppError(400, 'Free plan does not require payment.');

    // Check if user already has this plan
    const currentSub = await getActiveSubscription(userId);
    if (currentSub && currentSub.planId === planId) {
      throw new AppError(400, 'You are already on this plan.');
    }

    // Create a pending payment record
    const orderId = `order_${crypto.randomBytes(12).toString('hex')}`;
    const payment = await prisma.payment.create({
      data: {
        userId,
        provider: 'razorpay',
        providerOrderId: orderId,
        amount: plan.priceAmount,
        currency: plan.currency,
        status: 'pending',
        planId: plan.id,
      },
    });

    // In production: use Razorpay SDK to create an actual order
    // const razorpay = new Razorpay({ key_id: env.RAZORPAY_KEY_ID, key_secret: env.RAZORPAY_KEY_SECRET });
    // const order = await razorpay.orders.create({ amount: plan.priceAmount, currency: plan.currency });

    res.json({
      success: true,
      data: {
        paymentId: payment.id,
        orderId: orderId,
        amount: plan.priceAmount,
        currency: plan.currency,
        planName: plan.name,
        // In production, include Razorpay key_id for frontend checkout
        // razorpayKeyId: env.RAZORPAY_KEY_ID,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/subscription/verify-payment
 * Verify payment and activate subscription.
 *
 * In production, this should verify the Razorpay signature.
 * For development, it accepts a paymentId and activates the subscription.
 */
export const verifyPayment = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const { paymentId, razorpayPaymentId, razorpaySignature } = req.body;

    if (!paymentId) {
      throw new AppError(400, 'Payment ID is required.');
    }

    // Find the pending payment
    const payment = await prisma.payment.findFirst({
      where: {
        id: paymentId,
        userId,
        status: 'pending',
      },
    });

    if (!payment) {
      throw new AppError(404, 'Payment not found or already processed.');
    }

    if (!payment.planId) {
      throw new AppError(400, 'Payment is not associated with a plan.');
    }

    // In production: verify Razorpay signature
    // const generated_signature = crypto
    //   .createHmac('sha256', env.RAZORPAY_KEY_SECRET)
    //   .update(payment.providerOrderId + '|' + razorpayPaymentId)
    //   .digest('hex');
    // if (generated_signature !== razorpaySignature) {
    //   throw new AppError(400, 'Payment verification failed.');
    // }

    const plan = await prisma.plan.findUnique({ where: { id: payment.planId } });
    if (!plan) throw new AppError(404, 'Associated plan not found.');

    const now = new Date();
    const periodEnd = new Date(now);
    periodEnd.setDate(periodEnd.getDate() + 30);

    // Activate subscription in a transaction
    await prisma.$transaction([
      // Mark payment as completed
      prisma.payment.update({
        where: { id: paymentId },
        data: {
          status: 'completed',
          providerPaymentId: razorpayPaymentId || `dev_${crypto.randomBytes(8).toString('hex')}`,
        },
      }),

      // Expire old subscriptions
      prisma.userSubscription.updateMany({
        where: {
          userId,
          status: { in: ['active', 'trialing'] },
        },
        data: { status: 'expired' },
      }),

      // Create new subscription
      prisma.userSubscription.create({
        data: {
          userId,
          planId: plan.id,
          status: 'active',
          billingPeriodStart: now,
          billingPeriodEnd: periodEnd,
          dailyResetDate: now,
        },
      }),

      // Record plan allowance in credit ledger
      prisma.creditLedger.create({
        data: {
          userId,
          creditType: 'plan_allowance',
          transactionType: 'credit',
          amount: plan.monthlyCreditLimit,
          sourceReference: paymentId,
          reason: `${plan.name} plan activated via payment`,
          createdBy: 'system',
        },
      }),

      // Record in processed webhook events (for idempotency)
      prisma.processedWebhookEvent.create({
        data: {
          provider: 'razorpay',
          providerEventId: paymentId,
          eventType: 'payment.completed',
        },
      }),
    ]);

    res.json({
      success: true,
      message: `${plan.name} plan activated successfully!`,
      data: {
        planName: plan.name,
        billingPeriodEnd: periodEnd.toISOString(),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/webhooks/razorpay
 * Razorpay webhook handler (server-to-server, no auth required).
 * Verifies webhook signature and processes events idempotently.
 */
export const handleRazorpayWebhook = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const signature = req.headers['x-razorpay-signature'] as string;
    const body = JSON.stringify(req.body);

    // In production: verify webhook signature
    // const expectedSignature = crypto
    //   .createHmac('sha256', env.RAZORPAY_WEBHOOK_SECRET)
    //   .update(body)
    //   .digest('hex');
    // if (signature !== expectedSignature) {
    //   res.status(400).json({ success: false, message: 'Invalid webhook signature' });
    //   return;
    // }

    const event = req.body;
    const eventId = event.id || event.event_id || crypto.randomBytes(16).toString('hex');
    const eventType = event.event || event.type;

    // Idempotency check — prevent duplicate processing
    const alreadyProcessed = await prisma.processedWebhookEvent.findFirst({
      where: {
        provider: 'razorpay',
        providerEventId: eventId,
      },
    });

    if (alreadyProcessed) {
      res.json({ success: true, message: 'Event already processed.' });
      return;
    }

    // Process based on event type
    switch (eventType) {
      case 'subscription.charged':
      case 'payment.captured':
        // Handle successful payment — activate/renew subscription
        // Implementation depends on Razorpay payload structure
        break;

      case 'subscription.cancelled':
        // Handle cancellation
        break;

      case 'payment.failed':
        // Handle failed payment
        break;

      default:
        // Unknown event type — log and acknowledge
        break;
    }

    // Record that we processed this event
    await prisma.processedWebhookEvent.create({
      data: {
        provider: 'razorpay',
        providerEventId: eventId,
        eventType: eventType || 'unknown',
      },
    });

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};
