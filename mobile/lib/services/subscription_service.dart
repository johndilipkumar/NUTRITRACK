import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class SubscriptionService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<dynamic>> getPlans() async {
    final response = await _dio.get(ApiConstants.plans);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _dio.get(ApiConstants.subscriptionStatus);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getSubscriptionHistory() async {
    final response = await _dio.get(ApiConstants.subscriptionHistory);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getUsageHistory({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiConstants.usageHistory,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data['data'];
  }

  Future<void> cancelSubscription() async {
    await _dio.post(ApiConstants.cancelSubscription);
  }

  Future<Map<String, dynamic>> createCheckout(String planId) async {
    final response = await _dio.post(
      ApiConstants.checkout,
      data: {'planId': planId},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final response = await _dio.post(
      ApiConstants.verifyPayment,
      data: {
        'paymentId': paymentId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
    return response.data['data'];
  }
}
