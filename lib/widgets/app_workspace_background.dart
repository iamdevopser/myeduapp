import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared workspace backdrop: soft brand gradient with readable content on top.
///
/// Use as the outer layer of role workspaces; place opaque [child] surfaces
/// (cards, lists) inside for contrast.
class AppWorkspaceBackground extends StatelessWidget {
  const AppWorkspaceBackground({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  static const _gradient = LinearGradient(
    colors: [
      Color(0xFFF5F7FA),
      Color(0xFFF0F4F8),
      Color(0xFFF5F7FA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: _gradient,
        color: AppColors.background,
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}
