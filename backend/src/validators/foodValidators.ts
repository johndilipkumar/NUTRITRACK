import { z } from 'zod';

// ─── Gemini AI response validation schema ───────────────────────────────
// This validates the structured JSON that Gemini returns after analyzing a food image.

const foodItemSchema = z.object({
  name: z.string(),
  category: z.string().default('food'),
  estimated_portion: z.string().optional().default('unknown'),
  calories: z.number().min(0).default(0),
  protein_g: z.number().min(0).default(0),
  carbs_g: z.number().min(0).default(0),
  fat_g: z.number().min(0).default(0),
  fiber_g: z.number().min(0).default(0),
  sugar_g: z.number().min(0).default(0),
  sodium_mg: z.number().min(0).default(0),
  nutrition_score: z.number().min(0).max(100).default(50),
  classification: z.string().default('unknown'),
  confidence: z.number().min(0).max(1).default(0.5),
  positive_points: z.array(z.string()).default([]),
  concerns: z.array(z.string()).default([]),
  healthier_alternative: z.string().optional().default(''),
});

const totalsSchema = z.object({
  calories: z.number().min(0).default(0),
  protein_g: z.number().min(0).default(0),
  carbs_g: z.number().min(0).default(0),
  fat_g: z.number().min(0).default(0),
  fiber_g: z.number().min(0).default(0),
  sugar_g: z.number().min(0).default(0),
  sodium_mg: z.number().min(0).default(0),
});

export const geminiResponseSchema = z.object({
  meal_name: z.string().default('Unknown Meal'),
  items: z.array(foodItemSchema).min(1),
  total: totalsSchema,
  overall_score: z.number().min(0).max(100).default(50),
  overall_classification: z.string().default('unknown'),
  disclaimer: z.string().default(
    'Nutritional values are estimates based on the image and estimated portion sizes.'
  ),
});

export type GeminiAnalysisResponse = z.infer<typeof geminiResponseSchema>;
export type FoodItemResponse = z.infer<typeof foodItemSchema>;

// ─── Save food request validation ───────────────────────────────────────

export const saveFoodSchema = z.object({
  imageUrl: z.string().optional(),
  mealName: z.string().min(1, 'Meal name is required'),
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']).default('snack'),
  items: z.array(
    z.object({
      name: z.string(),
      category: z.string().default('food'),
      estimatedPortion: z.string().optional(),
      calories: z.number().min(0),
      proteinG: z.number().min(0),
      carbsG: z.number().min(0),
      fatG: z.number().min(0),
      fiberG: z.number().min(0).default(0),
      sugarG: z.number().min(0).default(0),
      sodiumMg: z.number().min(0).default(0),
      nutritionScore: z.number().min(0).max(100).default(50),
      classification: z.string().default('unknown'),
      confidence: z.number().min(0).max(1).default(0.5),
      positivePoints: z.array(z.string()).default([]),
      concerns: z.array(z.string()).default([]),
      healthierAlternative: z.string().optional(),
    })
  ),
  totalCalories: z.number().min(0),
  totalProtein: z.number().min(0),
  totalCarbs: z.number().min(0),
  totalFat: z.number().min(0),
  totalFiber: z.number().min(0).default(0),
  totalSugar: z.number().min(0).default(0),
  totalSodium: z.number().min(0).default(0),
  nutritionScore: z.number().min(0).max(100).default(50),
  classification: z.string().default('unknown'),
  confidence: z.number().min(0).max(1).default(0.5),
  disclaimer: z.string().optional(),
});

export type SaveFoodInput = z.infer<typeof saveFoodSchema>;

// ─── Manual food entry validation ───────────────────────────────────────

export const manualFoodSchema = z.object({
  foodName: z.string().min(1, 'Food name is required'),
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']).default('snack'),
  portion: z.string().optional(),
  calories: z.number().min(0, 'Calories must be positive'),
  proteinG: z.number().min(0).default(0),
  carbsG: z.number().min(0).default(0),
  fatG: z.number().min(0).default(0),
  fiberG: z.number().min(0).default(0),
  sugarG: z.number().min(0).default(0),
});

export type ManualFoodInput = z.infer<typeof manualFoodSchema>;
