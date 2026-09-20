import { Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { updateProfileSchema } from '../validators/userValidators';
import { deleteImage } from '../services/storageService';

/**
 * GET /api/user/profile
 * Returns the authenticated user's profile (excluding password hash).
 */
export const getProfile = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        age: true,
        gender: true,
        heightCm: true,
        weightKg: true,
        activityLevel: true,
        dailyCalorieGoal: true,
        dietaryPreference: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw new AppError(404, 'User not found.');
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/user/profile
 * Updates the authenticated user's profile fields.
 */
export const updateProfile = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;
    const input = updateProfileSchema.parse(req.body);

    const user = await prisma.user.update({
      where: { id: userId },
      data: input,
      select: {
        id: true,
        email: true,
        name: true,
        age: true,
        gender: true,
        heightCm: true,
        weightKg: true,
        activityLevel: true,
        dailyCalorieGoal: true,
        dietaryPreference: true,
        createdAt: true,
      },
    });

    res.json({
      success: true,
      message: 'Profile updated successfully.',
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/user/account
 * Deletes the authenticated user's account and all associated data.
 * This is irreversible — GDPR compliance.
 */
export const deleteAccount = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId!;

    // Get all food entries to delete associated images
    const entries = await prisma.foodEntry.findMany({
      where: { userId },
      select: { imageUrl: true },
    });

    // Delete the user (cascades to food entries, items, daily nutrition)
    await prisma.user.delete({ where: { id: userId } });

    // Clean up image files
    for (const entry of entries) {
      if (entry.imageUrl) {
        deleteImage(entry.imageUrl);
      }
    }

    res.json({
      success: true,
      message: 'Account and all associated data have been permanently deleted.',
    });
  } catch (error) {
    next(error);
  }
};
