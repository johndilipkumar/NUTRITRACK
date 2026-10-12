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
        final error = next.error ?? 'Analysis failed';
        if (error.toLowerCase().contains('generation limit')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                  SizedBox(width: 8),
                  Text('Limit Reached', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You've reached your generation limit for this plan.",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Upgrade your plan to access a higher generation allowance.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/pricing');
                  },
                  child: const Text('Upgrade Plan'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
