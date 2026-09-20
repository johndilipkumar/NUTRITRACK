import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Animated circular nutrition score indicator with color coding.
class NutritionScoreBadge extends StatefulWidget {
  final int score;
  final double size;
  final bool animate;
  final String? label;

  const NutritionScoreBadge({
    super.key,
    required this.score,
    this.size = 100,
    this.animate = true,
    this.label,
  });

  @override
  State<NutritionScoreBadge> createState() => _NutritionScoreBadgeState();
}

class _NutritionScoreBadgeState extends State<NutritionScoreBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NutritionScoreBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(widget.score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              progress: _animation.value,
              color: color,
              backgroundColor: Theme.of(context).dividerTheme.color ?? Colors.grey.shade200,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${((_animation.value * 100).round())}',
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: widget.size * 0.1,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontFamily: 'Inter',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = backgroundColor;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) {
    return old.progress != progress || old.color != color;
  }
}
