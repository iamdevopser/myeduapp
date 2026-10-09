import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/models/student_category_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/course_form_options.dart';
import '../utils/email_validation.dart';
import '../utils/app_navigation.dart';
import '../utils/teacher_activity.dart';
import '../utils/student_navigation.dart';
import '../utils/teacher_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_shell.dart';
import '../utils/bulk_score_grading.dart';
import '../widgets/score_dropdown.dart';
import '../widgets/student_profile_dialogs.dart';
import 'student_behaviors_panel.dart';
import 'student_report_screen.dart';
import 'teacher_student_announcements_screen.dart';

IconData studentCategoryIcon(String code) {
  switch (code) {
    case 'students':
      return Icons.people_outline;
    case 'performance':
      return Icons.insights_outlined;
    case 'materials':
      return Icons.folder_outlined;
    case 'activity':
    case 'activities':
      return Icons.event_outlined;
    case 'homework':
      return Icons.assignment_outlined;
    case 'exam':
      return Icons.quiz_outlined;
    case 'behaviors':
      return Icons.fact_check_outlined;
    default:
      return Icons.category_outlined;
  }
}

class StudentPlatformScreen extends StatefulWidget {
  const StudentPlatformScreen({super.key, this.initialClassId});

  final int? initialClassId;

  @override
  State<StudentPlatformScreen> createState() => _StudentPlatformScreenState();
}

class _StudentPlatformScreenState extends State<StudentPlatformScreen> {
  int? _selectedClassId;
  String _selectedCategoryCode = 'students';
  int _menuEpoch = 0;
  final Set<int> _expandedClassIds = {};
  bool _sessionLoading = false;
  final Map<String, Set<int>> _hiddenStudentsByCategory = {};

  String _categoryHideKey(int classId, String categoryCode) =>
      '$classId:$categoryCode';

  Set<int> _hiddenStudentsFor(int classId, String categoryCode) {
    return _hiddenStudentsByCategory[_categoryHideKey(classId, categoryCode)] ??
        {};
  }

  void _hideStudentFromCategory(int classId, String categoryCode, int studentId) {
    _hiddenStudentsByCategory
        .putIfAbsent(_categoryHideKey(classId, categoryCode), () => {})
        .add(studentId);
    setState(() {});
  }

  void _selectCategory(int classId, String code, {VoidCallback? onDone}) {
    if (code != 'students') {
      _hiddenStudentsByCategory.remove(_categoryHideKey(classId, code));
    }
    setState(() {
      _selectedClassId = classId;
      _selectedCategoryCode = code;
    });
    onDone?.call();
  }

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    if (_selectedClassId != null) {
      _expandedClassIds.add(_selectedClassId!);
    }
  }

  Future<void> _ensureStudentSession(
    AppState state,
    AppLocalizations strings,
  ) async {
    if (state.isTeacher || state.sessionStudentId != null || _sessionLoading) {
      return;
    }
    setState(() => _sessionLoading = true);
    final classes = await state.db.getStudentClasses();
    final options = <({int classId, int studentId, String label})>[];
    for (final row in classes) {
      final classId = row['id'] as int;
      final className = row['ad'] as String;
      final students = await state.db.getStudents(classId);
      for (final student in students) {
        options.add((
          classId: classId,
          studentId: student['id'] as int,
          label: '$className — ${student['ad_soyad']}',
        ));
      }
    }
    if (!mounted) return;
    if (options.isEmpty) {
      setState(() => _sessionLoading = false);
      return;
    }
    ({int classId, int studentId, String label})? picked;
    if (options.length == 1) {
      picked = options.first;
    } else {
      picked = await showDialog<({int classId, int studentId, String label})>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(strings.t('studentName')),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppSpacing.dialogMaxWidth(
                  MediaQuery.sizeOf(dialogContext).width,
                ),
                maxHeight: 360,
              ),
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(option.label),
                    onTap: () => Navigator.pop(dialogContext, option),
                  );
                },
              ),
            ),
          );
        },
      );
    }
    if (!mounted) return;
    if (picked != null) {
      final selected = picked;
      state.setStudentSession(
        classId: selected.classId,
        studentId: selected.studentId,
      );
      final categories =
          await state.db.getStudentCategories(selected.classId, activeOnly: true);
      final defaultCategory = categories
          .map((c) => c.code)
          .where((code) => code != 'students')
          .firstOrNull;
      setState(() {
        _selectedClassId = selected.classId;
        _expandedClassIds.add(selected.classId);
        if (defaultCategory != null) {
          _selectedCategoryCode = defaultCategory;
        }
        _sessionLoading = false;
      });
    } else {
      setState(() => _sessionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isTeacher = state.isTeacher;
        if (!isTeacher) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) openStudentPortal(context);
          });
          return const Center(child: CircularProgressIndicator());
        }
        final activeClassId = _selectedClassId;

        return AppShell(
          teacherSection: TeacherNavSection.studentPlatform,
          title: strings.t('studentPlatform'),
          subtitle: strings.t('dashboardSubtitle'),
          leading: buildPushedScreenBackLeading(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              tooltip: strings.t('teacherAnnouncements'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TeacherStudentAnnouncementsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.assessment_outlined),
              tooltip: strings.t('reports'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentReportScreen(
                      initialClassId: _selectedClassId,
                    ),
                  ),
                );
              },
            ),
          ],
          child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isPhone = AppSpacing.isMobile(width);
                    final sidebarWidth = (width * 0.3).clamp(240.0, 380.0);
                    final sidebar = _buildClassSidebarPanel(
                      context: context,
                      state: state,
                      strings: strings,
                      isTeacher: isTeacher,
                      activeClassId: activeClassId,
                    );
                    final detail = activeClassId == null
                        ? AppEmptyState(
                            icon: Icons.class_rounded,
                            title: strings.t('selectClass'),
                            description: strings.t('noClassesYet'),
                          )
                        : _StudentClassDetail(
                            classId: activeClassId,
                            categoryCode: _selectedCategoryCode,
                            readOnly: false,
                            viewStudentId: null,
                            hiddenStudentIds: _hiddenStudentsFor(
                              activeClassId,
                              _selectedCategoryCode,
                            ),
                            onHideStudentFromCategory: (studentId) {
                              _hideStudentFromCategory(
                                activeClassId,
                                _selectedCategoryCode,
                                studentId,
                              );
                            },
                          );
                    if (isPhone) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMobileClassBar(
                            context: context,
                            state: state,
                            strings: strings,
                            activeClassId: activeClassId,
                            onOpenPanel: () => _showMobileClassPanel(
                              context,
                              state: state,
                              strings: strings,
                              isTeacher: isTeacher,
                              activeClassId: activeClassId,
                            ),
                          ),
                          Expanded(child: detail),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: sidebarWidth, child: sidebar),
                        Expanded(child: detail),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMobileClassBar({
    required BuildContext context,
    required AppState state,
    required AppLocalizations strings,
    required int? activeClassId,
    required VoidCallback onOpenPanel,
  }) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onOpenPanel,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.class_outlined, color: AppColors.primaryBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FutureBuilder<List<StudentCategory>>(
                  future: activeClassId == null
                      ? Future.value(<StudentCategory>[])
                      : state.db.getStudentCategories(activeClassId,
                          activeOnly: true),
                  builder: (context, catSnap) {
                    final categories = catSnap.data ?? [];
                    final category = categories
                        .where((c) => c.code == _selectedCategoryCode)
                        .firstOrNull;
                    return FutureBuilder<List<Map<String, Object?>>>(
                      future: activeClassId == null
                          ? Future.value(<Map<String, Object?>>[])
                          : state.db.getStudentClasses(),
                      builder: (context, classSnap) {
                        final classRow = (classSnap.data ?? [])
                            .where((r) => r['id'] == activeClassId)
                            .firstOrNull;
                        final classLabel = classRow == null
                            ? strings.t('selectClass')
                            : CourseFormOptions.studentClassLabel(
                                classRow['ad'] as String,
                                classRow['yil'] as String,
                                section: classRow['sube'] as String?,
                              );
                        final categoryLabel =
                            category?.name ?? strings.t('studentPlatform');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              categoryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileClassPanel(
    BuildContext context, {
    required AppState state,
    required AppLocalizations strings,
    required bool isTeacher,
    required int? activeClassId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.t('studentPlatform'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _buildClassSidebarPanel(
                    context: context,
                    state: state,
                    strings: strings,
                    isTeacher: isTeacher,
                    activeClassId: activeClassId,
                    scrollController: scrollController,
                    onItemSelected: () => Navigator.pop(sheetContext),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildClassSidebarPanel({
    required BuildContext context,
    required AppState state,
    required AppLocalizations strings,
    required bool isTeacher,
    required int? activeClassId,
    ScrollController? scrollController,
    VoidCallback? onItemSelected,
    bool showBottomBorder = false,
  }) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: showBottomBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : const Border(right: BorderSide(color: AppColors.border)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          children: [
                              if (isTeacher) ...[
                                Text(
                                  strings.t('addStudentClass'),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                _ClassForm(
                                  onCreate: (name, year, section) async {
                                    final id = await state.db.insertStudentClass(
                                      name,
                                      year,
                                      section: section,
                                    );
                                    setState(() {
                                      _selectedClassId = id;
                                      _selectedCategoryCode = 'students';
                                      _menuEpoch++;
                                    });
                                  },
                                ),
                                const Divider(height: 24),
                              ],
                              Text(
                                strings.t('studentPlatform'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (isTeacher)
                                FutureBuilder<List<Map<String, Object?>>>(
                        key: ValueKey('classes-$_menuEpoch'),
                        future: state.db.getStudentClasses(),
                        builder: (context, snapshot) {
                          final classes = snapshot.data ?? [];
                          return Column(
                            children: classes.map((row) {
                              final classId = row['id'] as int;
                              final isSelected = _selectedClassId == classId;
                              final isExpanded =
                                  _expandedClassIds.contains(classId);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TeacherClassRow(
                                    className: row['ad'] as String,
                                    classSubtitle:
                                        CourseFormOptions.studentClassSubtitle(
                                      row['yil'] as String,
                                      row['sube'] as String?,
                                    ),
                                    isSelected: isSelected,
                                    isExpanded: isExpanded,
                                    onToggleExpanded: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedClassIds.remove(classId);
                                        } else {
                                          _expandedClassIds.add(classId);
                                        }
                                      });
                                    },
                                    onSelect: () {
                                      setState(() {
                                        _expandedClassIds.add(classId);
                                        _selectedClassId = classId;
                                        _selectedCategoryCode = 'students';
                                      });
                                      onItemSelected?.call();
                                    },
                                    onManageCategories: () async {
                                      await _showManageCategories(
                                        context,
                                        state,
                                        classId,
                                      );
                                      setState(() => _menuEpoch++);
                                    },
                                    onEdit: () async {
                                      final updated = await _showEditClassDialog(
                                        context,
                                        row['ad'] as String,
                                        row['yil'] as String,
                                        row['sube'] as String?,
                                      );
                                      if (updated != null) {
                                        await state.db.updateStudentClass(
                                          classId,
                                          updated['name']!,
                                          updated['year']!,
                                          section: updated['section']!,
                                        );
                                        setState(() => _menuEpoch++);
                                      }
                                    },
                                    onDelete: () async {
                                      await state.db.deleteStudentClass(classId);
                                      setState(() {
                                        _menuEpoch++;
                                        _expandedClassIds.remove(classId);
                                        if (_selectedClassId == classId) {
                                          _selectedClassId = null;
                                          _selectedCategoryCode = 'students';
                                        }
                                      });
                                    },
                                    manageCategoriesLabel:
                                        strings.t('manageCategories'),
                                  ),
                                  if (isExpanded)
                                    _CategoryMenu(
                                      classId: classId,
                                      selectedCode: isSelected
                                          ? _selectedCategoryCode
                                          : '',
                                      epoch: _menuEpoch,
                                      showAddCategory: true,
                                      hideStudentsCategory: false,
                                      onSelect: (code) {
                                        _selectCategory(
                                          classId,
                                          code,
                                          onDone: onItemSelected,
                                        );
                                      },
                                      onAdd: () async {
                                        await _addCategory(
                                          context,
                                          state,
                                          classId,
                                        );
                                        setState(() => _menuEpoch++);
                                      },
                                    ),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      )
            else if (activeClassId != null)
              _CategoryMenu(
                classId: activeClassId,
                selectedCode: _selectedCategoryCode,
                epoch: _menuEpoch,
                showAddCategory: false,
                hideStudentsCategory: true,
                onSelect: (code) {
                  _selectCategory(
                    activeClassId,
                    code,
                    onDone: onItemSelected,
                  );
                },
                onAdd: () {},
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory(
    BuildContext context,
    AppState state,
    int classId,
  ) async {
    final strings = AppLocalizations.of(context);
    final name = await _showTextDialog(
      context,
      title: strings.t('addCategory'),
      label: strings.t('categoryName'),
    );
    if (name == null || name.isEmpty) return;
    final order = await state.db.getNextCategoryOrder(classId);
    await state.db.insertStudentCategory(
      classId: classId,
      name: name,
      code: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      order: order,
    );
  }

  Future<void> _showManageCategories(
    BuildContext context,
    AppState state,
    int classId,
  ) async {
    final strings = AppLocalizations.of(context);
    await showAppDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.t('manageCategories')),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppSpacing.dialogMaxWidth(
                    MediaQuery.sizeOf(dialogContext).width,
                  ),
                  maxHeight: 400,
                ),
                child: FutureBuilder<List<StudentCategory>>(
                  future: state.db.getStudentCategories(classId),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final canReorder = !category.isFixedSystemCategory;
                        final canMoveUp = canReorder &&
                            index > 0 &&
                            !categories[index - 1].isFixedSystemCategory;
                        final canMoveDown = canReorder &&
                            index < categories.length - 1 &&
                            !categories[index + 1].isFixedSystemCategory;
                        return ListTile(
                          title: Text(category.name),
                          subtitle: Text(
                            category.system
                                ? strings.t('cannotDeleteSystemCategory')
                                : category.code,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: category.active,
                                onChanged: (value) async {
                                  await state.db.updateStudentCategory(
                                    id: category.id,
                                    name: category.name,
                                    order: category.order,
                                    active: value,
                                  );
                                  setDialogState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: !canMoveUp
                                    ? null
                                    : () async {
                                        await state.db.swapStudentCategoryOrder(
                                          category.id,
                                          categories[index - 1].id,
                                        );
                                        setDialogState(() {});
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: !canMoveDown
                                    ? null
                                    : () async {
                                        await state.db.swapStudentCategoryOrder(
                                          category.id,
                                          categories[index + 1].id,
                                        );
                                        setDialogState(() {});
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final name = await _showTextDialog(
                                    context,
                                    title: strings.t('editCategory'),
                                    label: strings.t('categoryName'),
                                    initial: category.name,
                                  );
                                  if (name == null || name.isEmpty) return;
                                  await state.db.updateStudentCategory(
                                    id: category.id,
                                    name: name,
                                    order: category.order,
                                    active: category.active,
                                  );
                                  setDialogState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: category.system
                                    ? null
                                    : () async {
                                        final count = await state.db
                                            .countScoresForType(
                                          classId,
                                          category.code,
                                        );
                                        if (count > 0) {
                                          if (!context.mounted) return;
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text(strings.t('delete')),
                                              content: Text(
                                                strings.t(
                                                  'deleteCategoryWarning',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                                  child: Text(
                                                    strings.t('cancelSimple'),
                                                  ),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                                  child: Text(
                                                    strings.t('confirm'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed != true) return;
                                        }
                                        await state.db.clearStudentScoresForType(
                                          classId: classId,
                                          type: category.code,
                                        );
                                        await state.db.deleteStudentCategory(
                                          category.id,
                                        );
                                        setDialogState(() {});
                                      },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.t('cancelSimple')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showTextDialog(
    BuildContext context, {
    required String title,
    required String label,
    String? initial,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showEditClassDialog(
    BuildContext context,
    String currentName,
    String currentYear,
    String? currentSection,
  ) async {
    final strings = AppLocalizations.of(context);
    final years = CourseFormOptions.academicYearOptions();
    var selectedGrade = CourseFormOptions.resolveGrade(currentName);
    var selectedYear = CourseFormOptions.resolveAcademicYear(currentYear);
    var selectedSection =
        CourseFormOptions.resolveSection(currentSection);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.t('edit')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: strings.t('academicYear'),
                    ),
                    items: years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedYear = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedGrade,
                    decoration: InputDecoration(
                      labelText: strings.t('studentClassName'),
                    ),
                    items: CourseFormOptions.grades()
                        .map(
                          (grade) => DropdownMenuItem(
                            value: grade,
                            child: Text(CourseFormOptions.gradeLabel(grade)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedGrade = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: InputDecoration(
                      labelText: strings.t('studentClassSection'),
                    ),
                    items: CourseFormOptions.sectionOptions
                        .map(
                          (section) => DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedSection = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop({
                      'name': CourseFormOptions.gradeLabel(selectedGrade),
                      'year': selectedYear,
                      'section': selectedSection,
                    });
                  },
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu({
    required this.classId,
    required this.selectedCode,
    required this.epoch,
    required this.onSelect,
    required this.onAdd,
    this.showAddCategory = true,
    this.hideStudentsCategory = false,
  });

  final int classId;
  final String selectedCode;
  final int epoch;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final bool showAddCategory;
  final bool hideStudentsCategory;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: FutureBuilder<List<StudentCategory>>(
        key: ValueKey('cats-$classId-$epoch'),
        future: state.db.getStudentCategories(classId, activeOnly: true),
        builder: (context, snapshot) {
          final categories = (snapshot.data ?? [])
              .where((c) => !hideStudentsCategory || c.code != 'students')
              .where((c) => !StudentCategory.isPerformanceLegacyMenuCode(c.code))
              .toList();
          return Column(
            children: [
              ...categories.map(
                (category) {
                  final color = AppColors.categoryColor(category.code);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 8),
                    leading: Icon(
                      studentCategoryIcon(category.code),
                      size: 18,
                      color: color,
                    ),
                    title: Text(category.name),
                    selected: selectedCode == category.code,
                    selectedTileColor: color.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => onSelect(category.code),
                  );
                },
              ),
              if (showAddCategory)
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 8),
                  leading: const Icon(Icons.add, size: 18),
                  title: Text(strings.t('addCategory')),
                  onTap: onAdd,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassForm extends StatefulWidget {
  const _ClassForm({required this.onCreate});

  final Future<void> Function(String name, String year, String section)
      onCreate;

  @override
  State<_ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<_ClassForm> {
  final years = CourseFormOptions.academicYearOptions();
  late String _selectedYear;
  late int _selectedGrade;
  late String _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedYear = years.first;
    _selectedGrade = CourseFormOptions.minGrade;
    _selectedSection = CourseFormOptions.sectionOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedYear,
          decoration: InputDecoration(labelText: strings.t('academicYear')),
          items: years
              .map(
                (year) => DropdownMenuItem(
                  value: year,
                  child: Text(year),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedYear = value);
            }
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedGrade,
          decoration: InputDecoration(
            labelText: strings.t('studentClassName'),
          ),
          items: CourseFormOptions.grades()
              .map(
                (grade) => DropdownMenuItem(
                  value: grade,
                  child: Text(CourseFormOptions.gradeLabel(grade)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedGrade = value);
            }
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSection,
          decoration: InputDecoration(
            labelText: strings.t('studentClassSection'),
          ),
          items: CourseFormOptions.sectionOptions
              .map(
                (section) => DropdownMenuItem(
                  value: section,
                  child: Text(section),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedSection = value);
            }
          },
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            await widget.onCreate(
              CourseFormOptions.gradeLabel(_selectedGrade),
              _selectedYear,
              _selectedSection,
            );
          },
          child: Text(strings.t('addStudentClass')),
        ),
      ],
    );
  }
}

class _ReferenceStudentTable extends StatelessWidget {
  const _ReferenceStudentTable({
    required this.students,
    required this.classLabel,
    required this.readOnly,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Map<String, Object?>> students;
  final String classLabel;
  final bool readOnly;
  final AppLocalizations strings;
  final Future<void> Function(Map<String, Object?> student) onEdit;
  final Future<void> Function(Map<String, Object?> student) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _headerCell('ID', flex: 1, style: theme),
                _headerCell(strings.t('studentName'), flex: 4, style: theme),
                _headerCell(strings.t('studentClassName'), flex: 2, style: theme),
                _headerCell(strings.t('secretaryStudentStatus'), flex: 2, style: theme),
                if (!readOnly)
                  SizedBox(
                    width: AppSpacing.minTouchTarget * 2,
                    child: Text(
                      strings.t('adminAccountActions'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = students[index];
                final name = student['ad_soyad'] as String;
                final initial =
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('${student['numara']}'),
                      ),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  AppColors.referenceBlue.withValues(alpha: 0.12),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.referenceBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(classLabel)),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              strings.t('studentStatusActive'),
                              style: TextStyle(
                                color: AppColors.accentGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!readOnly)
                        SizedBox(
                          width: AppSpacing.minTouchTarget * 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => onEdit(student),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => onDelete(student),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {required int flex, required ThemeData style}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: style.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StudentClassDetail extends StatefulWidget {
  const _StudentClassDetail({
    required this.classId,
    required this.categoryCode,
    this.readOnly = false,
    this.viewStudentId,
    this.hiddenStudentIds = const {},
    this.onHideStudentFromCategory,
  });

  final int classId;
  final String categoryCode;
  final bool readOnly;
  final int? viewStudentId;
  final Set<int> hiddenStudentIds;
  final ValueChanged<int>? onHideStudentFromCategory;

  @override
  State<_StudentClassDetail> createState() => _StudentClassDetailState();
}

class _StudentClassDetailState extends State<_StudentClassDetail> {
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _bulkController = TextEditingController();
  final TextEditingController _listSearchController = TextEditingController();
  bool _sortStudentsByName = false;
  final ScrollController _scoresVerticalScrollController = ScrollController();
  final ScrollController _scoresHorizontalScrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  final Set<int> _bulkSelectedStudentIds = {};
  int? _bulkSelectedColumnId;
  String? _studentScoresDateKey;
  List<Map<String, Object?>>? _studentScores;
  bool _studentScoresLoading = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _bulkController.dispose();
    _listSearchController.dispose();
    _scoresVerticalScrollController.dispose();
    _scoresHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final content = widget.categoryCode == 'students'
        ? _buildStudentListSection(state, strings)
        : widget.categoryCode == StudentCategory.behaviorsCode
            ? StudentBehaviorsPanel(
                classId: widget.classId,
                readOnly: widget.readOnly,
                viewStudentId: widget.viewStudentId,
                hiddenStudentIds: widget.hiddenStudentIds,
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              )
            : StudentCategory.isPerformanceCode(widget.categoryCode)
                ? _buildScoresSection(
                    state,
                    strings,
                    performanceMode: true,
                  )
                : _buildScoresSection(
                    state,
                    strings,
                    type: widget.categoryCode,
                  );
    return Padding(padding: const EdgeInsets.all(16), child: content);
  }

  Widget _buildStudentListSection(AppState state, AppLocalizations strings) {
    final isPhone = context.isMobileLayout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.readOnly) ...[
          if (isPhone) ...[
            TextField(
              controller: _studentNameController,
              decoration: InputDecoration(
                labelText: strings.t('studentName'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final name = _studentNameController.text.trim();
                      if (name.isEmpty) return;
                      final number = await state.db.getNextStudentNumber(
                        widget.classId,
                      );
                      await state.db.insertStudent(
                        classId: widget.classId,
                        number: number,
                        name: name,
                      );
                      _studentNameController.clear();
                      setState(() {});
                    },
                    child: Text(strings.t('addStudent')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final names = _bulkController.text
                          .split('\n')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (names.isEmpty) return;
                      var number = await state.db.getNextStudentNumber(
                        widget.classId,
                      );
                      for (final name in names) {
                        await state.db.insertStudent(
                          classId: widget.classId,
                          number: number,
                          name: name,
                        );
                        number += 1;
                      }
                      _bulkController.clear();
                      setState(() {});
                    },
                    child: Text(strings.t('addStudentsBulk')),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _listSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: strings.t('studentName'),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _sortStudentsByName = !_sortStudentsByName);
                  },
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: Text(strings.t('filterButton')),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.referenceBlue,
                  ),
                  onPressed: () => _showNewStudentDialog(context, state, strings),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(strings.t('studentPlatformNewStudent')),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (isPhone) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _bulkController,
              decoration:
                  InputDecoration(labelText: strings.t('addStudentsBulk')),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
          ],
        ],
        Expanded(
          child: FutureBuilder<List<Object?>>(
            future: Future.wait<Object?>([
              state.db.getStudents(widget.classId),
              state.db.getStudentClassById(widget.classId),
            ]),
            builder: (context, snapshot) {
              final students =
                  (snapshot.data?[0] as List<Map<String, Object?>>?) ?? [];
              final classRow = snapshot.data?[1] as Map<String, Object?>?;
              var filtered = students;
              if (widget.viewStudentId != null) {
                filtered = filtered
                    .where((s) => s['id'] == widget.viewStudentId)
                    .toList();
              }
              final query = _listSearchController.text.trim().toLowerCase();
              if (query.isNotEmpty) {
                filtered = filtered
                    .where((s) => (s['ad_soyad'] as String)
                        .toLowerCase()
                        .contains(query))
                    .toList();
              }
              if (_sortStudentsByName) {
                filtered = List<Map<String, Object?>>.from(filtered);
                filtered.sort(
                  (a, b) => (a['ad_soyad'] as String)
                      .compareTo(b['ad_soyad'] as String),
                );
              }
              final classLabel = classRow == null
                  ? ''
                  : CourseFormOptions.studentClassSubtitle(
                      classRow['yil'] as String,
                      classRow['sube'] as String?,
                    );
              if (filtered.isEmpty) {
                return Center(child: Text(strings.t('noStudents')));
              }
              if (!isPhone) {
                return _ReferenceStudentTable(
                  students: filtered,
                  classLabel: classLabel,
                  readOnly: widget.readOnly,
                  strings: strings,
                  onEdit: (student) async {
                    final updated = await _showEditStudentDialog(
                      context,
                      student,
                    );
                    if (updated != null) {
                      await _saveStudentProfile(
                        context,
                        state: state,
                        strings: strings,
                        studentId: student['id'] as int,
                        updated: updated,
                      );
                      setState(() {});
                    }
                  },
                  onDelete: (student) async {
                    await state.db.deleteStudent(student['id'] as int);
                    setState(() {});
                  },
                );
              }
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = filtered[index];
                  return ListTile(
                    leading: Text('${student['numara']}'),
                    title: Text(student['ad_soyad'] as String),
                    trailing: widget.readOnly
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final updated = await _showEditStudentDialog(
                                    context,
                                    student,
                                  );
                                  if (updated != null) {
                                    await _saveStudentProfile(
                                      context,
                                      state: state,
                                      strings: strings,
                                      studentId: student['id'] as int,
                                      updated: updated,
                                    );
                                    setState(() {});
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await state.db.deleteStudent(
                                    student['id'] as int,
                                  );
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showNewStudentDialog(
    BuildContext context,
    AppState state,
    AppLocalizations strings,
  ) async {
    final nameController = TextEditingController();
    final bulkController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.t('studentPlatformNewStudent')),
          content: SizedBox(
            width: AppSpacing.dialogMaxWidth(MediaQuery.sizeOf(context).width),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: strings.t('studentName'),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bulkController,
                  decoration: InputDecoration(
                    labelText: strings.t('addStudentsBulk'),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.t('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.referenceBlue,
              ),
              onPressed: () async {
                final names = <String>[];
                final single = nameController.text.trim();
                if (single.isNotEmpty) names.add(single);
                names.addAll(
                  bulkController.text
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty),
                );
                if (names.isEmpty) return;
                var number =
                    await state.db.getNextStudentNumber(widget.classId);
                for (final name in names) {
                  await state.db.insertStudent(
                    classId: widget.classId,
                    number: number,
                    name: name,
                  );
                  number += 1;
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) setState(() {});
              },
              child: Text(strings.t('addStudent')),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    bulkController.dispose();
  }

  Future<void> _refreshStudentScores(AppState state, String dateKey) async {
    if (_studentScoresLoading) return;
    _studentScoresLoading = true;
    try {
      final data = await state.db.getStudentScores(
        widget.classId,
        date: dateKey,
      );
      if (!mounted || AppDatabase.scoreDateKey(_selectedDate) != dateKey) {
        return;
      }
      setState(() {
        _studentScores = data;
        _studentScoresDateKey = dateKey;
      });
    } finally {
      _studentScoresLoading = false;
    }
  }

  void _ensureStudentScoresLoaded(AppState state, String dateKey) {
    if (_studentScoresDateKey != dateKey) {
      _studentScoresDateKey = dateKey;
      _studentScores = null;
    }
    if (_studentScores != null || _studentScoresLoading) {
      return;
    }
    Future.microtask(() => _refreshStudentScores(state, dateKey));
  }

  void _invalidateStudentScores(AppState state) {
    final dateKey = AppDatabase.scoreDateKey(_selectedDate);
    Future.microtask(() => _refreshStudentScores(state, dateKey));
  }

  Widget _dateNavigator(AppLocalizations strings) {
    final state = context.read<AppState>();
    return Row(
      children: [
        IconButton(
          tooltip: strings.t('previousDay'),
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            _invalidateStudentScores(state);
          },
        ),
        TextButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              _invalidateStudentScores(state);
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            '${strings.t('selectedDate')}: ${AppDatabase.scoreDateKey(_selectedDate)}',
          ),
        ),
        IconButton(
          tooltip: strings.t('nextDay'),
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
            });
            _invalidateStudentScores(state);
          },
        ),
      ],
    );
  }

  Future<void> _applyBulkScore({
    required AppState state,
    required AppLocalizations strings,
    required int columnId,
    required List<int> studentIds,
    required String dateKey,
    required List<Map<String, Object?>> scores,
    required int? score,
    bool absent = false,
  }) async {
    if (studentIds.isEmpty) {
      return;
    }
    final failures = await applyBulkStudentScores(
      studentIds: studentIds,
      saveStudent: (studentId) async {
        final existing = scores.firstWhere(
          (row) =>
              row['ogrenci_id'] == studentId && row['kolon_id'] == columnId,
          orElse: () => {'yapildi': 0},
        );
        final done = (existing['yapildi'] as int?) ?? 0;
        await state.db.setStudentScore(
          studentId: studentId,
          columnId: columnId,
          score: score,
          done: done,
          date: dateKey,
          absent: absent,
        );
      },
    );
    if (!mounted) return;
    if (failures > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('bulkScorePartialFailure'))),
      );
    }
    _invalidateStudentScores(state);
    setState(() {
      _bulkSelectedStudentIds.clear();
    });
  }

  Future<void> _promptBulkScore({
    required AppLocalizations strings,
    required int? columnId,
    required List<int> studentIds,
    required AppState state,
    required String dateKey,
    required List<Map<String, Object?>> scores,
  }) async {
    if (columnId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('bulkScoreSelectColumn'))),
      );
      return;
    }
    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('bulkScoreSelectStudents'))),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.t('applyScoreToSelected')),
          content: ScoreDropdown(
            value: null,
            absent: false,
            readOnly: false,
            onChanged: ({score, absent = false}) async {
              Navigator.pop(dialogContext);
              await _applyBulkScore(
                state: state,
                strings: strings,
                columnId: columnId,
                studentIds: studentIds,
                dateKey: dateKey,
                scores: scores,
                score: score,
                absent: absent,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBulkGradingBar({
    required AppLocalizations strings,
    required List<Map<String, Object?>> students,
    required List<Map<String, Object?>> columns,
    required int? activeColumnId,
    required VoidCallback onApply,
  }) {
    final columnTitle = columns
        .where((col) => col['id'] == activeColumnId)
        .map((col) => col['ad'] as String)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () {
              setState(() {
                _bulkSelectedStudentIds
                  ..clear()
                  ..addAll(students.map((s) => s['id'] as int));
              });
            },
            child: Text(strings.t('selectAllStudents')),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() => _bulkSelectedStudentIds.clear());
            },
            child: Text(strings.t('clearSelection')),
          ),
          if (columnTitle != null)
            Text(
              columnTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          FilledButton(
            onPressed: onApply,
            child: Text(strings.t('applyScoreToSelected')),
          ),
          if (_bulkSelectedStudentIds.isNotEmpty)
            Text(
              '${_bulkSelectedStudentIds.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Future<List<Map<String, Object?>>> _loadScoreColumns(
    AppState state, {
    required String dateKey,
    required String? type,
    required bool performanceMode,
    required String materialColumnName,
    required String primaryActivityColumnName,
  }) async {
    if (performanceMode) {
      await state.db.ensurePerformanceScoreColumns(
        widget.classId,
        materialColumnName: materialColumnName,
        primaryActivityColumnName: primaryActivityColumnName,
      );
      final all = await state.db.getScoreColumnsForDate(widget.classId, dateKey);
      final material =
          all.where((col) => col['tur'] == 'materials').take(1).toList();
      final activities =
          all.where((col) => col['tur'] == 'activity').toList();
      return [...material, ...activities];
    }
    final all = await state.db.getScoreColumnsForDate(widget.classId, dateKey);
    return all.where((col) => col['tur'] == type).toList();
  }

  Widget _buildScoresSection(
    AppState state,
    AppLocalizations strings, {
    String? type,
    bool performanceMode = false,
  }) {
    final sectionType =
        performanceMode ? StudentCategory.performanceCode : type!;
    final titleLabel = performanceMode
        ? strings.t('activityColumnTitle')
        : strings.t('columnName');
    final clearLabel = strings.t('clearScores');
    final showDone =
        performanceMode || type == 'homework' || type == 'activity';
    final dateKey = AppDatabase.scoreDateKey(_selectedDate);
    final materialColumnName = strings.t('materialColumn');
    final primaryActivityColumnName = strings.t('activity1Column');
    return FutureBuilder<List<StudentCategory>>(
      future: state.db.getStudentCategories(widget.classId),
      builder: (context, catSnap) {
        final categories = catSnap.data ?? [];
        final category = performanceMode
            ? categories
                .where((c) => c.code == StudentCategory.performanceCode)
                .firstOrNull
            : categories.where((c) => c.code == type).firstOrNull;
        final sectionTitle = performanceMode
            ? (category?.name ?? strings.t('performance'))
            : (category?.name ?? sectionType);
        final sectionSubtitle = performanceMode
            ? strings.t('performanceTableHint')
            : category?.code ?? sectionType;
        final accent = AppColors.categoryColor(sectionType);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        studentCategoryIcon(sectionType),
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sectionTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            sectionSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _dateNavigator(strings),
            const SizedBox(height: 8),
            if (!widget.readOnly)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (performanceMode) {
                          final name = await state.db.nextActivityColumnName(
                            widget.classId,
                          );
                          await state.db.insertScoreColumn(
                            classId: widget.classId,
                            name: name,
                            type: 'activity',
                          );
                        } else {
                          final result = await _showColumnDialog(
                            context,
                            title: strings.t('addColumn'),
                            nameLabel: titleLabel,
                            descriptionLabel: strings.t('note'),
                          );
                          if (result == null) return;
                          final columnId = await state.db.insertScoreColumn(
                            classId: widget.classId,
                            name: result['name']!,
                            type: type!,
                          );
                          final description = result['description']?.trim();
                          if (description != null && description.isNotEmpty) {
                            await state.db.setScoreColumnDateDescription(
                              columnId: columnId,
                              date: dateKey,
                              description: description,
                            );
                          }
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.add),
                      label: Text(strings.t('addColumn')),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await _showClearTypeScoresDialog(
                          context,
                          clearLabel,
                        );
                        if (confirmed != true) return;
                        if (performanceMode) {
                          await state.db.clearStudentScoresForType(
                            classId: widget.classId,
                            type: 'materials',
                          );
                          await state.db.clearStudentScoresForType(
                            classId: widget.classId,
                            type: 'activity',
                          );
                        } else {
                          await state.db.clearStudentScoresForType(
                            classId: widget.classId,
                            type: type!,
                          );
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete_sweep),
                      label: Text(clearLabel),
                    ),
                  ],
                ),
              ),
            if (!widget.readOnly) const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: state.db.getStudents(widget.classId),
                builder: (context, snapshot) {
                  var students = snapshot.data ?? [];
                  if (widget.viewStudentId != null) {
                    students = students
                        .where((s) => s['id'] == widget.viewStudentId)
                        .toList();
                  } else if (widget.hiddenStudentIds.isNotEmpty) {
                    students = students
                        .where(
                          (s) => !widget.hiddenStudentIds.contains(s['id']),
                        )
                        .toList();
                  }
              return FutureBuilder<List<Map<String, Object?>>>(
                future: _loadScoreColumns(
                  state,
                  dateKey: dateKey,
                  type: type,
                  performanceMode: performanceMode,
                  materialColumnName: materialColumnName,
                  primaryActivityColumnName: primaryActivityColumnName,
                ),
                builder: (context, colSnap) {
                  final columns = colSnap.data ?? [];
                  final primaryActivityColumnId = performanceMode
                      ? columns
                          .where((col) => col['tur'] == 'activity')
                          .map((col) => col['id'] as int)
                          .firstOrNull
                      : null;
                  final hasColumnDescriptions = columns.any((col) {
                    final description = col['aciklama'] as String?;
                    return description != null && description.trim().isNotEmpty;
                  });
                  _ensureStudentScoresLoaded(state, dateKey);
                  final scores = _studentScores ?? [];
                  final activeColumnId = _bulkSelectedColumnId ??
                          (columns.isNotEmpty
                              ? columns.first['id'] as int
                              : null);
                      final bulkBar = !widget.readOnly
                          ? _buildBulkGradingBar(
                              strings: strings,
                              students: students,
                              columns: columns,
                              activeColumnId: activeColumnId,
                              onApply: () => _promptBulkScore(
                                strings: strings,
                                columnId: activeColumnId,
                                studentIds:
                                    _bulkSelectedStudentIds.toList(growable: false),
                                state: state,
                                dateKey: dateKey,
                                scores: scores,
                              ),
                            )
                          : null;
                      if (context.isMobileLayout) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (bulkBar != null) bulkBar,
                            Expanded(
                              child: _buildMobileScoreCards(
                          context,
                          state: state,
                          strings: strings,
                          students: students,
                          columns: columns,
                          scores: scores,
                          dateKey: dateKey,
                          type: sectionType,
                          showDone: showDone,
                          titleLabel: titleLabel,
                          performanceMode: performanceMode,
                          primaryActivityColumnId: primaryActivityColumnId,
                          bulkSelectedStudentIds: _bulkSelectedStudentIds,
                          activeColumnId: activeColumnId,
                          onBulkStudentToggle: (studentId, selected) {
                            setState(() {
                              if (selected) {
                                _bulkSelectedStudentIds.add(studentId);
                              } else {
                                _bulkSelectedStudentIds.remove(studentId);
                              }
                            });
                          },
                          onSelectColumn: (columnId) {
                            setState(() => _bulkSelectedColumnId = columnId);
                          },
                          onScoresChanged: () =>
                              _invalidateStudentScores(state),
                        ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (bulkBar != null) bulkBar,
                          Expanded(
                            child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scoresVerticalScrollController,
                        child: SingleChildScrollView(
                          controller: _scoresVerticalScrollController,
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: _scoresHorizontalScrollController,
                            notificationPredicate: (notification) =>
                                notification.depth == 1,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _scoresHorizontalScrollController,
                              child: IntrinsicWidth(
                                child: DataTable(
                              headingRowHeight:
                                  _ScoreTableLayout.headingRowHeight(
                                readOnly: widget.readOnly,
                                hasDescriptions: hasColumnDescriptions,
                              ),
                              columnSpacing:
                                  _ScoreTableLayout.columnSpacing(context),
                              horizontalMargin: 12,
                              columns: [
                                if (!widget.readOnly)
                                  const DataColumn(
                                    label: SizedBox(width: 40),
                                  ),
                                DataColumn(
                                  label: SizedBox(
                                    width: _ScoreTableLayout.studentNumberWidth(
                                      context,
                                    ),
                                    child: Text(strings.t('studentNumber')),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: _ScoreTableLayout.studentNameWidth(
                                      context,
                                    ),
                                    child: Text(strings.t('studentName')),
                                  ),
                                ),
                                ...columns.map(
                                  (col) {
                                    final columnDescription =
                                        col['aciklama'] as String?;
                                    final columnTitle = col['ad'] as String;
                                    final columnId = col['id'] as int;
                                    final columnType = col['tur'] as String;
                                    final isMaterialColumn =
                                        columnType == 'materials';
                                    final isPrimaryActivityColumn =
                                        performanceMode &&
                                        primaryActivityColumnId != null &&
                                        columnId == primaryActivityColumnId;
                                    final isBulkColumn =
                                        activeColumnId == columnId;
                                    return DataColumn(
                                      label: _buildScoreColumnHeader(
                                        context,
                                        title: columnTitle,
                                        description: columnDescription,
                                        readOnly: widget.readOnly,
                                        highlighted: isBulkColumn,
                                        onSelectColumn: widget.readOnly
                                            ? null
                                            : () {
                                                setState(() =>
                                                    _bulkSelectedColumnId =
                                                        columnId);
                                              },
                                        allowEdit: !isMaterialColumn,
                                        allowDelete: !isMaterialColumn &&
                                            !isPrimaryActivityColumn,
                                        onEdit: () async {
                                          final updated =
                                              await _showColumnDialog(
                                            context,
                                            title: strings.t('edit'),
                                            nameLabel: titleLabel,
                                            descriptionLabel: strings.t('note'),
                                            initialName: columnTitle,
                                            initialDescription:
                                                columnDescription,
                                          );
                                          if (updated != null) {
                                            await state.db.updateScoreColumn(
                                              columnId: columnId,
                                              name: updated['name']!,
                                              type: columnType,
                                              description:
                                                  updated['description'],
                                              scoreDate: dateKey,
                                            );
                                            setState(() {});
                                          }
                                        },
                                        onDelete: () async {
                                          await state.db.deleteScoreColumn(
                                            columnId,
                                          );
                                          setState(() {});
                                        },
                                        onClear: () async {
                                          final confirmed =
                                              await _showClearColumnScoresDialog(
                                            context,
                                            columnTitle,
                                          );
                                          if (confirmed != true) return;
                                          await state.db
                                              .clearStudentScoresForColumn(
                                            columnId,
                                          );
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                ),
                                if (!widget.readOnly)
                                  DataColumn(
                                    label: SizedBox(
                                      width: _ScoreTableLayout.rowActionsWidth(
                                        context,
                                      ),
                                    ),
                                  ),
                              ],
                              rows: students.map((student) {
                                final studentId = student['id'] as int;
                                final isSelected =
                                    _bulkSelectedStudentIds.contains(studentId);
                                return DataRow(
                                  selected: isSelected,
                                  cells: [
                                    if (!widget.readOnly)
                                      DataCell(
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _bulkSelectedStudentIds
                                                    .add(studentId);
                                              } else {
                                                _bulkSelectedStudentIds
                                                    .remove(studentId);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    DataCell(
                                      SizedBox(
                                        width: _ScoreTableLayout
                                            .studentNumberWidth(context),
                                        child: Text('${student['numara']}'),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: _ScoreTableLayout.studentNameWidth(
                                          context,
                                        ),
                                        child: Text(
                                          student['ad_soyad'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    ...columns.map((col) {
                                      final columnId = col['id'] as int;
                                      final score = scores.firstWhere(
                                        (row) =>
                                            row['ogrenci_id'] == studentId &&
                                            row['kolon_id'] == columnId,
                                        orElse: () => {
                                          'not_deger': null,
                                          'yapildi': null,
                                          'devamsiz': 0,
                                        },
                                      );
                                      return DataCell(
                                        SizedBox(
                                          width: _ScoreTableLayout.scoreColumnWidth(
                                            context,
                                          ),
                                          child: _ScoreCell(
                                            key: ValueKey(
                                              '$studentId-$columnId-$dateKey',
                                            ),
                                            studentId: studentId,
                                            columnId: columnId,
                                            date: dateKey,
                                            initialScore:
                                                score['not_deger'] as int?,
                                            initialAbsent:
                                                (score['devamsiz'] as int?) ==
                                                    1,
                                            initialDone:
                                                (score['yapildi'] as int?) == 1,
                                            showDone: showDone,
                                            readOnly: widget.readOnly,
                                            onScoresChanged: () =>
                                                _invalidateStudentScores(
                                                  state,
                                                ),
                                          ),
                                        ),
                                      );
                                    }),
                                    if (!widget.readOnly)
                                      DataCell(
                                        SizedBox(
                                          width: _ScoreTableLayout
                                              .rowActionsWidth(context),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _compactTableIconButton(
                                                icon: Icons.edit,
                                                tooltip: strings.t('edit'),
                                                onPressed: () async {
                                                  final updated =
                                                      await _showEditStudentDialog(
                                                    context,
                                                    student,
                                                  );
                                                  if (updated != null) {
                                                    await _saveStudentProfile(
                                                      context,
                                                      state: state,
                                                      strings: strings,
                                                      studentId: studentId,
                                                      updated: updated,
                                                    );
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                              _compactTableIconButton(
                                                icon: Icons.delete,
                                                tooltip: strings.t('delete'),
                                                onPressed: () async {
                                                  if (widget
                                                          .onHideStudentFromCategory !=
                                                      null) {
                                                    widget
                                                        .onHideStudentFromCategory!(
                                                      studentId,
                                                    );
                                                    return;
                                                  }
                                                  await state.db.deleteStudent(
                                                    studentId,
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                              _compactTableIconButton(
                                                icon: Icons.cleaning_services,
                                                tooltip: strings
                                                    .t('clearStudentScores'),
                                                onPressed: () async {
                                                  final confirmed =
                                                      await _showClearStudentScoresDialog(
                                                    context,
                                                    student['ad_soyad']
                                                        as String,
                                                  );
                                                  if (confirmed != true) return;
                                                  await state.db
                                                      .clearStudentScoresForStudent(
                                                    studentId,
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                              ),
                          ),
                        ),
                      ),
                            ),
                          ),
                        ],
                      );
                },
              );
            },
          ),
        ),
      ],
        );
      },
    );
  }

  Widget _buildMobileScoreCards(
    BuildContext context, {
    required AppState state,
    required AppLocalizations strings,
    required List<Map<String, Object?>> students,
    required List<Map<String, Object?>> columns,
    required List<Map<String, Object?>> scores,
    required String dateKey,
    required String type,
    required bool showDone,
    required String titleLabel,
    bool performanceMode = false,
    int? primaryActivityColumnId,
    Set<int> bulkSelectedStudentIds = const {},
    int? activeColumnId,
    void Function(int studentId, bool selected)? onBulkStudentToggle,
    void Function(int columnId)? onSelectColumn,
    VoidCallback? onScoresChanged,
  }) {
    if (students.isEmpty) {
      return Center(child: Text(strings.t('noStudents')));
    }
    return ListView.separated(
      controller: _scoresVerticalScrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = student['id'] as int;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBulkStudentToggle != null)
                      Checkbox(
                        value: bulkSelectedStudentIds.contains(studentId),
                        onChanged: (value) {
                          onBulkStudentToggle(
                            studentId,
                            value == true,
                          );
                        },
                      ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        '${student['numara']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        student['ad_soyad'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (!widget.readOnly)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: strings.t('edit'),
                            onPressed: () async {
                              final updated = await _showEditStudentDialog(
                                context,
                                student,
                              );
                              if (updated != null) {
                                await _saveStudentProfile(
                                  context,
                                  state: state,
                                  strings: strings,
                                  studentId: studentId,
                                  updated: updated,
                                );
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            tooltip: strings.t('delete'),
                            onPressed: () async {
                              if (widget.onHideStudentFromCategory != null) {
                                widget.onHideStudentFromCategory!(studentId);
                                return;
                              }
                              await state.db.deleteStudent(studentId);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                if (columns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      strings.t('addColumn'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                else
                  ...columns.map((col) {
                    final columnId = col['id'] as int;
                    final columnTitle = col['ad'] as String;
                    final columnDescription = col['aciklama'] as String?;
                    final columnType = col['tur'] as String;
                    final isMaterialColumn = columnType == 'materials';
                    final isPrimaryActivityColumn = performanceMode &&
                        primaryActivityColumnId != null &&
                        columnId == primaryActivityColumnId;
                    final score = scores.firstWhere(
                      (row) =>
                          row['ogrenci_id'] == studentId &&
                          row['kolon_id'] == columnId,
                      orElse: () => {
                        'not_deger': null,
                        'yapildi': null,
                        'devamsiz': 0,
                      },
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: onSelectColumn == null
                                          ? null
                                          : () => onSelectColumn(columnId),
                                      child: Text(
                                        columnTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: activeColumnId == columnId
                                              ? AppColors.primaryBlue
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (columnDescription != null &&
                                        columnDescription.trim().isNotEmpty)
                                      Text(
                                        columnDescription,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              if (!widget.readOnly)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  itemBuilder: (_) => [
                                    if (!isMaterialColumn)
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(strings.t('edit')),
                                      ),
                                    if (!isMaterialColumn && !isPrimaryActivityColumn)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(strings.t('delete')),
                                      ),
                                    PopupMenuItem(
                                      value: 'clear',
                                      child: Text(strings.t('clearScores')),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final updated = await _showColumnDialog(
                                        context,
                                        title: strings.t('edit'),
                                        nameLabel: titleLabel,
                                        descriptionLabel: strings.t('note'),
                                        initialName: columnTitle,
                                        initialDescription: columnDescription,
                                      );
                                      if (updated != null) {
                                        await state.db.updateScoreColumn(
                                          columnId: columnId,
                                          name: updated['name']!,
                                          type: columnType,
                                          description: updated['description'],
                                          scoreDate: dateKey,
                                        );
                                        setState(() {});
                                      }
                                    } else if (value == 'delete') {
                                      await state.db.deleteScoreColumn(
                                        columnId,
                                      );
                                      setState(() {});
                                    } else if (value == 'clear') {
                                      final confirmed =
                                          await _showClearColumnScoresDialog(
                                        context,
                                        columnTitle,
                                      );
                                      if (confirmed == true) {
                                        await state.db
                                            .clearStudentScoresForColumn(
                                          columnId,
                                        );
                                        setState(() {});
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _ScoreCell(
                            key: ValueKey('$studentId-$columnId-$dateKey'),
                            studentId: studentId,
                            columnId: columnId,
                            date: dateKey,
                            initialScore: score['not_deger'] as int?,
                            initialAbsent:
                                (score['devamsiz'] as int?) == 1,
                            initialDone: (score['yapildi'] as int?) == 1,
                            showDone: showDone,
                            readOnly: widget.readOnly,
                            onScoresChanged: onScoresChanged,
                          ),
                        ],
                      ),
                    );
                  }),
                if (!widget.readOnly) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirmed = await _showClearStudentScoresDialog(
                          context,
                          student['ad_soyad'] as String,
                        );
                        if (confirmed == true) {
                          await state.db.clearStudentScoresForStudent(
                            studentId,
                          );
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.cleaning_services, size: 18),
                      label: Text(strings.t('clearStudentScores')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String?>?> _showColumnDialog(
    BuildContext context, {
    required String title,
    required String nameLabel,
    required String descriptionLabel,
    String? initialName,
    String? initialDescription,
  }) async {
    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController(text: initialName ?? '');
    final descriptionController = TextEditingController(
      text: initialDescription ?? '',
    );
    return showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: nameLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: descriptionLabel),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final description = descriptionController.text.trim();
              Navigator.of(context).pop({
                'name': name,
                'description': description.isEmpty ? null : description,
              });
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStudentProfile(
    BuildContext context, {
    required AppState state,
    required AppLocalizations strings,
    required int studentId,
    required Map<String, dynamic> updated,
  }) async {
    try {
      await state.db.updateStudent(
        studentId: studentId,
        number: updated['number'] as int,
        name: updated['name'] as String,
        email: updated['email'] as String?,
        motherEmail: updated['motherEmail'] as String?,
        fatherEmail: updated['fatherEmail'] as String?,
        classId: updated['classId'] as int?,
      );
      final saved = await state.db.getStudentById(studentId);
      final expectedEmail = updated['email'] as String?;
      if (expectedEmail != null &&
          expectedEmail.isNotEmpty &&
          (saved?['email'] as String? ?? '').isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('studentEmailSchemaMissing')),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } on StateError catch (e) {
      if (e.message == 'student_email_schema_missing' && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('studentEmailSchemaMissing')),
            duration: const Duration(seconds: 10),
          ),
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _showEditStudentDialog(
    BuildContext context,
    Map<String, Object?> student,
  ) {
    return showStudentProfileEditDialog(context, student: student);
  }

  Future<bool?> _showClearTypeScoresDialog(
    BuildContext context,
    String title,
  ) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(strings.t('clearTypeScoresConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showClearColumnScoresDialog(
    BuildContext context,
    String columnName,
  ) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${strings.t('clearColumnScores')} - $columnName'),
        content: Text(strings.t('clearColumnScoresConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showClearStudentScoresDialog(
    BuildContext context,
    String studentName,
  ) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${strings.t('clearStudentScores')} - $studentName'),
        content: Text(strings.t('clearStudentScoresConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }
}

abstract final class _ScoreTableLayout {
  static double studentNumberWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppSpacing.phoneBreakpoint) return 44;
    if (w < AppSpacing.shellBreakpoint) return 48;
    return 52;
  }

  static double studentNameWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppSpacing.phoneBreakpoint) return 120;
    if (w < AppSpacing.shellBreakpoint) return 150;
    return 180;
  }

  static double scoreColumnWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppSpacing.phoneBreakpoint) return 92;
    if (w < AppSpacing.shellBreakpoint) return 108;
    return 120;
  }

  static double columnSpacing(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppSpacing.phoneBreakpoint) return 8;
    if (w < AppSpacing.shellBreakpoint) return 12;
    return 16;
  }

  static double rowActionsWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < AppSpacing.phoneBreakpoint) return 96;
    return 108;
  }

  static double headingRowHeight({
    required bool readOnly,
    required bool hasDescriptions,
  }) {
    if (readOnly) {
      return hasDescriptions ? 56 : 48;
    }
    if (hasDescriptions) {
      return 88;
    }
    return 56;
  }
}

Widget _compactTableIconButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 16),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
  );
}

Widget _buildScoreColumnHeader(
  BuildContext context, {
  required String title,
  String? description,
  required bool readOnly,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onClear,
  bool allowEdit = true,
  bool allowDelete = true,
  bool highlighted = false,
  VoidCallback? onSelectColumn,
}) {
  final hasDescription = description != null && description.trim().isNotEmpty;
  return SizedBox(
    width: _ScoreTableLayout.scoreColumnWidth(context),
    child: DecoratedBox(
      decoration: highlighted
          ? BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primaryBlue),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: highlighted ? const EdgeInsets.all(4) : EdgeInsets.zero,
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onSelectColumn,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.primaryBlue : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasDescription)
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (!readOnly)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allowEdit)
                _compactTableIconButton(
                  icon: Icons.edit,
                  tooltip: AppLocalizations.of(context).t('edit'),
                  onPressed: onEdit,
                ),
              if (allowDelete)
                _compactTableIconButton(
                  icon: Icons.delete,
                  tooltip: AppLocalizations.of(context).t('delete'),
                  onPressed: onDelete,
                ),
              _compactTableIconButton(
                icon: Icons.cleaning_services,
                tooltip: AppLocalizations.of(context).t('clearScores'),
                onPressed: onClear,
              ),
            ],
          ),
      ],
        ),
      ),
    ),
  );
}

class _ScoreCell extends StatefulWidget {
  const _ScoreCell({
    super.key,
    required this.studentId,
    required this.columnId,
    required this.date,
    required this.initialScore,
    required this.initialAbsent,
    required this.initialDone,
    required this.showDone,
    this.readOnly = false,
    this.onScoresChanged,
  });

  final int studentId;
  final int columnId;
  final String date;
  final int? initialScore;
  final bool initialAbsent;
  final bool initialDone;
  final bool showDone;
  final bool readOnly;
  final VoidCallback? onScoresChanged;

  @override
  State<_ScoreCell> createState() => _ScoreCellState();
}

class _ScoreCellState extends State<_ScoreCell> {
  late int? _score;
  late bool _done;
  late bool _absent;

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore;
    _done = widget.initialDone;
    _absent = widget.initialAbsent;
  }

  @override
  void didUpdateWidget(covariant _ScoreCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScore != widget.initialScore) {
      _score = widget.initialScore;
    }
    if (oldWidget.initialAbsent != widget.initialAbsent) {
      _absent = widget.initialAbsent;
    }
    if (oldWidget.initialDone != widget.initialDone) {
      _done = widget.initialDone;
    }
  }

  Future<void> _saveSelection({int? score, bool? absent}) async {
    if (!mounted) return;
    final previousScore = _score;
    final previousAbsent = _absent;
    final nextScore = score ?? _score;
    final nextAbsent = absent ?? _absent;
    if (nextScore == previousScore && nextAbsent == previousAbsent) {
      return;
    }
    setState(() {
      _score = nextScore;
      _absent = nextAbsent;
      if (nextAbsent) {
        _score = null;
      }
    });
    final state = context.read<AppState>();
    try {
      await state.db.setStudentScore(
        studentId: widget.studentId,
        columnId: widget.columnId,
        score: _score,
        done: _done ? 1 : 0,
        date: widget.date,
        absent: _absent,
      );
      widget.onScoresChanged?.call();
      try {
        await state.recordTeacherActivity(
          type: TeacherActivityTypes.performanceUpdated,
          title: AppLocalizations.of(context).t('activityPerformanceUpdated'),
        );
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _score = previousScore;
        _absent = previousAbsent;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('saveFailed')),
        ),
      );
    }
  }

  Future<void> _saveDone(bool value) async {
    if (!mounted) return;
    final previous = _done;
    setState(() => _done = value);
    final state = context.read<AppState>();
    try {
      await state.db.setStudentScore(
        studentId: widget.studentId,
        columnId: widget.columnId,
        score: _score,
        done: value ? 1 : 0,
        date: widget.date,
        absent: _absent,
      );
      widget.onScoresChanged?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _done = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('saveFailed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ScoreDropdown(
            value: _score,
            absent: _absent,
            readOnly: widget.readOnly,
            onChanged: ({score, absent = false}) =>
                _saveSelection(score: score, absent: absent),
          ),
        ),
        if (widget.showDone)
          widget.readOnly
              ? Icon(
                  _done
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: _done
                      ? AppColors.primaryBlue
                      : AppColors.textMuted,
                )
              : Checkbox(
                  value: _done,
                  onChanged: (value) {
                    if (value == null) return;
                    _saveDone(value);
                  },
                ),
      ],
    );
  }
}

class _TeacherClassRow extends StatelessWidget {
  const _TeacherClassRow({
    required this.className,
    required this.classSubtitle,
    required this.isSelected,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onSelect,
    required this.onManageCategories,
    required this.onEdit,
    required this.onDelete,
    required this.manageCategoriesLabel,
  });

  final String className;
  final String classSubtitle;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSelect;
  final Future<void> Function() onManageCategories;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;
  final String manageCategoriesLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: isSelected
          ? AppColors.primaryBlue.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 22,
                ),
                onPressed: onToggleExpanded,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                    Text(
                      classSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) async {
                  switch (value) {
                    case 'categories':
                      await onManageCategories();
                    case 'edit':
                      await onEdit();
                    case 'delete':
                      await onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'categories',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.tune, size: 20),
                      title: Text(manageCategoriesLabel),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.edit, size: 20),
                      title: Text(strings.t('edit')),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.delete, size: 20),
                      title: Text(strings.t('delete')),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
