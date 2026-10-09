import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../utils/student_score_display.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/design/design_surface_card.dart';

/// Tasarım 05 — gerçek not kolonları ve öğrenci notları.
class SecretaryStudentGradesPanel extends StatelessWidget {
  const SecretaryStudentGradesPanel({
    super.key,
    required this.classId,
    required this.studentId,
    required this.db,
  });

  final int classId;
  final int studentId;
  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<List<_GradeRow>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return AppEmptyState(
            icon: Icons.grade_outlined,
            title: strings.t('studentPortalNoGradeYet'),
          );
        }
        return DesignSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                Semantics(
                  label: '${rows[i].title}, ${rows[i].valueLabel}',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      rows[i].title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    subtitle: rows[i].date.isNotEmpty
                        ? Text(rows[i].date)
                        : null,
                    trailing: Text(
                      rows[i].valueLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: rows[i].absent
                            ? const Color(0xFFDC2626)
                            : AppColors.navy,
                      ),
                    ),
                  ),
                ),
                if (i < rows.length - 1)
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<List<_GradeRow>> _load() async {
    final columns = await db.getScoreColumns(classId);
    final scores = await db.getStudentScores(classId);
    final studentScores = scores
        .where((r) => r['ogrenci_id'] == studentId)
        .toList();
    final colById = {for (final c in columns) c['id'] as int: c};
    final rows = <_GradeRow>[];
    for (final row in studentScores) {
      final colId = row['kolon_id'] as int?;
      if (colId == null) continue;
      final col = colById[colId];
      if (col == null) continue;
      final tur = col['tur'] as String? ?? '';
      if (tur == 'homework') continue;
      final absent = studentScoreRowIsAbsent(row);
      final score = row['not_deger'] as int?;
      final valueLabel = absent ? '—' : (score != null ? '$score' : '—');
      rows.add(
        _GradeRow(
          title: col['ad'] as String? ?? '',
          date: row['tarih'] as String? ?? '',
          valueLabel: valueLabel,
          absent: absent,
        ),
      );
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }
}

class _GradeRow {
  const _GradeRow({
    required this.title,
    required this.date,
    required this.valueLabel,
    required this.absent,
  });

  final String title;
  final String date;
  final String valueLabel;
  final bool absent;
}
