import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/widgets/design/design_info_row.dart';
import 'package:my_edu_app/widgets/design/design_pill_tabs.dart';
import 'package:my_edu_app/widgets/design/design_stat_card.dart';

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
  testWidgets('DesignPillTabs renders tabs', (tester) async {
    var selected = 0;
    await tester.binding.setSurfaceSize(const Size(390, 200));
    await tester.pumpWidget(
      _wrap(
        DesignPillTabs(
          tabs: const ['Bilgiler', 'Notlar', 'Devamsızlık'],
          selectedIndex: selected,
          onSelected: (i) => selected = i,
        ),
      ),
    );
    expect(find.text('Bilgiler'), findsOneWidget);
    await tester.tap(find.text('Notlar'));
    await tester.pump();
    expect(selected, 1);
  });

  testWidgets('DesignInfoRow shows label and value', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DesignInfoRow(
          icon: Icons.person,
          label: 'Ad Soyad',
          value: 'Test Öğrenci',
        ),
      ),
    );
    expect(find.text('Test Öğrenci'), findsOneWidget);
  });

  testWidgets('DesignStatCard at 1280 width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 200));
    await tester.pumpWidget(
      _wrap(
        const DesignStatCard(
          label: 'Öğrenci',
          value: '248',
          icon: Icons.school,
          tint: Color(0xFF14B8A6),
        ),
      ),
    );
    expect(find.text('248'), findsOneWidget);
  });
}
