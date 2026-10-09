import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/services/student_portal_service.dart';
import 'package:my_edu_app/utils/student_announcement_meta.dart';
import 'package:my_edu_app/utils/student_portal_announcement_ui.dart';
import 'package:my_edu_app/utils/mobile_bottom_nav_destinations.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/utils/student_nav_section.dart';
import 'package:my_edu_app/widgets/design/design_portal_page_layout.dart';
import 'package:my_edu_app/widgets/design/design_scroll_filter_pills.dart';

void main() {
  test('student bottom nav includes calendar tab', () {
    final specs = mobileBottomNavSpecsForRole(AppRole.student);
    expect(specs.length, 5);
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.student,
        specs: specs,
        studentSection: StudentNavSection.academicPlansWeekly,
      ),
      2,
    );
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.student,
        specs: specs,
        studentSection: StudentNavSection.announcements,
      ),
      3,
    );
    expect(
      mobileBottomNavSelectedIndex(
        role: AppRole.student,
        specs: specs,
        studentSection: StudentNavSection.profile,
      ),
      4,
    );
  });

  test('grade filter excludes school-wide only', () {
    const items = [
      StudentPortalAnnouncement(
        id: 1,
        title: 'G',
        body: '',
        teacherLabel: 'T',
        courseName: '',
        date: '',
        targetType: StudentAnnouncementTargetType.grade,
      ),
    ];
    final filtered = filterStudentAnnouncements(
      items,
      StudentAnnouncementFilter.classScope,
    );
    expect(filtered.length, 1);
  });

  testWidgets('DesignPortalPageLayout at 1280 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 400));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesignPortalPageLayout(
            title: 'Duyurular',
            filterLabels: const ['Tümü', 'Okul'],
            selectedFilterIndex: 0,
            onFilterSelected: (_) {},
            body: const Text('content'),
          ),
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('DesignScrollFilterPills at 768 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 100));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesignScrollFilterPills(
            labels: const ['Tümü', 'Okul', 'Sınıf', 'Veli'],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(DesignScrollFilterPills), findsOneWidget);
  });
}
