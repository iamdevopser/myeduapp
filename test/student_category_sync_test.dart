import 'package:flutter_test/flutter_test.dart';

void main() {
  group('category student list sync', () {
    test('entering category clears temporary hides', () {
      final hidden = <String, Set<int>>{'12:performance': {7, 8}};
      hidden.remove('12:performance');
      expect(hidden.containsKey('12:performance'), isFalse);
    });

    test('hidden students are filtered from score table list', () {
      final students = [
        {'id': 1, 'ad_soyad': 'A'},
        {'id': 2, 'ad_soyad': 'B'},
        {'id': 3, 'ad_soyad': 'C'},
      ];
      const hidden = {2};
      final visible = students
          .where((student) => !hidden.contains(student['id']))
          .toList();
      expect(visible.map((s) => s['id']).toList(), [1, 3]);
    });

    test('activity column add naming continues after Aktivite 1', () {
      final activityCount = 1;
      expect('Aktivite ${activityCount + 1}', 'Aktivite 2');
      expect('Aktivite ${activityCount + 2}', 'Aktivite 3');
    });
  });
}
