import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';
import '../../utils/course_form_options.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/design/design_info_row.dart';
import '../../widgets/design/design_pill_tabs.dart';
import '../../widgets/design/design_surface_card.dart';
import '../../widgets/student_profile_dialogs.dart';
import 'secretary_student_grades_panel.dart';

/// Tasarım 05 — öğrenci detay.
class SecretaryStudentDetailScreen extends StatefulWidget {
  const SecretaryStudentDetailScreen({
    super.key,
    required this.studentId,
    this.initialRow,
  });

  final int studentId;
  final Map<String, Object?>? initialRow;

  @override
  State<SecretaryStudentDetailScreen> createState() =>
      _SecretaryStudentDetailScreenState();
}

class _SecretaryStudentDetailScreenState
    extends State<SecretaryStudentDetailScreen> {
  int _tab = 0;
  Map<String, Object?>? _student;
  List<Map<String, Object?>> _parents = const [];
  List<Map<String, Object?>> _classes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _student = widget.initialRow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final db = context.read<AppState>().db;
    final service = SecretaryStudentService(db);
    final students = await service.listStudents();
    final row = students.cast<Map<String, Object?>>().firstWhere(
      (r) => r['id'] == widget.studentId,
      orElse: () => _student ?? {},
    );
    final parents = await db.listParentsForStudent(widget.studentId);
    final classes = await service.listStudentClasses();
    if (!mounted) return;
    setState(() {
      _student = row.isEmpty ? _student : row;
      _parents = parents;
      _classes = classes;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final auth = AuthorizationService(context.read<AppState>());
    if (!auth.canEditStudent || _student == null) return;
    final strings = AppLocalizations.of(context);
    final service = SecretaryStudentService(context.read<AppState>().db);
    final updated = await showStudentProfileEditDialog(
      context,
      student: Map<String, Object?>.from(_student!),
      classOptions: _classes,
    );
    if (updated == null) return;
    await service.updateStudentProfile(
      studentId: widget.studentId,
      number: updated['number'] as int,
      name: updated['name'] as String,
      email: updated['email'] as String?,
      motherEmail: updated['motherEmail'] as String?,
      fatherEmail: updated['fatherEmail'] as String?,
      classId: updated['classId'] as int?,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('secretaryStudentSaved'))));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.pagePadding(width);

    if (_loading && _student == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.t('studentDetailTitle'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final student = _student ?? {};
    final name = student['ad_soyad'] as String? ?? '';
    final number = '${student['numara'] ?? ''}';
    final classLabel = CourseFormOptions.studentClassGradeSectionLabel(
      student['sinif_ad'] as String? ?? '',
      section: student['sinif_sube'] as String?,
    );
    final parentName = _parents.isNotEmpty
        ? _parents.first['ad_soyad'] as String? ?? '—'
        : '—';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Scaffold(
      backgroundColor: DesignSystem.workspaceBackground,
      appBar: AppBar(
        title: Text(strings.t('studentDetailTitle')),
        actions: [
          if (auth.canEditStudent)
            Semantics(
              button: true,
              label: strings.t('edit'),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: strings.t('edit'),
                onPressed: _edit,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesignSurfaceCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: DesignSystem.pageTitle(
                                  context,
                                ).copyWith(fontSize: 20),
                              ),
                              Text(
                                '$classLabel · $number',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DesignPillTabs(
                    tabs: [
                      strings.t('designTabInfo'),
                      strings.t('designTabGrades'),
                      strings.t('designTabAttendance'),
                    ],
                    selectedIndex: _tab,
                    onSelected: (i) {
                      setState(() => _tab = i);
                      if (i == 2 && auth.canViewAttendance) {
                        openSecretaryStudentAttendanceHistory(
                          context,
                          widget.studentId,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0)
                    _infoTab(strings, name, classLabel, number, parentName),
                  if (_tab == 1)
                    SecretaryStudentGradesPanel(
                      classId:
                          student['sinif_id'] as int? ??
                          (_classes.isNotEmpty
                              ? _classes.first['id'] as int
                              : 0),
                      studentId: widget.studentId,
                      db: context.read<AppState>().db,
                    ),
                  if (_tab == 2)
                    DesignSurfaceCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          strings.t('secretaryAttendanceHistory'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: padding.copyWith(top: 8, bottom: 12),
              child: Row(
                children: [
                  if (auth.canEditStudent)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _edit,
                        child: Text(strings.t('edit')),
                      ),
                    ),
                  if (auth.canEditStudent) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.t('designSendMessageHint')),
                          ),
                        );
                      },
                      child: Text(strings.t('designSendMessage')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTab(
    AppLocalizations strings,
    String name,
    String classLabel,
    String number,
    String parentName,
  ) {
    return DesignSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          DesignInfoRow(
            icon: Icons.person_outline,
            label: strings.t('studentName'),
            value: name,
          ),
          DesignInfoRow(
            icon: Icons.class_outlined,
            label: strings.t('studentClassName'),
            value: classLabel,
          ),
          DesignInfoRow(
            icon: Icons.badge_outlined,
            label: strings.t('studentNumber'),
            value: number,
          ),
          DesignInfoRow(
            icon: Icons.family_restroom_outlined,
            label: strings.t('parentPortalTitle'),
            value: parentName,
          ),
          DesignInfoRow(
            icon: Icons.check_circle_outline,
            label: strings.t('secretaryStudentStatus'),
            value: strings.t('studentStatusActive'),
            valueColor: const Color(0xFF16A34A),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
