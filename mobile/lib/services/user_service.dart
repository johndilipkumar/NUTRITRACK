import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

/// User profile service.
class UserService {
  final Dio _dio = ApiClient.instance.dio;

  /// Get the current user's profile.
  Future<User> getProfile() async {
    final response = await _dio.get(ApiConstants.userProfile);
    return User.fromJson(response.data['data']);
  }

  /// Update the user's profile.
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final response = await _dio.put(
      ApiConstants.userProfile,
      data: updates,
    );
    return User.fromJson(response.data['data']);
  }

  /// Delete the user's account and all associated data.
  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.deleteAccount);
  }
}
