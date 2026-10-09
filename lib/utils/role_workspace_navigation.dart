import 'package:flutter/material.dart';

import '../models/app_role.dart';
import 'admin_navigation.dart';
import 'secretary_navigation.dart';
import 'student_navigation.dart';
import 'teacher_navigation.dart';

void openRolePrimaryWorkspace(BuildContext context, AppRole role) {
  switch (role) {
    case AppRole.admin:
      openAdminPortal(context);
    case AppRole.teacher:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TeacherTabWorkspace()),
      );
    case AppRole.secretary:
      openSecretaryPortal(context);
    case AppRole.student:
      openStudentPortal(context);
    case AppRole.parent:
      break;
  }
}
