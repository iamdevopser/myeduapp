import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/services/student_portal_service.dart';
import 'package:my_edu_app/utils/student_announcement_meta.dart';
import 'package:my_edu_app/utils/student_portal_announcement_ui.dart';
import 'package:my_edu_app/widgets/design/design_feed_row.dart';
import 'package:my_edu_app/widgets/design/design_grouped_list_card.dart';
import 'package:my_edu_app/widgets/design/design_month_grid_calendar.dart';
import 'package:my_edu_app/widgets/design/design_scroll_filter_pills.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('DesignScrollFilterPills at 360px', (tester) async {
    var selected = 0;
    await tester.binding.setSurfaceSize(const Size(360, 120));
    await tester.pumpWidget(
      _wrap(
        DesignScrollFilterPills(
          labels: const ['Tümü', 'Okul', 'Sınıf', 'Veli'],
          selectedIndex: selected,
          onSelected: (i) => selected = i,
        ),
      ),
    );
    expect(find.text('Okul'), findsOneWidget);
    await tester.tap(find.text('Sınıf'));
    await tester.pump();
    expect(selected, 2);
  });

  testWidgets('DesignFeedRow and grouped card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 400));
    await tester.pumpWidget(
      _wrap(
        DesignGroupedListCard(
          children: const [
            DesignFeedRow(
              title: 'Okul Kayıt Duyurusu',
              subtitle: 'Yeni kayıt dönemi hakkında bilgilendirme.',
              dateLabel: '12 Mar',
              icon: Icons.campaign_outlined,
              iconBackground: Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Okul Kayıt Duyurusu'), findsOneWidget);
  });

  testWidgets('DesignMonthGridCalendar renders month', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 420));
    await tester.pumpWidget(
      _wrap(
        DesignMonthGridCalendar(
          hasEventsOnWeekday: (w) => w == DateTime.monday,
        ),
      ),
    );
    expect(find.byType(DesignMonthGridCalendar), findsOneWidget);
  });

  test('announcement filter school and section scope', () {
    const items = [
      StudentPortalAnnouncement(
        id: 1,
        title: 'A',
        body: '',
        teacherLabel: 'T',
        courseName: '',
        date: '2025-03-01',
        targetType: StudentAnnouncementTargetType.allSchool,
      ),
      StudentPortalAnnouncement(
        id: 2,
        title: 'B',
        body: '',
        teacherLabel: 'T',
        courseName: 'Mat',
        date: '2025-03-02',
        targetType: StudentAnnouncementTargetType.grade,
      ),
      StudentPortalAnnouncement(
        id: 3,
        title: 'C',
        body: '',
        teacherLabel: 'T',
        courseName: '',
        date: '2025-03-03',
        targetType: StudentAnnouncementTargetType.section,
        classId: 3,
      ),
    ];
    final school = filterStudentAnnouncements(
      items,
      StudentAnnouncementFilter.school,
    );
    expect(school.length, 1);
    expect(school.first.id, 1);
    final veli = filterStudentAnnouncements(
      items,
      StudentAnnouncementFilter.parentHint,
    );
    expect(veli.single.id, 3);
  });
}
