import 'package:flutter/foundation.dart';

/// API endpoint constants.
/// The base URL points to the backend server.
/// On Android emulator, 10.0.2.2 maps to the host machine's localhost.
class ApiConstants {
  ApiConstants._();

  // Base URL — change for production deployment
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Updated to your computer's local Wi-Fi IP so a physical phone can connect
      return 'http://192.168.10.3:3000';
    }
    return 'http://localhost:3000';
  }

  // Supabase Constants
  static const String supabaseUrl = 'https://mbbvpssjvxzjijeejqrn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1iYnZwc3Nqdnh6amlqZWVqcXJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk4ODc2OTEsImV4cCI6MjEwNTQ2MzY5MX0.io-09UckxY2GOeeHUIYCj1UvHNQ2yVNtHZcjpE-6pqU';

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String resetPasswordRequest = '/api/auth/reset-password-request';
  static const String resetPassword = '/api/auth/reset-password';

  // Food endpoints
  static const String analyzeFood = '/api/food/analyze';
  static const String saveFood = '/api/food/save';
  static const String manualFood = '/api/food/manual';
  static const String foodHistory = '/api/food/history';
  static String foodById(String id) => '/api/food/$id';
  static String deleteFood(String id) => '/api/food/$id';

  // Dashboard endpoints
  static const String dashboard = '/api/dashboard';
  static const String dailyAnalytics = '/api/dashboard/analytics/daily';
  static const String weeklyAnalytics = '/api/dashboard/analytics/weekly';

  // User endpoints
  static const String userProfile = '/api/user/profile';
  static const String deleteAccount = '/api/user/account';
}
