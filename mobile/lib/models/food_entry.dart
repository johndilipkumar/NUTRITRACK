import 'food_item.dart';

/// A saved food entry (a complete meal/scan).
class FoodEntry {
  final String id;
  final String? imageUrl;
  final String mealName;
  final String mealType;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double totalSodium;
  final int nutritionScore;
  final String classification;
  final double confidence;
  final String? disclaimer;
  final bool isManualEntry;
  final List<FoodItem> items;
  final DateTime createdAt;

  FoodEntry({
    required this.id,
    this.imageUrl,
    required this.mealName,
    this.mealType = 'snack',
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalFiber = 0,
    this.totalSugar = 0,
    this.totalSodium = 0,
    this.nutritionScore = 50,
    this.classification = 'unknown',
    this.confidence = 0.5,
    this.disclaimer,
    this.isManualEntry = false,
    this.items = const [],
    required this.createdAt,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      mealName: json['mealName'] as String? ?? json['meal_name'] as String? ?? 'Unknown Meal',
      mealType: json['mealType'] as String? ?? json['meal_type'] as String? ?? 'snack',
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? (json['total_calories'] as num?)?.toDouble() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? (json['total_protein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? (json['total_carbs'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? (json['total_fat'] as num?)?.toDouble() ?? 0,
      totalFiber: (json['totalFiber'] as num?)?.toDouble() ?? (json['total_fiber'] as num?)?.toDouble() ?? 0,
      totalSugar: (json['totalSugar'] as num?)?.toDouble() ?? (json['total_sugar'] as num?)?.toDouble() ?? 0,
      totalSodium: (json['totalSodium'] as num?)?.toDouble() ?? (json['total_sodium'] as num?)?.toDouble() ?? 0,
      nutritionScore: json['nutritionScore'] as int? ?? json['nutrition_score'] as int? ?? 50,
      classification: json['classification'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      disclaimer: json['disclaimer'] as String?,
      isManualEntry: json['isManualEntry'] as bool? ?? json['is_manual_entry'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
