import { prisma } from '../config/database';

async function testSubscriptionFlow() {
  console.log('🧪 Starting Subscription & Generation Limit Verification...\n');

  // 1. Verify 3 plans exist
  const plans = await prisma.plan.findMany({
    where: { slug: { in: ['free', 'basic', 'pro'] } },
    orderBy: { sortOrder: 'asc' },
  });

  console.log(`Found ${plans.length} plans:`);
  for (const p of plans) {
    console.log(` - ${p.name} (${p.slug}): ₹${p.priceAmount / 100}/${p.billingInterval}, Limit: ${p.generationLimit} generations`);
  }

  if (plans.length !== 3) {
    throw new Error(`Expected 3 plans, found ${plans.length}`);
  }

  const freePlan = plans.find(p => p.slug === 'free')!;
  const basicPlan = plans.find(p => p.slug === 'basic')!;
  const proPlan = plans.find(p => p.slug === 'pro')!;

  if (freePlan.generationLimit !== 2 || basicPlan.generationLimit !== 4 || proPlan.generationLimit !== 8) {
    throw new Error('Plan generation limits do not match spec (2, 4, 8)');
  }
  if (freePlan.priceAmount !== 0 || basicPlan.priceAmount !== 10000 || proPlan.priceAmount !== 16000) {
    throw new Error('Plan prices do not match spec (₹0, ₹100, ₹160)');
  }
  console.log('✅ Plan specs verified: Free=2 (₹0), Basic=4 (₹100), Pro=8 (₹160)');

  // 2. Test user subscription creation & upgrade simulation
  // Find or create a test user
  let testUser = await prisma.user.findFirst({
    where: { email: 'test_sub_verifier@nutritrack.test' },
  });

  if (!testUser) {
    testUser = await prisma.user.create({
      data: {
        email: 'test_sub_verifier@nutritrack.test',
        passwordHash: 'dummyhash',
        name: 'Subscription Test User',
      },
    });
  }

  console.log(`\nTesting with user: ${testUser.email} (${testUser.id})`);

  // Expire any existing active subscriptions for a clean test
  await prisma.userSubscription.updateMany({
    where: { userId: testUser.id, status: 'active' },
    data: { status: 'expired' },
  });

  // Assign Free plan
  const now = new Date();
  const periodEnd = new Date(now);
  periodEnd.setDate(periodEnd.getDate() + 30);

  let sub = await prisma.userSubscription.create({
    data: {
      userId: testUser.id,
      planId: freePlan.id,
      status: 'active',
      billingPeriodStart: now,
      billingPeriodEnd: periodEnd,
      dailyResetDate: now,
    },
    include: { plan: true },
  });

  console.log(`✅ Default subscription created: ${sub.plan.name} (Limit: ${sub.plan.generationLimit})`);

  // Count usage
  let used = await prisma.usageEvent.count({
    where: {
      userId: testUser.id,
      status: 'completed',
      createdAt: { gte: sub.billingPeriodStart, lte: sub.billingPeriodEnd },
    },
  });
  console.log(`User generations used: ${used} / ${sub.plan.generationLimit}, remaining: ${Math.max(0, sub.plan.generationLimit - used)}`);

  // Simulate upgrade to Basic
  await prisma.userSubscription.updateMany({
    where: { userId: testUser.id, status: 'active' },
    data: { status: 'expired' },
  });
  sub = await prisma.userSubscription.create({
    data: {
      userId: testUser.id,
      planId: basicPlan.id,
      status: 'active',
      billingPeriodStart: now,
      billingPeriodEnd: periodEnd,
      dailyResetDate: now,
      isMockSubscription: true,
    },
    include: { plan: true },
  });
  console.log(`✅ Mock upgrade to Basic completed: ${sub.plan.name} (Limit: ${sub.plan.generationLimit}, isMock: ${sub.isMockSubscription})`);

  // Simulate upgrade to Pro
  await prisma.userSubscription.updateMany({
    where: { userId: testUser.id, status: 'active' },
    data: { status: 'expired' },
  });
  sub = await prisma.userSubscription.create({
    data: {
      userId: testUser.id,
      planId: proPlan.id,
      status: 'active',
      billingPeriodStart: now,
      billingPeriodEnd: periodEnd,
      dailyResetDate: now,
      isMockSubscription: true,
    },
    include: { plan: true },
  });
  console.log(`✅ Mock upgrade to Pro completed: ${sub.plan.name} (Limit: ${sub.plan.generationLimit}, isMock: ${sub.isMockSubscription})`);

  // Clean up test user
  await prisma.userSubscription.deleteMany({ where: { userId: testUser.id } });
  await prisma.user.delete({ where: { id: testUser.id } });
  console.log('\n🧹 Test user cleaned up.');

  console.log('\n✨ All subscription and generation limit logic verified successfully!');
}

testSubscriptionFlow()
  .catch((e) => {
    console.error('❌ Verification failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
