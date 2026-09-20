import { GoogleGenerativeAI, Part } from '@google/generative-ai';
import fs from 'fs';
import { env } from '../config/env';
import { geminiResponseSchema, GeminiAnalysisResponse } from '../validators/foodValidators';

// Initialize the Gemini client with the server-side API key
// The key is NEVER exposed to the Flutter client
const genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);

/**
 * The system prompt instructs Gemini to act as a nutrition analyst.
 * It requests strict JSON output matching our Zod validation schema.
 * This prompt is never modifiable by end users.
 */
const NUTRITION_ANALYSIS_PROMPT = `You are an expert nutritionist and food analyst AI. Analyze the food or drink in this image and provide detailed nutritional information.

CRITICAL INSTRUCTIONS:
1. Identify ALL distinct food and drink items visible in the image.
2. For each item, estimate nutritional values based on visual assessment and typical serving sizes.
3. Be honest about uncertainty — if you cannot confidently identify something, indicate lower confidence.
4. If a nutrition label is visible, prioritize the label information over visual estimation.
5. For packaged foods, try to identify the brand and product name.
6. Distinguish between what is visually identifiable and what is estimated.
7. Provide a nutrition score from 0-100 where: 90-100=Excellent, 75-89=Good, 60-74=Moderate, 40-59=Needs improvement, 0-39=Low nutritional quality.

RESPONSE FORMAT — You MUST respond with ONLY valid JSON, no markdown, no code blocks, no extra text:
{
  "meal_name": "descriptive name for the overall meal",
  "items": [
    {
      "name": "food or drink name",
      "category": "meal|snack|drink|dessert|packaged|fruit|vegetable",
      "estimated_portion": "e.g. 150g, 1 cup, 1 slice",
      "calories": 0,
      "protein_g": 0,
      "carbs_g": 0,
      "fat_g": 0,
      "fiber_g": 0,
      "sugar_g": 0,
      "sodium_mg": 0,
      "nutrition_score": 0,
      "classification": "excellent|good|moderately healthy|needs improvement|low nutritional quality",
      "confidence": 0.0,
      "positive_points": ["list of positive nutritional aspects"],
      "concerns": ["list of potential nutritional concerns"],
      "healthier_alternative": "suggestion for a healthier version or alternative"
    }
  ],
  "total": {
    "calories": 0,
    "protein_g": 0,
    "carbs_g": 0,
    "fat_g": 0,
    "fiber_g": 0,
    "sugar_g": 0,
    "sodium_mg": 0
  },
  "overall_score": 0,
  "overall_classification": "excellent|good|moderately healthy|needs improvement|low nutritional quality",
  "disclaimer": "Nutritional values are estimates based on the image and estimated portion sizes."
}

If the image does not contain any food or drink, respond with:
{
  "meal_name": "No food detected",
  "items": [],
  "total": { "calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0, "fiber_g": 0, "sugar_g": 0, "sodium_mg": 0 },
  "overall_score": 0,
  "overall_classification": "unknown",
  "disclaimer": "No food or drink was detected in this image."
}

Remember: Output ONLY the JSON object. No markdown formatting, no \`\`\`json blocks, no explanatory text.`;

/**
 * Analyzes a food image using Google Gemini AI.
 *
 * @param imagePath - Absolute path to the uploaded image file
 * @returns Validated nutritional analysis result
 * @throws Error if Gemini fails or returns invalid data after retries
 */
export async function analyzeFood(imagePath: string): Promise<GeminiAnalysisResponse> {
  const MAX_RETRIES = 2;
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      // Read the image file and convert to base64
      const imageBuffer = fs.readFileSync(imagePath);
      const base64Image = imageBuffer.toString('base64');

      // Determine MIME type from file extension
      const ext = imagePath.toLowerCase().split('.').pop();
      const mimeTypeMap: Record<string, string> = {
        jpg: 'image/jpeg',
        jpeg: 'image/jpeg',
        png: 'image/png',
        webp: 'image/webp',
        heic: 'image/heic',
        heif: 'image/heif',
      };
      const mimeType = mimeTypeMap[ext || 'jpg'] || 'image/jpeg';

      // Prepare the image part for Gemini
      const imagePart: Part = {
        inlineData: {
          data: base64Image,
          mimeType,
        },
      };

      // Call Gemini with the nutrition analysis prompt + image
      const model = genAI.getGenerativeModel({ model: 'gemini-3.6-flash' });
      const result = await model.generateContent([NUTRITION_ANALYSIS_PROMPT, imagePart]);
      const response = await result.response;
      const text = response.text();

      // Parse and validate the JSON response
      const parsed = parseGeminiResponse(text);
      const validated = geminiResponseSchema.parse(parsed);

      // Additional safety: ensure items array has at least the "no food" fallback
      if (validated.items.length === 0 && validated.meal_name !== 'No food detected') {
        validated.meal_name = 'No food detected';
        validated.disclaimer = 'No food or drink was detected in this image.';
      }

      return validated;
    } catch (error) {
      lastError = error as Error;
      console.error(`Gemini analysis attempt ${attempt + 1} failed:`, (error as Error).message);

      // Don't retry on certain errors
      if ((error as Error).message?.includes('SAFETY')) {
        throw new Error(
          'The image could not be analyzed due to content safety filters. Please try a different image.'
        );
      }

      // Wait before retrying (exponential backoff)
      if (attempt < MAX_RETRIES) {
        await new Promise((resolve) => setTimeout(resolve, 1000 * (attempt + 1)));
      }
    }
  }

  throw new Error(
    `Food analysis failed after ${MAX_RETRIES + 1} attempts. ${lastError?.message || 'Unknown error'}`
  );
}

/**
 * Parses Gemini's text response, handling potential markdown code blocks
 * or extra text around the JSON.
 */
function parseGeminiResponse(text: string): unknown {
  // Remove markdown code blocks if present
  let cleaned = text.trim();

  // Handle ```json ... ``` wrapping
  const jsonBlockMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonBlockMatch) {
    cleaned = jsonBlockMatch[1].trim();
  }

  // Try to extract JSON object if there's extra text
  const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    cleaned = jsonMatch[0];
  }

  try {
    return JSON.parse(cleaned);
  } catch {
    throw new Error(`Failed to parse Gemini response as JSON: ${cleaned.substring(0, 200)}...`);
  }
}
