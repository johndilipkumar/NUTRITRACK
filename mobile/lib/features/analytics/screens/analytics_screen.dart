import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/error_widget.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);

    return Scaffold(
      body: SafeArea(
        child: analytics.isLoading
            ? _buildLoadingState()
            : analytics.error != null
                ? AppErrorWidget(
                    message: analytics.error!,
                    onRetry: () => ref.read(analyticsProvider.notifier).fetchAnalytics(),
                  )
                : _buildContent(context, analytics),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          ShimmerLoading(height: 36, width: 150),
          SizedBox(height: 20),
          ShimmerLoading(height: 50),
          SizedBox(height: 16),
          ShimmerLoading(height: 260),
          SizedBox(height: 16),
          ShimmerLoading(height: 260),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnalyticsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daily = state.dailyData?['daily'] as List<dynamic>? ?? [];
    final summary = state.dailyData?['summary'] as Map<String, dynamic>? ?? {};
    final topFoods = state.weeklyData?['topFoods'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),

          // Day range selector — pill buttons
          Row(
            children: [
              _DayChip(label: '7D', selected: state.selectedDays == 7, onTap: () => ref.read(analyticsProvider.notifier).setDays(7)),
              const SizedBox(width: 8),
              _DayChip(label: '14D', selected: state.selectedDays == 14, onTap: () => ref.read(analyticsProvider.notifier).setDays(14)),
              const SizedBox(width: 8),
              _DayChip(label: '30D', selected: state.selectedDays == 30, onTap: () => ref.read(analyticsProvider.notifier).setDays(30)),
            ],
          ),
          const SizedBox(height: 20),

          // Summary cards — glassmorphic
          Row(
            children: [
              _summaryCard(context, isDark, 'Avg Cal', '${summary['avgCalories'] ?? 0}', 'kcal/day', AppColors.accentOrange),
              const SizedBox(width: 10),
              _summaryCard(context, isDark, 'Score', '${summary['avgScore'] ?? 0}', '/100', AppColors.primary),
              const SizedBox(width: 10),
              _summaryCard(context, isDark, 'Meals', '${summary['totalMeals'] ?? 0}', 'scanned', AppColors.accentPurple),
            ],
          ),
          const SizedBox(height: 24),

          // Calorie chart — in glass card
          _GlassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Calories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: daily.isEmpty
                      ? Center(
                          child: Text(
                            'No data yet',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : _buildCalorieChart(context, daily, isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Score chart — in glass card
          _GlassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: daily.isEmpty
                      ? Center(
                          child: Text(
                            'No data yet',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : _buildScoreChart(context, daily, isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Top foods
          if (topFoods.isNotEmpty) ...[
            Text(
              'Most Eaten',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...topFoods.take(5).map((food) {
              final f = food as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Count badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${f['count']}×',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f['name'] ?? '',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Avg ~${f['avgCalories']} kcal • Score: ${f['avgScore']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, bool isDark, String label, String value, String unit, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(unit, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieChart(BuildContext context, List<dynamic> daily, bool isDark) {
    final barGroups = <BarChartGroupData>[];
    final maxCal = daily.fold<double>(0, (max, d) {
      final cal = (d['calories'] as num).toDouble();
      return cal > max ? cal : max;
    });

    for (int i = 0; i < daily.length && i < 14; i++) {
      final d = daily[i] as Map<String, dynamic>;
      final cal = (d['calories'] as num).toDouble();
      barGroups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: cal,
            gradient: cal > 0
                ? LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.6), AppColors.primary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: cal > 0 ? null : AppColors.primary.withValues(alpha: 0.15),
            width: daily.length > 10 ? 10 : 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ]),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxCal > 0 ? maxCal * 1.2 : 2500,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxCal > 0 ? maxCal / 4 : 500,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < daily.length) {
                  final date = DateTime.parse(daily[idx]['date'] as String);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppDateUtils.formatDay(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} kcal',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChart(BuildContext context, List<dynamic> daily, bool isDark) {
    final spots = <FlSpot>[];

    for (int i = 0; i < daily.length; i++) {
      final d = daily[i] as Map<String, dynamic>;
      final score = (d['avgScore'] as num).toDouble();
      if (score > 0) {
        spots.add(FlSpot(i.toDouble(), score));
      }
    }

    if (spots.isEmpty) return Center(child: Text('No score data yet', style: Theme.of(context).textTheme.bodySmall));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary],
            ),
            barWidth: 3,
            dotData: FlDotData(show: spots.length < 15),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) => LineTooltipItem(
              'Score: ${spot.y.toInt()}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerTheme.color ?? Colors.grey,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
