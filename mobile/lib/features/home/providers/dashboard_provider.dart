import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/dashboard_data.dart';
import '../../../services/dashboard_service.dart';

/// Dashboard state.
class DashboardState {
  final bool isLoading;
  final DashboardData? data;
  final String? error;

  const DashboardState({this.isLoading = false, this.data, this.error});

  DashboardState copyWith({bool? isLoading, DashboardData? data, String? error}) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _service = DashboardService();

  DashboardNotifier() : super(const DashboardState());

  /// Fetch dashboard data from the backend.
  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getDashboard();
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard. Pull down to refresh.',
      );
    }
  }

  /// Force refresh the dashboard.
  Future<void> refresh() => fetchDashboard();
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
