import rateLimit from 'express-rate-limit';

/**
 * General API rate limiter: 100 requests per 15 minutes per IP.
 */
export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: {
    success: false,
    message: 'Too many requests. Please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Strict rate limiter for the AI analysis endpoint: 10 requests per minute.
 * Gemini API calls are expensive so we limit them aggressively.
 */
export const analysisLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10,
  message: {
    success: false,
    message: 'Too many analysis requests. Please wait a moment before scanning more food.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Auth rate limiter: 20 attempts per 15 minutes to prevent brute force.
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: {
    success: false,
    message: 'Too many login attempts. Please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
