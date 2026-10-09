import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../../l10n/app_localizations.dart';

import '../../providers/app_state.dart';

import '../../services/student_portal_service.dart';

import '../../theme/app_colors.dart';

import '../../theme/app_spacing.dart';

import '../../utils/student_navigation.dart';

import '../../widgets/app_card.dart';

import '../../widgets/reference_stat_card.dart';

import 'student_portal_scope.dart';

import 'widgets/student_portal_ui.dart';

import 'widgets/student_teacher_badge.dart';



class StudentDashboardScreen extends StatefulWidget {

  const StudentDashboardScreen({super.key});



  @override

  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();

}



class _StudentDashboardScreenState extends State<StudentDashboardScreen> {

  StudentDashboardSummary? _summary;

  List<StudentPortalTodayLesson> _today = [];

  List<StudentPortalHomework> _homework = [];

  List<StudentPortalExam> _exams = [];

  List<StudentPortalAnnouncement> _announcements = [];

  bool _loading = true;



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    _load();

  }



  Future<void> _load() async {

    final scope = StudentPortalScope.of(context);

    final service = StudentPortalService(context.read<AppState>().db);

    final summary = await service.loadDashboardSummary(scope.enrollments);

    final today = await service.loadTodayLessons(scope.enrollments);

    final homework = await service.loadHomework(

      enrollments: scope.enrollments,

      filter: 'pending',

    );

    final exams = await service.loadExams(scope.enrollments);

    final announcements =

        await service.loadAnnouncements(scope.enrollments);

    if (!mounted) return;

    setState(() {

      _summary = summary;

      _today = today;

      _homework = homework.take(5).toList();

      _exams = exams.where((e) => e.isUpcoming).take(5).toList();

      _announcements = announcements.take(3).toList();

      _loading = false;

    });

  }



  @override

  Widget build(BuildContext context) {

    final strings = AppLocalizations.of(context);

    final scope = StudentPortalScope.of(context);

    if (_loading || _summary == null) {

      return const Center(child: CircularProgressIndicator());

    }

    final summary = _summary!;

    final cross = AppSpacing.gridCrossAxisCount(

      context.layoutWidth,

      desktop: 4,

      tablet: 2,

    );



    return SingleChildScrollView(

      padding: AppSpacing.pagePadding(context.layoutWidth),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            strings.t('studentPortalWelcome').replaceAll(

              '{name}',

              scope.primary.studentName,

            ),

            style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                  fontWeight: FontWeight.w700,

                ),

          ),

          const SizedBox(height: AppSpacing.xs),

          Text(

            strings.t('dashboardTodaySummary'),

            style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                  color: AppColors.textSecondary,

                ),

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

                icon: Icons.menu_book_outlined,

                label: strings.t('studentPortalCourses'),

                value: '${summary.courseCount}',

                tint: AppColors.brandPrimary,

                onTap: () => navigateStudentSection(

                  context,

                  StudentNavSection.courses,

                ),

              ),

              ReferenceStatCard(

                icon: Icons.assignment_outlined,

                label: strings.t('studentPortalPendingHomework'),

                value: '${summary.pendingHomework}',

                tint: const Color(0xFFF59E0B),

                onTap: () => navigateStudentSection(

                  context,

                  StudentNavSection.assignments,

                ),

              ),

              ReferenceStatCard(

                icon: Icons.quiz_outlined,

                label: strings.t('studentPortalUpcomingExams'),

                value: '${summary.upcomingExams}',

                tint: const Color(0xFFEF4444),

                onTap: () => navigateStudentSection(

                  context,

                  StudentNavSection.exams,

                ),

              ),

              ReferenceStatCard(

                icon: Icons.event_busy_outlined,

                label: strings.t('studentPortalAttendance'),

                value: '${summary.absenceCount}',

                tint: const Color(0xFF0D9488),

                onTap: () => navigateStudentSection(

                  context,

                  StudentNavSection.attendance,

                ),

              ),

            ],

          ),

          const SizedBox(height: AppSpacing.xl),

          _twoColumnLayout(

            context,

            left: _sectionCard(

              context,

              strings: strings,

              title: strings.t('studentPortalTodayLessons'),

              onSeeAll: null,

              child: _today.isEmpty

                  ? Text(strings.t('studentPortalNoTodayLessons'))

                  : Column(

                      children: _today

                          .map(

                            (l) => ListTile(

                              contentPadding: EdgeInsets.zero,

                              title: Text(l.courseName),

                              subtitle: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text(l.timeRange),

                                  StudentTeacherBadge(label: l.teacherLabel),

                                ],

                              ),

                            ),

                          )

                          .toList(),

                    ),

            ),

            right: _sectionCard(

              context,

              strings: strings,

              title: strings.t('studentPortalUpcomingHomework'),

              onSeeAll: () => navigateStudentSection(

                context,

                StudentNavSection.assignments,

              ),

              child: _homework.isEmpty

                  ? Text(strings.t('studentPortalNoHomework'))

                  : Column(

                      children: _homework

                          .map(

                            (h) => ListTile(

                              contentPadding: EdgeInsets.zero,

                              title: Text(h.title),

                              subtitle: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text(h.enrollment.displayClass),

                                  StudentTeacherBadge(label: h.teacherLabel),

                                ],

                              ),

                            ),

                          )

                          .toList(),

                    ),

            ),

          ),

          const SizedBox(height: AppSpacing.lg),

          _twoColumnLayout(

            context,

            left: _sectionCard(

              context,

              strings: strings,

              title: strings.t('studentPortalUpcomingExams'),

              onSeeAll: () => navigateStudentSection(

                context,

                StudentNavSection.exams,

              ),

              child: _exams.isEmpty

                  ? Text(strings.t('studentPortalNoExams'))

                  : Column(

                      children: _exams

                          .map(

                            (e) => ListTile(

                              contentPadding: EdgeInsets.zero,

                              title: Text(e.title),

                              subtitle: StudentTeacherBadge(

                                label: e.teacherLabel,

                              ),

                              trailing: Text(e.date),

                            ),

                          )

                          .toList(),

                    ),

            ),

            right: _sectionCard(

              context,

              strings: strings,

              title: strings.t('studentPortalAnnouncements'),

              onSeeAll: () => navigateStudentSection(

                context,

                StudentNavSection.announcements,

              ),

              child: _announcements.isEmpty

                  ? Text(strings.t('studentPortalNoAnnouncements'))

                  : Column(

                      children: _announcements

                          .map(

                            (a) => ListTile(

                              contentPadding: EdgeInsets.zero,

                              title: Text(a.title),

                              subtitle: StudentTeacherBadge(

                                label: a.teacherLabel,

                              ),

                              trailing: Text(a.date),

                            ),

                          )

                          .toList(),

                    ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _sectionCard(

    BuildContext context, {

    required AppLocalizations strings,

    required String title,

    required Widget child,

    VoidCallback? onSeeAll,

  }) {

    return AppCard(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          StudentPortalSectionHeader(

            title: title,

            actionLabel: onSeeAll != null ? strings.t('seeAll') : null,

            onAction: onSeeAll,

          ),

          const SizedBox(height: AppSpacing.md),

          child,

        ],

      ),

    );

  }



  Widget _twoColumnLayout(

    BuildContext context, {

    required Widget left,

    required Widget right,

  }) {

    if (context.isMobileLayout) {

      return Column(

        children: [left, const SizedBox(height: AppSpacing.lg), right],

      );

    }

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Expanded(child: left),

        const SizedBox(width: AppSpacing.lg),

        Expanded(child: right),

      ],

    );

  }

}


