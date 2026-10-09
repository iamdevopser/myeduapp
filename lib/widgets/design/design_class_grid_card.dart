import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/design_system.dart';
import 'design_surface_card.dart';

/// Tasarım 13 — sınıf kartı (renkli ikon + ad + öğrenci sayısı).
class DesignClassGridCard extends StatelessWidget {
  const DesignClassGridCard({
    super.key,
    required this.classRow,
    required this.accentIndex,
    required this.onTap,
  });

  final Map<String, Object?> classRow;
  final int accentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final classId = classRow['id'] as int;
    final accent = DesignSystem.classAccentAt(accentIndex);
    final name = classRow['ad'] as String? ?? '';

    return Semantics(
      button: true,
      label: name,
      child: DesignSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: state.db.getStudents(classId),
          builder: (context, snap) {
            final count = snap.data?.length ?? 0;
            return Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.class_rounded, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignSystem.pageTitle(context).color,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.t('designClassStudentCount')
                            .replaceAll('{count}', '$count'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
