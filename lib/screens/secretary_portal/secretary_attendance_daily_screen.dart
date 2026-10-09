import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_attendance_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/attendance_status.dart';
import '../../utils/course_form_options.dart';
import 'secretary_attendance_ui.dart';
import 'secretary_ui/secretary_design.dart';
import 'secretary_ui/secretary_paginated_table.dart';

class SecretaryAttendanceDailyScreen extends StatefulWidget {
  const SecretaryAttendanceDailyScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SecretaryAttendanceDailyScreen> createState() =>
      _SecretaryAttendanceDailyScreenState();
}

class _SecretaryAttendanceDailyScreenState
    extends State<SecretaryAttendanceDailyScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _gradeFilter;
  String? _sectionFilter;
  int _reload = 0;
  bool _busy = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveStatus(
    SecretaryAttendanceService service,
    int studentId,
    AttendanceStatus status,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await service.setStudentStatus(
        studentId: studentId,
        date: _selectedDate,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('attendanceSaved')),
          ),
        );
        setState(() => _reload++);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bulk(
    SecretaryAttendanceService service,
    List<int> ids,
    AttendanceStatus status,
  ) async {
    if (_busy || ids.isEmpty) return;
    setState(() => _busy = true);
    try {
      await service.bulkSetStatus(
        studentIds: ids,
        date: _selectedDate,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('attendanceSaved')),
          ),
        );
        setState(() => _reload++);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canViewAttendance) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final db = context.read<AppState>().db;
    final service = SecretaryAttendanceService(db);
    final classService = SecretaryStudentService(db);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;
    final canEdit = auth.canEditAttendance;
    return FutureBuilder(
      key: ValueKey(
        'daily-$_reload-${attendanceDateKey(_selectedDate)}-'
        '$_gradeFilter-$_sectionFilter',
      ),
      future: Future.wait([
        service.loadDaily(
          date: _selectedDate,
          gradeFilter: _gradeFilter,
          sectionFilter: _sectionFilter,
        ),
        classService.listStudentClasses(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data![0] as List<SecretaryAttendanceStudentRow>;
        final classes = snapshot.data![1] as List<Map<String, Object?>>;
        final gradeOptions = _gradeOptions(classes);
        final sectionOptions = _sectionOptions(classes);
        final studentIds = rows.map((r) => r.studentId).toList();

        final toolbar = SecretaryGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isPhone ? double.infinity : 240,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        '${strings.t('attendanceDate')}: ${attendanceDateKey(_selectedDate)}',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isPhone ? double.infinity : 200,
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
                    width: isPhone ? double.infinity : 160,
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
                ],
              ),
              if (canEdit && rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AttendanceBulkActionButton(
                      label: strings.t('attendanceMarkAllPresent'),
                      status: AttendanceStatus.present,
                      enabled: !_busy,
                      onPressed: () =>
                          _bulk(service, studentIds, AttendanceStatus.present),
                    ),
                    AttendanceBulkActionButton(
                      label: strings.t('attendanceMarkAllAbsent'),
                      status: AttendanceStatus.absent,
                      enabled: !_busy,
                      onPressed: () =>
                          _bulk(service, studentIds, AttendanceStatus.absent),
                    ),
                    AttendanceBulkActionButton(
                      label: strings.t('attendanceMarkAllExcused'),
                      status: AttendanceStatus.excused,
                      enabled: !_busy,
                      onPressed: () =>
                          _bulk(service, studentIds, AttendanceStatus.excused),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

        final body = _buildBody(
          context,
          strings: strings,
          rows: rows,
          canEdit: canEdit,
          service: service,
          isPhone: isPhone,
          fillHeight: widget.embedded,
        );

        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            const SizedBox(height: 16),
            Expanded(child: body),
          ],
        );

        if (widget.embedded) {
          return column;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolbar,
              const SizedBox(height: 16),
              _buildBody(
                context,
                strings: strings,
                rows: rows,
                canEdit: canEdit,
                service: service,
                isPhone: isPhone,
                fillHeight: false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AppLocalizations strings,
    required List<SecretaryAttendanceStudentRow> rows,
    required bool canEdit,
    required SecretaryAttendanceService service,
    required bool isPhone,
    required bool fillHeight,
  }) {
    if (rows.isEmpty) {
      return SecretaryGlassCard(
        blur: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(strings.t('noStudents')),
          ),
        ),
      );
    }

    if (isPhone) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        itemBuilder: (context, index) =>
            _phoneRow(context, strings, rows[index], canEdit, service),
      );
    }

    return SecretaryPaginatedTable(
      fillHeight: fillHeight,
      pageSize: 25,
      columns: [
        DataColumn(label: Text(strings.t('studentNumber'))),
        DataColumn(label: Text(strings.t('studentName'))),
        DataColumn(label: Text(strings.t('studentClassName'))),
        DataColumn(label: Text(strings.t('studentClassSection'))),
        DataColumn(label: Text(strings.t('attendanceStatusLabel'))),
      ],
      rowCount: rows.length,
      rowBuilder: (context, index) {
        final row = rows[index];
        return DataRow(
          cells: [
            DataCell(Text('${row.number}')),
            DataCell(Text(row.name)),
            DataCell(Text(row.gradeLabel)),
            DataCell(Text(row.section)),
            DataCell(
              AttendanceStatusPillGroup(
                strings: strings,
                value: row.status,
                enabled: canEdit && !_busy,
                compact: true,
                onChanged: (v) => _saveStatus(service, row.studentId, v),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _phoneRow(
    BuildContext context,
    AppLocalizations strings,
    SecretaryAttendanceStudentRow row,
    bool canEdit,
    SecretaryAttendanceService service,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SecretaryGlassCard(
        blur: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${row.number} — ${row.name}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text('${row.gradeLabel} / ${row.section}'),
            const SizedBox(height: 10),
            AttendanceStatusPillGroup(
              strings: strings,
              value: row.status,
              enabled: canEdit && !_busy,
              onChanged: (v) => _saveStatus(service, row.studentId, v),
            ),
          ],
        ),
      ),
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
