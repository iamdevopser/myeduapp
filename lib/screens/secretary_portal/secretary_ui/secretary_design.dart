import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Secretary workspace visual tokens (indigo accent, glass cards).
abstract final class SecretaryDesign {
  static const Color primary = AppColors.brandPrimary;
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color workspaceBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color.fromRGBO(225, 231, 239, 0.8);

  static const double cardRadius = 16;
  static const Duration hoverDuration = Duration(milliseconds: 200);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  static BoxDecoration glassCardDecoration({Color? fill}) {
    return BoxDecoration(
      color: (fill ?? Colors.white).withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: cardBorder),
      boxShadow: cardShadow,
    );
  }

  static Widget workspaceBackground({required Widget child}) {
    return ColoredBox(color: workspaceBg, child: child);
  }
}

class SecretaryGlassCard extends StatefulWidget {
  const SecretaryGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool blur;

  @override
  State<SecretaryGlassCard> createState() => _SecretaryGlassCardState();
}

class _SecretaryGlassCardState extends State<SecretaryGlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SecretaryDesign.cardRadius);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: const BorderSide(color: SecretaryDesign.cardBorder),
    );
    final surface = Colors.white.withValues(alpha: widget.blur ? 0.88 : 0.92);

    final shadows = _hovered && widget.onTap != null
        ? [
            ...SecretaryDesign.cardShadow,
            BoxShadow(
              color: SecretaryDesign.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : SecretaryDesign.cardShadow;

    Widget padded = Padding(padding: widget.padding, child: widget.child);

    if (widget.blur) {
      padded = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: padded,
        ),
      );
    }

    Widget materialChild = padded;
    if (widget.onTap != null) {
      materialChild = InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        child: padded,
      );
    }

    final card = Material(
      color: surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: materialChild,
    );

    return MouseRegion(
      onEnter: widget.onTap != null
          ? (_) => setState(() => _hovered = true)
          : null,
      onExit: widget.onTap != null
          ? (_) => setState(() => _hovered = false)
          : null,
      child: AnimatedContainer(
        duration: SecretaryDesign.hoverDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
        child: card,
      ),
    );
  }
}

class SecretaryStatusBadge extends StatelessWidget {
  const SecretaryStatusBadge({
    super.key,
    required this.label,
    required this.tone,
  });

  final String label;
  final SecretaryBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      SecretaryBadgeTone.success => (
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
      ),
      SecretaryBadgeTone.danger => (
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
      ),
      SecretaryBadgeTone.neutral => (
        const Color(0xFFE2E8F0),
        AppColors.textSecondary,
      ),
      SecretaryBadgeTone.info => (
        SecretaryDesign.primary.withValues(alpha: 0.12),
        SecretaryDesign.primary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum SecretaryBadgeTone { success, danger, neutral, info }

class SecretaryHubTabBar extends StatelessWidget {
  const SecretaryHubTabBar({
    super.key,
    required this.tabs,
    required this.controller,
  });

  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return SecretaryGlassCard(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          color: SecretaryDesign.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: SecretaryDesign.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}
