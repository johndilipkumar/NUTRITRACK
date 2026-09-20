import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/dashboard_service.dart';

/// Analytics state.
class AnalyticsState {
  final bool isLoading;
  final Map<String, dynamic>? dailyData;
  final Map<String, dynamic>? weeklyData;
  final String? error;
  final int selectedDays;

  const AnalyticsState({
    this.isLoading = false,
    this.dailyData,
    this.weeklyData,
    this.error,
    this.selectedDays = 7,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? dailyData,
    Map<String, dynamic>? weeklyData,
    String? error,
    int? selectedDays,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      dailyData: dailyData ?? this.dailyData,
      weeklyData: weeklyData ?? this.weeklyData,
      error: error,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final DashboardService _service = DashboardService();

  AnalyticsNotifier() : super(const AnalyticsState());

  /// Fetch analytics data.
  Future<void> fetchAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _service.getDailyAnalytics(days: state.selectedDays),
        _service.getWeeklyAnalytics(),
      ]);
      state = state.copyWith(
        isLoading: false,
        dailyData: results[0],
        weeklyData: results[1],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load analytics.',
      );
    }
  }

  /// Change the day range and refetch.
  Future<void> setDays(int days) async {
    state = state.copyWith(selectedDays: days);
    await fetchAnalytics();
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});
