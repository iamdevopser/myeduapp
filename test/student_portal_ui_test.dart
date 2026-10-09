import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/screens/student_portal/widgets/student_portal_ui.dart';

void main() {
  testWidgets('StudentProfileInfoRow stacks label on narrow width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudentProfileInfoRow(
            label: 'Sınıf',
            value: '9-A',
          ),
        ),
      ),
    );
    expect(find.text('Sınıf'), findsOneWidget);
    expect(find.text('9-A'), findsOneWidget);
  });

  testWidgets('StudentAnnouncementCard expands body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentAnnouncementCard(
            title: 'Duyuru',
            body: 'Detay metni',
            date: '2026-01-01',
            teacherLabel: 'Öğretmen',
          ),
        ),
      ),
    );
    expect(find.text('Duyuru'), findsOneWidget);
    await tester.tap(find.text('Duyuru'));
    await tester.pumpAndSettle();
    expect(find.text('Detay metni'), findsOneWidget);
  });
}
