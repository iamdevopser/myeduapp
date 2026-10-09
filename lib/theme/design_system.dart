import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Elevation / shadow tokens.
abstract final class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> dialog = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 48,
      offset: const Offset(0, 20),
    ),
  ];
}

/// Border tokens (light). Dark equivalents come from `AppDesignTokens`.
abstract final class AppBorders {
  static const double defaultWidth = 1;
  static const double strongWidth = 1.5;

  static const BorderSide defaultSide =
      BorderSide(color: AppColors.border, width: defaultWidth);
  static const BorderSide subtle =
      BorderSide(color: AppColors.borderSubtle, width: defaultWidth);
  static const BorderSide strong =
      BorderSide(color: AppColors.borderStrong, width: strongWidth);
}

/// Faz 2 — `MyEduApp_design_pages_separated` ortak token'ları.
abstract final class DesignSystem {
  static const double cardRadius = AppRadius.card;
  static const double hubTileMinHeight = 108;
  static const double sectionTitleSize = AppTypography.titleSize;
  static const double pageTitleSize = AppTypography.headingSize;

  static const Color workspaceBackground = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE2E8F0);

  static final List<BoxShadow> cardShadow = AppShadows.card;

  static const List<Color> classAccentPalette = [
    Color(0xFF3B82F6),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
  ];

  static Color classAccentAt(int index) =>
      classAccentPalette[index % classAccentPalette.length];

  static BoxDecoration surfaceCardDecoration({Color? fill}) {
    return BoxDecoration(
      color: fill ?? Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.fromBorderSide(AppBorders.defaultSide),
      boxShadow: AppShadows.card,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: sectionTitleSize,
          color: AppColors.navy,
        );
  }

  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: pageTitleSize,
          color: AppColors.navy,
        );
  }
}
