import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/food_service.dart';
import '../../home/providers/dashboard_provider.dart';
import '../../history/providers/history_provider.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodService = FoodService();
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _portionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _fiberController = TextEditingController(text: '0');
  final _sugarController = TextEditingController(text: '0');
  String _mealType = 'snack';

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _foodService.saveManualFood(
        foodName: _nameController.text.trim(),
        mealType: _mealType,
        portion: _portionController.text.trim().isNotEmpty ? _portionController.text.trim() : null,
        calories: double.tryParse(_caloriesController.text) ?? 0,
        proteinG: double.tryParse(_proteinController.text) ?? 0,
        carbsG: double.tryParse(_carbsController.text) ?? 0,
        fatG: double.tryParse(_fatController.text) ?? 0,
        fiberG: double.tryParse(_fiberController.text) ?? 0,
        sugarG: double.tryParse(_sugarController.text) ?? 0,
      );

      ref.read(dashboardProvider.notifier).refresh();
      ref.read(historyProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food entry saved! ✓'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save entry'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add food manually when you don't have a photo",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      )),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Food Name *',
                  hintText: 'e.g., Chicken Salad',
                  prefixIcon: Icon(Icons.restaurant_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Meal type
              Text('Meal Type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.mealTypes.map((type) {
                  final selected = _mealType == type;
                  return ChoiceChip(
                    label: Text('${AppConstants.mealTypeEmojis[type]} ${AppConstants.mealTypeLabels[type]}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _mealType = type),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _portionController,
                decoration: const InputDecoration(
                  labelText: 'Portion (optional)',
                  hintText: 'e.g., 1 cup, 150g',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal) *',
                  prefixIcon: Icon(Icons.local_fire_department_rounded),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text('Macros (optional)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _macroField(_proteinController, 'Protein (g)')),
                  const SizedBox(width: 12),
                  Expanded(child: _macroField(_carbsController, 'Carbs (g)')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _macroField(_fatController, 'Fat (g)')),
                  const SizedBox(width: 12),
                  Expanded(child: _macroField(_fiberController, 'Fiber (g)')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _macroField(_sugarController, 'Sugar (g)')),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}
