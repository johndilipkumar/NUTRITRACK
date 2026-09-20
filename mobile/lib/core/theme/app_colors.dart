import 'package:flutter/material.dart';

/// Application color palette.
/// Uses a health-oriented green primary with warm, modern accents.
class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFF2ECC71);       // Vibrant green
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFF82E0AA);
  static const Color primarySurface = Color(0xFFE8F8F0);

  // ─── Accent Colors ────────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6B6B);         // Warm coral
  static const Color accentOrange = Color(0xFFFFA502);    // Warm orange
  static const Color accentPurple = Color(0xFF9B59B6);    // Soft purple
  static const Color accentBlue = Color(0xFF3498DB);      // Calm blue

  // ─── Macro Colors ─────────────────────────────────────────────────────
  static const Color protein = Color(0xFF3498DB);    // Blue
  static const Color carbs = Color(0xFFF39C12);      // Orange
  static const Color fat = Color(0xFFE74C3C);        // Red
  static const Color fiber = Color(0xFF2ECC71);      // Green
  static const Color sugar = Color(0xFF9B59B6);      // Purple
  static const Color sodium = Color(0xFF95A5A6);     // Grey

  // ─── Nutrition Score Colors ───────────────────────────────────────────
  static Color scoreColor(int score) {
    if (score >= 90) return const Color(0xFF2ECC71);   // Green — Excellent
    if (score >= 75) return const Color(0xFF27AE60);   // Darker green — Good
    if (score >= 60) return const Color(0xFFF39C12);   // Orange — Moderate
    if (score >= 40) return const Color(0xFFE67E22);   // Dark orange — Needs improvement
    return const Color(0xFFE74C3C);                     // Red — Low quality
  }

  // ─── Light Theme Colors ───────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D3436);
  static const Color lightTextSecondary = Color(0xFF636E72);
  static const Color lightDivider = Color(0xFFDFE6E9);

  // ─── Dark Theme Colors ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2128);
  static const Color darkText = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkDivider = Color(0xFF30363D);

  // ─── Semantic Colors ──────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);
}
