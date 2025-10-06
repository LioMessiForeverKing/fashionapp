import 'package:flutter/material.dart';

class AppConstants {
  // Supabase Configuration
  static const String kSupabaseUrl = 'https://bzeejrtlulnzncnllsyj.supabase.co';
  static const String kSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ6ZWVqcnRsdWxuem5jbmxsc3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3NzQzNzcsImV4cCI6MjA3NTM1MDM3N30.YbpekE4h6-NQSN-4xKlvqjEDdnzkmSnkVTEXJZnK1ok';

  // Google OAuth Configuration
  static const String kGoogleWebClientId =
      '108734757179-v1a2fl1fh1d1rla1l1h2kkkba6695j20.apps.googleusercontent.com';
  static const String kGoogleIosClientId =
      '108734757179-06vdgfpb9q01pr17bj3bqe9h32gvbnm8.apps.googleusercontent.com';

  // Design System - Color Palette
  static const Color primaryBlue = Color(0xFFE6F3FF);
  static const Color accentCoral = Color(0xFFFFB5A3);
  static const Color accentPink = Color(0xFFFFB3D9);
  static const Color accentGreen = Color(0xFFB8E6B8);
  static const Color accentYellow = Color(0xFFFFE066);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3748);

  // Typography
  static const String primaryFont = 'PlayfairDisplay';
  static const String secondaryFont = 'Karla';

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}
