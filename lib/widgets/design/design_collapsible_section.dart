import 'package:flutter/material.dart';

import '../../theme/app_design_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';

/// Başlıklı, aç/kapa yapılabilir bölüm (ikincil dashboard içeriği için).
///
/// Başlık satırı tek bir `button` (min [AppSpacing.minTouchTarget] yükseklik,
/// `expanded` semantics). [initiallyExpanded] varsayılan `true`; kapalıyken
/// içerik ağaçtan çıkarılır (durum kaybı istenmiyorsa açık bırakın).
class DesignCollapsibleSection extends StatefulWidget {
  const DesignCollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.expandTooltip,
    this.collapseTooltip,
    this.expandToken,
  });

  /// Değeri (null olmayan) değiştiğinde bölüm otomatik açılır.
  final Object? expandToken;

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final String? expandTooltip;
  final String? collapseTooltip;

  @override
  State<DesignCollapsibleSection> createState() =>
      _DesignCollapsibleSectionState();
}

class _DesignCollapsibleSectionState extends State<DesignCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant DesignCollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan gelen bir istek (ör. bekleyen not defteri) bölümü açar.
    if (widget.expandToken != oldWidget.expandToken &&
        widget.expandToken != null) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tooltip =
        (_expanded ? widget.collapseTooltip : widget.expandTooltip) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: widget.title,
          excludeSemantics: true,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: DesignSystem.sectionTitle(context).copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: tokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          widget.child,
        ],
      ],
    );
  }
}
