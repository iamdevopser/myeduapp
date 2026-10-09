import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';

/// Tasarım 03/04 — sayfa başlığı + aksiyon satırı.
class DesignListPageHeader extends StatelessWidget {
  const DesignListPageHeader({
    super.key,
    required this.title,
    this.searchField,
    this.primaryAction,
    this.secondaryAction,
  });

  final String title;
  final Widget? searchField;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stack = AppSpacing.isMobile(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: DesignSystem.pageTitle(context)),
        const SizedBox(height: 16),
        if (stack)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (searchField != null) searchField!,
              if (primaryAction != null || secondaryAction != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (secondaryAction != null) secondaryAction!,
                    if (secondaryAction != null && primaryAction != null)
                      const SizedBox(width: 8),
                    if (primaryAction != null) Expanded(child: primaryAction!),
                  ],
                ),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (searchField != null) Expanded(flex: 3, child: searchField!),
              const SizedBox(width: 12),
              if (secondaryAction != null) secondaryAction!,
              if (secondaryAction != null) const SizedBox(width: 8),
              if (primaryAction != null) primaryAction!,
            ],
          ),
      ],
    );
  }
}
