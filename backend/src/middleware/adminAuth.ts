import { Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { AuthRequest } from './auth';

/**
 * Admin authorization middleware.
 * Must be used AFTER the `authenticate` middleware.
 * Verifies that the authenticated user has the 'admin' role.
 */
export const requireAdmin = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.userId;

    if (!userId) {
      res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    if (!user || user.role !== 'admin') {
      res.status(403).json({
        success: false,
        message: 'Administrative access required.',
      });
      return;
    }

    next();
  } catch (error) {
    next(error);
  }
};
