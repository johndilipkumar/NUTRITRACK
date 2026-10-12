import { z } from 'zod';

// ─── Plan management validators ─────────────────────────────────────────

export const createPlanSchema = z.object({
  name: z.string().min(1, 'Plan name is required').max(100),
  slug: z.string().min(1).max(50).regex(/^[a-z0-9-]+$/, 'Slug must be lowercase alphanumeric with hyphens'),
  description: z.string().max(500).optional(),
  priceAmount: z.number().int().min(0, 'Price cannot be negative'),
  currency: z.string().default('INR'),
  billingInterval: z.enum(['monthly', 'yearly']).default('monthly'),
  monthlyCreditLimit: z.number().int().min(1, 'Monthly credit limit must be positive'),
  dailyCreditLimit: z.number().int().min(1).optional().nullable(),
  dailyRequestLimit: z.number().int().min(1, 'Daily request limit must be positive'),
  generationLimit: z.number().int().min(1, 'Generation limit must be positive').default(2),
  maxInputTokens: z.number().int().min(1).default(2048),
  maxOutputTokens: z.number().int().min(1, 'Max output tokens must be positive'),
  allowedModels: z.array(z.string()).default([]),
  features: z.record(z.boolean()).default({}),
  isDefault: z.boolean().default(false),
  isActive: z.boolean().default(true),
  sortOrder: z.number().int().default(0),
});

export const updatePlanSchema = createPlanSchema.partial().refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one field must be provided for update' }
);

// ─── Credit adjustment validators ───────────────────────────────────────

export const creditAdjustmentSchema = z.object({
  userId: z.string().uuid('Invalid user ID'),
  amount: z.number().int().min(1, 'Credit amount must be positive'),
  type: z.enum(['grant', 'revoke']),
  reason: z.string().min(1, 'Reason is required').max(500),
  expiresAt: z.string().datetime().optional().nullable(),
});

// ─── Plan assignment validator ──────────────────────────────────────────

export const assignPlanSchema = z.object({
  userId: z.string().uuid('Invalid user ID'),
  planId: z.string().uuid('Invalid plan ID'),
  reason: z.string().min(1, 'Reason is required').max(500),
});

// ─── User AI access toggle ─────────────────────────────────────────────

export const toggleAiAccessSchema = z.object({
  userId: z.string().uuid('Invalid user ID'),
  enabled: z.boolean(),
  reason: z.string().min(1, 'Reason is required').max(500),
});

export const toggleUnlimitedGenerationsSchema = z.object({
  userId: z.string().uuid('Invalid user ID'),
  enabled: z.boolean(),
  reason: z.string().max(500).optional(),
});

// ─── Global config update ───────────────────────────────────────────────

export const updateGlobalConfigSchema = z.object({
  key: z.string().min(1),
  value: z.string(),
  description: z.string().optional(),
});

export type CreatePlanInput = z.infer<typeof createPlanSchema>;
export type UpdatePlanInput = z.infer<typeof updatePlanSchema>;
export type CreditAdjustmentInput = z.infer<typeof creditAdjustmentSchema>;
export type AssignPlanInput = z.infer<typeof assignPlanSchema>;
