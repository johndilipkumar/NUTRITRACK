import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/scan_provider.dart';

/// Image preview screen — shows the captured/selected image with retake and analyze options.
class ImagePreviewScreen extends ConsumerWidget {
  const ImagePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);

    if (scanState.imageFile == null) {
      return const Scaffold(
        body: Center(child: Text('No image selected')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Image preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: kIsWeb
                    ? Image.network(
                        scanState.imageFile!.path,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Image.file(
                        File(scanState.imageFile!.path),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
              ),
            ),

            // Action text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Use this photo?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Make sure the entire meal is clearly visible',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  // Retake
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        label: const Text('Retake', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Analyze
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          context.push('/scan/analyzing');
                          await ref.read(scanProvider.notifier).analyzeFood();
                        },
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Analyze Food'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
