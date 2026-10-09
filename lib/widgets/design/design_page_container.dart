import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';

/// Generic page body wrapper: responsive horizontal padding
/// ([AppSpacing.horizontalPagePadding]), centered max width and optional scroll.
///
/// Not yet adopted by screens (screen migration is deferred to later phases).
class DesignPageContainer extends StatelessWidget {
  const DesignPageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.readableMaxWidth,
    this.scrollable = false,
    this.verticalPadding = AppSpacing.lg,
  });

  final Widget child;

  /// Use [AppSpacing.contentMaxWidth] for wide (dashboard/table) pages.
  final double maxWidth;
  final bool scrollable;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = AppSpacing.horizontalPagePadding(width);

    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        child: SizedBox(width: double.infinity, child: content),
      );
    }
    return content;
  }
}

/// Section title row: [DesignSystem.sectionTitle] + optional trailing action.
class DesignSectionHeader extends StatelessWidget {
  const DesignSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: DesignSystem.sectionTitle(context)),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
