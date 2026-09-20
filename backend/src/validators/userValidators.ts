import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z.string().max(100).optional(),
  age: z.number().int().min(1).max(150).optional().nullable(),
  gender: z.enum(['male', 'female', 'other', 'prefer_not_to_say']).optional().nullable(),
  heightCm: z.number().min(30).max(300).optional().nullable(),
  weightKg: z.number().min(10).max(500).optional().nullable(),
  activityLevel: z
    .enum(['sedentary', 'light', 'moderate', 'active', 'very_active'])
    .optional()
    .nullable(),
  dailyCalorieGoal: z.number().int().min(500).max(10000).optional(),
  dietaryPreference: z
    .enum(['none', 'vegetarian', 'vegan', 'keto', 'paleo', 'halal', 'kosher', 'gluten_free'])
    .optional()
    .nullable(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
