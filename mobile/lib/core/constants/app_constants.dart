/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'NutriTrack';
  static const String appTagline = 'AI-Powered Nutrition Tracking';

  // Default daily goals
  static const int defaultCalorieGoal = 2000;
  static const int defaultProteinGoal = 125; // grams
  static const int defaultCarbsGoal = 250;   // grams
  static const int defaultFatGoal = 56;      // grams

  // Meal types
  static const List<String> mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  static const Map<String, String> mealTypeLabels = {
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snack': 'Snack',
  };

  static const Map<String, String> mealTypeEmojis = {
    'breakfast': '🌅',
    'lunch': '☀️',
    'dinner': '🌙',
    'snack': '🍿',
  };

  // Nutrition score ranges
  static String scoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Moderate';
    if (score >= 40) return 'Needs improvement';
    return 'Low nutritional quality';
  }

  static String scoreEmoji(int score) {
    if (score >= 90) return '🌟';
    if (score >= 75) return '✅';
    if (score >= 60) return '👌';
    if (score >= 40) return '⚠️';
    return '🔴';
  }

  // Activity levels
  static const Map<String, String> activityLevels = {
    'sedentary': 'Sedentary (little or no exercise)',
    'light': 'Light (1-3 days/week)',
    'moderate': 'Moderate (3-5 days/week)',
    'active': 'Active (6-7 days/week)',
    'very_active': 'Very Active (intense daily exercise)',
  };

  // Loading messages for scan
  static const List<String> scanLoadingMessages = [
    'Looking at your food...',
    'Identifying ingredients...',
    'Estimating portion size...',
    'Calculating nutrition...',
    'Preparing your nutrition report...',
  ];
}
