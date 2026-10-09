import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_system.dart';

/// Semantic design tokens exposed through [ThemeData.extensions].
///
/// Access with `context.tokens` (or `Theme.of(context).extension<AppDesignTokens>()`).
@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  const AppDesignTokens({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.dialogShadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderSubtle;
  final Color borderStrong;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;
  final List<BoxShadow> dialogShadow;

  static final AppDesignTokens light = AppDesignTokens(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    accent: AppColors.accent,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    borderSubtle: AppColors.borderSubtle,
    borderStrong: AppColors.borderStrong,
    divider: AppColors.divider,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    cardShadow: AppShadows.card,
    elevatedShadow: AppShadows.elevated,
    dialogShadow: AppShadows.dialog,
  );

  static final AppDesignTokens dark = AppDesignTokens(
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceElevated: AppColorsDark.surfaceElevated,
    primary: AppColorsDark.primary,
    secondary: AppColorsDark.secondary,
    accent: AppColorsDark.accent,
    textPrimary: AppColorsDark.textPrimary,
    textSecondary: AppColorsDark.textSecondary,
    textMuted: AppColorsDark.textMuted,
    border: AppColorsDark.border,
    borderSubtle: AppColorsDark.borderSubtle,
    borderStrong: AppColorsDark.borderStrong,
    divider: AppColorsDark.divider,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    error: AppColorsDark.error,
    info: AppColorsDark.info,
    cardShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ],
    dialogShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.55),
        blurRadius: 48,
        offset: const Offset(0, 20),
      ),
    ],
  );

  @override
  AppDesignTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderSubtle,
    Color? borderStrong,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? elevatedShadow,
    List<BoxShadow>? dialogShadow,
  }) {
    return AppDesignTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
      dialogShadow: dialogShadow ?? this.dialogShadow,
    );
  }

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<BoxShadow> s(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? a;
    return AppDesignTokens(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      primary: c(primary, other.primary),
      secondary: c(secondary, other.secondary),
      accent: c(accent, other.accent),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      divider: c(divider, other.divider),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      info: c(info, other.info),
      cardShadow: s(cardShadow, other.cardShadow),
      elevatedShadow: s(elevatedShadow, other.elevatedShadow),
      dialogShadow: s(dialogShadow, other.dialogShadow),
    );
  }
}

extension AppDesignTokensContext on BuildContext {
  /// Design tokens for the current theme (falls back to light/dark by brightness).
  AppDesignTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<AppDesignTokens>() ??
        (theme.brightness == Brightness.dark
            ? AppDesignTokens.dark
            : AppDesignTokens.light);
  }
}
