import 'package:flutter/material.dart';

/// Dark-theme equivalents of the semantic tokens in [AppColors].
abstract final class AppColorsDark {
  static const Color background = Color(0xFF0B1220);
  static const Color surface = Color(0xFF111A2E);
  static const Color surfaceElevated = Color(0xFF18233A);
  static const Color primary = Color(0xFF60A5FA);
  static const Color secondary = Color(0xFFA78BFA);
  static const Color accent = Color(0xFF8B7CF0);
  static const Color border = Color(0xFF273449);
  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color borderStrong = Color(0xFF3B4B66);
  static const Color divider = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFFB4C0D3);
  static const Color textMuted = Color(0xFF8493AB);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF38BDF8);
}

/// MyEduApp design tokens — `docs/design/myeduapp_ui_reference.png`
abstract final class AppColors {
  /// Referans sidebar / header navy (#0D2344 ailesi).
  static const Color navy = Color(0xFF0D2344);
  static const Color navyLight = Color(0xFF1A2B4B);
  /// Referans birincil aksiyon mavisi.
  static const Color referenceBlue = Color(0xFF007BFF);
  static const Color sidebarActive = Color(0xFF007BFF);
  static const Color sidebarHover = Color(0xFF2A3D66);

  static const Color primaryBlue = Color(0xFF2563EB);
  /// Referans mockup mor birincil (Ders Oluşturucu, secretary formlar).
  static const Color brandPrimary = Color(0xFF6D5BD0);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentRed = Color(0xFFDC2626);

  // ---- Semantic color tokens (light) ----
  /// Workspace background (aligned with `DesignSystem.workspaceBackground`).
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color primary = primaryBlue;
  static const Color secondary = accentPurple;
  static const Color accent = brandPrimary;
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color success = accentGreen;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = accentRed;
  static const Color info = Color(0xFF0284C7);

  static const Color categoryStudents = Color(0xFF3B82F6);
  static const Color categoryMaterials = Color(0xFF8B5CF6);
  static const Color categoryActivities = Color(0xFF22C55E);
  static const Color categoryHomeworks = Color(0xFFF59E0B);
  static const Color categoryExams = Color(0xFFEF4444);
  static const Color categoryPerformance = Color(0xFF6366F1);
  static const Color categoryBehaviors = Color(0xFF0D9488);

  static Color categoryColor(String code) {
    switch (code) {
      case 'students':
        return categoryStudents;
      case 'performance':
        return categoryPerformance;
      case 'materials':
        return categoryMaterials;
      case 'activity':
      case 'activities':
        return categoryActivities;
      case 'homework':
        return categoryHomeworks;
      case 'exam':
        return categoryExams;
      case 'behaviors':
        return categoryBehaviors;
      default:
        return primaryBlue;
    }
  }
}
