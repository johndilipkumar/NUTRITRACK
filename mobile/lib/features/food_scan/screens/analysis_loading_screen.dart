import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/scan_provider.dart';

/// Beautiful loading screen shown while Gemini analyzes the food image.
class AnalysisLoadingScreen extends ConsumerWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);

    // Navigate to result screen when analysis is complete
    ref.listen<ScanState>(scanProvider, (prev, next) {
      if (next.status == ScanStatus.success) {
        context.go('/scan/result');
      } else if (next.status == ScanStatus.error) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Analysis failed'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    final messageIndex = scanState.loadingMessageIndex
        .clamp(0, AppConstants.scanLoadingMessages.length - 1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Food image (small preview)
              if (scanState.imageFile != null)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: kIsWeb
                      ? Image.network(scanState.imageFile!.path, fit: BoxFit.cover)
                      : Image.file(File(scanState.imageFile!.path), fit: BoxFit.cover),
                ),
              const SizedBox(height: 40),

              // Pulsing loader
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 32),

              // Animated loading message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  AppConstants.scanLoadingMessages[messageIndex],
                  key: ValueKey(messageIndex),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This may take a few seconds',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
