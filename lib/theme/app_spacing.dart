import 'package:flutter/material.dart';

/// Screen size buckets for adaptive layouts.
enum AppLayoutSize {
  mobile,
  tablet,
  desktop,
}

/// Fine-grained responsive buckets (QA widths 360 … 1920).
enum AppBreakpoint {
  smallMobile,
  largeMobile,
  tablet,
  smallDesktop,
  largeDesktop,
}

/// Single source of truth for corner radii.
abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double card = 16;
  static const double pill = 999;
}

/// Consistent spacing scale for MyEduApp layouts.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Minimum interactive target size (accessibility).
  static const double minTouchTarget = 48;

  /// Max width of page content on wide screens.
  static const double contentMaxWidth = 1280;

  /// Max width for long-form / reading content.
  static const double readableMaxWidth = 960;

  static const double sidebarWidth = 260;
  static const double sidebarCollapsed = 72;
  static const double headerHeight = 64;
  static const double cardRadius = AppRadius.medium;

  /// Breakpoint upper bounds (exclusive) for [AppBreakpoint].
  static const double smallMobileBreakpoint = 390;
  static const double largeMobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double smallDesktopBreakpoint = 1440;

  /// Widths used for responsive QA.
  static const List<double> qaWidths = [360, 390, 430, 768, 1024, 1280, 1440, 1920];

  static AppBreakpoint breakpoint(double width) {
    if (width < smallMobileBreakpoint) return AppBreakpoint.smallMobile;
    if (width < largeMobileBreakpoint) return AppBreakpoint.largeMobile;
    if (width < tabletBreakpoint) return AppBreakpoint.tablet;
    if (width < smallDesktopBreakpoint) return AppBreakpoint.smallDesktop;
    return AppBreakpoint.largeDesktop;
  }

  /// Horizontal page padding scaled by [AppBreakpoint] (12 / 16 / 24 / 24 / 32).
  static double horizontalPagePadding(double width) {
    return switch (breakpoint(width)) {
      AppBreakpoint.smallMobile => md,
      AppBreakpoint.largeMobile => lg,
      AppBreakpoint.tablet => xl,
      AppBreakpoint.smallDesktop => xl,
      AppBreakpoint.largeDesktop => xxl,
    };
  }

  /// Mobile: < 600 px
  static const double phoneBreakpoint = 600;

  /// Tablet upper bound / desktop start: >= 1024 px
  static const double desktopBreakpoint = 1024;

  /// Legacy tablet tuning breakpoint (grid/column density).
  static const double shellBreakpoint = 900;

  static AppLayoutSize layoutSize(double width) {
    if (width < phoneBreakpoint) return AppLayoutSize.mobile;
    if (width < desktopBreakpoint) return AppLayoutSize.tablet;
    return AppLayoutSize.desktop;
  }

  static bool isMobile(double width) => layoutSize(width) == AppLayoutSize.mobile;

  static bool isTablet(double width) => layoutSize(width) == AppLayoutSize.tablet;

  static bool isDesktop(double width) =>
      layoutSize(width) == AppLayoutSize.desktop;

  static int gridCrossAxisCount(double width, {int desktop = 3, int tablet = 2}) {
    return switch (layoutSize(width)) {
      AppLayoutSize.mobile => 1,
      AppLayoutSize.tablet => tablet,
      AppLayoutSize.desktop => desktop,
    };
  }

  static EdgeInsets pagePadding(double width) {
    return EdgeInsets.all(isMobile(width) ? md : lg);
  }

  static double dialogMaxWidth(double width) {
    if (isMobile(width)) return width - lg * 2;
    if (isTablet(width)) return 560;
    return 640;
  }
}

extension AppLayoutContext on BuildContext {
  double get layoutWidth => MediaQuery.sizeOf(this).width;

  AppLayoutSize get layoutSize => AppSpacing.layoutSize(layoutWidth);

  bool get isMobileLayout => layoutSize == AppLayoutSize.mobile;

  bool get isTabletLayout => layoutSize == AppLayoutSize.tablet;

  bool get isDesktopLayout => layoutSize == AppLayoutSize.desktop;
}
