import 'package:flutter/material.dart';

import '../../models/student_enrollment.dart';

class StudentPortalScope extends InheritedWidget {
  const StudentPortalScope({
    super.key,
    required this.enrollments,
    required this.primary,
    required super.child,
  });

  final List<StudentEnrollment> enrollments;
  final StudentEnrollment primary;

  static StudentPortalScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StudentPortalScope>();
    assert(scope != null, 'StudentPortalScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(StudentPortalScope oldWidget) {
    return oldWidget.primary.studentId != primary.studentId ||
        oldWidget.enrollments.length != enrollments.length;
  }
}
