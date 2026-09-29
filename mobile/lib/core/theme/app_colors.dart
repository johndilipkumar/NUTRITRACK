import 'package:flutter/material.dart';

/// Application color palette.
/// Clean black & white minimal design with selective color accents.
class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFF111111);        // Near-black
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF444444);
  static const Color primarySurface = Color(0xFFF2F2F2);

  // ─── Accent Colors ────────────────────────────────────────────────────
  static const Color accent = Color(0xFF111111);
  static const Color accentOrange = Color(0xFFFF6B35);    // Warm orange for calories
  static const Color accentPurple = Color(0xFF7C3AED);    // Vivid purple
  static const Color accentBlue = Color(0xFF2563EB);      // Clean blue

  // ─── Macro Colors ─────────────────────────────────────────────────────
  static const Color protein = Color(0xFF2563EB);    // Blue
  static const Color carbs = Color(0xFFEA580C);      // Orange
  static const Color fat = Color(0xFFDC2626);        // Red
  static const Color fiber = Color(0xFF16A34A);      // Green
  static const Color sugar = Color(0xFF7C3AED);      // Purple
  static const Color sodium = Color(0xFF6B7280);     // Grey

  // ─── Nutrition Score Colors ───────────────────────────────────────────
  static Color scoreColor(int score) {
    if (score >= 90) return const Color(0xFF16A34A);   // Green — Excellent
    if (score >= 75) return const Color(0xFF22C55E);   // Lighter green — Good
    if (score >= 60) return const Color(0xFFEAB308);   // Yellow — Moderate
    if (score >= 40) return const Color(0xFFEA580C);   // Orange — Needs improvement
    return const Color(0xFFDC2626);                     // Red — Low quality
  }

  // ─── Light Theme Colors ───────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8F8F8);
  static const Color lightText = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);

  // ─── Dark Theme Colors ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkDivider = Color(0xFF262626);

  // ─── Semantic Colors ──────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
