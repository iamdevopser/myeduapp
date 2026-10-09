import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../../l10n/app_localizations.dart';

import '../../models/student_enrollment.dart';

import '../../providers/app_state.dart';

import '../../services/student_portal_service.dart';

import '../../utils/app_navigation.dart';
import '../../widgets/app_empty_state.dart';

import 'student_portal_scope.dart';



typedef StudentPortalChildBuilder = Widget Function(

  BuildContext context,

  List<StudentEnrollment> enrollments,

  StudentEnrollment primary,

);



/// Oturumdaki öğrenciye ait veri kapsamı (profil seçimi yok).

class StudentSessionGate extends StatelessWidget {

  const StudentSessionGate({super.key, required this.builder});



  final StudentPortalChildBuilder builder;



  @override

  Widget build(BuildContext context) {

    final state = context.watch<AppState>();

    final strings = AppLocalizations.of(context);



    if (!state.isStudent || state.sessionStudentId == null) {

      return AppEmptyState(

        icon: Icons.lock_outline,

        title: strings.t('studentPortalLoginRequired'),

        description: strings.t('studentPortalLoginRequiredHint'),

        actionLabel: strings.t('exitToHome'),

        onAction: () {

          state.clearSession();

          leaveWorkspaceToLogin(context);

        },

      );

    }



    return FutureBuilder<List<StudentEnrollment>>(

      future: _loadEnrollments(state),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {

          return const Center(child: CircularProgressIndicator());

        }

        final enrollments = snapshot.data!;

        if (enrollments.isEmpty) {

          return AppEmptyState(

            icon: Icons.person_off_outlined,

            title: strings.t('studentPortalNoProfile'),

          );

        }

        final primary = enrollments.firstWhere(

          (e) =>

              e.studentId == state.sessionStudentId! &&

              e.classId == state.sessionClassId!,

          orElse: () => enrollments.first,

        );

        return StudentPortalScope(

          enrollments: enrollments,

          primary: primary,

          child: builder(context, enrollments, primary),

        );

      },

    );

  }



  Future<List<StudentEnrollment>> _loadEnrollments(AppState state) async {

    final service = StudentPortalService(state.db);

    final classId = state.sessionClassId;

    final studentId = state.sessionStudentId;

    if (classId == null || studentId == null) return [];

    final primary = await service.enrollmentBySession(

      classId: classId,

      studentId: studentId,

    );

    if (primary == null) return [];

    return service.enrollmentsForIdentity(primary);

  }

}


