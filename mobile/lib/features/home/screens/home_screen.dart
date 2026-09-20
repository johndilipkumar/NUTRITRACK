import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../widgets/macro_progress_bar.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/error_widget.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).fetchDashboard();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: dashboard.data == null
            ? (dashboard.error != null
                ? AppErrorWidget(
                    message: dashboard.error!,
                    onRetry: () => ref.read(dashboardProvider.notifier).fetchDashboard(),
                  )
                : _buildLoadingState())
            : _buildDashboard(context, dashboard),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 60),
          ShimmerLoading(height: 32, width: 250),
          SizedBox(height: 24),
          ShimmerLoading(height: 280),
          SizedBox(height: 16),
          ShimmerLoading(height: 60),
          SizedBox(height: 8),
          ShimmerLoading(height: 60),
          SizedBox(height: 8),
          ShimmerLoading(height: 60),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardState state) {
    final data = state.data!;
    final calorieProgress = data.goals.calories > 0
        ? (data.today.calories / data.goals.calories).clamp(0.0, 1.5)
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = data.userName.isNotEmpty
        ? data.userName[0].toUpperCase() + data.userName.substring(1)
        : '';

    return CustomScrollView(
      slivers: [
        // Header with avatar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${AppDateUtils.getGreeting()}, $userName 👋',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                // Profile avatar
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Calorie ring card — premium glass
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Today's Calories",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Big calorie ring
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: calorieProgress),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _PremiumCalorieRingPainter(
                                    progress: value,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                    rotation: _rotationController.value * 2 * pi,
                                  ),
                                  child: child,
                                );
                              },
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${data.today.calories.toInt()}',
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 52,
                                            color: AppColors.primary,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                    ),
                                    Text(
                                      '/ ${data.goals.calories} kcal',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Macro bars with icons
                      MacroProgressBar(
                        label: 'Protein',
                        current: data.today.protein,
                        goal: data.goals.protein.toDouble(),
                        color: AppColors.primary,
                        icon: Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 10),
                      MacroProgressBar(
                        label: 'Carbs',
                        current: data.today.carbs,
                        goal: data.goals.carbs.toDouble(),
                        color: AppColors.carbs,
                        icon: Icons.grain_rounded,
                      ),
                      const SizedBox(height: 10),
                      MacroProgressBar(
                        label: 'Fat',
                        current: data.today.fat,
                        goal: data.goals.fat.toDouble(),
                        color: AppColors.fat,
                        icon: Icons.water_drop_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Today's meals header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Meals",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (data.today.mealCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${data.today.mealCount} meals',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Meals list or empty state
        if (data.recentMeals.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _PremiumEmptyState(),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final meal = data.recentMeals[index];
                final mealIsDark = isDark;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: GestureDetector(
                    onTap: () => context.push('/food/${meal.id}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (mealIsDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (mealIsDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    AppConstants.mealTypeEmojis[meal.mealType] ?? '🍽️',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal.mealName,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${AppConstants.mealTypeLabels[meal.mealType] ?? 'Meal'} • ${AppDateUtils.formatTime(meal.createdAt)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '~${meal.totalCalories.toInt()}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                  Text(
                                    'kcal',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: data.recentMeals.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

/// Premium empty state with artistic icon
class _PremiumEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const SizedBox(height: 16),
        // Glowing circle with fork/knife
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                ),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFF888888),
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your culinary canvas is clean.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          "Let's add your first masterpiece.\nTap the + to scan.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Premium multi-ring calorie painter with neon glow, tick marks, and concentric rings.
class _PremiumCalorieRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final double rotation;

  _PremiumCalorieRingPainter({
    required this.progress,
    required this.backgroundColor,
    this.rotation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 8;
    final mainRadius = outerRadius - 14;
    final innerRadius = mainRadius - 14;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Outer decorative ring with tick marks
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = backgroundColor;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Draw tick marks
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primary.withValues(alpha: 0.3);
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180 - pi / 2;
      final isLong = i % 5 == 0;
      final startR = outerRadius - (isLong ? 8 : 4);
      final endR = outerRadius;
      canvas.drawLine(
        Offset(center.dx + startR * cos(angle), center.dy + startR * sin(angle)),
        Offset(center.dx + endR * cos(angle), center.dy + endR * sin(angle)),
        tickPaint..strokeWidth = isLong ? 2 : 1,
      );
    }

    // Main background ring
    final mainBgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = backgroundColor;
    canvas.drawCircle(center, mainRadius, mainBgPaint);

    // Inner subtle ring
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = backgroundColor.withValues(alpha: 0.5);
    canvas.drawCircle(center, innerRadius, innerPaint);

    canvas.restore();

    // Progress arcs (don't rotate)
    final clampedProgress = progress.clamp(0.0, 1.0);
    final color = clampedProgress > 0.9 ? AppColors.warning : AppColors.primary;

    // Neon outer glow
    final outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: mainRadius),
      -pi / 2,
      2 * pi * clampedProgress,
      false,
      outerGlowPaint,
    );

    // Medium glow
    final medGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: mainRadius),
      -pi / 2,
      2 * pi * clampedProgress,
      false,
      medGlowPaint,
    );

    // Solid arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: mainRadius),
      -pi / 2,
      2 * pi * clampedProgress,
      false,
      arcPaint,
    );

    // Inner progress ring (thinner, slightly lighter)
    if (clampedProgress > 0) {
      final innerArcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -pi / 2,
        2 * pi * clampedProgress,
        false,
        innerArcPaint,
      );
    }

    // Bright dot at the end of the arc
    if (clampedProgress > 0.01) {
      final endAngle = -pi / 2 + 2 * pi * clampedProgress;
      final dotCenter = Offset(
        center.dx + mainRadius * cos(endAngle),
        center.dy + mainRadius * sin(endAngle),
      );

      // Dot glow
      final dotGlow = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dotCenter, 6, dotGlow);

      // White dot
      canvas.drawCircle(dotCenter, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumCalorieRingPainter old) {
    return old.progress != progress || old.rotation != rotation;
  }
}
