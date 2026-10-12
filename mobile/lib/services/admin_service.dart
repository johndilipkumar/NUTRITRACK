import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class AdminService {
  final Dio _dio = ApiClient.instance.dio;

  // -- Plans --
  Future<List<dynamic>> getPlans() async {
    final response = await _dio.get(ApiConstants.adminPlans);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> planData) async {
    final response = await _dio.post(ApiConstants.adminPlans, data: planData);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updatePlan(String id, Map<String, dynamic> planData) async {
    final response = await _dio.put('${ApiConstants.adminPlans}/$id', data: planData);
    return response.data['data'];
  }

  // -- Users --
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 20, String search = ''}) async {
    final response = await _dio.get(
      ApiConstants.adminUsers,
      queryParameters: {'page': page, 'limit': limit, 'search': search},
    );
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getUserDetails(String id) async {
    final response = await _dio.get('${ApiConstants.adminUsers}/$id');
    return response.data['data'];
  }

  // -- Actions --
  Future<void> adjustCredits({
    required String userId,
    required int amount,
    required String type, // 'grant' or 'revoke'
    required String reason,
  }) async {
    await _dio.post(
      ApiConstants.adminCredits,
      data: {
        'userId': userId,
        'amount': amount,
        'type': type,
        'reason': reason,
      },
    );
  }

  Future<void> assignPlan({
    required String userId,
    required String planId,
    required String reason,
  }) async {
    await _dio.post(
      ApiConstants.adminAssignPlan,
      data: {
        'userId': userId,
        'planId': planId,
        'reason': reason,
      },
    );
  }

  Future<void> toggleAiAccess({
    required String userId,
    required bool enabled,
    required String reason,
  }) async {
    await _dio.post(
      ApiConstants.adminToggleAiAccess,
      data: {
        'userId': userId,
        'enabled': enabled,
        'reason': reason,
      },
    );
  }

  Future<void> toggleUnlimitedGenerations({
    required String userId,
    required bool enabled,
    String? reason,
  }) async {
    await _dio.post(
      ApiConstants.adminToggleUnlimited,
      data: {
        'userId': userId,
        'enabled': enabled,
        'reason': reason ?? 'Admin toggle',
      },
    );
  }

  // -- Analytics --
  Future<Map<String, dynamic>> getOverview({int days = 30}) async {
    final response = await _dio.get(
      ApiConstants.adminAnalyticsOverview,
      queryParameters: {'days': days},
    );
    return response.data['data'];
  }

  // -- Config --
  Future<List<dynamic>> getConfig() async {
    final response = await _dio.get(ApiConstants.adminConfig);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateConfig(String key, String value, [String? description]) async {
    final response = await _dio.put(
      ApiConstants.adminConfig,
      data: {
        'key': key,
        'value': value,
        'description': description,
      },
    );
    return response.data['data'];
  }
}
