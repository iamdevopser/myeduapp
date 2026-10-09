import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';
import 'design_class_grid_card.dart';
import 'design_page_container.dart';
import 'design_surface_card.dart';

/// Tasarım 13 — Sınıflarım + Güncel Dersler birincil satır.
class TeacherDesignHomePrimary extends StatelessWidget {
  const TeacherDesignHomePrimary({
    super.key,
    required this.classes,
    required this.todaySchedule,
    required this.onClassTap,
  });

  final List<Map<String, Object?>> classes;
  final List<Map<String, Object?>> todaySchedule;
  final void Function(int classId) onClassTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppSpacing.isMobile(width);
    final gap = AppSpacing.lg;

    final classesPanel = _ClassesPanel(
      title: strings.t('myClasses'),
      classes: classes,
      onClassTap: onClassTap,
      strings: strings,
    );

    final lessonsPanel = _CurrentLessonsPanel(
      title: strings.t('designCurrentLessons'),
      rows: todaySchedule,
      strings: strings,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          classesPanel,
          SizedBox(height: gap),
          lessonsPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: classesPanel),
        SizedBox(width: gap),
        Expanded(flex: 2, child: lessonsPanel),
      ],
    );
  }
}

class _ClassesPanel extends StatelessWidget {
  const _ClassesPanel({
    required this.title,
    required this.classes,
    required this.onClassTap,
    required this.strings,
  });

  final String title;
  final List<Map<String, Object?>> classes;
  final void Function(int classId) onClassTap;
  final AppLocalizations strings;

  static const double _twoColumnMinWidth = 300;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignSectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        if (classes.isEmpty)
          DesignSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                strings.t('noClassesYet'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Tasarım 13: 2x2 sınıf kartı; çok dar alanda tek sütun.
              final cross = constraints.maxWidth >= _twoColumnMinWidth ? 2 : 1;
              const gap = AppSpacing.md;
              final tileW =
                  (constraints.maxWidth - gap * (cross - 1)) / cross;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < classes.length; i++)
                    SizedBox(
                      width: tileW,
                      child: DesignClassGridCard(
                        classRow: classes[i],
                        accentIndex: i,
                        onTap: () =>
                            onClassTap(classes[i]['id'] as int),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _CurrentLessonsPanel extends StatelessWidget {
  const _CurrentLessonsPanel({
    required this.title,
    required this.rows,
    required this.strings,
  });

  final String title;
  final List<Map<String, Object?>> rows;
  final AppLocalizations strings;

  static const _lessonColors = [
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignSectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        DesignSurfaceCard(
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    strings.t('noEvents'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rows.length && i < 8; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: DesignSystem.cardBorder),
                      _LessonRow(
                        row: rows[i],
                        color: _lessonColors[i % _lessonColors.length],
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.row, required this.color});

  final Map<String, Object?> row;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = row['ders_ad'] as String? ??
        row['konu_metin'] as String? ??
        '';
    final time =
        '${row['baslangic'] ?? ''} - ${row['bitis'] ?? ''}'.trim();
    final classLabel = row['sinif_ad'] as String? ??
        row['sube'] as String? ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.menu_book_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (classLabel.isNotEmpty)
                  Text(
                    classLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
              ],
            ),
          ),
          if (time.isNotEmpty && time != '-')
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
            ),
        ],
      ),
    );
  }
}
