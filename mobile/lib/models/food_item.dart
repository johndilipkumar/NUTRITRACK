/// Individual food item within a meal (e.g., one dish, one drink).
class FoodItem {
  final String? id;
  final String name;
  final String category;
  final String? estimatedPortion;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;
  final int nutritionScore;
  final String classification;
  final double confidence;
  final List<String> positivePoints;
  final List<String> concerns;
  final String? healthierAlternative;

  FoodItem({
    this.id,
    required this.name,
    this.category = 'food',
    this.estimatedPortion,
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.sodiumMg = 0,
    this.nutritionScore = 50,
    this.classification = 'unknown',
    this.confidence = 0.5,
    this.positivePoints = const [],
    this.concerns = const [],
    this.healthierAlternative,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'food',
      estimatedPortion: json['estimatedPortion'] as String? ?? json['estimated_portion'] as String?,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? (json['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiberG'] as num?)?.toDouble() ?? (json['fiber_g'] as num?)?.toDouble() ?? 0,
      sugarG: (json['sugarG'] as num?)?.toDouble() ?? (json['sugar_g'] as num?)?.toDouble() ?? 0,
      sodiumMg: (json['sodiumMg'] as num?)?.toDouble() ?? (json['sodium_mg'] as num?)?.toDouble() ?? 0,
      nutritionScore: json['nutritionScore'] as int? ?? json['nutrition_score'] as int? ?? 50,
      classification: json['classification'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      positivePoints: _parseStringList(json['positivePoints'] ?? json['positive_points']),
      concerns: _parseStringList(json['concerns']),
      healthierAlternative: json['healthierAlternative'] as String? ?? json['healthier_alternative'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'estimatedPortion': estimatedPortion,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'fiberG': fiberG,
      'sugarG': sugarG,
      'sodiumMg': sodiumMg,
      'nutritionScore': nutritionScore,
      'classification': classification,
      'confidence': confidence,
      'positivePoints': positivePoints,
      'concerns': concerns,
      'healthierAlternative': healthierAlternative,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
