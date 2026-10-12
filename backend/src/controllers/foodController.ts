import { Response, NextFunction } from 'express';
import crypto from 'crypto';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { analyzeFood } from '../services/geminiService';
import { getImageUrl, getImagePath, deleteImage } from '../services/storageService';
import { saveFoodSchema, manualFoodSchema } from '../validators/foodValidators';
import {
  checkGlobalSafeguards,
  checkQuota,
  reserveCredits,
  reconcileReservation,
  releaseReservation,
  calculateCredits,
} from '../services/subscriptionService';

/**
 * POST /api/food/analyze
 * Uploads an image and sends it to Gemini for nutritional analysis.
 * Returns the analysis result without saving to database.
 */
export const analyzeFoodImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    if (!req.file) {
      throw new AppError(400, 'Please upload a food image.');
    }

    // 1. Check global safeguards
    const globalCheck = await checkGlobalSafeguards();
    if (!globalCheck.allowed) {
      throw new AppError(503, globalCheck.reason || 'AI service temporarily disabled.');
    }

    // Check if user has unlimited generations
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true, unlimitedGenerations: true },
    });

    const isUnlimited = user?.unlimitedGenerations === true || user?.role === 'admin';

    let reservationId: string | null = null;
    let subscriptionId: string | null = null;

    if (!isUnlimited) {
      // 1.5 Check generation limit (simple count of successful analyses in billing period)
      const subscription = await prisma.userSubscription.findFirst({
        where: {
          userId,
          status: { in: ['active', 'trialing', 'past_due'] },
        },
        include: { plan: true },
        orderBy: { createdAt: 'desc' },
      });

      if (!subscription) {
        throw new AppError(402, 'No active subscription. Please subscribe to a plan.');
      }

      const generationsUsed = await prisma.usageEvent.count({
        where: {
          userId,
          status: 'completed',
          createdAt: {
            gte: subscription.billingPeriodStart,
            lte: subscription.billingPeriodEnd,
          },
        },
      });

      if (generationsUsed >= subscription.plan.generationLimit) {
        throw new AppError(402,
          `You've reached your generation limit (${subscription.plan.generationLimit}) for this billing period. ` +
          `Upgrade your plan to access a higher generation allowance.`
        );
      }

      // 2. Check user quota (credit-based)
      const quota = await checkQuota(userId);
      if (!quota.allowed) {
        throw new AppError(402, quota.reason || 'Insufficient quota.');
      }

      // 3. Reserve credits (estimate: 1500 input + 500 output)
      const estimatedCredits = calculateCredits(1500, 500);
      const res = await reserveCredits(userId, quota.subscription.id, estimatedCredits);
      reservationId = res.reservationId;
      subscriptionId = quota.subscription.id;
    }

    // Get the absolute path to the uploaded file for Gemini
    const imagePath = getImagePath(req.file.filename);
    const imageUrl = getImageUrl(req.file.filename);

    const startTime = Date.now();
    try {
      // 4. Send image to Gemini for analysis
      const { data: analysis, usage } = await analyzeFood(imagePath);
      const durationMs = Date.now() - startTime;

      // 5. Reconcile reservation
      if (reservationId && subscriptionId) {
        const actualCredits = calculateCredits(usage.inputTokens, usage.outputTokens);
        await reconcileReservation(
          reservationId,
          actualCredits,
          subscriptionId,
          usage.inputTokens,
          usage.outputTokens,
          'completed',
          undefined,
          durationMs
        );
      } else {
        // Log completed generation event for unlimited user
        await prisma.usageEvent.create({
          data: {
            userId,
            requestId: crypto.randomUUID(),
            provider: 'google',
            model: 'gemini-2.0-flash',
            inputTokens: usage.inputTokens,
            outputTokens: usage.outputTokens,
            applicationCreditsCharged: 0,
            status: 'completed',
            durationMs,
          },
        });
      }

      // Check if food was detected
      if (analysis.items.length === 0) {
        res.json({
          success: true,
          message: 'No food or drink was detected in this image.',
          data: {
            imageUrl,
            analysis,
            foodDetected: false,
          },
        });
        return;
      }

      res.json({
        success: true,
        message: 'Food analyzed successfully.',
        data: {
          imageUrl,
          analysis,
          foodDetected: true,
        },
      });
    } catch (analysisError) {
      // Release reservation on failure if one exists
      if (reservationId && subscriptionId) {
        await releaseReservation(reservationId, subscriptionId);
      }
      throw analysisError;
    }
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/food/save
 * Saves an analyzed food entry to the database and updates daily nutrition.
 */
export const saveFood = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = saveFoodSchema.parse(req.body);
    const userId = req.userId!;

    // Create the food entry with all its items in a transaction
    const foodEntry = await prisma.$transaction(async (tx) => {
      // Create the food entry
      const entry = await tx.foodEntry.create({
        data: {
          userId,
          imageUrl: input.imageUrl || null,
          mealName: input.mealName,
          mealType: input.mealType,
          totalCalories: input.totalCalories,
          totalProtein: input.totalProtein,
          totalCarbs: input.totalCarbs,
          totalFat: input.totalFat,
          totalFiber: input.totalFiber,
          totalSugar: input.totalSugar,
          totalSodium: input.totalSodium,
          nutritionScore: input.nutritionScore,
          classification: input.classification,
          confidence: input.confidence,
          disclaimer: input.disclaimer,
          items: {
            create: input.items.map((item) => ({
              name: item.name,
              category: item.category,
              estimatedPortion: item.estimatedPortion || null,
              calories: item.calories,
              proteinG: item.proteinG,
              carbsG: item.carbsG,
              fatG: item.fatG,
              fiberG: item.fiberG,
              sugarG: item.sugarG,
              sodiumMg: item.sodiumMg,
              nutritionScore: item.nutritionScore,
              classification: item.classification,
              confidence: item.confidence,
              positivePoints: item.positivePoints,
              concerns: item.concerns,
              healthierAlternative: item.healthierAlternative || null,
            })),
          },
        },
        include: { items: true },
      });

      // Update daily nutrition aggregate
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      await tx.dailyNutrition.upsert({
        where: {
          userId_date: { userId, date: today },
        },
        create: {
          userId,
          date: today,
          totalCalories: input.totalCalories,
          totalProtein: input.totalProtein,
          totalCarbs: input.totalCarbs,
          totalFat: input.totalFat,
          totalFiber: input.totalFiber,
          totalSugar: input.totalSugar,
          totalSodium: input.totalSodium,
          mealCount: 1,
          avgScore: input.nutritionScore,
        },
        update: {
          totalCalories: { increment: input.totalCalories },
          totalProtein: { increment: input.totalProtein },
          totalCarbs: { increment: input.totalCarbs },
          totalFat: { increment: input.totalFat },
          totalFiber: { increment: input.totalFiber },
          totalSugar: { increment: input.totalSugar },
          totalSodium: { increment: input.totalSodium },
          mealCount: { increment: 1 },
          // Recompute average score
          avgScore: {
            set: await tx.dailyNutrition
              .findUnique({ where: { userId_date: { userId, date: today } } })
              .then((existing) => {
                if (!existing) return input.nutritionScore;
                const totalMeals = existing.mealCount + 1;
                return (existing.avgScore * existing.mealCount + input.nutritionScore) / totalMeals;
              }),
          },
        },
      });

      return entry;
    });

    res.status(201).json({
      success: true,
      message: 'Meal saved successfully.',
      data: foodEntry,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/food/manual
 * Saves a manually entered food item.
 */
export const saveManualFood = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = manualFoodSchema.parse(req.body);
    const userId = req.userId!;

    const foodEntry = await prisma.$transaction(async (tx) => {
      const entry = await tx.foodEntry.create({
        data: {
          userId,
          mealName: input.foodName,
          mealType: input.mealType,
          totalCalories: input.calories,
          totalProtein: input.proteinG,
          totalCarbs: input.carbsG,
          totalFat: input.fatG,
          totalFiber: input.fiberG,
          totalSugar: input.sugarG,
          totalSodium: 0,
          nutritionScore: 50, // Neutral score for manual entries
          classification: 'manual entry',
          confidence: 1.0,
          isManualEntry: true,
          disclaimer: 'Manually entered by user.',
          items: {
            create: [
              {
                name: input.foodName,
                category: 'food',
                estimatedPortion: input.portion || null,
                calories: input.calories,
                proteinG: input.proteinG,
                carbsG: input.carbsG,
                fatG: input.fatG,
                fiberG: input.fiberG,
                sugarG: input.sugarG,
                sodiumMg: 0,
                nutritionScore: 50,
                classification: 'manual entry',
                confidence: 1.0,
              },
            ],
          },
        },
        include: { items: true },
      });

      // Update daily nutrition
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      await tx.dailyNutrition.upsert({
        where: { userId_date: { userId, date: today } },
        create: {
          userId,
          date: today,
          totalCalories: input.calories,
          totalProtein: input.proteinG,
          totalCarbs: input.carbsG,
          totalFat: input.fatG,
          totalFiber: input.fiberG,
          totalSugar: input.sugarG,
          totalSodium: 0,
          mealCount: 1,
          avgScore: 50,
        },
        update: {
          totalCalories: { increment: input.calories },
          totalProtein: { increment: input.proteinG },
          totalCarbs: { increment: input.carbsG },
          totalFat: { increment: input.fatG },
          totalFiber: { increment: input.fiberG },
          totalSugar: { increment: input.sugarG },
          mealCount: { increment: 1 },
        },
      });

      return entry;
    });

    res.status(201).json({
      success: true,
      message: 'Food entry saved successfully.',
      data: foodEntry,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/food/history
 * Returns paginated food history for the authenticated user, ordered by date descending.
 */
export const getFoodHistory = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const skip = (page - 1) * limit;

    const [entries, total] = await Promise.all([
      prisma.foodEntry.findMany({
        where: { userId },
        include: { items: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.foodEntry.count({ where: { userId } }),
    ]);

    res.json({
      success: true,
      data: {
        entries,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/food/:id
 * Returns a single food entry with all items. Verifies ownership.
 */
export const getFoodById = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId as string;
    const id = req.params.id as string;

    const entry = await prisma.foodEntry.findFirst({
      where: { id, userId }, // Ownership check
      include: { items: true },
    });

    if (!entry) {
      throw new AppError(404, 'Food entry not found.');
    }

    res.json({
      success: true,
      data: entry,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/food/:id
 * Deletes a food entry and its associated items. Verifies ownership.
 * Also updates the daily nutrition aggregate.
 */
export const deleteFood = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId as string;
    const id = req.params.id as string;

    // Find the entry to verify ownership and get data for aggregate update
    const entry = await prisma.foodEntry.findFirst({
      where: { id, userId },
    });

    if (!entry) {
      throw new AppError(404, 'Food entry not found.');
    }

    await prisma.$transaction(async (tx) => {
      // Delete the food entry (cascade deletes items)
      await tx.foodEntry.delete({ where: { id } });

      // Update daily nutrition aggregate
      const entryDate = new Date(entry.createdAt);
      entryDate.setHours(0, 0, 0, 0);

      const dailyNutrition = await tx.dailyNutrition.findUnique({
        where: { userId_date: { userId, date: entryDate } },
      });

      if (dailyNutrition) {
        if (dailyNutrition.mealCount <= 1) {
          // Last meal of the day — delete the daily record
          await tx.dailyNutrition.delete({
            where: { userId_date: { userId, date: entryDate } },
          });
        } else {
          // Decrement totals
          await tx.dailyNutrition.update({
            where: { userId_date: { userId, date: entryDate } },
            data: {
              totalCalories: { decrement: entry.totalCalories },
              totalProtein: { decrement: entry.totalProtein },
              totalCarbs: { decrement: entry.totalCarbs },
              totalFat: { decrement: entry.totalFat },
              totalFiber: { decrement: entry.totalFiber },
              totalSugar: { decrement: entry.totalSugar },
              totalSodium: { decrement: entry.totalSodium },
              mealCount: { decrement: 1 },
            },
          });
        }
      }
    });

    // Delete the associated image file
    if (entry.imageUrl) {
      deleteImage(entry.imageUrl);
    }

    res.json({
      success: true,
      message: 'Food entry deleted successfully.',
    });
  } catch (error) {
    next(error);
  }
};
