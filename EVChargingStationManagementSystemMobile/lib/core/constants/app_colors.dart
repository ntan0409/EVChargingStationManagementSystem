import 'package:flutter/material.dart';

class AppColors {
  // Brand EVOne Primary Palette (Emerald & Deep Forest)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF059669); // Emerald 600
  static const Color primaryDarker = Color(0xFF064E3B); // Deep Forest
  static const Color primaryLight = Color(0xFF34D399); // Emerald 400
  static const Color primaryContainer = Color(0xFFECFDF5); // Soft Emerald light

  // Secondary Palette (High-Tech Sky Blue & Indigo)
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue 500
  static const Color secondaryDark = Color(0xFF0284C7); // Sky Blue 600
  static const Color secondaryLight = Color(0xFFE0F2FE); // Soft Sky light
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Accent & Warm Colors
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color accentGold = Color(0xFFEAB308); // Gold 500

  // Status Colors (Aligned with Web Status Badges)
  static const Color statusAvailable = Color(0xFF10B981); // Emerald
  static const Color statusOccupied = Color(0xFF0EA5E9); // Sky Blue
  static const Color statusReserved = Color(0xFFF59E0B); // Amber
  static const Color statusFaulted = Color(0xFFEF4444); // Red 500
  static const Color statusOffline = Color(0xFF94A3B8); // Slate 400

  // Neutrals (Light Mode - Slate & White)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color dividerLight = Color(0xFFF1F5F9); // Slate 100

  // Neutrals (Dark Mode - Obsidian & Deep Slate)
  static const Color backgroundDark = Color(0xFF090D16); // Obsidian 950
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color dividerDark = Color(0xFF1E293B);

  // Functional Alerts
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);
}
