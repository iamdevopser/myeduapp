import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/authorization_service.dart';
import '../widgets/app_shell.dart';

/// Oturum rolüne göre doğru [AppShell] sidebar/drawer ile sarar.
class WorkspaceAppShell extends StatelessWidget {
  const WorkspaceAppShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.teacherNavSection,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final TeacherNavSection? teacherNavSection;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);

    if (auth.canAccessTeacherWorkspace) {
      return AppShell(
        teacherSection: teacherNavSection,
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: child,
      );
    }
    if (auth.canAccessStudentWorkspace) {
      return AppShell(
        studentSection: state.activeStudentSection,
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: child,
      );
    }
    if (auth.canAccessParentWorkspace) {
      return AppShell(
        parentSection: state.activeParentSection,
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: child,
      );
    }
    if (auth.isSecretary && auth.isUnlocked) {
      return AppShell(
        secretarySection: state.activeSecretarySection,
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: child,
      );
    }
    if (auth.canAccessAdminWorkspace) {
      return AppShell(
        adminSection: state.activeAdminSection,
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}
