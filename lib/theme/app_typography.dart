import 'package:flutter/material.dart';

/// Typography scale tokens (color-less; color comes from the theme).
///
/// `heading` / `title` match `DesignSystem.pageTitle` (22/w800) and
/// `DesignSystem.sectionTitle` (18/w700).
abstract final class AppTypography {
  static const double displaySize = 32;
  static const double headingSize = 22;
  static const double titleSize = 18;
  static const double bodySize = 14;
  static const double bodySmallSize = 13;
  static const double labelSize = 14;
  static const double captionSize = 12;

  static const TextStyle display = TextStyle(
    fontSize: displaySize,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: headingSize,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontSize: titleSize,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: bodySmallSize,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontSize: labelSize,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// Maps tokens onto Material [TextTheme] roles. Sizes of roles that screens
  /// already rely on (e.g. bodyLarge 16, titleMedium 16, titleLarge 22) are kept.
  static TextTheme textTheme() {
    return TextTheme(
      displaySmall: display,
      headlineSmall: heading,
      titleLarge: heading.copyWith(fontWeight: FontWeight.w700),
      titleMedium: title.copyWith(fontSize: 16),
      titleSmall: label,
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body,
      bodySmall: bodySmall,
      labelLarge: label,
      labelMedium: caption.copyWith(fontWeight: FontWeight.w600),
      labelSmall: caption.copyWith(fontSize: 11),
    );
  }
}
