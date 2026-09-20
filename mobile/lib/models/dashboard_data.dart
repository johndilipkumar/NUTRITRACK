import 'food_entry.dart';

/// Dashboard data from the backend.
class DashboardData {
  final String userName;
  final int dailyCalorieGoal;
  final NutritionTotals today;
  final NutritionGoals goals;
  final List<FoodEntry> recentMeals;

  DashboardData({
    required this.userName,
    this.dailyCalorieGoal = 2000,
    required this.today,
    required this.goals,
    this.recentMeals = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final todayData = data['today'] as Map<String, dynamic>? ?? {};
    final goalsData = data['goals'] as Map<String, dynamic>? ?? {};

    return DashboardData(
      userName: user['name'] as String? ?? 'there',
      dailyCalorieGoal: user['dailyCalorieGoal'] as int? ?? 2000,
      today: NutritionTotals.fromJson(todayData),
      goals: NutritionGoals.fromJson(goalsData),
      recentMeals: (data['recentMeals'] as List<dynamic>?)
              ?.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class NutritionTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final int mealCount;
  final double avgScore;

  NutritionTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.mealCount = 0,
    this.avgScore = 0,
  });

  factory NutritionTotals.fromJson(Map<String, dynamic> json) {
    return NutritionTotals(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
      mealCount: json['mealCount'] as int? ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NutritionGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  NutritionGoals({
    this.calories = 2000,
    this.protein = 125,
    this.carbs = 250,
    this.fat = 56,
  });

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      calories: json['calories'] as int? ?? 2000,
      protein: json['protein'] as int? ?? 125,
      carbs: json['carbs'] as int? ?? 250,
      fat: json['fat'] as int? ?? 56,
    );
  }
}
