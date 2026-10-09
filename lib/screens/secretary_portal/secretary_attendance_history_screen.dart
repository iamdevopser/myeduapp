import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_attendance_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/course_form_options.dart';
import 'secretary_attendance_ui.dart';
import 'secretary_ui/secretary_design.dart';
import 'secretary_ui/secretary_paginated_table.dart';

class SecretaryAttendanceHistoryScreen extends StatefulWidget {
  const SecretaryAttendanceHistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SecretaryAttendanceHistoryScreen> createState() =>
      _SecretaryAttendanceHistoryScreenState();
}

class _SecretaryAttendanceHistoryScreenState
    extends State<SecretaryAttendanceHistoryScreen> {
  late DateTime _from;
  late DateTime _to;
  int? _gradeFilter;
  String? _sectionFilter;
  int? _studentFilter;
  int _reload = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focusId = context.read<AppState>().secretaryFocusStudentId;
    if (focusId != null && _studentFilter != focusId) {
      setState(() => _studentFilter = focusId);
    }
  }

  Future<void> _pickRange(bool isStart) async {
    final initial = isStart ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canViewAttendance) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = SecretaryAttendanceService(state.db);
    final studentService = SecretaryStudentService(state.db);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder(
      key: ValueKey(
        'hist-$_reload-$_from-$_to-$_gradeFilter-$_sectionFilter-$_studentFilter',
      ),
      future: Future.wait([
        service.loadHistory(
          from: _from,
          to: _to,
          gradeFilter: _gradeFilter,
          sectionFilter: _sectionFilter,
          studentIdFilter: _studentFilter,
        ),
        studentService.listStudents(),
        studentService.listStudentClasses(),
        if (_studentFilter != null)
          service.studentSummary(_studentFilter!)
        else
          Future.value(
            const StudentAttendanceSummary(absentCount: 0, excusedCount: 0),
          ),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final history =
            snapshot.data![0] as List<SecretaryAttendanceHistoryRow>;
        final students = snapshot.data![1] as List<Map<String, Object?>>;
        final classes = snapshot.data![2] as List<Map<String, Object?>>;
        final summary = snapshot.data![3] as StudentAttendanceSummary;
        final gradeOptions = _gradeOptions(classes);
        final sectionOptions = _sectionOptions(classes);

        final toolbar = SecretaryGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isPhone ? double.infinity : 200,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickRange(true),
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        '${strings.t('attendanceDateFrom')}: ${_fmt(_from)}',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isPhone ? double.infinity : 200,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickRange(false),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        '${strings.t('attendanceDateTo')}: ${_fmt(_to)}',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isPhone ? double.infinity : 180,
                    child: DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _gradeFilter,
                      decoration: InputDecoration(
                        labelText: strings.t('studentClassName'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(strings.t('filterAll')),
                        ),
                        ...gradeOptions.map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(CourseFormOptions.gradeLabel(g)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _gradeFilter = v),
                    ),
                  ),
                  SizedBox(
                    width: isPhone ? double.infinity : 140,
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _sectionFilter,
                      decoration: InputDecoration(
                        labelText: strings.t('studentClassSection'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(strings.t('filterAll')),
                        ),
                        ...sectionOptions.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _sectionFilter = v),
                    ),
                  ),
                  SizedBox(
                    width: isPhone ? double.infinity : 280,
                    child: DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _studentFilter,
                      decoration: InputDecoration(
                        labelText: strings.t('studentName'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(strings.t('filterAll')),
                        ),
                        ...students.map(
                          (s) => DropdownMenuItem(
                            value: s['id'] as int,
                            child: Text(
                              '${s['numara']} — ${s['ad_soyad']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _studentFilter = v),
                    ),
                  ),
                ],
              ),
              if (_studentFilter != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${strings.t('attendanceTotalAbsent')}: ${summary.absentCount} · '
                  '${strings.t('attendanceTotalExcused')}: ${summary.excusedCount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        );

        final body = _buildHistoryBody(
          strings: strings,
          history: history,
          isPhone: isPhone,
          fillHeight: widget.embedded,
        );

        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolbar,
              const SizedBox(height: 16),
              Expanded(child: body),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [toolbar, const SizedBox(height: 16), body],
          ),
        );
      },
    );
  }

  Widget _buildHistoryBody({
    required AppLocalizations strings,
    required List<SecretaryAttendanceHistoryRow> history,
    required bool isPhone,
    required bool fillHeight,
  }) {
    if (history.isEmpty) {
      return SecretaryGlassCard(
        blur: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(strings.t('studentPortalNoAttendance')),
          ),
        ),
      );
    }

    if (isPhone) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final row = history[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SecretaryGlassCard(
              blur: false,
              child: ListTile(
                title: Text('${row.number} — ${row.studentName}'),
                subtitle: Text(
                  '${row.date} · ${row.gradeLabel}/${row.section}',
                ),
                trailing: AttendanceStatusReadonlyBadge(
                  strings: strings,
                  status: row.status,
                ),
              ),
            ),
          );
        },
      );
    }

    return SecretaryPaginatedTable(
      fillHeight: fillHeight,
      pageSize: 30,
      columns: [
        DataColumn(label: Text(strings.t('attendanceDate'))),
        DataColumn(label: Text(strings.t('studentName'))),
        DataColumn(label: Text(strings.t('studentClassName'))),
        DataColumn(label: Text(strings.t('studentClassSection'))),
        DataColumn(label: Text(strings.t('attendanceStatusLabel'))),
      ],
      rowCount: history.length,
      rowBuilder: (context, index) {
        final row = history[index];
        return DataRow(
          cells: [
            DataCell(Text(row.date)),
            DataCell(Text('${row.number} ${row.studentName}')),
            DataCell(Text(row.gradeLabel)),
            DataCell(Text(row.section)),
            DataCell(
              AttendanceStatusReadonlyBadge(
                strings: strings,
                status: row.status,
              ),
            ),
          ],
        );
      },
    );
  }

  List<int> _gradeOptions(List<Map<String, Object?>> classes) {
    final set = <int>{};
    for (final c in classes) {
      set.add(CourseFormOptions.resolveGrade(c['ad'] as String?));
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<String> _sectionOptions(List<Map<String, Object?>> classes) {
    final set = <String>{};
    for (final c in classes) {
      final s = CourseFormOptions.resolveSection(c['sube'] as String?);
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList();
    list.sort();
    return list;
  }
}
