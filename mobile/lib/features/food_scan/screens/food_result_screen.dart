import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/nutrition_score_badge.dart';
import '../providers/scan_provider.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../history/providers/history_provider.dart';

/// Food analysis result screen — shows detailed nutrition breakdown from Gemini.
class FoodResultScreen extends ConsumerStatefulWidget {
  const FoodResultScreen({super.key});

  @override
  ConsumerState<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends ConsumerState<FoodResultScreen> {
  String _selectedMealType = 'snack';

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final result = scanState.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis Result')),
        body: const Center(child: Text('No analysis result available')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with food image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black38,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
              onPressed: () {
                ref.read(scanProvider.notifier).reset();
                context.go('/home');
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: scanState.imageFile != null
                  ? (kIsWeb
                      ? Image.network(scanState.imageFile!.path, fit: BoxFit.cover)
                      : Image.file(File(scanState.imageFile!.path), fit: BoxFit.cover))
                  : Container(color: AppColors.primary),
            ),
          ),

          // Result content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal name and score
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.mealName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppConstants.scoreEmoji(result.overallScore)} ${AppConstants.scoreLabel(result.overallScore)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.scoreColor(result.overallScore),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      NutritionScoreBadge(
                        score: result.overallScore,
                        size: 80,
                        label: 'Score',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Total calories - big display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: AppColors.accentOrange, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            '~${result.totalCalories.toInt()}',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kcal',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Macros grid
                  _buildMacrosGrid(context, result),
                  const SizedBox(height: 24),

                  // Food items breakdown — always show details for every item
                  if (result.items.isNotEmpty) ...[
                    Text(
                      result.items.length > 1 ? 'Food Breakdown' : 'Nutritional Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...result.items.map((item) => Card(
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                            initiallyExpanded: result.items.length == 1, // Auto-expand for single items
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '~${item.calories.toInt()} kcal • ${item.estimatedPortion ?? 'estimated'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.scoreColor(item.nutritionScore).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.nutritionScore}',
                                style: TextStyle(
                                  color: AppColors.scoreColor(item.nutritionScore),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _macroRow('Calories', '${item.calories.toStringAsFixed(0)} kcal', AppColors.accentOrange),
                                    _macroRow('Protein', '${item.proteinG.toStringAsFixed(1)} g', AppColors.protein),
                                    _macroRow('Carbs', '${item.carbsG.toStringAsFixed(1)} g', AppColors.carbs),
                                    _macroRow('Fat', '${item.fatG.toStringAsFixed(1)} g', AppColors.fat),
                                    _macroRow('Fiber', '${item.fiberG.toStringAsFixed(1)} g', AppColors.fiber),
                                    _macroRow('Sugar', '${item.sugarG.toStringAsFixed(1)} g', AppColors.sugar),
                                    _macroRow('Sodium', '${item.sodiumMg.toStringAsFixed(0)} mg', AppColors.sodium),
                                    if (item.healthierAlternative != null && item.healthierAlternative!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.info),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Try instead: ${item.healthierAlternative!}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.info),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Nutrition insights
                  _buildInsights(context, result),
                  const SizedBox(height: 16),

                  // Disclaimer
                  if (result.disclaimer.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.disclaimer,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Meal type selector
                  Text('Meal Type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.mealTypes.map((type) {
                      final isSelected = _selectedMealType == type;
                      return ChoiceChip(
                        label: Text(
                          '${AppConstants.mealTypeEmojis[type]} ${AppConstants.mealTypeLabels[type]}',
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedMealType = type);
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: scanState.status == ScanStatus.saving
                          ? null
                          : () async {
                              final success = await ref
                                  .read(scanProvider.notifier)
                                  .saveFood(_selectedMealType);
                              if (success && mounted) {
                                // Refresh dashboard and history
                                ref.read(dashboardProvider.notifier).refresh();
                                ref.read(historyProvider.notifier).refresh();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Meal saved successfully! 🎉'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                ref.read(scanProvider.notifier).reset();
                                context.go('/home');
                              }
                            },
                      icon: scanState.status == ScanStatus.saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(scanState.status == ScanStatus.saving ? 'Saving...' : 'Save Meal'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosGrid(BuildContext context, result) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _macroCard(context, 'Protein', '${result.totalProtein.toStringAsFixed(1)} g', AppColors.protein, Icons.fitness_center_rounded),
        _macroCard(context, 'Carbs', '${result.totalCarbs.toStringAsFixed(1)} g', AppColors.carbs, Icons.grain_rounded),
        _macroCard(context, 'Fat', '${result.totalFat.toStringAsFixed(1)} g', AppColors.fat, Icons.water_drop_rounded),
        _macroCard(context, 'Fiber', '${result.totalFiber.toStringAsFixed(1)} g', AppColors.fiber, Icons.eco_rounded),
        _macroCard(context, 'Sugar', '${result.totalSugar.toStringAsFixed(1)} g', AppColors.sugar, Icons.cake_rounded),
        _macroCard(context, 'Sodium', '${result.totalSodium.toStringAsFixed(0)} mg', AppColors.sodium, Icons.science_rounded),
      ],
    );
  }

  Widget _macroCard(BuildContext context, String label, String value, Color color, IconData icon) {
    final width = (MediaQuery.of(context).size.width - 56) / 3;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context, result) {
    final allPositive = <String>[];
    final allConcerns = <String>[];

    for (final item in result.items) {
      allPositive.addAll(item.positivePoints);
      allConcerns.addAll(item.concerns);
    }

    if (allPositive.isEmpty && allConcerns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutrition Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...allPositive.toSet().take(5).map((p) => _insightRow(p, true)),
        ...allConcerns.toSet().take(5).map((c) => _insightRow(c, false)),
      ],
    );
  }

  Widget _insightRow(String text, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 18,
            color: isPositive ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
