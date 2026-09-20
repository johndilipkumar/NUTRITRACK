import { Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../config/database';
import { env } from '../config/env';
import { AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import {
  registerSchema,
  loginSchema,
  resetPasswordRequestSchema,
  resetPasswordSchema,
} from '../validators/authValidators';

/**
 * Generate a JWT token for the given user.
 */
function generateToken(userId: string, email: string): string {
  return jwt.sign({ userId, email }, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN,
  } as jwt.SignOptions);
}

/**
 * POST /api/auth/register
 * Creates a new user account and returns a JWT token.
 */
export const register = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = registerSchema.parse(req.body);

    // Check if email already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase() },
    });

    if (existingUser) {
      throw new AppError(409, 'An account with this email already exists.');
    }

    // Hash password with bcrypt (12 rounds)
    const passwordHash = await bcrypt.hash(input.password, 12);

    // Create user
    const user = await prisma.user.create({
      data: {
        email: input.email.toLowerCase(),
        passwordHash,
        name: input.name || null,
        dailyCalorieGoal: 2000,
      },
      select: {
        id: true,
        email: true,
        name: true,
        dailyCalorieGoal: true,
        createdAt: true,
      },
    });

    // Generate JWT
    const token = generateToken(user.id, user.email);

    res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      data: {
        token,
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/login
 * Authenticates a user and returns a JWT token.
 */
export const login = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = loginSchema.parse(req.body);

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase() },
    });

    if (!user) {
      throw new AppError(401, 'Invalid email or password.');
    }

    // Compare password
    const isPasswordValid = await bcrypt.compare(input.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new AppError(401, 'Invalid email or password.');
    }

    // Generate JWT
    const token = generateToken(user.id, user.email);

    res.json({
      success: true,
      message: 'Login successful.',
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          dailyCalorieGoal: user.dailyCalorieGoal,
          age: user.age,
          gender: user.gender,
          heightCm: user.heightCm,
          weightKg: user.weightKg,
          activityLevel: user.activityLevel,
          dietaryPreference: user.dietaryPreference,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/reset-password-request
 * Generates a password reset token (token-based flow without email for MVP).
 * In production, this would send the token via email.
 */
export const resetPasswordRequest = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = resetPasswordRequestSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase() },
    });

    // Always return success to prevent email enumeration
    if (!user) {
      res.json({
        success: true,
        message: 'If an account with that email exists, a reset token has been generated.',
      });
      return;
    }

    // Generate a reset token (valid for 1 hour)
    const resetToken = uuidv4();
    const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        resetToken,
        resetTokenExpiry,
      },
    });

    // In MVP: return the token directly (in production, send via email)
    res.json({
      success: true,
      message: 'If an account with that email exists, a reset token has been generated.',
      // Only include token in development mode
      ...(env.NODE_ENV === 'development' && { data: { resetToken } }),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/reset-password
 * Resets the user's password using a valid reset token.
 */
export const resetPassword = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const input = resetPasswordSchema.parse(req.body);

    // Find user with matching, non-expired reset token
    const user = await prisma.user.findFirst({
      where: {
        resetToken: input.token,
        resetTokenExpiry: {
          gt: new Date(),
        },
      },
    });

    if (!user) {
      throw new AppError(400, 'Invalid or expired reset token.');
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(input.newPassword, 12);

    // Update password and clear reset token
    await prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        resetToken: null,
        resetTokenExpiry: null,
      },
    });

    res.json({
      success: true,
      message: 'Password has been reset successfully. Please login with your new password.',
    });
  } catch (error) {
    next(error);
  }
};
