import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_spacing.dart';
import '../utils/teacher_display_name.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';

/// Öğretmen — öğrenci duyuruları (sınıfa özel veya genel).
class TeacherStudentAnnouncementsScreen extends StatefulWidget {
  const TeacherStudentAnnouncementsScreen({super.key});

  @override
  State<TeacherStudentAnnouncementsScreen> createState() =>
      _TeacherStudentAnnouncementsScreenState();
}

class _TeacherStudentAnnouncementsScreenState
    extends State<TeacherStudentAnnouncementsScreen> {
  List<Map<String, Object?>> _rows = [];
  List<Map<String, Object?>> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    _classes = await db.getStudentClasses();
    _rows = await db.listStudentAnnouncementsForTeacher();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showCreateDialog() async {
    final strings = AppLocalizations.of(context);
    final db = context.read<AppState>().db;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final courseController = TextEditingController();
    int? classId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.t('teacherAnnouncementsNew')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: strings.t('teacherAnnouncementsTitle'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: strings.t('teacherAnnouncementsBody'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: courseController,
                    decoration: InputDecoration(
                      labelText: strings.t('teacherAnnouncementsCourse'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: classId,
                    decoration: InputDecoration(
                      labelText: strings.t('teacherAnnouncementsClass'),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(strings.t('teacherAnnouncementsAllClasses')),
                      ),
                      ..._classes.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c['id'] as int,
                          child: Text(
                            '${c['ad']}${c['sube'] != null ? '-${c['sube']}' : ''}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => classId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(strings.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(strings.t('save')),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final teacherName = await TeacherDisplayName.resolve(db);
    await db.insertStudentAnnouncement(
      title: title,
      body: body,
      teacherName: teacherName,
      classId: classId,
      courseLabel: courseController.text.trim().isEmpty
          ? null
          : courseController.text.trim(),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('teacherAnnouncements')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? AppEmptyState(
                  icon: Icons.campaign_outlined,
                  title: strings.t('teacherAnnouncementsEmpty'),
                  actionLabel: strings.t('teacherAnnouncementsNew'),
                  onAction: _showCreateDialog,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    final id = row['id'] as int;
                    final classLabel = row['sinif_id'] == null
                        ? strings.t('teacherAnnouncementsAllClasses')
                        : _classes
                            .where((c) => c['id'] == row['sinif_id'])
                            .map((c) => '${c['ad']}-${c['sube']}')
                            .join();
                    return AppCard(
                      child: ListTile(
                        title: Text(row['baslik'] as String),
                        subtitle: Text(
                          '${classLabel}\n${row['icerik'] as String}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await context.read<AppState>().db
                                .deleteStudentAnnouncement(id);
                            await _reload();
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
