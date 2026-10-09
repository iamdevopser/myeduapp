import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_design_tokens.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static const Size _minButtonSize = Size(64, AppSpacing.minTouchTarget);
  static const Size _minIconButtonSize =
      Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: Colors.white,
    );

    return _build(
      scheme: scheme,
      tokens: AppDesignTokens.light,
      scaffold: AppColors.background,
      surface: AppColors.surface,
      border: AppColors.border,
      divider: AppColors.divider,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textMuted: AppColors.textMuted,
      tableHeading: const Color(0xFFF8FAFC),
      cardShadow: Colors.black.withValues(alpha: 0.06),
      appBar: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColorsDark.primary,
      secondary: AppColorsDark.secondary,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      onSurfaceVariant: AppColorsDark.textSecondary,
      outline: AppColorsDark.borderStrong,
      outlineVariant: AppColorsDark.border,
      error: AppColorsDark.error,
    );

    return _build(
      scheme: scheme,
      tokens: AppDesignTokens.dark,
      scaffold: AppColorsDark.background,
      surface: AppColorsDark.surface,
      border: AppColorsDark.border,
      divider: AppColorsDark.divider,
      textPrimary: AppColorsDark.textPrimary,
      textSecondary: AppColorsDark.textSecondary,
      textMuted: AppColorsDark.textMuted,
      tableHeading: AppColorsDark.surfaceElevated,
      cardShadow: Colors.black.withValues(alpha: 0.35),
      appBar: const AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required AppDesignTokens tokens,
    required Color scaffold,
    required Color surface,
    required Color border,
    required Color divider,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color tableHeading,
    required Color cardShadow,
    required AppBarTheme appBar,
  }) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      dividerColor: divider,
      focusColor: scheme.primary.withValues(alpha: 0.18),
      textTheme: AppTypography.textTheme(),
      extensions: <ThemeExtension<dynamic>>[tokens],
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      appBarTheme: appBar,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: _minButtonSize,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: border),
          minimumSize: _minButtonSize,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: _minButtonSize,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: _minIconButtonSize),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textMuted),
      ),
      chipTheme: ChipThemeData(side: BorderSide(color: border)),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        textStyle: AppTypography.caption.copyWith(color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(tableHeading),
        dataRowMinHeight: 48,
        headingRowHeight: 52,
        dividerThickness: 1,
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: buttonShape,
      ),
    );
  }
}
