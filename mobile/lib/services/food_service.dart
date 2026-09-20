import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/food_analysis_result.dart';
import '../models/food_entry.dart';

/// Food service — handles image analysis, saving meals, history, and manual entries.
class FoodService {
  final Dio _dio = ApiClient.instance.dio;

  /// Upload an image and get AI nutritional analysis.
  Future<FoodAnalysisResult> analyzeFood(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: imageFile.name),
    });

    final response = await _dio.post(
      ApiConstants.analyzeFood,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    return FoodAnalysisResult.fromJson(response.data);
  }

  /// Save an analyzed food entry to the database.
  Future<FoodEntry> saveFood(
    FoodAnalysisResult analysis,
    String mealType,
  ) async {
    final response = await _dio.post(
      ApiConstants.saveFood,
      data: analysis.toSaveJson(mealType),
    );

    return FoodEntry.fromJson(response.data['data']);
  }

  /// Save a manually entered food item.
  Future<FoodEntry> saveManualFood({
    required String foodName,
    required String mealType,
    String? portion,
    required double calories,
    double proteinG = 0,
    double carbsG = 0,
    double fatG = 0,
    double fiberG = 0,
    double sugarG = 0,
  }) async {
    final response = await _dio.post(
      ApiConstants.manualFood,
      data: {
        'foodName': foodName,
        'mealType': mealType,
        'portion': portion,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
        'sugarG': sugarG,
      },
    );

    return FoodEntry.fromJson(response.data['data']);
  }

  /// Get paginated food history.
  Future<({List<FoodEntry> entries, int total, int totalPages})> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.foodHistory,
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data['data'];
    final entries = (data['entries'] as List)
        .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'];

    return (
      entries: entries,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }

  /// Get a single food entry by ID.
  Future<FoodEntry> getFoodById(String id) async {
    final response = await _dio.get(ApiConstants.foodById(id));
    return FoodEntry.fromJson(response.data['data']);
  }

  /// Delete a food entry.
  Future<void> deleteFood(String id) async {
    await _dio.delete(ApiConstants.deleteFood(id));
  }
}
