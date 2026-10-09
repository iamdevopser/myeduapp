import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tasarım 08/11 — gruplu liste satırı (ikon + başlık + önizleme + tarih).
class DesignFeedRow extends StatelessWidget {
  const DesignFeedRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.icon,
    required this.iconBackground,
    this.trailing,
    this.onTap,
    this.semanticsLabel,
    this.unread = false,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
  final IconData icon;
  final Color iconBackground;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final bool unread;

  /// İsteğe bağlı kategori hapı (ör. [DesignPill]); alt satırda gösterilir.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
          color: AppColors.navy,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
          height: 1.35,
        );
    final dateStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        );

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(title, style: titleStyle, maxLines: 2)),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(dateLabel, style: dateStyle),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: subtitleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (badge != null) ...[
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: badge!),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ] else if (onTap != null)
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFCBD5E1),
              size: 22,
            ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? title,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: content,
            ),
    );
  }
}
