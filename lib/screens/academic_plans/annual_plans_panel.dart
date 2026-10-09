import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import 'academic_plan_import_actions.dart';
import 'academic_plan_labels.dart';
import '../../services/academic_plan_import_service.dart';

class AnnualPlansPanel extends StatefulWidget {
  const AnnualPlansPanel({super.key});

  @override
  State<AnnualPlansPanel> createState() => _AnnualPlansPanelState();
}

class _AnnualPlansPanelState extends State<AnnualPlansPanel> {
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
    _plans = await db.getAnnualPlans();
    _lessons = await db.listLessonsForAcademicPlanning();
    _studentClasses = await db.getStudentClasses();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editPlan({Map<String, Object?>? existing}) async {
    final strings = AppLocalizations.of(context);
    final yearController = TextEditingController(
      text: existing?['ogretim_yili'] as String? ?? '',
    );
    final unitController = TextEditingController(
      text: existing?['unite_konu'] as String? ?? '',
    );
    final periodController = TextEditingController(
      text: existing?['planlanan_donem'] as String? ?? '',
    );
    final hoursController = TextEditingController(
      text: '${existing?['ders_saati'] ?? ''}',
    );
    final objectivesController = TextEditingController(
      text: existing?['hedefler'] as String? ?? '',
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
          existing == null ? strings.t('annualPlanAdd') : strings.t('edit'),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: yearController,
                  decoration:
                      InputDecoration(labelText: strings.t('academicYear')),
                ),
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
                  onChanged: (v) => lessonId = v,
                ),
                DropdownButtonFormField<int?>(
                  value: studentClassId,
                  decoration:
                      InputDecoration(labelText: strings.t('selectClass')),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('—')),
                    ..._studentClasses.map(
                      (row) => DropdownMenuItem<int?>(
                        value: row['id'] as int,
                        child: Text('${row['ad']} ${row['sube'] ?? ''}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => studentClassId = v,
                ),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(labelText: strings.t('subjectLabel')),
                ),
                TextField(
                  controller: classController,
                  decoration:
                      InputDecoration(labelText: strings.t('classGroupLabel')),
                ),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(labelText: strings.t('unitTopic')),
                ),
                TextField(
                  controller: periodController,
                  decoration:
                      InputDecoration(labelText: strings.t('plannedPeriod')),
                ),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: strings.t('lessonHours')),
                ),
                TextField(
                  controller: objectivesController,
                  decoration:
                      InputDecoration(labelText: strings.t('learningObjectives')),
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

    final hours = int.tryParse(hoursController.text.trim());
    final values = {
      'ogretim_yili': yearController.text.trim(),
      'ders_id': lessonId,
      'ogrenci_sinif_id': studentClassId,
      'konu_metin': subjectController.text.trim(),
      'sinif_metin': classController.text.trim(),
      'unite_konu': unitController.text.trim(),
      'planlanan_donem': periodController.text.trim(),
      'ders_saati': hours,
      'hedefler': objectivesController.text.trim(),
      'notlar': notesController.text.trim(),
    };
    final db = context.read<AppState>().db;
    if (existing == null) {
      await db.insertAnnualPlan(values);
    } else {
      await db.updateAnnualPlan(existing['id'] as int, values);
    }
    await _load();
  }

  Future<void> _deletePlan(int id) async {
    await context.read<AppState>().db.deleteAnnualPlan(id);
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
                  kind: AcademicPlanImportKind.annual,
                  onComplete: _load,
                ),
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(strings.t('academicPlanImport')),
              ),
              FilledButton.icon(
                onPressed: () => _editPlan(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.t('annualPlanAdd')),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _plans.isEmpty
              ? AppEmptyState(
                  icon: Icons.date_range_outlined,
                  title: strings.t('annualPlansEmpty'),
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
                          '${plan['ogretim_yili']} · $subject${classLabel.isNotEmpty ? ' · $classLabel' : ''}',
                        ),
                        subtitle: Text(plan['unite_konu'] as String? ?? ''),
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
