import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/course_form_options.dart';
import '../../utils/secretary_navigation.dart';
import '../../theme/design_system.dart';
import '../../widgets/design/design_list_page_header.dart';
import '../../widgets/design/design_surface_card.dart';
import 'secretary_ui/secretary_design.dart';
import 'secretary_ui/secretary_paginated_table.dart';
import '../../widgets/app_card.dart';
import '../../widgets/student_profile_dialogs.dart';

class SecretaryStudentsListScreen extends StatefulWidget {
  const SecretaryStudentsListScreen({
    super.key,
    this.embedded = false,
    this.onAddStudent,
  });

  final bool embedded;
  final VoidCallback? onAddStudent;

  @override
  State<SecretaryStudentsListScreen> createState() =>
      _SecretaryStudentsListScreenState();
}

class _SecretaryStudentsListScreenState
    extends State<SecretaryStudentsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _gradeFilter;
  String? _sectionFilter;
  int _reloadToken = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canViewStudents) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = SecretaryStudentService(context.read<AppState>().db);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder<List<List<Map<String, Object?>>>>(
      key: ValueKey(_reloadToken),
      future: Future.wait<List<Map<String, Object?>>>([
        service.listStudents(),
        service.listStudentClasses(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data![0];
        final classes = snapshot.data![1];
        final filtered = _applyFilters(students);
        final gradeOptions = _gradeOptions(classes);
        final sectionOptions = _sectionOptions(classes);

        final filters = _buildFilterCard(
          strings: strings,
          isPhone: isPhone,
          gradeOptions: gradeOptions,
          sectionOptions: sectionOptions,
        );

        final results = _buildResultsBody(
          context: context,
          strings: strings,
          auth: auth,
          classes: classes,
          filtered: filtered,
          isPhone: isPhone,
          fillHeight: widget.embedded,
        );

        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filters,
              const SizedBox(height: 16),
              Expanded(child: results),
            ],
          );
        }

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesignListPageHeader(
                title: strings.t('secretaryStudentsMenu'),
                searchField: null,
                primaryAction: widget.onAddStudent != null
                    ? FilledButton.icon(
                        onPressed: widget.onAddStudent,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(strings.t('studentPlatformNewStudent')),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              filters,
              const SizedBox(height: 16),
              results,
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterCard({
    required AppLocalizations strings,
    required bool isPhone,
    required List<int> gradeOptions,
    required List<String> sectionOptions,
  }) {
    return DesignSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: strings.t('secretarySearchStudents'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DesignSystem.cardBorder),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SizedBox(
                width: isPhone ? double.infinity : 200,
                child: DropdownButtonFormField<int?>(
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
        ],
      ),
    );
  }

  Widget _buildResultsBody({
    required BuildContext context,
    required AppLocalizations strings,
    required AuthorizationService auth,
    required List<Map<String, Object?>> classes,
    required List<Map<String, Object?>> filtered,
    required bool isPhone,
    required bool fillHeight,
  }) {
    if (filtered.isEmpty) {
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
        itemCount: filtered.length,
        itemBuilder: (context, index) => _StudentCard(
          row: filtered[index],
          strings: strings,
          auth: auth,
          classes: classes,
          onChanged: _reload,
        ),
      );
    }

    return SecretaryPaginatedTable(
      fillHeight: fillHeight,
      columns: [
        DataColumn(label: Text(strings.t('studentName'))),
        DataColumn(label: Text(strings.t('studentNumber'))),
        DataColumn(label: Text(strings.t('studentClassName'))),
        DataColumn(label: Text(strings.t('studentClassSection'))),
        DataColumn(label: Text(strings.t('secretaryStudentStatus'))),
        DataColumn(label: Text(strings.t('edit'))),
      ],
      rowCount: filtered.length,
      rowBuilder: (context, index) {
        final row = filtered[index];
        final id = row['id'] as int;
        final grade = CourseFormOptions.resolveGrade(
          row['sinif_ad'] as String?,
        );
        final section = CourseFormOptions.resolveSection(
          row['sinif_sube'] as String?,
        );
        return DataRow(
          cells: [
            DataCell(
              InkWell(
                onTap: () =>
                    openSecretaryStudentDetail(context, id, studentRow: row),
                child: Text(
                  row['ad_soyad'] as String? ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ),
            DataCell(Text('${row['numara'] ?? ''}')),
            DataCell(Text(CourseFormOptions.gradeLabel(grade))),
            DataCell(Text(section)),
            DataCell(
              SecretaryStatusBadge(
                label: strings.t('secretaryStatusActive'),
                tone: SecretaryBadgeTone.success,
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (auth.canManageStudentParentRelation)
                    IconButton(
                      icon: const Icon(Icons.family_restroom_outlined),
                      tooltip: strings.t('secretaryStudentParents'),
                      onPressed: () => openSecretaryStudentParents(context, id),
                    ),
                  if (auth.canViewAttendance)
                    IconButton(
                      icon: const Icon(Icons.event_busy_outlined),
                      tooltip: strings.t('secretaryAttendanceHistory'),
                      onPressed: () =>
                          openSecretaryStudentAttendanceHistory(context, id),
                    ),
                  if (auth.canEditStudent)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: strings.t('edit'),
                      onPressed: () => _editStudent(context, id, row, classes),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, Object?>> _applyFilters(
    List<Map<String, Object?>> students,
  ) {
    return students.where((row) {
      final name = (row['ad_soyad'] as String? ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty &&
          !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_gradeFilter != null) {
        final grade = CourseFormOptions.resolveGrade(
          row['sinif_ad'] as String?,
        );
        if (grade != _gradeFilter) return false;
      }
      if (_sectionFilter != null) {
        final section = CourseFormOptions.resolveSection(
          row['sinif_sube'] as String?,
        );
        if (section != _sectionFilter) return false;
      }
      return true;
    }).toList();
  }

  List<int> _gradeOptions(List<Map<String, Object?>> classes) {
    final grades = classes
        .map((c) => CourseFormOptions.resolveGrade(c['ad'] as String?))
        .toSet()
        .toList();
    grades.sort();
    return grades;
  }

  List<String> _sectionOptions(List<Map<String, Object?>> classes) {
    final sections = classes
        .map((c) => CourseFormOptions.resolveSection(c['sube'] as String?))
        .toSet()
        .toList();
    sections.sort(
      (a, b) => CourseFormOptions.sectionSortIndex(
        a,
      ).compareTo(CourseFormOptions.sectionSortIndex(b)),
    );
    return sections;
  }

  Future<void> _editStudent(
    BuildContext context,
    int studentId,
    Map<String, Object?> row,
    List<Map<String, Object?>> classes,
  ) async {
    final strings = AppLocalizations.of(context);
    final service = SecretaryStudentService(context.read<AppState>().db);
    final student = Map<String, Object?>.from(row);
    student['sinif_id'] = row['sinif_id'];
    final updated = await showStudentProfileEditDialog(
      context,
      student: student,
      classOptions: classes,
    );
    if (updated == null) return;
    await service.updateStudentProfile(
      studentId: studentId,
      number: updated['number'] as int,
      name: updated['name'] as String,
      email: updated['email'] as String?,
      motherEmail: updated['motherEmail'] as String?,
      fatherEmail: updated['fatherEmail'] as String?,
      classId: updated['classId'] as int?,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('secretaryStudentSaved'))));
    await _reload();
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.row,
    required this.strings,
    required this.auth,
    required this.classes,
    required this.onChanged,
  });

  final Map<String, Object?> row;
  final AppLocalizations strings;
  final AuthorizationService auth;
  final List<Map<String, Object?>> classes;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final parsed = CourseFormOptions.parseGradeFromName(
      row['sinif_ad'] as String? ?? '',
    );
    final section = CourseFormOptions.resolveSection(
      row['sinif_sube'] as String?,
    );
    final classLabel = parsed != null
        ? CourseFormOptions.gradeLabel(parsed)
        : row['sinif_ad'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => openSecretaryStudentDetail(
          context,
          row['id'] as int,
          studentRow: row,
        ),
        child: ListTile(
          title: Text(row['ad_soyad'] as String? ?? ''),
          subtitle: Text(
            '${strings.t('studentNumber')}: ${row['numara'] ?? ''} · '
            '$classLabel $section · ${strings.t('secretaryStatusActive')}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (auth.canManageStudentParentRelation)
                IconButton(
                  icon: const Icon(Icons.family_restroom_outlined),
                  onPressed: () =>
                      openSecretaryStudentParents(context, row['id'] as int),
                ),
              if (auth.canViewAttendance)
                IconButton(
                  icon: const Icon(Icons.event_busy_outlined),
                  onPressed: () => openSecretaryStudentAttendanceHistory(
                    context,
                    row['id'] as int,
                  ),
                ),
              if (auth.canEditStudent)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final state = context.read<AppState>();
                    final service = SecretaryStudentService(state.db);
                    final id = row['id'] as int;
                    final updated = await showStudentProfileEditDialog(
                      context,
                      student: row,
                      classOptions: classes,
                    );
                    if (updated == null) return;
                    await service.updateStudentProfile(
                      studentId: id,
                      number: updated['number'] as int,
                      name: updated['name'] as String,
                      email: updated['email'] as String?,
                      motherEmail: updated['motherEmail'] as String?,
                      fatherEmail: updated['fatherEmail'] as String?,
                      classId: updated['classId'] as int?,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.t('secretaryStudentSaved')),
                        ),
                      );
                      await onChanged();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
