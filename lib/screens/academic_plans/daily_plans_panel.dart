import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/local/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import 'academic_plan_import_actions.dart';
import 'academic_plan_labels.dart';
import '../../services/academic_plan_import_service.dart';

class DailyPlansPanel extends StatefulWidget {
  const DailyPlansPanel({super.key});

  @override
  State<DailyPlansPanel> createState() => _DailyPlansPanelState();
}

class _DailyPlansPanelState extends State<DailyPlansPanel> {
  List<Map<String, Object?>> _plans = [];
  List<Map<String, Object?>> _lessons = [];
  List<Map<String, Object?>> _studentClasses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    _plans = await db.getDailyPlans();
    _lessons = await db.listLessonsForAcademicPlanning();
    _studentClasses = await db.getStudentClasses();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editPlan({Map<String, Object?>? existing}) async {
    final strings = AppLocalizations.of(context);
    var date = existing?['tarih'] as String? ??
        AppDatabase.scoreDateKey(DateTime.now());
    final topicController = TextEditingController(
      text: existing?['konu'] as String? ?? '',
    );
    final objectivesController = TextEditingController(
      text: existing?['hedefler'] as String? ?? '',
    );
    final activitiesController = TextEditingController(
      text: existing?['etkinlikler'] as String? ?? '',
    );
    final materialsController = TextEditingController(
      text: existing?['materyaller'] as String? ?? '',
    );
    final homeworkController = TextEditingController(
      text: existing?['odev'] as String? ?? '',
    );
    final notesController = TextEditingController(
      text: existing?['notlar'] as String? ?? '',
    );
    final subjectController = TextEditingController(
      text: academicPlanSubjectLabel(existing ?? {}),
    );
    final classController = TextEditingController(
      text: academicPlanClassLabel(existing ?? {}),
    );
    int? lessonId = existing?['ders_id'] as int?;
    int? studentClassId = existing?['ogrenci_sinif_id'] as int?;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? strings.t('dailyPlanAdd') : strings.t('edit'),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: strings.t('selectedDate')),
                  controller: TextEditingController(text: date),
                  onChanged: (v) => date = v.trim(),
                ),
                _lessonClassFields(
                  strings,
                  lessonId: lessonId,
                  studentClassId: studentClassId,
                  onLesson: (v) => lessonId = v,
                  onClass: (v) => studentClassId = v,
                  subjectController: subjectController,
                  classController: classController,
                ),
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(labelText: strings.t('topic')),
                ),
                TextField(
                  controller: objectivesController,
                  decoration:
                      InputDecoration(labelText: strings.t('learningObjectives')),
                  maxLines: 2,
                ),
                TextField(
                  controller: activitiesController,
                  decoration: InputDecoration(labelText: strings.t('activities')),
                  maxLines: 2,
                ),
                TextField(
                  controller: materialsController,
                  decoration: InputDecoration(labelText: strings.t('materials')),
                  maxLines: 2,
                ),
                TextField(
                  controller: homeworkController,
                  decoration: InputDecoration(labelText: strings.t('homeworks')),
                  maxLines: 2,
                ),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: strings.t('note')),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    if (saved != true) return;

    final values = {
      'tarih': date,
      'ders_id': lessonId,
      'ogrenci_sinif_id': studentClassId,
      'konu_metin': subjectController.text.trim(),
      'sinif_metin': classController.text.trim(),
      'konu': topicController.text.trim(),
      'hedefler': objectivesController.text.trim(),
      'etkinlikler': activitiesController.text.trim(),
      'materyaller': materialsController.text.trim(),
      'odev': homeworkController.text.trim(),
      'notlar': notesController.text.trim(),
    };
    final db = context.read<AppState>().db;
    if (existing == null) {
      await db.insertDailyPlan(values);
    } else {
      await db.updateDailyPlan(existing['id'] as int, values);
    }
    await _load();
  }

  Widget _lessonClassFields(
    AppLocalizations strings, {
    required int? lessonId,
    required int? studentClassId,
    required ValueChanged<int?> onLesson,
    required ValueChanged<int?> onClass,
    required TextEditingController subjectController,
    required TextEditingController classController,
  }) {
    return Column(
      children: [
        DropdownButtonFormField<int?>(
          value: lessonId,
          decoration: InputDecoration(labelText: strings.t('courses')),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('—')),
            ..._lessons.map(
              (row) => DropdownMenuItem<int?>(
                value: row['id'] as int,
                child: Text('${row['sinif_ad']} / ${row['ad']}'),
              ),
            ),
          ],
          onChanged: onLesson,
        ),
        DropdownButtonFormField<int?>(
          value: studentClassId,
          decoration: InputDecoration(labelText: strings.t('selectClass')),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('—')),
            ..._studentClasses.map(
              (row) => DropdownMenuItem<int?>(
                value: row['id'] as int,
                child: Text('${row['ad']} ${row['sube'] ?? ''}'),
              ),
            ),
          ],
          onChanged: onClass,
        ),
        TextField(
          controller: subjectController,
          decoration: InputDecoration(labelText: strings.t('subjectLabel')),
        ),
        TextField(
          controller: classController,
          decoration: InputDecoration(labelText: strings.t('classGroupLabel')),
        ),
      ],
    );
  }

  Future<void> _deletePlan(int id) async {
    await context.read<AppState>().db.deleteDailyPlan(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => runAcademicPlanImport(
                  context,
                  kind: AcademicPlanImportKind.daily,
                  onComplete: _load,
                ),
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(strings.t('academicPlanImport')),
              ),
              FilledButton.icon(
                onPressed: () => _editPlan(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.t('dailyPlanAdd')),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _plans.isEmpty
              ? AppEmptyState(
                  icon: Icons.today_outlined,
                  title: strings.t('dailyPlansEmpty'),
                )
              : ListView.separated(
                  itemCount: _plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final subject = academicPlanSubjectLabel(plan);
                    final classLabel = academicPlanClassLabel(plan);
                    return AppCard(
                      child: ListTile(
                        title: Text(
                          '${plan['tarih']} · $subject${classLabel.isNotEmpty ? ' · $classLabel' : ''}',
                        ),
                        subtitle: Text(plan['konu'] as String? ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editPlan(existing: plan),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deletePlan(plan['id'] as int),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
