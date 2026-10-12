import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class MockUpgradeResult {
  final bool success;
  final String message;
  final bool simulated;
  final Map<String, dynamic>? data;

  MockUpgradeResult({
    required this.success,
    required this.message,
    required this.simulated,
    this.data,
  });
}

/// Isolated Mock Subscription Service for development/demo mode.
/// Simulates upgrade and failure flows without real payment credentials or gateways.
/// Can be replaced with a real PaymentGatewayService in production.
class MockSubscriptionService {
  final Dio _dio = ApiClient.instance.dio;

  Future<MockUpgradeResult> simulateUpgrade({
    required String planId,
    bool simulateFailure = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.mockUpgrade,
        data: {
          'planId': planId,
          'simulateFailure': simulateFailure,
        },
      );
      return MockUpgradeResult(
        success: response.data['success'] == true,
        message: response.data['message'] ?? 'Mock upgrade completed.',
        simulated: true,
        data: response.data['data'],
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Mock upgrade failed.';
      return MockUpgradeResult(
        success: false,
        message: msg,
        simulated: true,
      );
    } catch (e) {
      return MockUpgradeResult(
        success: false,
        message: e.toString(),
        simulated: true,
      );
    }
  }
}
