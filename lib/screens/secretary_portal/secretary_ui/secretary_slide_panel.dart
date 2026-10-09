import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'secretary_design.dart';

/// Right-side slide-over panel for secretary create/edit flows.
Future<T?> showSecretaryEndPanel<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final panelWidth = width < 600
      ? width
      : math.min(520.0, math.max(380.0, width * 0.38));

  final panel = SizedBox(
    width: panelWidth,
    height: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (actions != null) ...actions,
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ],
    ),
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: SecretaryDesign.workspaceBg,
          elevation: 16,
          child: panel,
        ),
      );
    },
    transitionBuilder:
        (dialogContext, animation, secondaryAnimation, dialogChild) {
          final offset =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offset, child: dialogChild);
        },
  );
}
