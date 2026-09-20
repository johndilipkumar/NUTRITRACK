import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_data.dart';

/// Dashboard service — fetches dashboard and analytics data.
class DashboardService {
  final Dio _dio = ApiClient.instance.dio;

  /// Get the home dashboard data (today's nutrition, goals, recent meals).
  Future<DashboardData> getDashboard() async {
    final response = await _dio.get(ApiConstants.dashboard);
    return DashboardData.fromJson(response.data);
  }

  /// Get daily analytics for the last N days.
  Future<Map<String, dynamic>> getDailyAnalytics({int days = 7}) async {
    final response = await _dio.get(
      ApiConstants.dailyAnalytics,
      queryParameters: {'days': days},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get weekly analytics.
  Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    final response = await _dio.get(ApiConstants.weeklyAnalytics);
    return response.data['data'] as Map<String, dynamic>;
  }
}
