import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../models/food_analysis_result.dart';
import '../../../services/food_service.dart';

/// Scan flow states.
enum ScanStatus { idle, analyzing, success, error, saving, saved }

class ScanState {
  final ScanStatus status;
  final XFile? imageFile;
  final FoodAnalysisResult? result;
  final String? error;
  final int loadingMessageIndex;

  const ScanState({
    this.status = ScanStatus.idle,
    this.imageFile,
    this.result,
    this.error,
    this.loadingMessageIndex = 0,
  });

  ScanState copyWith({
    ScanStatus? status,
    XFile? imageFile,
    FoodAnalysisResult? result,
    String? error,
    int? loadingMessageIndex,
  }) {
    return ScanState(
      status: status ?? this.status,
      imageFile: imageFile ?? this.imageFile,
      result: result ?? this.result,
      error: error,
      loadingMessageIndex: loadingMessageIndex ?? this.loadingMessageIndex,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final FoodService _foodService = FoodService();

  ScanNotifier() : super(const ScanState());

  /// Set the captured/selected image.
  void setImage(XFile file) {
    state = ScanState(status: ScanStatus.idle, imageFile: file);
  }

  /// Analyze the food image using the backend + Gemini.
  Future<void> analyzeFood() async {
    if (state.imageFile == null) return;

    state = state.copyWith(
      status: ScanStatus.analyzing,
      error: null,
      loadingMessageIndex: 0,
    );

    // Cycle through loading messages
    _cycleLoadingMessages();

    try {
      final result = await _foodService.analyzeFood(state.imageFile!);

      if (!result.foodDetected) {
        state = state.copyWith(
          status: ScanStatus.error,
          error: 'No food or drink was detected in this image. Try taking a clearer photo with the entire meal visible.',
        );
        return;
      }

      state = state.copyWith(status: ScanStatus.success, result: result);
    } catch (e) {
      print('ANALYZE ERROR: $e');
      String errorMsg = 'Failed: $e';
      
      if (e is DioException) {
        if (e.response != null && e.response?.data is Map) {
          errorMsg = e.response?.data['message'] ?? errorMsg;
        }
      }
      
      if (e.toString().contains('timeout') ||
          e.toString().contains('Timeout')) {
        errorMsg = 'Analysis timed out. Please try again with a clearer image.';
      } else if (e.toString().contains('connect') ||
          e.toString().contains('Connect')) {
        errorMsg = 'Cannot connect to the server. Please check your internet connection.';
      }
      state = state.copyWith(status: ScanStatus.error, error: errorMsg);
    }
  }

  /// Save the analyzed food entry.
  Future<bool> saveFood(String mealType) async {
    if (state.result == null) return false;

    state = state.copyWith(status: ScanStatus.saving);
    try {
      await _foodService.saveFood(state.result!, mealType);
      state = state.copyWith(status: ScanStatus.saved);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.success, // Keep result visible
        error: 'Failed to save meal. Please try again.',
      );
      return false;
    }
  }

  /// Reset the scan flow.
  void reset() {
    state = const ScanState();
  }

  /// Cycle through loading messages for visual feedback.
  void _cycleLoadingMessages() {
    Future.delayed(const Duration(seconds: 2), () {
      if (state.status == ScanStatus.analyzing && mounted) {
        state = state.copyWith(loadingMessageIndex: 1);
      }
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (state.status == ScanStatus.analyzing && mounted) {
        state = state.copyWith(loadingMessageIndex: 2);
      }
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (state.status == ScanStatus.analyzing && mounted) {
        state = state.copyWith(loadingMessageIndex: 3);
      }
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (state.status == ScanStatus.analyzing && mounted) {
        state = state.copyWith(loadingMessageIndex: 4);
      }
    });
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});
