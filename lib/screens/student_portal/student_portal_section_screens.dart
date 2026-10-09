import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/student_portal_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';
import '../../utils/student_daily_performance.dart';
import '../../utils/student_navigation.dart';
import '../../utils/student_score_display.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../utils/design_academic_calendar_data.dart';
import '../../utils/student_announcement_notification.dart';
import '../../utils/mentorship_helpers.dart';
import '../../utils/student_portal_announcement_ui.dart';
import '../../widgets/design/design_academic_calendar_view.dart';
import '../../widgets/design/design_feed_row.dart';
import '../../widgets/design/design_grouped_list_card.dart';
import '../../widgets/design/design_month_grid_calendar.dart';
import '../../widgets/design/design_portal_page_layout.dart';
import '../../widgets/design/design_surface_card.dart';
import '../academic_plans/weekly_schedule_panel.dart';
import 'student_portal_scope.dart';
import 'widgets/student_portal_ui.dart';

class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    return FutureBuilder<List<StudentPortalCourse>>(
      future: StudentPortalService(context.read<AppState>().db)
          .loadCourses(scope.enrollments),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final courses = snapshot.data!;
        if (courses.isEmpty) {
          return AppEmptyState(
            icon: Icons.menu_book_outlined,
            title: strings.t('studentPortalNoCourses'),
          );
        }
        final width = context.layoutWidth;
        final cross = AppSpacing.gridCrossAxisCount(
          width,
          desktop: 3,
          tablet: 2,
        );
        final padding = AppSpacing.pagePadding(width);
        if (cross == 1) {
          return ListView.separated(
            padding: padding,
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = courses[index];
              return StudentCourseCard(
                name: c.name,
                className: c.className,
                teacherLabel: c.teacherLabel,
                onTap: () =>
                    openStudentLessonPlatform(context, lessonId: c.lessonId),
              );
            },
          );
        }
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: context.isTabletLayout ? 1.35 : 1.25,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final c = courses[index];
            return StudentCourseCard(
              name: c.name,
              className: c.className,
              teacherLabel: c.teacherLabel,
              onTap: () =>
                  openStudentLessonPlatform(context, lessonId: c.lessonId),
            );
          },
        );
      },
    );
  }
}

class StudentWeeklyScheduleScreen extends StatelessWidget {
  const StudentWeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = context.layoutWidth;
    final useDesignCalendar = AppSpacing.isMobile(width) || width < 1024;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = AppSpacing.pagePadding(width);
        if (useDesignCalendar) {
          return Padding(
            padding: padding,
            child: StudentDesignAcademicCalendarPanel(
              height: constraints.maxHeight,
            ),
          );
        }
        return Padding(
          padding: padding,
          child: SizedBox(
            height: constraints.maxHeight,
            child: const StudentWeeklyScheduleReadOnlyPanel(),
          ),
        );
      },
    );
  }
}

class StudentDesignAcademicCalendarPanel extends StatefulWidget {
  const StudentDesignAcademicCalendarPanel({super.key, required this.height});

  final double height;

  @override
  State<StudentDesignAcademicCalendarPanel> createState() =>
      _StudentDesignAcademicCalendarPanelState();
}

class _StudentDesignAcademicCalendarPanelState
    extends State<StudentDesignAcademicCalendarPanel> {
  DesignAcademicCalendarData? _data;
  List<StudentPortalExam> _exams = const [];
  List<StudentPortalMentorshipEvent> _mentorship = const [];
  bool _loading = true;
  bool _loadStarted = false;
  DateTime _selectedDay = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _load();
  }

  Future<void> _load() async {
    final scope = StudentPortalScope.of(context);
    final classIds = scope.enrollments.map((e) => e.classId).toSet();
    final db = context.read<AppState>().db;
    final portal = StudentPortalService(db);
    final data = await DesignAcademicCalendarData.load(
      db,
      allowedClassIds: classIds,
    );
    final exams = await portal.loadExams(scope.enrollments);
    final mentorship = await portal.loadMentorshipEvents(scope.enrollments);
    if (!mounted) return;
    setState(() {
      _data = data;
      _exams = exams;
      _mentorship = mentorship;
      _loading = false;
    });
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  List<StudentPortalExam> _examsOnDay(DateTime day) {
    final key = _dateKey(day);
    return _exams.where((e) => e.date.startsWith(key)).toList();
  }

  List<StudentPortalMentorshipEvent> _mentorshipOnDay(DateTime day) {
    final key = _dateKey(day);
    return _mentorship.where((e) => e.date.startsWith(key)).toList();
  }

  bool _dayHasEvents(DateTime day, DesignAcademicCalendarData data) {
    if (_mentorshipOnDay(day).isNotEmpty) return true;
    if (_examsOnDay(day).isNotEmpty) return true;
    final w = day.weekday;
    if (w >= DateTime.monday && w <= DateTime.friday) {
      return data.dayLessons[w]?.isNotEmpty ?? false;
    }
    return false;
  }

  int _weekdayIndex(DateTime date) {
    final w = date.weekday;
    if (w >= DateTime.monday && w <= DateTime.friday) return w;
    return DateTime.monday;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading || _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = _data!;
    final dayIndex = _weekdayIndex(_selectedDay);
    final lessons = data.dayLessons[dayIndex] ?? const <DesignCalendarLesson>[];
    final dayExams = _examsOnDay(_selectedDay);
    final dayMentorship = _mentorshipOnDay(_selectedDay);
    final isToday = _sameDay(_selectedDay, DateTime.now());
    final eventsTitle = isToday
        ? strings.t('designTodayEvents')
        : strings.t('designSelectedDayEvents');

    return SizedBox(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignMonthGridCalendar(
            selectedDate: _selectedDay,
            hasEventsOnDate: (d) => _dayHasEvents(d, data),
            onSelected: (d) => setState(() => _selectedDay = d),
          ),
          const SizedBox(height: 16),
          Text(eventsTitle, style: DesignSystem.sectionTitle(context)),
          const SizedBox(height: 12),
          Expanded(
            child: lessons.isEmpty && dayExams.isEmpty && dayMentorship.isEmpty
                ? Center(
                    child: Text(
                      strings.t('noEvents'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount:
                        dayMentorship.length + dayExams.length + lessons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index < dayMentorship.length) {
                        final event = dayMentorship[index];
                        final label = event.isParentMeeting
                            ? strings.t('parentMeetingEvent')
                            : mentorshipEventTypeLabel(
                                strings,
                                event.type,
                              );
                        return Semantics(
                          label: '$label, ${event.title}, ${event.time}',
                          child: DesignSurfaceCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDB2777),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    mentorshipEventTypeIcon(event.type),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      Text(
                                        '${label} · ${event.time}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final examIndex = index - dayMentorship.length;
                      if (examIndex < dayExams.length) {
                        final exam = dayExams[examIndex];
                        return Semantics(
                          label: '${exam.title}, ${exam.date}',
                          child: DesignSurfaceCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.quiz_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      Text(
                                        exam.date,
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final lesson =
                          lessons[index - dayMentorship.length - dayExams.length];
                      final times = data.periodTimes[lesson.period];
                      final timeLabel = times != null
                          ? '${times.start} - ${times.end}'
                          : '';
                      return DesignSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: lesson.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.event_note,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  if (timeLabel.isNotEmpty)
                                    Text(
                                      timeLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class StudentWeeklyScheduleReadOnlyPanel extends StatelessWidget {
  const StudentWeeklyScheduleReadOnlyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = StudentPortalScope.of(context);
    final classIds = scope.enrollments.map((e) => e.classId).toSet();
    return WeeklySchedulePanel(
      readOnly: true,
      allowedStudentClassIds: classIds,
    );
  }
}

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(strings.t('studentPortalFilterAll')),
                selected: _filter == 'all',
                onSelected: (_) => setState(() => _filter = 'all'),
              ),
              ChoiceChip(
                label: Text(strings.t('studentPortalFilterPending')),
                selected: _filter == 'pending',
                onSelected: (_) => setState(() => _filter = 'pending'),
              ),
              ChoiceChip(
                label: Text(strings.t('studentPortalFilterCompleted')),
                selected: _filter == 'completed',
                onSelected: (_) => setState(() => _filter = 'completed'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<StudentPortalHomework>>(
            future: StudentPortalService(context.read<AppState>().db)
                .loadHomework(
              enrollments: scope.enrollments,
              filter: _filter,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return AppEmptyState(
                  icon: Icons.assignment_outlined,
                  title: strings.t('studentPortalNoHomework'),
                );
              }
              return ListView.separated(
                padding: AppSpacing.pagePadding(context.layoutWidth),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final h = items[index];
                  final done =
                      h.status == StudentAssignmentStatus.completed;
                  return StudentPortalActivityCard(
                    title: h.title,
                    subtitleLines: [h.enrollment.displayClass],
                    teacherLabel: h.teacherLabel,
                    statusLabel: done
                        ? strings.t('studentPortalStatusDone')
                        : strings.t('studentPortalStatusPending'),
                    statusColor: done
                        ? AppColors.accentGreen
                        : AppColors.brandPrimary,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class StudentExamsScreen extends StatelessWidget {
  const StudentExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    return FutureBuilder<List<StudentPortalExam>>(
      future: StudentPortalService(context.read<AppState>().db)
          .loadExams(scope.enrollments),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return AppEmptyState(
            icon: Icons.quiz_outlined,
            title: strings.t('studentPortalNoExams'),
          );
        }
        return ListView.separated(
          padding: AppSpacing.pagePadding(context.layoutWidth),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final e = items[index];
            final value = e.absent
                ? strings.t('scoreAbsent')
                : (e.score != null
                    ? '${e.score}'
                    : strings.t('studentPortalNoGradeYet'));
            return StudentPortalActivityCard(
              title: e.title,
              subtitleLines: [e.enrollment.displayClass],
              teacherLabel: e.teacherLabel,
              trailingPrimary: e.date,
              trailingSecondary: value,
            );
          },
        );
      },
    );
  }
}

class StudentPerformanceScreen extends StatelessWidget {
  const StudentPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    final service = StudentPortalService(context.read<AppState>().db);
    return FutureBuilder<({List<Map<String, Object?>> perf, List<Map<String, Object?>> feedback})>(
      future: () async {
        final perf = await service.loadPerformanceRows(scope.primary);
        final feedback = <Map<String, Object?>>[];
        for (final enr in scope.enrollments) {
          feedback.addAll(await service.loadPublishedBehaviors(enr));
        }
        return (perf: perf, feedback: feedback);
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!.perf;
        final feedback = snapshot.data!.feedback;
        if (rows.isEmpty && feedback.isEmpty) {
          return AppEmptyState(
            icon: Icons.insights_outlined,
            title: strings.t('studentPortalNoPerformance'),
          );
        }
        final daily = StudentDailyPerformance.dailyAveragesForStudent(
          rows,
          studentId: scope.primary.studentId,
        );
        return ListView(
          padding: AppSpacing.pagePadding(context.layoutWidth),
          children: [
            if (feedback.isNotEmpty) ...[
              Text(
                strings.t('studentPortalBehaviorFeedback'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...feedback.map(
                (row) => AppCard(
                  child: ListTile(
                    title: Text(row['davranis_ad'] as String? ?? ''),
                    subtitle: Text(row['tarih'] as String? ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (daily.isNotEmpty)
              AppCard(
                child: Text(
                  '${strings.t('periodAverage')}: '
                  '${StudentDailyPerformance.formatAverage(
                    StudentDailyPerformance.periodAverageFromDailyAverages(
                      daily,
                    ),
                  )}',
                ),
              ),
            ...rows.map((row) {
              final display = formatStudentScoreDisplay(
                numericScore: row['not_deger'] as int?,
                absent: studentScoreRowIsAbsent(row),
              );
              final label = display == '—'
                  ? strings.t('studentPortalNoGradeYet')
                  : (display == 'a'
                      ? strings.t('scoreAbsent')
                      : display);
              return AppCard(
                child: ListTile(
                  title: Text(row['kolon_ad'] as String? ?? ''),
                  subtitle: Text(row['tarih'] as String? ?? ''),
                  trailing: Text(label),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    return FutureBuilder<List<StudentPortalAttendance>>(
      future: StudentPortalService(context.read<AppState>().db)
          .loadAttendance(scope.enrollments),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return AppEmptyState(
            icon: Icons.event_busy_outlined,
            title: strings.t('studentPortalNoAttendance'),
          );
        }
        return ListView.separated(
          padding: AppSpacing.pagePadding(context.layoutWidth),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final a = items[index];
            return StudentPortalActivityCard(
              title: a.date,
              subtitleLines: [a.courseLabel, a.enrollment.displayClass],
              teacherLabel: a.teacherLabel,
              statusLabel: strings.t('scoreAbsent'),
              statusColor: AppColors.accentRed,
            );
          },
        );
      },
    );
  }
}

class StudentDocumentsScreen extends StatefulWidget {
  const StudentDocumentsScreen({super.key});

  @override
  State<StudentDocumentsScreen> createState() => _StudentDocumentsScreenState();
}

class _StudentDocumentsScreenState extends State<StudentDocumentsScreen> {
  int _filterIndex = 0;
  bool _showSearch = false;
  String _query = '';

  List<String> _filterLabels(AppLocalizations strings) => [
        strings.t('studentPortalFilterAll'),
        strings.t('designFilterSchool'),
        strings.t('designFilterClass'),
        strings.t('designFilterParent'),
      ];

  StudentDocumentFilter _filterFromIndex(int index) {
    return switch (index) {
      0 => StudentDocumentFilter.all,
      1 => StudentDocumentFilter.school,
      2 => StudentDocumentFilter.classScope,
      _ => StudentDocumentFilter.course,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    return FutureBuilder<List<StudentPortalDocument>>(
      future: StudentPortalService(context.read<AppState>().db)
          .loadDocuments(scope.enrollments),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = filterStudentDocuments(
          snapshot.data!,
          _filterFromIndex(_filterIndex),
        );
        final q = _query.trim().toLowerCase();
        if (q.isNotEmpty) {
          docs = docs
              .where((d) => d.name.toLowerCase().contains(q))
              .toList();
        }
        return DesignPortalPageLayout(
          title: strings.t('studentPortalDocuments'),
          filterLabels: _filterLabels(strings),
          selectedFilterIndex: _filterIndex,
          onFilterSelected: (i) => setState(() => _filterIndex = i),
          searchHint: strings.t('designSearchDocuments'),
          showSearchField: _showSearch,
          onSearchToggle: () => setState(() => _showSearch = !_showSearch),
          onSearchChanged: (v) => setState(() => _query = v),
          body: docs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: AppEmptyState(
                    icon: Icons.folder_open_outlined,
                    title: strings.t('studentPortalNoDocuments'),
                  ),
                )
              : DesignGroupedListCard(
                  children: [
                    for (var i = 0; i < docs.length; i++)
                      DesignFeedRow(
                        title: docs[i].name,
                        subtitle: [
                          docs[i].type,
                          if (docs[i].date.isNotEmpty) docs[i].date,
                        ].where((s) => s.isNotEmpty).join(' • '),
                        dateLabel: '',
                        icon: documentFeedIcon(docs[i].type),
                        iconBackground: documentFeedAccent(i),
                        semanticsLabel: strings.t('designOpenDocument')
                            .replaceAll('{name}', docs[i].name),
                        onTap: () => openStudentPortalDocument(context, docs[i]),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState extends State<StudentAnnouncementsScreen> {
  int _filterIndex = 0;
  bool _showSearch = false;
  String _query = '';
  Set<int> _unreadIds = {};
  bool _pendingOpenScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUnread();
    if (!_pendingOpenScheduled) {
      _pendingOpenScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _consumePendingAnnouncementOpen();
      });
    }
  }

  Future<void> _consumePendingAnnouncementOpen() async {
    final id = context.read<AppState>().takePendingStudentAnnouncementOpenId();
    if (id == null || !mounted) return;
    await openStudentAnnouncementDetailById(context, id);
    await _loadUnread();
  }

  Future<void> _loadUnread() async {
    final ids = await unreadStudentAnnouncementIds(
      context.read<AppState>(),
    );
    if (mounted) setState(() => _unreadIds = ids);
  }

  List<String> _filterLabels(AppLocalizations strings) => [
        strings.t('studentPortalFilterAll'),
        strings.t('designFilterSchool'),
        strings.t('designFilterClass'),
        strings.t('designFilterParent'),
      ];

  StudentAnnouncementFilter _filterFromIndex(int index) {
    return switch (index) {
      0 => StudentAnnouncementFilter.all,
      1 => StudentAnnouncementFilter.school,
      2 => StudentAnnouncementFilter.classScope,
      _ => StudentAnnouncementFilter.parentHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    return FutureBuilder<List<StudentPortalAnnouncement>>(
      future: StudentPortalService(context.read<AppState>().db)
          .loadAnnouncements(scope.enrollments),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = filterStudentAnnouncements(
          snapshot.data!,
          _filterFromIndex(_filterIndex),
        );
        final q = _query.trim().toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where(
                (a) =>
                    a.title.toLowerCase().contains(q) ||
                    a.body.toLowerCase().contains(q),
              )
              .toList();
        }
        return DesignPortalPageLayout(
          title: strings.t('studentPortalAnnouncements'),
          filterLabels: _filterLabels(strings),
          selectedFilterIndex: _filterIndex,
          onFilterSelected: (i) => setState(() => _filterIndex = i),
          searchHint: strings.t('designSearchAnnouncements'),
          showSearchField: _showSearch,
          onSearchToggle: () => setState(() => _showSearch = !_showSearch),
          onSearchChanged: (v) => setState(() => _query = v),
          body: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: AppEmptyState(
                    icon: Icons.campaign_outlined,
                    title: strings.t('studentPortalNoAnnouncements'),
                  ),
                )
              : DesignGroupedListCard(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      DesignFeedRow(
                        title: items[i].title,
                        subtitle: announcementBodyPreview(items[i].body),
                        dateLabel: announcementShortDate(items[i].date),
                        icon: announcementFeedIcon(items[i], i),
                        iconBackground: announcementFeedAccent(i),
                        unread: _unreadIds.contains(items[i].id),
                        semanticsLabel: _unreadIds.contains(items[i].id)
                            ? '${items[i].title}, ${strings.t('designUnreadAnnouncement')}'
                            : items[i].title,
                        onTap: () async {
                          openStudentAnnouncementDetail(context, items[i]);
                          await _loadUnread();
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scope = StudentPortalScope.of(context);
    final p = scope.primary;
    return ListView(
      padding: AppSpacing.pagePadding(context.layoutWidth),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentProfileHeader(
                name: p.studentName,
                subtitle: p.displayClass,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.lg),
              StudentProfileInfoRow(
                label: strings.t('studentNumber'),
                value: '${p.number}',
              ),
              StudentProfileInfoRow(
                label: strings.t('studentClassName'),
                value: p.displayClass,
              ),
              if (p.email != null && p.email!.isNotEmpty)
                StudentProfileInfoRow(
                  label: strings.t('studentPortalEmail'),
                  value: p.email!,
                ),
            ],
          ),
        ),
        if (scope.enrollments.length > 1) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('studentPortalAllClasses'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ...scope.enrollments.map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.displayClass),
                    subtitle: Text(e.studentName),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
