import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/utils/admin_nav_section.dart';
import 'package:my_edu_app/utils/mobile_bottom_nav_destinations.dart';
import 'package:my_edu_app/utils/parent_nav_section.dart';
import 'package:my_edu_app/utils/secretary_nav_section.dart';
import 'package:my_edu_app/utils/student_nav_section.dart';
import 'package:my_edu_app/utils/teacher_nav_section.dart';

void main() {
  test('roles expose expected bottom nav destination counts', () {
    for (final role in AppRole.values) {
      final count = mobileBottomNavSpecsForRole(role).length;
      if (role == AppRole.student) {
        expect(count, 5);
      } else {
        expect(count, 4);
      }
    }
  });

  test('teacher selected index follows workspace section', () {
    final specs = mobileBottomNavSpecsForRole(AppRole.teacher);
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.teacher,
        specs: specs,
        teacherSection: TeacherNavSection.studentPlatform,
      ),
      1,
    );
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.teacher,
        specs: specs,
        teacherSection: TeacherNavSection.settings,
      ),
      3,
    );
  });

  test('student selected index maps home and profile', () {
    final specs = mobileBottomNavSpecsForRole(AppRole.student);
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.student,
        specs: specs,
        studentSection: StudentNavSection.profile,
      ),
      4,
    );
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.student,
        specs: specs,
        studentSection: StudentNavSection.home,
      ),
      0,
    );
  });

  test('admin settings route highlights settings tab', () {
    final specs = mobileBottomNavSpecsForRole(AppRole.admin);
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.admin,
        specs: specs,
        adminSection: AdminNavSection.users,
        settingsRouteActive: true,
      ),
      3,
    );
  });

  test('secretary buckets map to students and attendance tabs', () {
    final specs = mobileBottomNavSpecsForRole(AppRole.secretary);
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.secretary,
        specs: specs,
        secretarySection: SecretaryNavSection.studentList,
      ),
      1,
    );
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.secretary,
        specs: specs,
        secretarySection: SecretaryNavSection.attendanceDaily,
      ),
      2,
    );
  });

  test('parent announcements tab index', () {
    final specs = mobileBottomNavSpecsForRole(AppRole.parent);
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.parent,
        specs: specs,
        parentSection: ParentNavSection.announcements,
      ),
      2,
    );
  });
}
