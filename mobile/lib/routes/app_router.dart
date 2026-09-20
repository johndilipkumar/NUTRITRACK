import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/food_scan/screens/camera_screen.dart';
import '../features/food_scan/screens/image_preview_screen.dart';
import '../features/food_scan/screens/analysis_loading_screen.dart';
import '../features/food_scan/screens/food_result_screen.dart';
import '../features/food_scan/screens/manual_entry_screen.dart';
import '../features/food_details/screens/food_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../core/theme/app_colors.dart';

/// GoRouter configuration with auth guard and bottom navigation shell.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
          GoRoute(
            path: '/analytics',
            builder: (_, _) => const AnalyticsScreen(),
          ),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(path: '/scan', builder: (_, _) => const CameraScreen()),
      GoRoute(
        path: '/scan/preview',
        builder: (_, _) => const ImagePreviewScreen(),
      ),
      GoRoute(
        path: '/scan/analyzing',
        builder: (_, _) => const AnalysisLoadingScreen(),
      ),
      GoRoute(
        path: '/scan/result',
        builder: (_, _) => const FoodResultScreen(),
      ),
      GoRoute(
        path: '/manual-entry',
        builder: (_, _) => const ManualEntryScreen(),
      ),
      GoRoute(
        path: '/food/:id',
        builder: (_, state) =>
            FoodDetailScreen(foodId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
  );

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      router.refresh();
    }
  });

  return router;
});

/// Main app shell with centered constraints and a premium floating dock.
class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Wrap the entire app shell in a Center + ConstrainedBox
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              // Main content goes here
              Positioned.fill(child: child),

              // Floating Dock
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface)
                                  .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.fromBorderSide(
                            BorderSide(
                              color:
                                  (isDark
                                          ? AppColors.darkDivider
                                          : AppColors.lightDivider)
                                      .withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _NavItem(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              selected: selectedIndex == 0,
                              onTap: () => context.go('/home'),
                            ),
                            _NavItem(
                              icon: Icons.history_rounded,
                              label: 'History',
                              selected: selectedIndex == 1,
                              onTap: () => context.go('/history'),
                            ),
                            const SizedBox(width: 4),
                            // Floating Action Button integrated into the dock
                            _ScanButton(),
                            const SizedBox(width: 4),
                            _NavItem(
                              icon: Icons.bar_chart_rounded,
                              label: 'Analytics',
                              selected: selectedIndex == 2,
                              onTap: () => context.go('/analytics'),
                            ),
                            _NavItem(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              selected: selectedIndex == 3,
                              onTap: () => context.go('/settings'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatefulWidget {
  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: () => context.push('/scan'),
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _isHovered ? null : _controller.reverse(),
        onTapCancel: () => _isHovered ? null : _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? AppColors.primary
        : Theme.of(context).textTheme.bodySmall?.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _isHovered ? null : _controller.reverse(),
        onTapCancel: () => _isHovered ? null : _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: color, size: 22),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                    child: Text(widget.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
