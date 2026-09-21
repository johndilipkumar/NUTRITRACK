import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

/// Configured Dio HTTP client for the NutriTrack API.
/// Handles JWT token injection, error mapping, and logging.
class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;
  String? _token;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),  // Render free tier cold start can take 50s
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 90),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // JWT interceptor — automatically attaches token to requests
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Map Dio errors to readable messages
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                message: 'Connection timed out. Please check your internet connection.',
                type: error.type,
              ),
            );
          }
          if (error.type == DioExceptionType.connectionError) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                message: 'Cannot connect to the server. Please check your internet connection.',
                type: error.type,
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );

    // Logging interceptor for debug builds only
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Sets the JWT token for authenticated requests.
  void setToken(String? token) {
    _token = token;
  }

  /// Clears the JWT token (on logout).
  void clearToken() {
    _token = null;
  }

  /// Returns the current token (for checking auth state).
  String? get token => _token;
}
