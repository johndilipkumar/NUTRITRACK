import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_lib;
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../core/network/api_client.dart';

/// Authentication state.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final String? token;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    // Listen to Supabase auth state changes
    supabase_lib.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        ApiClient.instance.setToken(session.accessToken);
        // Create a dummy user object or fetch from Node backend /api/user/profile
        final sUser = session.user;
        final user = User(
          id: sUser.id,
          email: sUser.email ?? '',
          name: sUser.userMetadata?['full_name'] ?? sUser.email?.split('@')[0] ?? 'User',
          dailyCalorieGoal: 2000,
          createdAt: DateTime.now().toIso8601String(),
        );
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          token: session.accessToken,
        );
      } else {
        ApiClient.instance.clearToken();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Try to restore a saved session on app startup.
  Future<void> checkAuthStatus() async {
    // If already authenticated (e.g., from onAuthStateChange after OAuth redirect), don't reset
    if (state.status == AuthStatus.authenticated) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final hasSession = await _authService.restoreSession();
      if (hasSession) {
        // Session exists — build user from current Supabase session
        final session = supabase_lib.Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final sUser = session.user;
          final user = User(
            id: sUser.id,
            email: sUser.email ?? '',
            name: sUser.userMetadata?['full_name'] ?? sUser.email?.split('@')[0] ?? 'User',
            dailyCalorieGoal: 2000,
            createdAt: DateTime.now().toIso8601String(),
          );
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            token: session.accessToken,
          );
        }
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _authService.signInWithGoogle();
      // Auth state listener handles the success transition
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Google Sign In failed. Please try again.',
      );
    }
  }

  /// Register with Email/Password
  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _authService.register(email: email, password: password, name: name);
      
      if (response.session == null) {
        // Email confirmation is required
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Account created! Please check your email to verify it before signing in.',
        );
        return false;
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Registration failed. Check your details and try again.',
      );
      return false;
    }
  }

  /// Login with Email/Password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Invalid credentials or email not verified.',
      );
      return false;
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Update the user model in state
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Global auth state provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
