import { Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';

/**
 * GET /api/dashboard
 * Returns the user's dashboard data: today's nutrition, calorie goal, and recent meals.
 */
export const getDashboard = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    // Get today's date (midnight)
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Fetch user profile (for calorie goal) and today's data concurrently
    const [user, dailyNutrition, todaysMeals] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          name: true,
          email: true,
          dailyCalorieGoal: true,
          dietaryPreference: true,
        },
      }),
      prisma.dailyNutrition.findUnique({
        where: { userId_date: { userId, date: today } },
      }),
      prisma.foodEntry.findMany({
        where: {
          userId,
          createdAt: {
            gte: today,
            lt: tomorrow,
          },
        },
        include: { items: true },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    // Calculate macro goals (rough defaults based on calorie goal)
    const calorieGoal = user?.dailyCalorieGoal || 2000;
    const proteinGoal = Math.round(calorieGoal * 0.25 / 4);   // 25% from protein (4 cal/g)
    const carbsGoal = Math.round(calorieGoal * 0.50 / 4);     // 50% from carbs (4 cal/g)
    const fatGoal = Math.round(calorieGoal * 0.25 / 9);       // 25% from fat (9 cal/g)

    res.json({
      success: true,
      data: {
        user: {
          name: user?.name || 'there',
          dailyCalorieGoal: calorieGoal,
        },
        today: {
          calories: dailyNutrition?.totalCalories || 0,
          protein: dailyNutrition?.totalProtein || 0,
          carbs: dailyNutrition?.totalCarbs || 0,
          fat: dailyNutrition?.totalFat || 0,
          fiber: dailyNutrition?.totalFiber || 0,
          sugar: dailyNutrition?.totalSugar || 0,
          sodium: dailyNutrition?.totalSodium || 0,
          mealCount: dailyNutrition?.mealCount || 0,
          avgScore: dailyNutrition?.avgScore || 0,
        },
        goals: {
          calories: calorieGoal,
          protein: proteinGoal,
          carbs: carbsGoal,
          fat: fatGoal,
        },
        recentMeals: todaysMeals,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/analytics/daily
 * Returns daily nutrition data for the last N days (default 7).
 */
export const getDailyAnalytics = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const days = parseInt(req.query.days as string) || 7;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const dailyData = await prisma.dailyNutrition.findMany({
      where: {
        userId,
        date: { gte: startDate },
      },
      orderBy: { date: 'asc' },
    });

    // Fill in missing days with zeros
    const filledData = [];
    const currentDate = new Date(startDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    while (currentDate <= today) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const existingData = dailyData.find(
        (d) => d.date.toISOString().split('T')[0] === dateStr
      );

      filledData.push({
        date: dateStr,
        calories: existingData?.totalCalories || 0,
        protein: existingData?.totalProtein || 0,
        carbs: existingData?.totalCarbs || 0,
        fat: existingData?.totalFat || 0,
        fiber: existingData?.totalFiber || 0,
        sugar: existingData?.totalSugar || 0,
        sodium: existingData?.totalSodium || 0,
        mealCount: existingData?.mealCount || 0,
        avgScore: existingData?.avgScore || 0,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    // Compute averages
    const daysWithData = filledData.filter((d) => d.mealCount > 0);
    const avgCalories =
      daysWithData.length > 0
        ? Math.round(daysWithData.reduce((sum, d) => sum + d.calories, 0) / daysWithData.length)
        : 0;
    const avgScore =
      daysWithData.length > 0
        ? Math.round(daysWithData.reduce((sum, d) => sum + d.avgScore, 0) / daysWithData.length)
        : 0;

    res.json({
      success: true,
      data: {
        daily: filledData,
        summary: {
          avgCalories,
          avgScore,
          totalMeals: daysWithData.reduce((sum, d) => sum + d.mealCount, 0),
          daysTracked: daysWithData.length,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/analytics/weekly
 * Returns weekly aggregated nutrition data and most-eaten foods.
 */
export const getWeeklyAnalytics = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    // Get data for the last 4 weeks
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 28);
    startDate.setHours(0, 0, 0, 0);

    const [dailyData, topFoods] = await Promise.all([
      prisma.dailyNutrition.findMany({
        where: {
          userId,
          date: { gte: startDate },
        },
        orderBy: { date: 'asc' },
      }),
      // Get most frequently eaten foods
      prisma.foodItem.groupBy({
        by: ['name'],
        where: {
          foodEntry: {
            userId,
            createdAt: { gte: startDate },
          },
        },
        _count: { name: true },
        _avg: { calories: true, nutritionScore: true },
        orderBy: { _count: { name: 'desc' } },
        take: 10,
      }),
    ]);

    // Group daily data into weeks
    const weeks: Array<{
      weekStart: string;
      avgCalories: number;
      avgScore: number;
      totalMeals: number;
      totalProtein: number;
      totalCarbs: number;
      totalFat: number;
    }> = [];

    for (let w = 0; w < 4; w++) {
      const weekStart = new Date(startDate);
      weekStart.setDate(weekStart.getDate() + w * 7);
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 7);

      const weekData = dailyData.filter((d) => d.date >= weekStart && d.date < weekEnd);

      if (weekData.length > 0) {
        weeks.push({
          weekStart: weekStart.toISOString().split('T')[0],
          avgCalories: Math.round(
            weekData.reduce((s, d) => s + d.totalCalories, 0) / weekData.length
          ),
          avgScore: Math.round(
            weekData.reduce((s, d) => s + d.avgScore, 0) / weekData.length
          ),
          totalMeals: weekData.reduce((s, d) => s + d.mealCount, 0),
          totalProtein: Math.round(weekData.reduce((s, d) => s + d.totalProtein, 0)),
          totalCarbs: Math.round(weekData.reduce((s, d) => s + d.totalCarbs, 0)),
          totalFat: Math.round(weekData.reduce((s, d) => s + d.totalFat, 0)),
        });
      }
    }

    res.json({
      success: true,
      data: {
        weeks,
        topFoods: topFoods.map((f) => ({
          name: f.name,
          count: f._count.name,
          avgCalories: Math.round(f._avg.calories || 0),
          avgScore: Math.round(f._avg.nutritionScore || 0),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};
