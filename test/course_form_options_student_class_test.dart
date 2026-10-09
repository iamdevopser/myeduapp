import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/course_form_options.dart';

void main() {
  group('CourseFormOptions student class notebook', () {
    test('grade section label shows class level and section', () {
      expect(
        CourseFormOptions.studentClassGradeSectionLabel(
          '8. Sınıf',
          section: 'B',
        ),
        '8. Sınıf B',
      );
      expect(
        CourseFormOptions.studentClassGradeSectionLabel('9. Sınıf'),
        '9. Sınıf',
      );
    });

    test('notebook sort orders grade then section A B C', () {
      final rows = [
        {'id': 1, 'ad': '9. Sınıf', 'sube': 'B'},
        {'id': 2, 'ad': '7. Sınıf', 'sube': 'C'},
        {'id': 3, 'ad': '8. Sınıf', 'sube': 'A'},
        {'id': 4, 'ad': '7. Sınıf', 'sube': 'A'},
        {'id': 5, 'ad': '8. Sınıf', 'sube': null},
      ];
      rows.sort(CourseFormOptions.compareStudentClassRowsNotebook);
      expect(
        rows.map((r) => r['id']).toList(),
        [4, 2, 3, 5, 1],
      );
    });
  });
}
