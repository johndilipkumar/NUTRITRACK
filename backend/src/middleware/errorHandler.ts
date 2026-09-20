import { Request, Response, NextFunction } from 'express';

/**
 * Application-level error class for throwing typed HTTP errors.
 */
export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public isOperational: boolean = true
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

/**
 * Global error handler middleware.
 * Catches all unhandled errors and returns safe JSON responses
 * without leaking internal implementation details.
 */
export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Log the full error for debugging (server-side only)
  console.error('Error:', {
    name: err.name,
    message: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });

  // Known operational errors
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
    return;
  }

  // Prisma known errors
  if (err.name === 'PrismaClientKnownRequestError') {
    res.status(400).json({
      success: false,
      message: 'Database operation failed. Please check your request.',
    });
    return;
  }

  // Multer file size error
  if (err.name === 'MulterError') {
    res.status(400).json({
      success: false,
      message: 'File upload error. Please ensure your file is under 10MB.',
    });
    return;
  }

  // Zod validation errors
  if (err.name === 'ZodError') {
    res.status(400).json({
      success: false,
      message: 'Validation failed. Please check your input.',
    });
    return;
  }

  // Unknown/unexpected errors — never expose details to client
  res.status(500).json({
    success: false,
    message: 'An unexpected error occurred. Please try again later.',
  });
};
