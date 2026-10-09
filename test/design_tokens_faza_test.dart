import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/theme/app_design_tokens.dart';
import 'package:my_edu_app/theme/app_spacing.dart';
import 'package:my_edu_app/theme/app_theme.dart';

void main() {
  test('AppSpacing.breakpoint classifies all QA widths', () {
    final expected = <double, AppBreakpoint>{
      360: AppBreakpoint.smallMobile,
      390: AppBreakpoint.largeMobile,
      430: AppBreakpoint.largeMobile,
      768: AppBreakpoint.tablet,
      1024: AppBreakpoint.smallDesktop,
      1280: AppBreakpoint.smallDesktop,
      1440: AppBreakpoint.largeDesktop,
      1920: AppBreakpoint.largeDesktop,
    };
    expect(AppSpacing.qaWidths, expected.keys.toList());
    for (final w in AppSpacing.qaWidths) {
      expect(AppSpacing.breakpoint(w), expected[w], reason: '$w');
    }
  });

  test('legacy isMobile/isTablet/isDesktop unchanged', () {
    expect(AppSpacing.isMobile(599), isTrue);
    expect(AppSpacing.isTablet(600), isTrue);
    expect(AppSpacing.isTablet(1023), isTrue);
    expect(AppSpacing.isDesktop(1024), isTrue);
    expect(AppSpacing.isMobile(600), isFalse);
    expect(AppSpacing.isDesktop(1023), isFalse);
    expect(AppSpacing.pagePadding(599), const EdgeInsets.all(AppSpacing.md));
    expect(AppSpacing.pagePadding(600), const EdgeInsets.all(AppSpacing.lg));
  });

  test('AppDesignTokens registered in light and dark themes', () {
    final light = AppTheme.light().extension<AppDesignTokens>();
    final dark = AppTheme.dark().extension<AppDesignTokens>();
    expect(light, isNotNull);
    expect(dark, isNotNull);
    expect(light!.background, isNot(dark!.background));
  });

  test('AppDesignTokens copyWith and lerp', () {
    final a = AppDesignTokens.light;
    final b = AppDesignTokens.dark;
    expect(a.copyWith(primary: Colors.red).primary, Colors.red);
    expect(a.copyWith().surface, a.surface);
    expect(a.lerp(b, 0).background, a.background);
    expect(a.lerp(b, 1).background, b.background);
    expect(a.lerp(null, 0.5), a);
  });
}
