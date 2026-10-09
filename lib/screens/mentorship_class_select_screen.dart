import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/course_form_options.dart';
import '../utils/teacher_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_shell.dart';
import 'mentorship_dashboard_screen.dart';

class MentorshipClassSelectScreen extends StatefulWidget {
  const MentorshipClassSelectScreen({super.key});

  @override
  State<MentorshipClassSelectScreen> createState() =>
      _MentorshipClassSelectScreenState();
}

class _MentorshipClassSelectScreenState
    extends State<MentorshipClassSelectScreen> {
  List<Map<String, Object?>> _classes = [];
  int? _selectedClassId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    final classes = await db.getMentorshipClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _selectedClassId =
          classes.isNotEmpty ? classes.first['id'] as int? : null;
      _loading = false;
    });
  }

  Future<void> _transferClass() async {
    final strings = AppLocalizations.of(context);
    final db = context.read<AppState>().db;
    final available = await db.getClassesAvailableForMentorshipTransfer();
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('noMentorshipClasses'))),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.t('transferExistingClass')),
          content: SizedBox(
            width: 420,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (_, index) {
                final row = available[index];
                return ListTile(
                  title: Text(row['ad'] as String),
                  subtitle: Text(
                    CourseFormOptions.studentClassSubtitle(
                      row['yil'] as String,
                      row['sube'] as String?,
                    ),
                  ),
                  trailing: Text('${row['ogrenci_sayisi']}'),
                  onTap: () => Navigator.pop(dialogContext, row['id'] as int),
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
    if (selected == null) return;
    await db.linkMentorshipClass(selected);
    await _load();
    setState(() => _selectedClassId = selected);
  }

  Future<void> _createClass() async {
    final strings = AppLocalizations.of(context);
    final years = CourseFormOptions.academicYearOptions();
    var selectedYear = years.first;
    var selectedGrade = CourseFormOptions.minGrade;
    var selectedSection = CourseFormOptions.sectionOptions.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(strings.t('createNewClass')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedYear,
                      decoration:
                          InputDecoration(labelText: strings.t('academicYear')),
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
                      initialValue: selectedGrade,
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
                      initialValue: selectedSection,
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.t('cancelSimple')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    final db = context.read<AppState>().db;
    final classId = await db.insertStudentClass(
      CourseFormOptions.gradeLabel(selectedGrade),
      selectedYear,
      section: selectedSection,
    );
    await db.linkMentorshipClass(classId);
    await _load();
    setState(() => _selectedClassId = classId);
  }

  void _continue() {
    if (_selectedClassId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MentorshipDashboardScreen(classId: _selectedClassId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < AppSpacing.phoneBreakpoint;

    return AppShell(
      teacherSection: TeacherNavSection.mentorship,
      title: strings.t('mentorship'),
      subtitle: strings.t('mentorshipSubtitle'),
      child: ColoredBox(
        color: AppColors.background,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _transferClass,
                          icon: const Icon(Icons.import_export, size: 18),
                          label: Text(strings.t('transferExistingClass')),
                        ),
                        FilledButton.icon(
                          onPressed: _createClass,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(strings.t('createNewClass')),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: _classes.isEmpty
                          ? AppEmptyState(
                              icon: Icons.school_outlined,
                              title: strings.t('noMentorshipClasses'),
                            )
                          : ListView.separated(
                              itemCount: _classes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final row = _classes[index];
                                final classId = row['id'] as int;
                                final selected = _selectedClassId == classId;
                                return AppCard(
                                  onTap: () =>
                                      setState(() => _selectedClassId = classId),
                                  color: selected
                                      ? AppColors.primaryBlue
                                          .withValues(alpha: 0.04)
                                      : null,
                                  child: Row(
                                    children: [
                                      Radio<int>(
                                        value: classId,
                                        groupValue: _selectedClassId,
                                        onChanged: (value) => setState(
                                          () => _selectedClassId = value,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              row['ad'] as String,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              CourseFormOptions
                                                  .studentClassSubtitle(
                                                row['yil'] as String,
                                                row['sube'] as String?,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${strings.t('studentCount')}: ${row['ogrenci_sayisi']}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed:
                            _selectedClassId == null ? null : _continue,
                        child: Text(strings.t('mentorshipContinue')),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
