-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" TEXT,
    "age" INTEGER,
    "gender" TEXT,
    "height_cm" DOUBLE PRECISION,
    "weight_kg" DOUBLE PRECISION,
    "activity_level" TEXT,
    "daily_calorie_goal" INTEGER NOT NULL DEFAULT 2000,
    "dietary_preference" TEXT,
    "reset_token" TEXT,
    "reset_token_expiry" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "food_entries" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "image_url" TEXT,
    "meal_name" TEXT NOT NULL,
    "meal_type" TEXT NOT NULL DEFAULT 'snack',
    "total_calories" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_protein" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_carbs" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_fat" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_fiber" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_sugar" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_sodium" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "nutrition_score" INTEGER NOT NULL DEFAULT 0,
    "classification" TEXT NOT NULL DEFAULT 'unknown',
    "confidence" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "disclaimer" TEXT,
    "is_manual_entry" BOOLEAN NOT NULL DEFAULT false,
    "overall_positive" JSONB,
    "overall_concerns" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "food_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "food_items" (
    "id" TEXT NOT NULL,
    "food_entry_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL DEFAULT 'food',
    "estimated_portion" TEXT,
    "calories" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "protein_g" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "carbs_g" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "fat_g" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "fiber_g" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "sugar_g" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "sodium_mg" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "nutrition_score" INTEGER NOT NULL DEFAULT 0,
    "classification" TEXT NOT NULL DEFAULT 'unknown',
    "confidence" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "positive_points" JSONB,
    "concerns" JSONB,
    "healthier_alternative" TEXT,

    CONSTRAINT "food_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_nutrition" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "total_calories" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_protein" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_carbs" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_fat" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_fiber" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_sugar" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_sodium" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "meal_count" INTEGER NOT NULL DEFAULT 0,
    "avg_score" DOUBLE PRECISION NOT NULL DEFAULT 0,

    CONSTRAINT "daily_nutrition_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "food_entries_user_id_created_at_idx" ON "food_entries"("user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "daily_nutrition_user_id_date_idx" ON "daily_nutrition"("user_id", "date" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "daily_nutrition_user_id_date_key" ON "daily_nutrition"("user_id", "date");

-- AddForeignKey
ALTER TABLE "food_entries" ADD CONSTRAINT "food_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "food_items" ADD CONSTRAINT "food_items_food_entry_id_fkey" FOREIGN KEY ("food_entry_id") REFERENCES "food_entries"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_nutrition" ADD CONSTRAINT "daily_nutrition_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
