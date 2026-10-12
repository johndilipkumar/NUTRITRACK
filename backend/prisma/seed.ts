/**
 * Seed script for the three subscription plans: Free, Basic, Pro.
 * Run with: npx tsx prisma/seed.ts
 *
 * Idempotent — upserts plans by slug so it can be re-run safely.
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding subscription plans...\n');

  // Free Plan
  const free = await prisma.plan.upsert({
    where: { slug: 'free' },
    update: {
      name: 'Free',
      description: 'Get started with AI food analysis. Perfect for trying out NutriTrack.',
      priceAmount: 0,
      currency: 'INR',
      billingInterval: 'monthly',
      generationLimit: 2,
      monthlyCreditLimit: 100000,
      dailyCreditLimit: 5000,
      dailyRequestLimit: 20,
      maxInputTokens: 2048,
      maxOutputTokens: 500,
      allowedModels: ['gemini-2.0-flash'],
      features: { foodAnalysis: true, history: true, analytics: true },
      isDefault: true,
      isActive: true,
      sortOrder: 0,
    },
    create: {
      name: 'Free',
      slug: 'free',
      description: 'Get started with AI food analysis. Perfect for trying out NutriTrack.',
      priceAmount: 0,
      currency: 'INR',
      billingInterval: 'monthly',
      generationLimit: 2,
      monthlyCreditLimit: 100000,
      dailyCreditLimit: 5000,
      dailyRequestLimit: 20,
      maxInputTokens: 2048,
      maxOutputTokens: 500,
      allowedModels: ['gemini-2.0-flash'],
      features: { foodAnalysis: true, history: true, analytics: true },
      isDefault: true,
      isActive: true,
      sortOrder: 0,
    },
  });
  console.log(`✅ Free plan: ${free.id} (${free.generationLimit} generations, ₹${free.priceAmount / 100})`);

  // Basic Plan
  const basic = await prisma.plan.upsert({
    where: { slug: 'basic' },
    update: {
      name: 'Basic',
      description: 'More scans for regular trackers. 4 AI food analyses per month.',
      priceAmount: 10000, // ₹100 in paise
      currency: 'INR',
      billingInterval: 'monthly',
      generationLimit: 4,
      monthlyCreditLimit: 500000,
      dailyCreditLimit: 25000,
      dailyRequestLimit: 50,
      maxInputTokens: 4096,
      maxOutputTokens: 1000,
      allowedModels: ['gemini-2.0-flash'],
      features: { foodAnalysis: true, history: true, analytics: true, prioritySupport: false },
      isDefault: false,
      isActive: true,
      sortOrder: 1,
    },
    create: {
      name: 'Basic',
      slug: 'basic',
      description: 'More scans for regular trackers. 4 AI food analyses per month.',
      priceAmount: 10000,
      currency: 'INR',
      billingInterval: 'monthly',
      generationLimit: 4,
      monthlyCreditLimit: 500000,
      dailyCreditLimit: 25000,
      dailyRequestLimit: 50,
      maxInputTokens: 4096,
      maxOutputTokens: 1000,
      allowedModels: ['gemini-2.0-flash'],
      features: { foodAnalysis: true, history: true, analytics: true, prioritySupport: false },
      isDefault: false,
      isActive: true,
      sortOrder: 1,
    },
  });
  console.log(`✅ Basic plan: ${basic.id} (${basic.generationLimit} generations, ₹${basic.priceAmount / 100}/mo)`);

  // Pro Plan
  const pro = await prisma.plan.upsert({
    where: { slug: 'pro' },
    update: {
      name: 'Pro',
      description: 'Best value for power users. 8 AI food analyses per month.',
      priceAmount: 16000, // ₹160 in paise
      currency: 'INR',
      billingInterval: 'monthly',
      generationLimit: 8,
      monthlyCreditLimit: 2000000,
      dailyCreditLimit: 100000,
      dailyRequestLimit: 100,
      maxInputTokens: 8192,
      maxOutputTokens: 2000,
      allowedModels: ['gemini-2.0-flash', 'gemini-2.0-pro'],
      features: { foodAnalysis: true, history: true, analytics: true, prioritySupport: true },
      isDefault: false,
      isActive: true,
      sortOrder: 2,
    },
    create: {
      name: 'Pro',
      slug: 'pro',
      description: 'Best value for power users. 8 AI food analyses per month.',
      priceAmount: 16000,
      currency: 'INR',
      billingInterval: 'monthly',
      generationLimit: 8,
      monthlyCreditLimit: 2000000,
      dailyCreditLimit: 100000,
      dailyRequestLimit: 100,
      maxInputTokens: 8192,
      maxOutputTokens: 2000,
      allowedModels: ['gemini-2.0-flash', 'gemini-2.0-pro'],
      features: { foodAnalysis: true, history: true, analytics: true, prioritySupport: true },
      isDefault: false,
      isActive: true,
      sortOrder: 2,
    },
  });
  console.log(`✅ Pro plan: ${pro.id} (${pro.generationLimit} generations, ₹${pro.priceAmount / 100}/mo)`);

  console.log('\n🎉 Plan seeding complete!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
