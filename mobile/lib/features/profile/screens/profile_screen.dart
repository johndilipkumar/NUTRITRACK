import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  String? _gender;
  String? _activityLevel;
  String? _dietaryPreference;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.getProfile();
      _nameController.text = user.name ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _heightController.text = user.heightCm?.toString() ?? '';
      _weightController.text = user.weightKg?.toString() ?? '';
      _calorieGoalController.text = user.dailyCalorieGoal.toString();
      _gender = user.gender;
      _activityLevel = user.activityLevel;
      _dietaryPreference = user.dietaryPreference;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        'age': _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
        'gender': _gender,
        'heightCm': _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
        'weightKg': _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        'activityLevel': _activityLevel,
        'dailyCalorieGoal': int.tryParse(_calorieGoalController.text) ?? 2000,
        'dietaryPreference': _dietaryPreference,
      };

      final user = await _userService.updateProfile(updates);
      ref.read(authProvider.notifier).updateUser(user);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated! ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information — glass card
              _GlassSection(
                isDark: isDark,
                title: 'Personal Information',
                subtitle: 'All fields are optional',
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(labelText: 'Gender'),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('Male')),
                            DropdownMenuItem(value: 'female', child: Text('Female')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nutrition Goals — glass card
              _GlassSection(
                isDark: isDark,
                title: 'Nutrition Goals',
                children: [
                  TextFormField(
                    controller: _calorieGoalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Daily Calorie Goal (kcal)',
                      prefixIcon: Icon(Icons.local_fire_department_outlined),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = int.tryParse(v);
                        if (val == null || val < 500 || val > 10000) {
                          return 'Enter a value between 500 and 10,000';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _activityLevel,
                    decoration: const InputDecoration(
                      labelText: 'Activity Level',
                      prefixIcon: Icon(Icons.directions_run_rounded),
                    ),
                    items: AppConstants.activityLevels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _activityLevel = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _dietaryPreference,
                    decoration: const InputDecoration(
                      labelText: 'Dietary Preference',
                      prefixIcon: Icon(Icons.restaurant_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('None')),
                      DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                      DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                      DropdownMenuItem(value: 'keto', child: Text('Keto')),
                      DropdownMenuItem(value: 'paleo', child: Text('Paleo')),
                      DropdownMenuItem(value: 'gluten_free', child: Text('Gluten-free')),
                    ],
                    onChanged: (v) => setState(() => _dietaryPreference = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final bool isDark;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _GlassSection({
    required this.isDark,
    required this.title,
    this.subtitle,
    required this.children,
  });

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
