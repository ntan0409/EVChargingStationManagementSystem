import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (EV Electric Green / Teal Modern Vibe)
  static const Color primary = Color(0xFF00C853); // Vivid Green
  static const Color primaryDark = Color(0xFF009624);
  static const Color primaryLight = Color(0xFF5EFC82);
  static const Color primaryContainer = Color(0xFFE8F5E9);

  // Secondary Palette (Deep Navy / Electric Blue)
  static const Color secondary = Color(0xFF0288D1);
  static const Color secondaryDark = Color(0xFF01579B);
  static const Color secondaryLight = Color(0xFF81D4FA);

  // Accent Colors
  static const Color accent = Color(0xFFFF9100); // Orange
  static const Color accentGold = Color(0xFFFFD600);

  // Status Colors
  static const Color statusAvailable = Color(0xFF00C853); // Green
  static const Color statusOccupied = Color(0xFF0288D1); // Blue / Charging
  static const Color statusReserved = Color(0xFFFF9100); // Orange / Reserved
  static const Color statusFaulted = Color(0xFFD50000); // Red
  static const Color statusOffline = Color(0xFF9E9E9E); // Grey

  // Neutrals (Light Mode)
  static const Color backgroundLight = Color(0xFFF7F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1D20);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color dividerLight = Color(0xFFEEEEEE);

  // Neutrals (Dark Mode)
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Functional
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
