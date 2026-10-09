import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/parent_portal_service.dart';
import '../../services/secretary_document_service.dart';
import '../../services/student_portal_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/parent_navigation.dart';
import '../../utils/student_score_display.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/reference_stat_card.dart';
import '../academic_plans/weekly_schedule_panel.dart';
import '../student_portal/widgets/student_portal_ui.dart';
import 'widgets/parent_document_tile.dart';

class ParentStudentPicker extends StatelessWidget {
  const ParentStudentPicker({
    super.key,
    required this.students,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ParentLinkedStudent> students;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (students.isEmpty) {
      return Text(strings.t('parentNoLinkedStudents'));
    }
    if (students.length == 1) {
      return Text(
        '${strings.t('parentSelectedStudent')}: ${students.first.studentName}',
      );
    }
    return DropdownButtonFormField<int?>(
      isExpanded: true,
      value: selectedId,
      decoration: InputDecoration(
        labelText: strings.t('parentSelectStudent'),
      ),
      items: [
        ...students.map(
          (s) => DropdownMenuItem(
            value: s.studentId,
            child: Text('${s.studentName} (${s.displayClass})'),
          ),
        ),
      ],
      onChanged: onSelected,
    );
  }
}

Future<int?> _resolveStudentId(
  AppState state,
  List<ParentLinkedStudent> students,
) async {
  if (students.isEmpty) return null;
  final current = state.parentSelectedStudentId;
  if (current != null &&
      students.any((s) => s.studentId == current)) {
    return current;
  }
  final first = students.first.studentId;
  await state.selectParentStudent(first);
  return first;
}

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final parentId = state.sessionParentId!;
    final service = ParentPortalService(state.db);
    final width = context.layoutWidth;

    return FutureBuilder(
      future: Future.wait([
        service.parentProfile(parentId),
        service.listLinkedStudents(parentId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data![0] as Map<String, Object?>?;
        final students =
            snapshot.data![1] as List<ParentLinkedStudent>;
        final name = profile?['ad_soyad'] as String? ?? '';

        if (students.isEmpty) {
          return AppEmptyState(
            icon: Icons.family_restroom_outlined,
            title: strings.t('parentNoLinkedStudents'),
          );
        }

        return FutureBuilder<int?>(
          future: _resolveStudentId(state, students),
          builder: (context, idSnap) {
            final studentId = idSnap.data;
            if (studentId == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final student = students.firstWhere(
              (s) => s.studentId == studentId,
            );
            return FutureBuilder(
              future: Future.wait([
                service.dashboardSummaryForStudent(
                  parentId: parentId,
                  studentId: studentId,
                ),
                service.todayLessonsForStudent(
                  parentId: parentId,
                  studentId: studentId,
                ),
                service.announcementsForStudent(
                  parentId: parentId,
                  studentId: studentId,
                ),
              ]),
              builder: (context, dashSnap) {
                if (!dashSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final summary =
                    dashSnap.data![0] as StudentDashboardSummary;
                final today =
                    dashSnap.data![1] as List<StudentPortalTodayLesson>;
                final announcements =
                    dashSnap.data![2] as List<StudentPortalAnnouncement>;
                final cross = AppSpacing.gridCrossAxisCount(
                  width,
                  desktop: 4,
                  tablet: 2,
                );

                return SingleChildScrollView(
                  padding: AppSpacing.pagePadding(width),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.t('parentPortalWelcome'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ParentStudentPicker(
                        students: students,
                        selectedId: studentId,
                        onSelected: (id) => state.selectParentStudent(id),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      StudentProfileHeader(
                        name: student.studentName,
                        subtitle:
                            '${student.displayClass} · #${student.number}',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GridView.count(
                        crossAxisCount: cross,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: cross == 1 ? 2.4 : 1.55,
                        children: [
                          ReferenceStatCard(
                            label: strings.t('studentPortalCourses'),
                            value: '${summary.courseCount}',
                            icon: Icons.menu_book_outlined,
                            tint: AppColors.brandPrimary,
                            onTap: () => navigateParentSection(
                              context,
                              ParentNavSection.academic,
                            ),
                          ),
                          ReferenceStatCard(
                            label: strings.t('studentPortalPendingHomework'),
                            value: '${summary.pendingHomework}',
                            icon: Icons.assignment_outlined,
                            tint: const Color(0xFFF59E0B),
                            onTap: () => navigateParentSection(
                              context,
                              ParentNavSection.academic,
                            ),
                          ),
                          ReferenceStatCard(
                            label: strings.t('studentPortalUpcomingExams'),
                            value: '${summary.upcomingExams}',
                            icon: Icons.quiz_outlined,
                            tint: const Color(0xFFEF4444),
                            onTap: () => navigateParentSection(
                              context,
                              ParentNavSection.academic,
                            ),
                          ),
                          ReferenceStatCard(
                            label: strings.t('studentPortalAttendance'),
                            value: '${summary.absenceCount}',
                            icon: Icons.event_busy_outlined,
                            tint: const Color(0xFF0D9488),
                            onTap: () => navigateParentSection(
                              context,
                              ParentNavSection.attendance,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StudentPortalSectionHeader(
                              title: strings.t('studentPortalTodayLessons'),
                              actionLabel: strings.t('seeAll'),
                              onAction: () => navigateParentSection(
                                context,
                                ParentNavSection.weeklySchedule,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (today.isEmpty)
                              Text(strings.t('studentPortalNoTodayLessons'))
                            else
                              ...today.map(
                                (l) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l.courseName),
                                  subtitle: Text(l.timeRange),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StudentPortalSectionHeader(
                              title: strings.t('parentPortalAnnouncements'),
                              actionLabel: strings.t('seeAll'),
                              onAction: () => navigateParentSection(
                                context,
                                ParentNavSection.announcements,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (announcements.isEmpty)
                              Text(strings.t('teacherAnnouncementsEmpty'))
                            else
                              ...announcements.take(3).map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: StudentAnnouncementCard(
                                    title: a.title,
                                    body: a.body,
                                    date: a.date,
                                    teacherLabel: a.teacherLabel,
                                    courseName: a.courseName.isNotEmpty
                                        ? a.courseName
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: Text(strings.t('parentPortalAcademic')),
                            onPressed: () => navigateParentSection(
                              context,
                              ParentNavSection.academic,
                            ),
                          ),
                          ActionChip(
                            label: Text(strings.t('parentPortalAttendance')),
                            onPressed: () => navigateParentSection(
                              context,
                              ParentNavSection.attendance,
                            ),
                          ),
                          ActionChip(
                            label: Text(strings.t('parentPortalDocuments')),
                            onPressed: () => navigateParentSection(
                              context,
                              ParentNavSection.documents,
                            ),
                          ),
                          ActionChip(
                            label: Text(strings.t('parentPortalProfile')),
                            onPressed: () => navigateParentSection(
                              context,
                              ParentNavSection.profile,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ParentChildrenScreen extends StatelessWidget {
  const ParentChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final service = ParentPortalService(state.db);
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder<List<ParentLinkedStudent>>(
      future: service.listLinkedStudents(state.sessionParentId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data!;
        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            children: students
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () async {
                        await state.selectParentStudent(s.studentId);
                        if (context.mounted) {
                          navigateParentSection(
                            context,
                            ParentNavSection.home,
                          );
                        }
                      },
                      child: ListTile(
                        title: Text(s.studentName),
                        subtitle: Text(
                          '${strings.t('parentRelation')}: ${s.relationCode}\n'
                          '${s.displayClass} · #${s.number}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _StudentScopedScreen extends StatelessWidget {
  const _StudentScopedScreen({required this.builder});

  final Widget Function(
    BuildContext context,
    int parentId,
    int studentId,
    ParentLinkedStudent student,
  ) builder;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canAccessParentWorkspace) {
      return Center(child: Text(strings.t('parentAccessDenied')));
    }
    final service = ParentPortalService(state.db);

    return FutureBuilder<List<ParentLinkedStudent>>(
      future: service.listLinkedStudents(state.sessionParentId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data!;
        return FutureBuilder<int?>(
          future: _resolveStudentId(state, students),
          builder: (context, idSnap) {
            final studentId = idSnap.data;
            if (studentId == null) {
              return Center(child: Text(strings.t('parentNoLinkedStudents')));
            }
            final student = students.firstWhere(
              (s) => s.studentId == studentId,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: AppSpacing.pagePadding(
                    MediaQuery.sizeOf(context).width,
                  ).copyWith(bottom: 0),
                  child: ParentStudentPicker(
                    students: students,
                    selectedId: studentId,
                    onSelected: (id) => state.selectParentStudent(id),
                  ),
                ),
                Expanded(
                  child: builder(
                    context,
                    state.sessionParentId!,
                    studentId,
                    student,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ParentAnnouncementsScreen extends StatelessWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _StudentScopedScreen(
      builder: (context, parentId, studentId, student) {
        final service = ParentPortalService(context.read<AppState>().db);
        return FutureBuilder<List<StudentPortalAnnouncement>>(
          future: service.announcementsForStudent(
            parentId: parentId,
            studentId: studentId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return Center(child: Text(strings.t('teacherAnnouncementsEmpty')));
            }
            return ListView.separated(
              padding: AppSpacing.pagePadding(context.layoutWidth),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = items[i];
                return StudentAnnouncementCard(
                  title: a.title,
                  body: a.body,
                  date: a.date,
                  teacherLabel: a.teacherLabel,
                  courseName:
                      a.courseName.isNotEmpty ? a.courseName : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

class ParentDocumentsScreen extends StatelessWidget {
  const ParentDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final docService = SecretaryDocumentService(state.db, state.fileService);

    return _StudentScopedScreen(
      builder: (context, parentId, studentId, student) {
        final portal = ParentPortalService(state.db);
        return FutureBuilder<List<SecretaryDocument>>(
          future: portal.documentsForStudent(
            parentId: parentId,
            studentId: studentId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!;
            if (docs.isEmpty) {
              return Center(child: Text(strings.t('documentEmpty')));
            }
            return ListView.separated(
              padding: AppSpacing.pagePadding(context.layoutWidth),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = docs[i];
                return ParentDocumentTile(
                  document: d,
                  onOpen: () => docService.openDocument(d),
                  onDownload: () async {
                    final path = await docService.pickSaveCopyPath(d);
                    if (path != null) {
                      await docService.copyToPath(d, path);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class ParentAttendanceScreen extends StatelessWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return _StudentScopedScreen(
      builder: (context, parentId, studentId, student) {
        final service = ParentPortalService(context.read<AppState>().db);
        return FutureBuilder(
          future: Future.wait([
            service.attendanceForStudent(
              parentId: parentId,
              studentId: studentId,
            ),
            service.attendanceSummaryForStudent(
              parentId: parentId,
              studentId: studentId,
            ),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data![0] as List<Map<String, Object?>>;
            final summary =
                snapshot.data![1] as Map<String, int>;
            return SingleChildScrollView(
              padding: AppSpacing.pagePadding(context.layoutWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Wrap(
                      spacing: 16,
                      children: summary.entries
                          .map(
                            (e) => Chip(
                              label: Text('${e.key}: ${e.value}'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...rows.map(
                    (r) => AppCard(
                      child: ListTile(
                        title: Text(r['tarih'] as String? ?? ''),
                        subtitle: Text(r['durum'] as String? ?? ''),
                      ),
                    ),
                  ),
                  if (rows.isEmpty)
                    Text(strings.t('parentAttendanceEmpty')),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ParentAcademicScreen extends StatelessWidget {
  const ParentAcademicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StudentScopedScreen(
      builder: (context, parentId, studentId, student) {
        final service = ParentPortalService(context.read<AppState>().db);
        return FutureBuilder<List<Map<String, Object?>>>(
          future: service.academicRowsForStudent(
            parentId: parentId,
            studentId: studentId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data!;
            final strings = AppLocalizations.of(context);
            if (rows.isEmpty) {
              return AppEmptyState(
                icon: Icons.school_outlined,
                title: strings.t('studentPortalNoPerformance'),
              );
            }
            return ListView.separated(
              padding: AppSpacing.pagePadding(context.layoutWidth),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = rows[i];
                final display = formatStudentScoreDisplay(
                  numericScore: r['not_deger'] as int?,
                  absent: studentScoreRowIsAbsent(r),
                );
                final label = display == '—'
                    ? strings.t('studentPortalNoGradeYet')
                    : (display == 'a'
                        ? strings.t('scoreAbsent')
                        : display);
                return StudentPortalActivityCard(
                  title: r['kolon_ad'] as String? ?? '',
                  subtitleLines: [r['tarih'] as String? ?? ''],
                  teacherLabel: student.relationCode.isNotEmpty
                      ? student.relationCode
                      : strings.t('parentRelation'),
                  trailingPrimary: label,
                );
              },
            );
          },
        );
      },
    );
  }
}

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final service = ParentPortalService(state.db);
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder(
      future: Future.wait([
        service.parentProfile(state.sessionParentId!),
        service.listLinkedStudents(state.sessionParentId!),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final p = snapshot.data![0] as Map<String, Object?>?;
        final students =
            snapshot.data![1] as List<ParentLinkedStudent>;
        final name = p?['ad_soyad'] as String? ?? '';
        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentProfileHeader(
                      name: name,
                      subtitle: strings.t('parentPortalTitle'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (p?['email'] != null)
                      StudentProfileInfoRow(
                        label: strings.t('studentPortalEmail'),
                        value: p!['email'] as String,
                      ),
                    if (p?['telefon'] != null)
                      StudentProfileInfoRow(
                        label: strings.t('secretaryParentPhoneOptional'),
                        value: p!['telefon'] as String,
                      ),
                    Text(
                      strings.t('parentPortalReadOnlyHint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (students.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.t('parentPortalChildren'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...students.map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.studentName),
                          subtitle: Text(s.displayClass),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ParentWeeklyScheduleScreen extends StatelessWidget {
  const ParentWeeklyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StudentScopedScreen(
      builder: (context, parentId, studentId, student) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: AppSpacing.pagePadding(context.layoutWidth),
              child: SizedBox(
                height: constraints.maxHeight,
                child: WeeklySchedulePanel(
                  readOnly: true,
                  allowedStudentClassIds: {student.classId},
                ),
              ),
            );
          },
        );
      },
    );
  }
}
