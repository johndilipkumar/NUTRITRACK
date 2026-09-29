import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/scan_provider.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../history/providers/history_provider.dart';

/// Food analysis result screen — clean black & white design with full nutrition details.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis Result')),
        body: const Center(child: Text('No analysis result available')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: CustomScrollView(
        slivers: [
          // ─── Image Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  ref.read(scanProvider.notifier).reset();
                  context.go('/home');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (scanState.imageFile != null)
                    kIsWeb
                        ? Image.network(scanState.imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(scanState.imageFile!.path), fit: BoxFit.cover)
                  else
                    Container(color: AppColors.primary),
                  // Gradient overlay at bottom for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ─── Meal Name & Score ────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.mealName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.scoreColor(result.overallScore).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppConstants.scoreLabel(result.overallScore),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.scoreColor(result.overallScore),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildScoreRing(result.overallScore, isDark),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ─── Calories Hero ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${result.totalCalories.toInt()}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Macros Row ───────────────────────────────────
                  _buildMacroRow(context, isDark, result),
                  const SizedBox(height: 28),

                  // ─── Full Nutrition Table ─────────────────────────
                  _buildSectionHeader('Nutrition Facts', isDark),
                  const SizedBox(height: 12),
                  _buildNutritionTable(isDark, result),
                  const SizedBox(height: 28),

                  // ─── Item Details ─────────────────────────────────
                  if (result.items.isNotEmpty) ...[
                    _buildSectionHeader(
                      result.items.length > 1 ? 'Items (${result.items.length})' : 'Item Details',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    ...result.items.map((item) => _buildItemCard(context, isDark, item)),
                    const SizedBox(height: 20),
                  ],

                  // ─── Insights ─────────────────────────────────────
                  _buildInsights(context, isDark, result),

                  // ─── Disclaimer ───────────────────────────────────
                  if (result.disclaimer.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      result.disclaimer,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ─── Meal Type Selector ───────────────────────────
                  _buildSectionHeader('Save as', isDark),
                  const SizedBox(height: 12),
                  _buildMealTypeSelector(isDark),
                  const SizedBox(height: 20),

                  // ─── Save Button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: scanState.status == ScanStatus.saving
                          ? null
                          : () async {
                              final success = await ref
                                  .read(scanProvider.notifier)
                                  .saveFood(_selectedMealType);
                              if (success && mounted) {
                                ref.read(dashboardProvider.notifier).refresh();
                                ref.read(historyProvider.notifier).refresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Meal saved successfully'),
                                    backgroundColor: isDark ? Colors.white : Colors.black,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                ref.read(scanProvider.notifier).reset();
                                context.go('/home');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: scanState.status == ScanStatus.saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text('Save Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Score Ring ──────────────────────────────────────────────────────
  Widget _buildScoreRing(int score, bool isDark) {
    final color = AppColors.scoreColor(score);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 4,
              backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                'score',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Macros Row ─────────────────────────────────────────────────────
  Widget _buildMacroRow(BuildContext context, bool isDark, result) {
    return Row(
      children: [
        _macroChip('Protein', '${result.totalProtein.toStringAsFixed(1)}g', isDark),
        const SizedBox(width: 8),
        _macroChip('Carbs', '${result.totalCarbs.toStringAsFixed(1)}g', isDark),
        const SizedBox(width: 8),
        _macroChip('Fat', '${result.totalFat.toStringAsFixed(1)}g', isDark),
      ],
    );
  }

  Widget _macroChip(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: -0.3,
      ),
    );
  }

  // ─── Full Nutrition Table ───────────────────────────────────────────
  Widget _buildNutritionTable(bool isDark, result) {
    final dividerColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          _nutritionRow('Calories', '${result.totalCalories.toInt()} kcal', isDark, isBold: true),
          Divider(height: 1, color: dividerColor),
          _nutritionRow('Protein', '${result.totalProtein.toStringAsFixed(1)} g', isDark),
          Divider(height: 1, color: dividerColor),
          _nutritionRow('Carbohydrates', '${result.totalCarbs.toStringAsFixed(1)} g', isDark),
          Divider(height: 1, color: dividerColor),
          _nutritionRow('Fat', '${result.totalFat.toStringAsFixed(1)} g', isDark),
          Divider(height: 1, color: dividerColor),
          _nutritionRow('Fiber', '${result.totalFiber.toStringAsFixed(1)} g', isDark),
          Divider(height: 1, color: dividerColor),
          _nutritionRow('Sugar', '${result.totalSugar.toStringAsFixed(1)} g', isDark),
          Divider(height: 1, color: dividerColor),
          _nutritionRow('Sodium', '${result.totalSodium.toInt()} mg', isDark),
        ],
      ),
    );
  }

  Widget _nutritionRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Item Card ──────────────────────────────────────────────────────
  Widget _buildItemCard(BuildContext context, bool isDark, item) {
    final dividerColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB);
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8);
    final scoreColor = AppColors.scoreColor(item.nutritionScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.calories.toInt()} kcal · ${item.estimatedPortion ?? 'estimated'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.nutritionScore}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // Micro nutrients
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _itemNutrientRow('Protein', '${item.proteinG.toStringAsFixed(1)} g', isDark),
                const SizedBox(height: 8),
                _itemNutrientRow('Carbs', '${item.carbsG.toStringAsFixed(1)} g', isDark),
                const SizedBox(height: 8),
                _itemNutrientRow('Fat', '${item.fatG.toStringAsFixed(1)} g', isDark),
                const SizedBox(height: 8),
                _itemNutrientRow('Fiber', '${item.fiberG.toStringAsFixed(1)} g', isDark),
                const SizedBox(height: 8),
                _itemNutrientRow('Sugar', '${item.sugarG.toStringAsFixed(1)} g', isDark),
                const SizedBox(height: 8),
                _itemNutrientRow('Sodium', '${item.sodiumMg.toInt()} mg', isDark),
              ],
            ),
          ),
          // Healthier alternative
          if (item.healthierAlternative != null && item.healthierAlternative!.isNotEmpty) ...[
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      item.healthierAlternative!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemNutrientRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  // ─── Insights ───────────────────────────────────────────────────────
  Widget _buildInsights(BuildContext context, bool isDark, result) {
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
        _buildSectionHeader('Insights', isDark),
        const SizedBox(height: 12),
        ...allPositive.toSet().take(4).map((p) => _insightRow(p, true, isDark)),
        ...allConcerns.toSet().take(4).map((c) => _insightRow(c, false, isDark)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _insightRow(String text, bool isPositive, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPositive ? '✓  ' : '⚠  ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.warning,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Meal Type Selector ─────────────────────────────────────────────
  Widget _buildMealTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.mealTypes.map((type) {
        final isSelected = _selectedMealType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedMealType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              '${AppConstants.mealTypeEmojis[type]} ${AppConstants.mealTypeLabels[type]}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
