import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { supabase } from '../config/supabase';

// Extend Express Request type to include authenticated user
export interface AuthRequest extends Request {
  userId?: string;
  user?: {
    id: string;
    email: string;
    name: string | null;
  };
}

interface JwtPayload {
  userId: string;
  email: string;
}

/**
 * JWT authentication middleware.
 * Extracts Bearer token from Authorization header, verifies it,
 * and attaches the user to the request object.
 */
export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        message: 'Authentication required. Please provide a valid token.',
      });
      return;
    }

    const token = authHeader.split(' ')[1];

    const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(token);

    if (error || !supabaseUser) {
      res.status(401).json({
        success: false,
        message: 'Invalid or expired token.',
      });
      return;
    }

    // Verify user still exists in our database, or create them if they just signed up via OAuth
    let user = await prisma.user.findUnique({
      where: { email: supabaseUser.email?.toLowerCase() || '' },
      select: { id: true, email: true, name: true },
    });

    if (!user && supabaseUser.email) {
      // Auto-create user record for new Supabase auth users
      user = await prisma.user.create({
        data: {
          id: supabaseUser.id, // Keep IDs synced if possible, though Prisma uses uuid by default
          email: supabaseUser.email.toLowerCase(),
          passwordHash: '', // No password hash for OAuth
          name: supabaseUser.user_metadata?.full_name || supabaseUser.email.split('@')[0],
          dailyCalorieGoal: 2000,
        },
        select: { id: true, email: true, name: true },
      });
    } else if (!user) {
      res.status(401).json({
        success: false,
        message: 'User account not found.',
      });
      return;
    }

    req.userId = user.id;
    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};
