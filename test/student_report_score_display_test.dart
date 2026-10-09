import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/utils/student_report_score_display.dart';

void main() {
  test('studentReportScoreDescription uses per-date column description', () {
    expect(
      studentReportScoreDescription({
        'aciklama': '',
        'kolon_tarih_aciklama': 'Kitap ozeti',
        'kolon_aciklama': 'Son global metin',
        'kolon_ad': 'Aktivite 2',
      }),
      'Kitap ozeti',
    );
  });

  test('studentReportScoreDescription is empty without per-date text', () {
    expect(
      studentReportScoreDescription({
        'kolon_aciklama': 'Global metin',
        'kolon_ad': 'Aktivite 1',
      }),
      '',
    );
  });

  test('studentReportScoreTypeLabel includes activity column name', () {
    expect(
      studentReportScoreTypeLabel(
        categoryCode: 'activity',
        categoryLabel: 'Activities',
        columnName: 'Aktivite 2',
      ),
      'Activities — Aktivite 2',
    );
  });
}
