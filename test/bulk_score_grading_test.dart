import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/bulk_score_grading.dart';

void main() {
  group('applyBulkStudentScores', () {
    test('saves each selected student only', () async {
      final saved = <int>[];
      final failures = await applyBulkStudentScores(
        studentIds: [1, 2, 3],
        saveStudent: (id) async {
          saved.add(id);
        },
      );
      expect(failures, 0);
      expect(saved, [1, 2, 3]);
    });

    test('reports failures without stopping successful saves', () async {
      final saved = <int>[];
      final failures = await applyBulkStudentScores(
        studentIds: [1, 2, 3],
        saveStudent: (id) async {
          if (id == 2) {
            throw Exception('db');
          }
          saved.add(id);
        },
      );
      expect(failures, 1);
      expect(saved, [1, 3]);
    });
  });
}
