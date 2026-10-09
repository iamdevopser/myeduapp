import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';

class DesignSurfaceCard extends StatelessWidget {
  const DesignSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = DesignSystem.surfaceCardDecoration();
    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}
