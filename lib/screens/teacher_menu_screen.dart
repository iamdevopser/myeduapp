import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/models/class_notebook_note.dart';
import '../data/models/student_category_model.dart';
import '../data/models/teacher_recent_activity.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/course_form_options.dart';
import '../utils/student_daily_performance.dart';
import '../utils/teacher_activity.dart';
import '../utils/teacher_display_name.dart';
import '../utils/teacher_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/app_shell.dart';
import '../widgets/reference_stat_card.dart';
import '../widgets/design/design_collapsible_section.dart';
import '../widgets/design/design_page_container.dart';
import '../widgets/design/teacher_design_home_primary.dart';
import 'teacher_student_announcements_screen.dart';

/// Teacher dashboard — Ana Sayfa with quick actions, class list, notebook, activities.
class TeacherMenuScreen extends StatelessWidget {
  const TeacherMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppShell(
      teacherSection: TeacherNavSection.home,
      title: strings.t('teacherPanelTitle'),
      showSearch: true,
      searchHint: strings.t('designStudentSearchHint'),
      onSearchChanged: (_) => openStudentPlatform(context),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  int _reloadToken = 0;
  int? _notebookClassId;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingClassNotebook();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AppState>();
    if (_appState != next) {
      _appState?.removeListener(_onAppStateNotebookRequest);
      _appState = next;
      _appState!.addListener(_onAppStateNotebookRequest);
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateNotebookRequest);
    super.dispose();
  }

  void _onAppStateNotebookRequest() {
    _applyPendingClassNotebook();
  }

  void _applyPendingClassNotebook() {
    final classId = context.read<AppState>().takePendingClassNotebookClassId();
    if (classId == null || !mounted) return;
    setState(() => _notebookClassId = classId);
  }

  void _bumpReload() => setState(() => _reloadToken++);

  Future<_DashboardSnapshot> _loadSnapshot(AppState state) async {
    final classes = await state.db.getStudentClasses();
    final activities = await state.db.getRecentTeacherActivities(limit: 10);
    final subjects = await state.db.getSubjects();
    final folders = await state.db.getDocumentFolders();
    var studentCount = 0;
    for (final row in classes) {
      final id = row['id'] as int;
      studentCount += (await state.db.getStudents(id)).length;
    }
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 30));
    final fromKey = AppDatabase.scoreDateKey(from);
    final toKey = AppDatabase.scoreDateKey(to);
    final perfRows = await state.db.getStudentReportRows(
      fromDate: fromKey,
      toDate: toKey,
      categoryCode: StudentCategory.performanceCode,
    );
    final homeworkRows = await state.db.getStudentReportRows(
      fromDate: fromKey,
      toDate: toKey,
      categoryCode: 'homework',
    );
    final examRows = await state.db.getStudentReportRows(
      fromDate: fromKey,
      toDate: toKey,
      categoryCode: 'exam',
    );
    final teacherDisplayName = await TeacherDisplayName.resolve(state.db);
    final announcements = await state.db.listStudentAnnouncementsForTeacher();
    final scheduleRows = await state.db.getWeeklyScheduleEntries();
    final todayWeekday = DateTime.now().weekday;
    final todaySchedule = scheduleRows
        .where((row) => (row['gun'] as int?) == todayWeekday)
        .toList();

    return _DashboardSnapshot(
      classes: classes,
      activities: activities,
      subjectCount: subjects.length,
      folderCount: folders.length,
      studentCount: studentCount,
      performanceAverage: _dashboardPerformanceAverage(perfRows),
      homeworkEntryCount: homeworkRows.length,
      examEntryCount: examRows.length,
      teacherDisplayName: teacherDisplayName,
      announcements: announcements.take(8).toList(),
      todaySchedule: todaySchedule,
    );
  }

  Future<void> _showAddNotebookNoteDialog(
    AppState state,
    AppLocalizations strings,
    int classId,
  ) {
    return _showNotebookNoteEditorDialog(
      state,
      strings,
      classId: classId,
    );
  }

  Future<void> _showEditNotebookNoteDialog(
    AppState state,
    AppLocalizations strings,
    ClassNotebookNote note,
  ) {
    return _showNotebookNoteEditorDialog(
      state,
      strings,
      classId: note.classId,
      existing: note,
    );
  }

  Future<void> _confirmDeleteNotebookNote(
    AppState state,
    AppLocalizations strings,
    ClassNotebookNote note,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('delete')),
        content: Text(strings.t('deleteNotebookNoteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('yes')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.db.deleteClassNotebookNote(note.id);
    if (mounted) _bumpReload();
  }

  Future<void> _showNotebookNoteEditorDialog(
    AppState state,
    AppLocalizations strings, {
    required int classId,
    ClassNotebookNote? existing,
  }) async {
    final isEdit = existing != null;
    final textController = TextEditingController(text: existing?.text ?? '');
    var noteDate = existing != null
        ? _parseNoteDate(existing.noteDate)
        : DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit
                    ? strings.t('editNotebookNote')
                    : strings.t('addNotebookNote'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.t('notebookNoteDate')),
                    subtitle: Text(_formatNoteDate(noteDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: noteDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        noteDate = picked;
                        setDialogState(() {});
                      }
                    },
                  ),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: strings.t('notebookNoteHint'),
                    ),
                  ),
                ],
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
            );
          },
        );
      },
    );
    if (saved != true || textController.text.trim().isEmpty) {
      textController.dispose();
      return;
    }
    final dateStr = _formatNoteDate(noteDate);
    final trimmed = textController.text.trim();
    if (isEdit) {
      await state.db.updateClassNotebookNote(
        noteId: existing.id,
        text: trimmed,
        noteDate: dateStr,
      );
    } else {
      final noteId = await state.db.insertClassNotebookNote(
        classId: classId,
        text: trimmed,
        noteDate: dateStr,
      );
      final className = await _className(state, classId);
      await state.recordTeacherActivity(
        type: TeacherActivityTypes.classNotebookNote,
        title: strings
            .t('activityClassNotebookNote')
            .replaceAll('{class}', className),
        targetType: TeacherActivityTargets.classNotebookNote,
        targetId: noteId,
      );
    }
    textController.dispose();
    if (mounted) _bumpReload();
  }

  static DateTime _parseNoteDate(String noteDate) {
    final parts = noteDate.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.now();
  }

  static String _formatNoteDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<String> _className(AppState state, int classId) async {
    final classes = await state.db.getStudentClasses();
    final row = classes.cast<Map<String, Object?>>().firstWhere(
      (r) => r['id'] == classId,
      orElse: () => {},
    );
    return row['ad'] as String? ?? '';
  }

  static String _formatActivityTime(DateTime at) {
    final local = at.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day}.${local.month}.${local.year} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder<_DashboardSnapshot>(
      key: ValueKey(_reloadToken),
      future: _loadSnapshot(state),
      builder: (context, snap) {
        final data = snap.data;
        final classes = data?.classes ?? [];
        final notebookClasses = List<Map<String, Object?>>.from(classes);
        notebookClasses.sort(CourseFormOptions.compareStudentClassRowsNotebook);
        _notebookClassId ??=
            classes.isNotEmpty ? classes.first['id'] as int : null;
        if (_notebookClassId != null &&
            classes.every((r) => r['id'] != _notebookClassId)) {
          _notebookClassId =
              classes.isNotEmpty ? classes.first['id'] as int : null;
        }

        final isMobile = AppSpacing.isMobile(width);
        final gap = AppSpacing.md;
        final teacherName = data?.teacherDisplayName ?? '';

        final dashboardCards = <Widget>[
          _DashboardSectionCard(
            title: strings.t('quickActions'),
            height: isMobile ? 280 : 320,
            child: _QuickActionsCardBody(strings: strings, state: state),
          ),
          _DashboardSectionCard(
            title: strings.t('recentTeacherActions'),
            height: isMobile ? 280 : 320,
            child: data == null
                ? const Center(child: CircularProgressIndicator())
                : data.activities.isEmpty
                    ? _DashboardCardEmpty(
                        icon: Icons.history_outlined,
                        title: strings.t('noRecentTeacherActions'),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: data.activities.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final activity = data.activities[index];
                          return _ActivityRow(
                            activity: activity,
                            timeLabel:
                                _formatActivityTime(activity.createdAt),
                            compact: true,
                            onTap: activity.targetId != null &&
                                    activity.targetType != null
                                ? () => handleTeacherActivityTap(
                                      context,
                                      activity,
                                    )
                                : null,
                          );
                        },
                      ),
          ),
          _DashboardSectionCard(
            title: strings.t('classNotebook'),
            height: isMobile ? 300 : 320,
            child: classes.isEmpty
                ? _DashboardCardEmpty(
                    icon: Icons.menu_book_outlined,
                    title: strings.t('notebookNeedsClass'),
                  )
                : _ClassNotebookCardBody(
                    strings: strings,
                    state: state,
                    notebookClasses: notebookClasses,
                    notebookClassId: _notebookClassId,
                    reloadToken: _reloadToken,
                    onClassChanged: (id) =>
                        setState(() => _notebookClassId = id),
                    onAddNote: () => _showAddNotebookNoteDialog(
                      state,
                      strings,
                      _notebookClassId!,
                    ),
                    onEditNote: (note) => _showEditNotebookNoteDialog(
                      state,
                      strings,
                      note,
                    ),
                    onDeleteNote: (note) => _confirmDeleteNotebookNote(
                      state,
                      strings,
                      note,
                    ),
                  ),
          ),
        ];

        // Tasarım 13: birincil satır (Sınıflarım + Güncel Dersler) en üstte;
        // mevcut özet/duyuru ve çalışma alanı kartları ikincil (bölüm başlıklı).
        return DesignPageContainer(
          maxWidth: AppSpacing.contentMaxWidth,
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile) ...[
                _WelcomeBanner(strings: strings, teacherName: teacherName),
                const SizedBox(height: AppSpacing.lg),
              ],
              TeacherDesignHomePrimary(
                classes: classes,
                todaySchedule: data?.todaySchedule ?? const [],
                onClassTap: (id) => openStudentPlatform(context, classId: id),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (data != null) ...[
                DesignCollapsibleSection(
                  title: strings.t('designHubSecondarySummary'),
                  expandTooltip: strings.t('designSectionExpand'),
                  collapseTooltip: strings.t('designSectionCollapse'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReferenceDashboardStats(
                        strings: strings,
                        snapshot: data,
                        onStudents: () => openStudentPlatform(context),
                        onHomework: () => openReports(context),
                        onLessons: () => openAcademicPlans(context),
                        onClasses: () => openStudentPlatform(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _AnnouncementsPanel(
                        strings: strings,
                        rows: data.announcements,
                        onViewAll: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const TeacherStudentAnnouncementsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (snap.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              DesignCollapsibleSection(
                title: strings.t('designHubSecondaryWorkspace'),
                expandToken: _notebookClassId,
                expandTooltip: strings.t('designSectionExpand'),
                collapseTooltip: strings.t('designSectionCollapse'),
                child: _TeacherHomeDashboardGrid(
                  columns: isMobile ? 1 : 2,
                  gap: gap,
                  children: dashboardCards,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeacherHomeDashboardGrid extends StatelessWidget {
  const _TeacherHomeDashboardGrid({
    required this.columns,
    required this.gap,
    required this.children,
  });

  final int columns;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final itemWidth = (maxW - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _DashboardCardEmpty extends StatelessWidget {
  const _DashboardCardEmpty({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: AppColors.brandPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: onAction,
                      child: Text(
                        actionLabel!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.title,
    required this.height,
    required this.child,
  });

  final String title;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCardBody extends StatelessWidget {
  const _QuickActionsCardBody({
    required this.strings,
    required this.state,
  });

  final AppLocalizations strings;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.build_rounded,
        label: strings.t('createApp'),
        onTap: () => openLessonBuilder(context),
      ),
      (
        icon: Icons.group_add_rounded,
        label: strings.t('addClassQuick'),
        onTap: () => openStudentPlatform(context),
      ),
      (
        icon: Icons.person_add_rounded,
        label: strings.t('addStudent'),
        onTap: () => openStudentPlatform(context),
      ),
      (
        icon: Icons.assessment_rounded,
        label: strings.t('createReport'),
        onTap: () => openReports(context),
      ),
      (
        icon: Icons.folder_outlined,
        label: strings.t('documents'),
        onTap: () => openAcademicPlans(
          context,
          section: AcademicPlansSidebarSection.documents,
        ),
      ),
    ];

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: actions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionChip(
          icon: action.icon,
          label: action.label,
          onTap: action.onTap,
          compact: true,
        );
      },
    );
  }
}

class _ClassNotebookCardBody extends StatelessWidget {
  const _ClassNotebookCardBody({
    required this.strings,
    required this.state,
    required this.notebookClasses,
    required this.notebookClassId,
    required this.reloadToken,
    required this.onClassChanged,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  final AppLocalizations strings;
  final AppState state;
  final List<Map<String, Object?>> notebookClasses;
  final int? notebookClassId;
  final int reloadToken;
  final ValueChanged<int?> onClassChanged;
  final VoidCallback onAddNote;
  final void Function(ClassNotebookNote note) onEditNote;
  final void Function(ClassNotebookNote note) onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          isExpanded: true,
          isDense: true,
          decoration: InputDecoration(
            labelText: strings.t('selectClass'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: const OutlineInputBorder(),
          ),
          value: notebookClassId,
          items: [
            for (final row in notebookClasses)
              DropdownMenuItem(
                value: row['id'] as int,
                child: Text(
                  CourseFormOptions.studentClassGradeSectionLabel(
                    row['ad'] as String,
                    section: row['sube'] as String?,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onClassChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (notebookClassId != null)
          Expanded(
            child: FutureBuilder<List<ClassNotebookNote>>(
              key: ValueKey('nb-$reloadToken-$notebookClassId'),
              future: state.db.getClassNotebookNotes(
                notebookClassId!,
                limit: 8,
              ),
              builder: (context, noteSnap) {
                final notes = noteSnap.data ?? [];
                if (noteSnap.connectionState == ConnectionState.waiting &&
                    notes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onAddNote,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(strings.t('addNotebookNote')),
                      ),
                    ),
                    Expanded(
                      child: notes.isEmpty
                          ? _DashboardCardEmpty(
                              icon: Icons.note_outlined,
                              title: strings.t('notebookEmpty'),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: notes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.xs),
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                return AppCard(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.noteDate,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: strings.t('edit'),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            onPressed: () => onEditNote(note),
                                          ),
                                          IconButton(
                                            tooltip: strings.t('delete'),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            onPressed: () => onDeleteNote(note),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        note.text,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

double? _dashboardPerformanceAverage(List<Map<String, Object?>> rows) {
  final byStudent = StudentDailyPerformance.dailyAveragesByStudent(rows);
  final values = <double>[];
  for (final daily in byStudent.values) {
    values.addAll(daily.values);
  }
  if (values.isEmpty) {
    return null;
  }
  return values.reduce((a, b) => a + b) / values.length;
}

class _DashboardSnapshot {
  _DashboardSnapshot({
    required this.classes,
    required this.activities,
    required this.subjectCount,
    required this.folderCount,
    required this.studentCount,
    required this.performanceAverage,
    required this.homeworkEntryCount,
    required this.examEntryCount,
    required this.teacherDisplayName,
    required this.announcements,
    required this.todaySchedule,
  });

  final List<Map<String, Object?>> classes;
  final List<TeacherRecentActivity> activities;
  final int subjectCount;
  final int folderCount;
  final int studentCount;
  final double? performanceAverage;
  final int homeworkEntryCount;
  final int examEntryCount;
  final String teacherDisplayName;
  final List<Map<String, Object?>> announcements;
  final List<Map<String, Object?>> todaySchedule;
}

class _ShortAnalyticsRow extends StatelessWidget {
  const _ShortAnalyticsRow({
    required this.strings,
    required this.studentCount,
    required this.subjectCount,
    required this.folderCount,
    required this.performanceAverage,
    required this.homeworkEntryCount,
    required this.examEntryCount,
    required this.onPerformance,
    required this.onHomework,
    required this.onExams,
    required this.onAttendance,
    required this.onDocuments,
    this.inDashboardCard = false,
  });

  final AppLocalizations strings;
  final int studentCount;
  final int subjectCount;
  final int folderCount;
  final double? performanceAverage;
  final int homeworkEntryCount;
  final int examEntryCount;
  final VoidCallback onPerformance;
  final VoidCallback onHomework;
  final VoidCallback onExams;
  final VoidCallback onAttendance;
  final VoidCallback onDocuments;
  final bool inDashboardCard;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppSpacing.isMobile(width);
    final tiles = [
      _AnalyticsTile(
        icon: Icons.trending_up_outlined,
        label: strings.t('analyticsPerformance'),
        value: StudentDailyPerformance.formatAverage(
          performanceAverage,
          fractionDigits: 1,
        ),
        subtitle: strings.t('analyticsPerformanceHint'),
        onTap: onPerformance,
        compact: inDashboardCard,
      ),
      _AnalyticsTile(
        icon: Icons.assignment_outlined,
        label: strings.t('analyticsHomework'),
        value: '$homeworkEntryCount',
        subtitle: strings.t('analyticsHomeworkHint'),
        onTap: onHomework,
        compact: inDashboardCard,
      ),
      _AnalyticsTile(
        icon: Icons.quiz_outlined,
        label: strings.t('analyticsExams'),
        value: '$examEntryCount',
        subtitle: strings.t('analyticsExamsHint'),
        onTap: onExams,
        compact: inDashboardCard,
      ),
      _AnalyticsTile(
        icon: Icons.event_available_outlined,
        label: strings.t('analyticsAttendance'),
        value: '$studentCount',
        subtitle: strings.t('analyticsStudentsHint'),
        onTap: onAttendance,
        compact: inDashboardCard,
      ),
      _AnalyticsTile(
        icon: Icons.folder_outlined,
        label: strings.t('analyticsDocuments'),
        value: '$folderCount',
        subtitle: strings
            .t('analyticsDocumentsHint')
            .replaceAll('{subjects}', '$subjectCount'),
        onTap: onDocuments,
        compact: inDashboardCard,
      ),
    ];

    if (inDashboardCard) {
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) => tiles[index],
      );
    }

    if (isMobile) {
      return Column(
        children: [
          for (final tile in tiles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: tile,
            ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final tile in tiles)
          SizedBox(
            width: (width - AppSpacing.pagePadding(width).horizontal - 32) / 2,
            child: tile,
          ),
      ],
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  const _AnalyticsTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 12,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandPrimary, size: compact ? 20 : 24),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? Theme.of(context).textTheme.bodyMedium
                          : Theme.of(context).textTheme.titleSmall)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: compact ? 11 : null,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: compact ? 18 : 24,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.timeLabel,
    this.onTap,
    this.compact = false,
  });

  final TeacherRecentActivity activity;
  final String timeLabel;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        children: [
          Icon(
            iconForTeacherActivityType(activity.type),
            color: AppColors.navy,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ReferenceDashboardStats extends StatelessWidget {
  const _ReferenceDashboardStats({
    required this.strings,
    required this.snapshot,
    required this.onStudents,
    required this.onHomework,
    required this.onLessons,
    required this.onClasses,
  });

  final AppLocalizations strings;
  final _DashboardSnapshot snapshot;
  final VoidCallback onStudents;
  final VoidCallback onHomework;
  final VoidCallback onLessons;
  final VoidCallback onClasses;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = AppSpacing.isMobile(width) ? 2 : 4;
    final gap = AppSpacing.md;
    final tiles = [
      ReferenceStatCard(
        label: strings.t('analyticsAttendance'),
        value: '${snapshot.studentCount}',
        icon: Icons.groups_outlined,
        tint: const Color(0xFF22C55E),
        onTap: onStudents,
      ),
      ReferenceStatCard(
        label: strings.t('analyticsHomework'),
        value: '${snapshot.homeworkEntryCount}',
        icon: Icons.assignment_outlined,
        tint: const Color(0xFF8B5CF6),
        onTap: onHomework,
      ),
      ReferenceStatCard(
        label: strings.t('teacherDashboardCurrentLessons'),
        value: '${snapshot.subjectCount}',
        icon: Icons.menu_book_outlined,
        tint: const Color(0xFFF59E0B),
        onTap: onLessons,
      ),
      ReferenceStatCard(
        label: strings.t('teacherDashboardMyClassesGrid'),
        value: '${snapshot.classes.length}',
        icon: Icons.class_outlined,
        tint: const Color(0xFFEC4899),
        onTap: onClasses,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - gap * (crossCount - 1)) / crossCount;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: itemWidth, child: tile),
          ],
        );
      },
    );
  }
}

class _AnnouncementsPanel extends StatelessWidget {
  const _AnnouncementsPanel({
    required this.strings,
    required this.rows,
    required this.onViewAll,
  });

  final AppLocalizations strings;
  final List<Map<String, Object?>> rows;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.t('teacherDashboardRecentAnnouncements'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: Text(strings.t('seeAll'))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            Text(
              strings.t('teacherAnnouncementsEmpty'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else
            for (final row in rows.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['baslik'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            row['olusturma_tarihi'] as String? ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.strings, required this.teacherName});

  final AppLocalizations strings;
  final String teacherName;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = AppSpacing.isMobile(width);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.referenceBlue.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = AppSpacing.isMobile(constraints.maxWidth);
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacherName.isEmpty
                    ? strings.t('dashboardWelcome')
                    : strings
                        .t('dashboardWelcomeNamed')
                        .replaceAll('{name}', teacherName),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.t('dashboardTodaySummary'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          );
          final icon = Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
          );
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: AppSpacing.md), icon],
            );
          }
          return Row(
            children: [Expanded(child: text), icon],
          );
        },
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Material(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.brandPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
