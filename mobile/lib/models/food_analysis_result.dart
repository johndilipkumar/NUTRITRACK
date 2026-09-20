import 'food_item.dart';

/// The result from Gemini AI food analysis.
class FoodAnalysisResult {
  final String imageUrl;
  final String mealName;
  final List<FoodItem> items;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double totalSodium;
  final int overallScore;
  final String overallClassification;
  final String disclaimer;
  final bool foodDetected;

  FoodAnalysisResult({
    required this.imageUrl,
    required this.mealName,
    required this.items,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalFiber = 0,
    this.totalSugar = 0,
    this.totalSodium = 0,
    this.overallScore = 50,
    this.overallClassification = 'unknown',
    this.disclaimer = '',
    this.foodDetected = true,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final analysis = data['analysis'] as Map<String, dynamic>? ?? {};
    final total = analysis['total'] as Map<String, dynamic>? ?? {};

    return FoodAnalysisResult(
      imageUrl: data['imageUrl'] as String? ?? '',
      mealName: analysis['meal_name'] as String? ?? 'Unknown Meal',
      items: (analysis['items'] as List<dynamic>?)
              ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCalories: (total['calories'] as num?)?.toDouble() ?? 0,
      totalProtein: (total['protein_g'] as num?)?.toDouble() ?? 0,
      totalCarbs: (total['carbs_g'] as num?)?.toDouble() ?? 0,
      totalFat: (total['fat_g'] as num?)?.toDouble() ?? 0,
      totalFiber: (total['fiber_g'] as num?)?.toDouble() ?? 0,
      totalSugar: (total['sugar_g'] as num?)?.toDouble() ?? 0,
      totalSodium: (total['sodium_mg'] as num?)?.toDouble() ?? 0,
      overallScore: analysis['overall_score'] as int? ?? 50,
      overallClassification: analysis['overall_classification'] as String? ?? 'unknown',
      disclaimer: analysis['disclaimer'] as String? ?? '',
      foodDetected: data['foodDetected'] as bool? ?? true,
    );
  }

  /// Convert to the format expected by the save food endpoint.
  Map<String, dynamic> toSaveJson(String mealType) {
    return {
      'imageUrl': imageUrl,
      'mealName': mealName,
      'mealType': mealType,
      'items': items.map((item) => item.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalFiber': totalFiber,
      'totalSugar': totalSugar,
      'totalSodium': totalSodium,
      'nutritionScore': overallScore,
      'classification': overallClassification,
      'confidence': items.isNotEmpty
          ? items.map((e) => e.confidence).reduce((a, b) => a + b) / items.length
          : 0.5,
      'disclaimer': disclaimer,
    };
  }
}
