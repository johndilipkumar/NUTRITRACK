import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/food_entry.dart';
import '../../../services/food_service.dart';

/// Food history state.
class HistoryState {
  final bool isLoading;
  final List<FoodEntry> entries;
  final int currentPage;
  final int totalPages;
  final String? error;
  final bool hasMore;

  const HistoryState({
    this.isLoading = false,
    this.entries = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.error,
    this.hasMore = true,
  });

  HistoryState copyWith({
    bool? isLoading,
    List<FoodEntry>? entries,
    int? currentPage,
    int? totalPages,
    String? error,
    bool? hasMore,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final FoodService _foodService = FoodService();

  HistoryNotifier() : super(const HistoryState());

  /// Load the first page of food history.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _foodService.getHistory(page: 1);
      state = HistoryState(
        isLoading: false,
        entries: result.entries,
        currentPage: 1,
        totalPages: result.totalPages,
        hasMore: 1 < result.totalPages,
      );
    } catch (e) {
      print('HISTORY ERROR: $e');
      String errorMsg = 'Failed to load history. Pull down to refresh.';
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        errorMsg = 'Server is waking up. Please wait and pull down to refresh.';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Load the next page (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true);

    try {
      final result = await _foodService.getHistory(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        entries: [...state.entries, ...result.entries],
        currentPage: nextPage,
        hasMore: nextPage < result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Delete a food entry.
  Future<void> deleteEntry(String id) async {
    try {
      await _foodService.deleteFood(id);
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != id).toList(),
      );
    } catch (e) {
      // Silently fail — could show a snackbar
    }
  }

  /// Refresh from page 1.
  Future<void> refresh() => loadHistory();
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
