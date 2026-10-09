import 'package:flutter/material.dart';

import '../../theme/design_system.dart';
import 'design_surface_card.dart';

/// Tasarım 08/11 — tek kart içinde bölünmüş liste.
class DesignGroupedListCard extends StatelessWidget {
  const DesignGroupedListCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(
          const Divider(height: 1, color: DesignSystem.cardBorder),
        );
      }
    }
    return DesignSurfaceCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }
}
