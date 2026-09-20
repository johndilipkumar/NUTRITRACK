import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/food_entry.dart';
import '../../../services/food_service.dart';
import '../../../widgets/nutrition_score_badge.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../history/providers/history_provider.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String foodId;
  const FoodDetailScreen({super.key, required this.foodId});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  final FoodService _foodService = FoodService();
  FoodEntry? _entry;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    try {
      final entry = await _foodService.getFoodById(widget.foodId);
      setState(() {
        _entry = entry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load food details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this food entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _foodService.deleteFood(widget.foodId);
        ref.read(dashboardProvider.notifier).refresh();
        ref.read(historyProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }

    final entry = _entry!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: entry.imageUrl != null ? 220 : 0,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _deleteEntry,
              ),
            ],
            flexibleSpace: entry.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Image.network(
                      '${ApiConstants.baseUrl}${entry.imageUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.mealName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppConstants.mealTypeLabels[entry.mealType] ?? 'Meal'} • ${AppDateUtils.formatDate(entry.createdAt)} at ${AppDateUtils.formatTime(entry.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      NutritionScoreBadge(
                        score: entry.nutritionScore,
                        size: 70,
                        label: 'Score',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.accentOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '~${entry.totalCalories.toInt()} kcal',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildMacroRow(
                    'Protein',
                    '${entry.totalProtein.toStringAsFixed(1)} g',
                    AppColors.protein,
                  ),
                  _buildMacroRow(
                    'Carbs',
                    '${entry.totalCarbs.toStringAsFixed(1)} g',
                    AppColors.carbs,
                  ),
                  _buildMacroRow(
                    'Fat',
                    '${entry.totalFat.toStringAsFixed(1)} g',
                    AppColors.fat,
                  ),
                  _buildMacroRow(
                    'Fiber',
                    '${entry.totalFiber.toStringAsFixed(1)} g',
                    AppColors.fiber,
                  ),
                  _buildMacroRow(
                    'Sugar',
                    '${entry.totalSugar.toStringAsFixed(1)} g',
                    AppColors.sugar,
                  ),
                  _buildMacroRow(
                    'Sodium',
                    '${entry.totalSodium.toStringAsFixed(0)} mg',
                    AppColors.sodium,
                  ),
                  const SizedBox(height: 24),

                  if (entry.items.isNotEmpty) ...[
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...entry.items.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${item.estimatedPortion ?? ''} • ${item.classification}',
                          ),
                          trailing: Text(
                            '~${item.calories.toInt()} kcal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (entry.disclaimer != null &&
                      entry.disclaimer!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.disclaimer!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
