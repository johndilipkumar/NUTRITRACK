import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;
import '../core/network/api_client.dart';
import 'package:flutter/foundation.dart';

/// Authentication service — handles Supabase Auth.
class AuthService {
  final supabase_lib.SupabaseClient _supabase = supabase_lib.Supabase.instance.client;

  /// Sign in with Google (Gmail)
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      supabase_lib.OAuthProvider.google,
      redirectTo: kIsWeb
          ? Uri.base.origin
          : 'io.supabase.nutritrack://login-callback/',
    );
  }

  /// Register with Email/Password
  Future<supabase_lib.AuthResponse> register({
    required String email,
    required String password,
    String? name,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'full_name': name} : null,
    );
  }

  /// Login with Email/Password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Check if user has a saved auth token and restore the session.
  Future<bool> restoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      // Set the token for our Node.js backend to verify
      ApiClient.instance.setToken(session.accessToken);
      return true;
    }
    return false;
  }

  /// Logout — clear Supabase session.
  Future<void> logout() async {
    await _supabase.auth.signOut();
    ApiClient.instance.clearToken();
  }
}

