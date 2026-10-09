import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/widgets/design/design_feed_row.dart';
import 'package:my_edu_app/widgets/design/design_grouped_list_card.dart';
import 'package:my_edu_app/widgets/design/design_month_grid_calendar.dart';
import 'package:my_edu_app/widgets/design/design_portal_page_layout.dart';
import 'package:my_edu_app/widgets/design/design_scroll_filter_pills.dart';

void main() {
  final widths = [360.0, 390.0, 430.0, 768.0, 1024.0, 1280.0, 1440.0, 1920.0];

  testWidgets('portal layout at 8 breakpoints', (tester) async {
    for (final w in widths) {
      await tester.binding.setSurfaceSize(Size(w, 720));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignPortalPageLayout(
              title: 'Duyurular',
              filterLabels: const ['Tümü', 'Okul'],
              selectedFilterIndex: 0,
              onFilterSelected: (_) {},
              body: DesignGroupedListCard(
                children: const [
                  DesignFeedRow(
                    title: 'Test',
                    subtitle: 'Önizleme',
                    dateLabel: '1 Mar',
                    icon: Icons.campaign_outlined,
                    iconBackground: Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('calendar and filters at narrow widths', (tester) async {
    for (final w in [360.0, 390.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(w, 500));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                DesignScrollFilterPills(
                  labels: const ['Tümü', 'Okul', 'Sınıf', 'Veli'],
                  selectedIndex: 0,
                  onSelected: (_) {},
                ),
                DesignMonthGridCalendar(
                  hasEventsOnDate: (_) => false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
}
