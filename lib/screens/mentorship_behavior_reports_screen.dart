import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/course_form_options.dart';
import '../utils/mentorship_helpers.dart';
import '../utils/teacher_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_shell.dart';
import 'mentorship_event_dialogs.dart';

class MentorshipBehaviorReportsScreen extends StatefulWidget {
  const MentorshipBehaviorReportsScreen({super.key, this.classId});

  final int? classId;

  @override
  State<MentorshipBehaviorReportsScreen> createState() =>
      _MentorshipBehaviorReportsScreenState();
}

class _MentorshipBehaviorReportsScreenState
    extends State<MentorshipBehaviorReportsScreen> {
  List<Map<String, Object?>> _classes = [];
  List<Map<String, Object?>> _students = [];
  List<Map<String, Object?>> _reports = [];
  int? _classId;
  int? _studentId;
  String? _behaviorType;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _classId = widget.classId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    _classes = await db.getMentorshipClasses();
    _classId ??= _classes.isNotEmpty ? _classes.first['id'] as int? : null;
    if (_classId != null) {
      _students = await db.getStudents(_classId!);
      if (_studentId != null &&
          _students.every((row) => row['id'] != _studentId)) {
        _studentId = null;
      }
      _reports = await db.getMentorshipBehaviorReports(
        classId: _classId,
        studentId: _studentId,
        fromDate: AppDatabase.scoreDateKey(_from),
        toDate: AppDatabase.scoreDateKey(_to),
        type: _behaviorType,
      );
    } else {
      _students = [];
      _reports = [];
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    await _load();
  }

  Future<void> _createReport() async {
    if (_classId == null) return;
    await showMentorshipBehaviorDialog(
      context: context,
      db: context.read<AppState>().db,
      classId: _classId!,
      students: _students,
      onSaved: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < AppSpacing.phoneBreakpoint;

    return AppShell(
      teacherSection: TeacherNavSection.mentorship,
      title: strings.t('behaviorReports'),
      subtitle: strings.t('mentorship'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        FilledButton.icon(
          onPressed: _classId == null ? null : _createReport,
          icon: const Icon(Icons.add, size: 18),
          label: Text(strings.t('behaviorReport')),
        ),
      ],
      child: ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = isPhone
                        ? 1
                        : (width < AppSpacing.shellBreakpoint ? 2 : 3);
                    final fieldWidth = isPhone
                        ? width
                        : (width - (columns - 1) * AppSpacing.md) / columns;

                    Widget filterField(Widget child) {
                      return SizedBox(
                        width: isPhone ? double.infinity : fieldWidth,
                        child: child,
                      );
                    }

                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        filterField(
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _classId,
                            decoration: InputDecoration(
                              labelText: strings.t('selectClass'),
                            ),
                            items: _classes
                                .map(
                                  (row) => DropdownMenuItem(
                                    value: row['id'] as int,
                                    child: Text(
                                      CourseFormOptions.studentClassLabel(
                                        row['ad'] as String,
                                        row['yil'] as String,
                                        section: row['sube'] as String?,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              _classId = value;
                              _studentId = null;
                              await _load();
                            },
                          ),
                        ),
                        filterField(
                          DropdownButtonFormField<int?>(
                            isExpanded: true,
                            initialValue: _studentId,
                            decoration: InputDecoration(
                              labelText: strings.t('studentName'),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  strings.t('allStudents'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ..._students.map(
                                (row) => DropdownMenuItem(
                                  value: row['id'] as int,
                                  child: Text(
                                    '${row['numara']} ${row['ad_soyad']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              _studentId = value;
                              await _load();
                            },
                          ),
                        ),
                        filterField(
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _behaviorType,
                            decoration: InputDecoration(
                              labelText: strings.t('behaviorType'),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  strings.t('allBehaviorTypes'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: MentorshipBehaviorType.positive,
                                child: Text(
                                  strings.t('positiveBehavior'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: MentorshipBehaviorType.improvement,
                                child: Text(
                                  strings.t('needsImprovement'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: MentorshipBehaviorType.attention,
                                child: Text(
                                  strings.t('needsAttention'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              _behaviorType = value;
                              await _load();
                            },
                          ),
                        ),
                        filterField(
                          OutlinedButton.icon(
                            onPressed: () => _pickDate(from: true),
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(AppDatabase.scoreDateKey(_from)),
                          ),
                        ),
                        filterField(
                          OutlinedButton.icon(
                            onPressed: () => _pickDate(from: false),
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(AppDatabase.scoreDateKey(_to)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _reports.isEmpty
                        ? AppEmptyState(
                            icon: Icons.psychology_outlined,
                            title: strings.t('noBehaviorReports'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: IntrinsicWidth(
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.background,
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(strings.t('studentName')),
                                    ),
                                    DataColumn(
                                      label: Text(strings.t('selectedDate')),
                                    ),
                                    DataColumn(
                                      label: Text(strings.t('behaviorType')),
                                    ),
                                    DataColumn(
                                      label: Text(strings.t('behaviorDescription')),
                                    ),
                                    DataColumn(
                                      label: Text(strings.t('importanceLevel')),
                                    ),
                                  ],
                                  rows: _reports.map((report) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(report['ad_soyad'] as String),
                                        ),
                                        DataCell(
                                          Text(report['tarih'] as String),
                                        ),
                                        DataCell(
                                          Text(
                                            mentorshipBehaviorTypeLabel(
                                              strings,
                                              report['tur'] as String,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${report['davranis'] ?? ''} ${report['aciklama'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(report['seviye'] as String? ?? '-'),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
