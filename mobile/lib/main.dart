import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/settings/providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: NutriTrackApp(),
    ),
  );
}

class NutriTrackApp extends ConsumerStatefulWidget {
  const NutriTrackApp({super.key});

  @override
  ConsumerState<NutriTrackApp> createState() => _NutriTrackAppState();
}

class _NutriTrackAppState extends ConsumerState<NutriTrackApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NutriTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
