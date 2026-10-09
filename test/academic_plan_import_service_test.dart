import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/services/academic_plan_import_service.dart';

void main() {
  test('CSV import maps daily plan columns', () async {
    final file = File(
      '${Directory.systemTemp.path}/myedu_daily_plan_test.csv',
    );
    await file.writeAsString(
      'tarih,konu,hedefler\n2026-01-01,Matematik,Oran kavramı\n',
    );
    final service = AcademicPlanImportService();
    final plans = await service.parseFile(
      path: file.path,
      kind: AcademicPlanImportKind.daily,
    );
    expect(plans.length, 1);
    expect(plans.first['tarih'], '2026-01-01');
    expect(plans.first['konu'], 'Matematik');
    expect(plans.first['hedefler'], 'Oran kavramı');
  });

  test('CSV import maps annual plan columns', () async {
    final file = File(
      '${Directory.systemTemp.path}/myedu_annual_plan_test.csv',
    );
    await file.writeAsString(
      'ogretim_yili,unite_konu,ders_saati\n2025-2026,Cebir,12\n',
    );
    final service = AcademicPlanImportService();
    final plans = await service.parseFile(
      path: file.path,
      kind: AcademicPlanImportKind.annual,
    );
    expect(plans.length, 1);
    expect(plans.first['ogretim_yili'], '2025-2026');
    expect(plans.first['unite_konu'], 'Cebir');
    expect(plans.first['ders_saati'], 12);
  });
}
